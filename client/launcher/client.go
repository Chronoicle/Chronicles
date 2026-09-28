// The whole client: installing it into a folder without one, and "repair". The server lists the client's files in
// client.json ({"files": [{"path", "size", "md5"}]}, the manifest's "client") and serves them next to it
// (/client/<path>, with HTTP Range). Files are downloaded 4 at a time and streamed to disk through <file>.part,
// which a later try (or launcher start) continues.
package main

import (
	"context"
	"crypto/md5"
	"encoding/binary"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
	"time"
)

// fetchClient returns the server folder of the client files and their list. One bad entry rejects the whole list.
func fetchClient(man Manifest) (string, []File) {
	if man.Client == "" {
		panic("the server does not offer the client download yet")
	}
	var list struct {
		Files []File `json:"files"`
	}
	must(json.Unmarshal(download(man.Client, nil), &list))
	seen := map[string]bool{}
	for _, f := range list.Files {
		key := strings.ToLower(f.Path) // Windows: one file
		if clientPath(".", f.Path) == "" || !md5Hex.MatchString(f.MD5) || f.Size < 0 || f.Size > 1<<40 || seen[key] {
			panic("bad client file list from the server: " + f.Path)
		}
		seen[key] = true
	}
	if len(list.Files) == 0 {
		panic("bad client file list from the server: no files")
	}
	return path.Dir(man.Client), list.Files
}

// clientPath turns a client.json path into a path in root, or "" unless it is a plain relative "/" path to
// .build.info, BlizzardError.exe or a file under Data/ or Utils/ (the server must not be able to write anywhere else,
// like addonPath). Each part is only letters, digits, '_', '.' and '-' and does not end in '.' or ".part" (any case),
// and no part is a Windows device name (IsLocal: NUL, COM1.txt...): Windows would take "a." for "a", a device for a
// file, and x.part (x.PART) is the download of x. No *.launcher-backup either: on an install they would name index
// files the game has deleted, and "restore" would break the client.
func clientPath(root, p string) string {
	for _, part := range strings.Split(p, "/") {
		if !clientName.MatchString(part) || strings.HasSuffix(part, ".") || strings.HasSuffix(strings.ToLower(part), ".part") {
			return ""
		}
	}
	if !filepath.IsLocal(filepath.FromSlash(p)) || strings.HasSuffix(p, backupSuffix) {
		return ""
	}
	switch {
	case p == ".build.info", p == "BlizzardError.exe",
		strings.HasPrefix(p, "Data/"), strings.HasPrefix(p, "Utils/"):
		return filepath.Join(root, filepath.FromSlash(p))
	}
	return ""
}

const noSpace = "Not enough disk space" // setup forgets the folder on this error

var clientName = regexp.MustCompile(`^[A-Za-z0-9_.-]+$`)

// installed tells whether root holds a client. The install writes .build.info last, so it means a whole one.
func installed(root string) bool {
	_, err := os.Stat(filepath.Join(root, ".build.info"))
	return err == nil
}

// isClient tells whether root holds a 7.3.5 client (a retail or Classic folder has a .build.info too).
func isClient(root string) (ok bool) {
	defer func() { recover() }()
	return readBuildInfo(root).version == baseVersion
}

// started tells whether root holds an interrupted install: no .build.info (it comes last), but the CASC folders the
// install writes first (an old MPQ client, 3.3.5 to 5.4.8, has Data/ but neither).
func started(root string) bool {
	if installed(root) {
		return false
	}
	for _, p := range []string{"config", "data"} {
		if _, err := os.Stat(filepath.Join(root, "Data", p)); err == nil {
			return true
		}
	}
	return false
}

// installDir is where the client goes when the player picks folder: the folder itself when it is empty, named
// Chronicles, holds a 7.3.5 client or an interrupted install (picked again: go on there), else a Chronicles folder
// in it.
func installDir(picked string) string {
	entries, err := os.ReadDir(picked)
	if (err == nil && len(entries) == 0) || strings.EqualFold(filepath.Base(picked), "Chronicles") ||
		isClient(picked) || started(picked) {
		return picked
	}
	return filepath.Join(picked, "Chronicles")
}

// installClient downloads every file of the list that root does not have in the right size (a .part an interrupted
// install left is continued).
func installClient(root, base string, files []File) {
	must(os.MkdirAll(root, 0755))
	var need []File
	for _, f := range files {
		if st, err := os.Stat(clientPath(root, f.Path)); err != nil || st.Size() != f.Size {
			need = append(need, f)
		}
	}
	getClientFiles(root, base, "Installing World of Warcraft: Legion", need)
}

// repair checks the client in root against client.json and downloads what is missing or broken. The rule: it never
// touches .build.info, Data/data/shmem or the launcher's backups (*.launcher-backup) and never overwrites a file in
// Data/data/. update() (main.go) rewrites .build.info and shmem and adds archives and index versions, the game writes
// shmem and archives and deletes old index versions, so on a client updated since its install those differ from the
// server's copies, and an archive number or index version client.json lists may hold other data there. In Data/data/
// it only downloads a listed file that is missing and needed: a data.NNN archive, or the index version shmem names now
// (the other versions are gone on purpose). Every other listed file (Data/config, Data/indices, the locales, Utils,
// BlizzardError.exe) is checked by size and md5 and downloaded again when it differs.
func repair(root string, man Manifest) {
	base, files := fetchClient(man)
	current := map[string]bool{} // the index files shmem names (see update)
	shmem, _ := os.ReadFile(filepath.Join(root, "Data", "data", "shmem"))
	for b := 0; b < 16 && len(shmem) >= shmemVersion+64; b++ {
		current[idxName(b, binary.LittleEndian.Uint32(shmem[shmemVersion+4*b:]))] = true
	}
	t := &tracker{label: "Checking the client files", start: time.Now()}
	var check, broken []File
	for _, f := range files {
		dir, name := path.Split(f.Path)
		switch {
		case f.Path == ".build.info" || f.Path == "Data/data/shmem" || strings.HasSuffix(f.Path, backupSuffix):
		case dir == "Data/data/":
			_, err := os.Stat(clientPath(root, f.Path))
			if os.IsNotExist(err) && (strings.HasPrefix(name, "data.") || current[name]) {
				broken = append(broken, f)
			}
		default:
			check = append(check, f)
			t.total += f.Size
		}
	}
	say(t.label)
	for _, f := range check {
		if !fileOK(clientPath(root, f.Path), f, t) {
			broken = append(broken, f)
		}
	}
	getClientFiles(root, base, fmt.Sprintf("Repairing %d client files", len(broken)), broken)
}

// fileOK tells whether p has f's size and md5. The bytes count on t (a missing or wrong-size file all at once).
func fileOK(p string, f File, t *tracker) bool {
	if fd, err := os.Open(p); err == nil {
		defer fd.Close()
		if st, err := fd.Stat(); err == nil && st.Size() == f.Size {
			h := md5.New()
			_, err := io.Copy(io.MultiWriter(h, t), fd)
			return err == nil && hex.EncodeToString(h.Sum(nil)) == f.MD5
		}
	}
	t.add(f.Size)
	return false
}

// getClientFiles downloads files into root after checking that the drive has room for them plus 1 GB. .build.info
// comes last: a folder with a .build.info holds a whole client (installed).
func getClientFiles(root, base, label string, files []File) {
	if len(files) == 0 {
		return
	}
	t := &tracker{label: label, start: time.Now()}
	var rest, last []File
	for _, f := range files {
		t.total += f.Size - partSize(clientPath(root, f.Path), f.Size)
		if f.Path == ".build.info" {
			last = append(last, f)
		} else {
			rest = append(rest, f)
		}
	}
	if free := diskFree(root); free >= 0 && free < t.total+(1<<30) {
		panic(fmt.Sprintf(noSpace+" for %s: it needs %.1f GB more (and 1 GB to spare), %.1f GB are free. Free some space, "+
			"or press refresh to choose another folder.",
			root, float64(t.total)/1e9, float64(free)/1e9))
	}
	say(label)
	getFiles(root, base, rest, t)
	getFiles(root, base, last, t)
}

// partSize is how much of dst an earlier try left in dst.part (0 when there is none or it is too big to continue).
func partSize(dst string, size int64) int64 {
	if st, err := os.Stat(dst + ".part"); err == nil && st.Size() <= size {
		return st.Size()
	}
	return 0
}

// getFiles downloads files into root, 4 at a time. The first failure stops handing out files; it is raised here once
// the others have finished the file they are on.
// ponytail: those finish their file (up to ~1 GB) before the error shows; cancel them with a context if that annoys.
func getFiles(root, base string, files []File, t *tracker) {
	var mu sync.Mutex
	var wg sync.WaitGroup
	var fail any
	next := 0
	for range 4 {
		wg.Add(1)
		go func() {
			defer wg.Done()
			defer func() {
				if r := recover(); r != nil {
					mu.Lock()
					if fail == nil {
						fail = r
					}
					mu.Unlock()
				}
			}()
			for {
				mu.Lock()
				if fail != nil || next == len(files) {
					mu.Unlock()
					return
				}
				f := files[next]
				next++
				mu.Unlock()
				getFile(base+(&url.URL{Path: "/" + f.Path}).EscapedPath(), clientPath(root, f.Path), f, t)
			}
		}()
	}
	wg.Wait()
	if fail != nil {
		panic(fail)
	}
}

var errBadMD5 = errors.New("wrong md5")

// getFile downloads f from src to dst through dst.part (getPart). Network errors are tried again after 1, 2, 4... up to
// 30 seconds, until 10 minutes pass without a byte (a router restart or a laptop's sleep must not end a 72 GB install;
// the .part keeps what came); a wrong md5 deletes the .part and starts over once.
func getFile(src, dst string, f File, t *tracker) {
	must(os.MkdirAll(filepath.Dir(dst), 0755))
	part := dst + ".part"
	for bad, wait, last := 0, time.Second, time.Now(); ; {
		got, err := getPart(src, part, f, t)
		if err == nil {
			must(os.Rename(part, dst))
			return
		}
		if err == errBadMD5 {
			os.Remove(part)
			if bad++; bad == 2 {
				panic("download of " + f.Path + " is corrupt twice (its md5 is not the server's)")
			}
			t.grow(f.Size)
			continue
		}
		if got > 0 {
			wait, last = time.Second, time.Now()
		}
		if time.Since(last) > 10*time.Minute {
			panic(fmt.Sprintf("cannot download %s: %v (is the server up?)", f.Path, err))
		}
		time.Sleep(wait)
		wait = min(2*wait, 30*time.Second)
	}
}

// getPart brings part up to f.Size bytes from src (an existing part is hashed, then continued with a Range request)
// and checks the md5 of the whole. It returns how many bytes it downloaded.
func getPart(src, part string, f File, t *tracker) (int64, error) {
	fd, err := os.OpenFile(part, os.O_RDWR|os.O_CREATE, 0644)
	must(err)
	defer fd.Close()
	h := md5.New()
	have, err := io.Copy(h, fd) // leaves fd at the end: new bytes are appended
	must(err)
	restart := func() {
		must(fd.Truncate(0))
		_, err := fd.Seek(0, io.SeekStart)
		must(err)
		h.Reset()
		have = 0
	}
	if have > f.Size {
		restart()
	}
	var got int64
	if have < f.Size {
		ctx, cancel := context.WithCancel(context.Background())
		defer cancel()
		stall := time.AfterFunc(time.Minute, cancel) // no data for a minute: give this try up
		defer stall.Stop()
		req, err := http.NewRequestWithContext(ctx, "GET", server+src, nil)
		must(err)
		if have > 0 {
			req.Header.Set("Range", fmt.Sprintf("bytes=%d-", have))
		}
		resp, err := http.DefaultClient.Do(req)
		if err != nil {
			return 0, err
		}
		defer resp.Body.Close()
		switch {
		case resp.StatusCode == 206 && strings.HasPrefix(resp.Header.Get("Content-Range"), fmt.Sprintf("bytes %d-", have)):
		case resp.StatusCode == 200:
			if have > 0 { // the server sent the whole file after all
				t.grow(have)
				restart()
			}
		case resp.StatusCode >= 400 && resp.StatusCode < 500 && resp.StatusCode != 408 && resp.StatusCode != 429:
			// not there (or not allowed): waiting will not help (408 timeout and 429 too many requests will)
			panic(fmt.Sprintf("cannot download %s: %s", f.Path, resp.Status))
		default:
			return 0, errors.New(resp.Status)
		}
		got, err = io.CopyBuffer(io.MultiWriter(fd, h, t, watchdog{stall}), io.LimitReader(resp.Body, f.Size-have), make([]byte, 1<<20))
		if err == nil && have+got < f.Size {
			err = io.ErrUnexpectedEOF
		}
		if err != nil {
			return got, err
		}
	}
	if hex.EncodeToString(h.Sum(nil)) != f.MD5 {
		return got, errBadMD5
	}
	must(fd.Sync()) // on disk before the rename: a power cut must not leave a whole-size file with a zeroed tail
	return got, nil
}

// watchdog restarts its timer on every chunk that arrives (see getPart's stall).
type watchdog struct{ *time.Timer }

func (w watchdog) Write(p []byte) (int, error) {
	w.Reset(time.Minute)
	return len(p), nil
}
