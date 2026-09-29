// Download control shared by every transfer that shows progress (the client install, game updates, the launcher's
// own update): the player's bandwidth limit (one limit for all parallel transfers together) and pause. Pausing cancels
// the running requests; the client install's .part files keep what came, and resuming continues them with the same
// Range path an interrupted install uses (getFile/getPart). Game update files are small and held in memory: they come
// again from the start. The manifest, news and status (no tracker) are never paused or limited.
package main

import (
	"context"
	"io"
	"sync"
	"time"
)

var dl = &transfers{}

// downloading is told when transfers start (true) and when the last one ends (false). The window shows the pause
// button with it.
var downloading = func(on bool) {}

type transfers struct {
	mu     sync.Mutex
	limit  int64   // bytes per second, 0 = unlimited
	tokens float64 // bytes that may be read now (negative: read ahead of the limit)
	last   time.Time
	paused bool
	resume chan struct{} // closed on Resume
	ctx    context.Context
	cancel context.CancelFunc
	active int // running transfers
}

// SetLimit sets the limit in bytes per second (0 = unlimited). It applies to reads that are waiting right now too.
func (d *transfers) SetLimit(bps int64) {
	d.mu.Lock()
	d.limit = max(bps, 0)
	d.tokens = min(d.tokens, d.burst())
	d.mu.Unlock()
}

func (d *transfers) Limit() int64 {
	d.mu.Lock()
	defer d.mu.Unlock()
	return d.limit
}

// burst is how far the limit lets reads get ahead: a quarter of a second.
func (d *transfers) burst() float64 { return float64(d.limit) / 4 }

// reqContext is cancelled on Pause; transfers make their requests with it.
func (d *transfers) reqContext() context.Context {
	d.mu.Lock()
	defer d.mu.Unlock()
	if d.ctx == nil {
		d.ctx, d.cancel = context.WithCancel(context.Background())
	}
	return d.ctx
}

// Pause stops every running transfer (their requests are cancelled) until Resume.
func (d *transfers) Pause() {
	d.mu.Lock()
	defer d.mu.Unlock()
	if d.paused {
		return
	}
	d.paused, d.resume = true, make(chan struct{})
	if d.cancel != nil {
		d.cancel()
	}
	d.ctx, d.cancel = context.WithCancel(context.Background())
	d.cancel() // requests made while paused fail at once and wait in waitResume
}

func (d *transfers) Resume() {
	d.mu.Lock()
	defer d.mu.Unlock()
	if !d.paused {
		return
	}
	d.paused = false
	close(d.resume)
	d.ctx, d.cancel = context.WithCancel(context.Background())
}

func (d *transfers) Paused() bool {
	d.mu.Lock()
	defer d.mu.Unlock()
	return d.paused
}

// waitResume blocks while paused and tells whether it did (a failed transfer then tries again at once, and the
// pause does not count as time without progress).
func (d *transfers) waitResume() bool {
	d.mu.Lock()
	paused, ch := d.paused, d.resume
	d.mu.Unlock()
	if !paused {
		return false
	}
	<-ch
	return true
}

// busy tells whether a transfer is running.
func (d *transfers) busy() bool {
	d.mu.Lock()
	defer d.mu.Unlock()
	return d.active > 0
}

// start counts a running transfer; call the returned func when it ends.
func (d *transfers) start() func() {
	d.mu.Lock()
	d.active++
	first := d.active == 1
	d.mu.Unlock()
	if first {
		downloading(true)
	}
	return func() {
		d.mu.Lock()
		d.active--
		last := d.active == 0
		d.mu.Unlock()
		if last {
			downloading(false)
		}
	}
}

// wait blocks until the limit allows the next read and returns how many bytes it may read (0 = any), or ctx's error.
func (d *transfers) wait(ctx context.Context) (int, error) {
	for {
		d.mu.Lock()
		if d.limit <= 0 {
			d.mu.Unlock()
			return 0, ctx.Err()
		}
		now := time.Now()
		if !d.last.IsZero() {
			d.tokens = min(d.tokens+now.Sub(d.last).Seconds()*float64(d.limit), d.burst())
		}
		d.last = now
		if d.tokens > 0 {
			chunk := max(int(d.limit/20), 4096) // 50 ms of it: the parallel transfers take turns
			d.mu.Unlock()
			return chunk, ctx.Err()
		}
		sleep := time.Duration(-d.tokens/float64(d.limit)*float64(time.Second)) + time.Millisecond
		d.mu.Unlock()
		select {
		case <-ctx.Done():
			return 0, ctx.Err()
		case <-time.After(min(sleep, 100*time.Millisecond)): // a new limit is picked up within 0.1 s
		}
	}
}

func (d *transfers) take(n int) {
	d.mu.Lock()
	if d.limit > 0 {
		d.tokens -= float64(n)
	}
	d.mu.Unlock()
}

// limited reads r within the shared limit; ctx (the request's) ends a wait.
type limited struct {
	ctx context.Context
	r   io.Reader
}

func (l limited) Read(p []byte) (int, error) {
	chunk, err := dl.wait(l.ctx)
	if err != nil {
		return 0, err
	}
	if chunk > 0 && len(p) > chunk {
		p = p[:chunk]
	}
	n, err := l.r.Read(p)
	dl.take(n)
	return n, err
}
