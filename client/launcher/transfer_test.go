package main

import (
	"bytes"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"sync"
	"testing"
	"time"
)

// resetTransfers leaves dl as a test found it: unlimited, not paused.
func resetTransfers(t *testing.T) {
	t.Cleanup(func() {
		dl.Resume()
		dl.SetLimit(0)
	})
}

// The limit is one for all parallel transfers together, and a new limit applies to a running download.
func TestLimiter(t *testing.T) {
	resetTransfers(t)
	body := bytes.Repeat([]byte("x"), 1_500_000)
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { w.Write(body) }))
	defer srv.Close()
	server = srv.URL

	timed := func(n int) time.Duration {
		start := time.Now()
		var wg sync.WaitGroup
		for i := 0; i < n; i++ {
			wg.Add(1)
			go func() {
				defer wg.Done()
				if b, err := get(fmt.Sprintf("/f%d", i), &tracker{start: time.Now()}); err != nil || len(b) != len(body) {
					t.Errorf("download %d: %d bytes, %v", i, len(b), err)
				}
			}()
		}
		wg.Wait()
		return time.Since(start)
	}

	if d := timed(2); d > time.Second {
		t.Errorf("unlimited: 3 MB took %v", d)
	}

	dl.SetLimit(2_000_000) // 2 MB/s for both: 3 MB take (3 - 0.5 burst) / 2 = 1.25 s at least
	if d := timed(2); d < 1100*time.Millisecond || d > 3*time.Second {
		t.Errorf("2 MB/s shared by 2 downloads of 1.5 MB: took %v, want about 1.25-1.5 s", d)
	}

	dl.SetLimit(300_000) // 1.5 MB would take 5 s; lifting the limit after 0.3 s finishes it at once
	time.AfterFunc(300*time.Millisecond, func() { dl.SetLimit(0) })
	if d := timed(1); d > 1500*time.Millisecond {
		t.Errorf("limit lifted during the download: took %v", d)
	}
}

// Pause stops the install's transfer and keeps the .part; Resume continues it with a Range request.
func TestPauseResume(t *testing.T) {
	resetTransfers(t)
	big := bytes.Repeat([]byte("0123456789"), 300_000) // 3 MB
	files := map[string][]byte{
		".build.info":        []byte("Branch!STRING:0|Active!DEC:1\neu|1\n"),
		"Data/data/data.000": big,
	}
	s := newClientServer(t, files)
	root := t.TempDir()
	part := filepath.Join(root, "Data", "data", "data.000.part")
	partSize := func() int64 {
		st, err := os.Stat(part)
		if err != nil {
			return -1
		}
		return st.Size()
	}

	dl.SetLimit(1_000_000) // slow enough to pause in the middle
	done := make(chan string, 1)
	go func() { done <- panicText(func() { install(root) }) }()
	time.Sleep(800 * time.Millisecond)
	dl.Pause()
	time.Sleep(300 * time.Millisecond) // the cancelled request ends
	paused := partSize()
	if paused <= 0 || paused >= int64(len(big)) {
		t.Fatalf("after the pause the .part holds %d of %d bytes", paused, len(big))
	}
	s.mu.Lock()
	hits := s.hits["Data/data/data.000"]
	s.mu.Unlock()
	time.Sleep(700 * time.Millisecond)
	s.mu.Lock()
	if s.hits["Data/data/data.000"] != hits {
		t.Error("requests while paused")
	}
	s.mu.Unlock()
	if partSize() != paused {
		t.Errorf("the .part grew while paused: %d -> %d", paused, partSize())
	}
	select {
	case msg := <-done:
		t.Fatalf("the install ended while paused: %q", msg)
	default:
	}

	dl.SetLimit(0)
	dl.Resume()
	select {
	case msg := <-done:
		if msg != "" {
			t.Fatalf("install after resume: %s", msg)
		}
	case <-time.After(10 * time.Second):
		t.Fatal("no end after resume")
	}
	checkFiles(t, root, files)
	if want := fmt.Sprintf("bytes=%d-", paused); s.ranges["Data/data/data.000"] != want {
		t.Errorf("resume: Range %q, want %q", s.ranges["Data/data/data.000"], want)
	}
}
