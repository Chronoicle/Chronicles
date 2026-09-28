package main

import (
	"bytes"
	"crypto/md5"
	"encoding/binary"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"testing"
	"time"
)

// clientServer serves files under /client/ (Range requests through http.ServeContent) and lists them in
// /client/client.json; wrong[p] makes the list's md5 for p that of other bytes. It counts requests and Range headers.
type clientServer struct {
	mu     sync.Mutex
	files  map[string][]byte
	wrong  map[string]bool
	hits   map[string]int
	ranges map[string]string
}

func newClientServer(t *testing.T, files map[string][]byte) *clientServer {
	s := &clientServer{files: files, wrong: map[string]bool{}, hits: map[string]int{}, ranges: map[string]string{}}
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		s.mu.Lock()
		p := strings.TrimPrefix(r.URL.Path, "/client/")
		if p == "client.json" {
			var list struct {
				Files []File `json:"files"`
			}
			for p, b := range s.files {
				if s.wrong[p] {
					b = []byte("other")
				}
				list.Files = append(list.Files, File{Path: p, Size: int64(len(s.files[p])), MD5: md5hex(b)})
			}
			s.mu.Unlock()
			json.NewEncoder(w).Encode(list)
			return
		}
		b, ok := s.files[p]
		s.hits[p]++
		s.ranges[p] = r.Header.Get("Range")
		s.mu.Unlock()
		if !ok {
			http.NotFound(w, r)
			return
		}
		http.ServeContent(w, r, p, time.Time{}, bytes.NewReader(b))
	}))
	t.Cleanup(srv.Close)
	server = srv.URL
	return s
}

func md5hex(b []byte) string { s := md5.Sum(b); return hex.EncodeToString(s[:]) }

var clientMan = Manifest{Client: "/client/client.json"}

func install(root string) {
	base, files := fetchClient(clientMan)
	installClient(root, base, files)
}

func panicText(f func()) (msg string) {
	defer func() {
		if r := recover(); r != nil {
			msg = fmt.Sprint(r)
		}
	}()
	f()
	return ""
}

func checkFiles(t *testing.T, root string, files map[string][]byte) {
	t.Helper()
	for p, want := range files {
		if got, err := os.ReadFile(filepath.Join(root, filepath.FromSlash(p))); err != nil || !bytes.Equal(got, want) {
			t.Errorf("%s: not the server's file (%v)", p, err)
		}
		if _, err := os.Stat(filepath.Join(root, filepath.FromSlash(p)) + ".part"); err == nil {
			t.Errorf("%s.part left behind", p)
		}
	}
}

// Install: a fresh one, one continued from a .part (Range), a complete file skipped, a wrong md5 retried then failed.
func TestClientInstall(t *testing.T) {
	big := bytes.Repeat([]byte("0123456789"), 50000)
	files := map[string][]byte{
		".build.info":        []byte("Branch!STRING:0|Active!DEC:1\neu|1\n"),
		"BlizzardError.exe":  []byte("MZ error reporter"),
		"Data/data/data.000": big,
	}
	s := newClientServer(t, files)

	root := filepath.Join(t.TempDir(), "Chronicles")
	install(root)
	checkFiles(t, root, files)
	if !installed(root) {
		t.Fatal("not installed")
	}

	root = t.TempDir()
	os.MkdirAll(filepath.Join(root, "Data", "data"), 0755)
	os.WriteFile(filepath.Join(root, "Data", "data", "data.000.part"), big[:123456], 0644)
	os.WriteFile(filepath.Join(root, "BlizzardError.exe"), files["BlizzardError.exe"], 0644)
	s.hits = map[string]int{}
	install(root)
	checkFiles(t, root, files)
	if s.ranges["Data/data/data.000"] != "bytes=123456-" {
		t.Errorf("part not continued: Range %q", s.ranges["Data/data/data.000"])
	}
	if s.hits["BlizzardError.exe"] != 0 {
		t.Error("a complete file was downloaded again")
	}

	root = t.TempDir()
	s.wrong["Data/data/data.000"] = true
	s.hits = map[string]int{}
	if msg := panicText(func() { install(root) }); !strings.Contains(msg, "Data/data/data.000") {
		t.Errorf("wrong md5: want an error naming the file, got %q", msg)
	}
	if s.hits["Data/data/data.000"] != 2 {
		t.Errorf("wrong md5: want 2 tries, got %d", s.hits["Data/data/data.000"])
	}
	if installed(root) {
		t.Error(".build.info written although the install failed")
	}
}

// Paths client.json may not use, in the list and one by one; where a picked folder gets the client.
func TestClientPaths(t *testing.T) {
	bad := []string{"../x", "/etc/x", `C:\x`, "C:/x", "Interface/AddOns/x.lua", "WTF/Config.wtf",
		"Data/../x", "Data/./x", "Data//x", "Data/", `Data\x`, "Data/x:stream", "Wow.exe", "", ".", "Data",
		"Data/a.", "Data/a ", "Data/with space", "Utils/WOWBRO~1.EXE", "Data/data/data.000.part", "Data/x.part/y",
		"Data/x.PART", "Data/x.Part", ".build.info.launcher-backup", "Data/data/shmem.launcher-backup"}
	if runtime.GOOS == "windows" { // device names (IsLocal; with an extension, like com1.txt, only where Windows says so)
		bad = append(bad, "Data/NUL", "Data/data/LPT1", "Utils/COM3", "Utils/aux")
	}
	for _, p := range bad {
		if clientPath("root", p) != "" {
			t.Errorf("path %q accepted", p)
		}
	}
	for _, good := range []string{".build.info", "BlizzardError.exe",
		"Data/data/data.000", "Data/data/0e0000004d.idx", "Data/enGB/x", "Utils/x.dll", "Utils/a-b_c.1.pak"} {
		if clientPath("root", good) == "" {
			t.Errorf("path %q rejected", good)
		}
	}
	newClientServer(t, map[string][]byte{"Data/x": []byte("x"), "WTF/Config.wtf": []byte("x")})
	if msg := panicText(func() { fetchClient(clientMan) }); !strings.Contains(msg, "WTF/Config.wtf") {
		t.Errorf("a list with a bad path was accepted (%q)", msg)
	}

	dir := t.TempDir()
	if installDir(dir) != dir {
		t.Error("an empty folder is not used as is")
	}
	os.WriteFile(filepath.Join(dir, "x"), nil, 0644)
	if installDir(dir) != filepath.Join(dir, "Chronicles") {
		t.Error("no Chronicles folder in a full folder")
	}
	buildInfo := func(version string) {
		os.WriteFile(filepath.Join(dir, ".build.info"), []byte("Active!DEC:1|Build Key!HEX:16|Version!STRING:0\n1|0123|"+version), 0644)
	}
	buildInfo("11.0.2.56313")
	os.Mkdir(filepath.Join(dir, "Data"), 0755)
	if installDir(dir) != filepath.Join(dir, "Chronicles") {
		t.Error("a retail client counts as ours")
	}
	buildInfo(baseVersion)
	if installDir(dir) != dir {
		t.Error("a 7.3.5 client is not used as is")
	}
	os.Remove(filepath.Join(dir, ".build.info")) // Data/ alone: an old MPQ client (3.3.5), not ours
	if installDir(dir) != filepath.Join(dir, "Chronicles") {
		t.Error("an old MPQ client counts as an interrupted install")
	}
	os.Mkdir(filepath.Join(dir, "Data", "config"), 0755) // an interrupted install: picked again, it goes on there
	if installDir(dir) != dir {
		t.Error("an install with Data/config is not continued")
	}
}

// testIndex is an index file (see readIndex) with one record in archive a.
func testIndex(a int) []byte {
	h := make([]byte, 16)
	copy(h[4:], []byte{4, 5, 9, 30})
	ix := &index{header: h, pad: 32, records: map[string][]byte{}}
	ix.set(make([]byte, 9), a, 0, 30)
	return ix.bytes()
}

// Repair of a client updated twice since its install, after which the game deleted the original versions of the
// indexes it changed: missing needed Data/data files (an archive, the index version shmem names) and broken or missing
// other files come again; existing Data/data files, .build.info, shmem and the deleted index versions stay as they are.
func TestClientRepair(t *testing.T) {
	shmem := make([]byte, 400)
	binary.LittleEndian.PutUint32(shmem, 4)
	for b := 0; b < 16; b++ {
		binary.LittleEndian.PutUint32(shmem[shmemVersion+4*b:], 1)
	}
	files := map[string][]byte{
		".build.info":                []byte("server build info"),
		"Data/data/shmem":            shmem,
		"Data/data/data.000":         []byte("archive zero"),
		"Data/data/data.001":         []byte("archive one"),
		"Data/config/01/23/0123abcd": []byte("build config"),
		"Utils/u.txt":                []byte("utility"),
	}
	for b := 0; b < 16; b++ {
		files["Data/data/"+idxName(b, 1)] = testIndex(1)
	}
	s := newClientServer(t, files)
	root := t.TempDir()
	install(root)

	played := append([]byte{}, shmem...) // two updates of buckets 0 and 5: versions 2 and 3, archives 2 and 3
	binary.LittleEndian.PutUint32(played[shmemVersion:], 3)
	binary.LittleEndian.PutUint32(played[shmemVersion+4*5:], 3)
	local := map[string][]byte{
		".build.info":                []byte("player build info"),
		"Data/data/shmem":            played,
		"Data/data/data.001":         []byte("archive one, as the game left it"),
		"Data/data/data.002":         []byte("first update"),
		"Data/data/data.003":         []byte("second update"),
		"Data/data/" + idxName(0, 1): nil, // deleted by the game (listed, not named by shmem)
		"Data/data/" + idxName(5, 1): nil,
		"Data/data/" + idxName(0, 2): testIndex(2),
		"Data/data/" + idxName(0, 3): testIndex(3),
		"Data/data/" + idxName(5, 2): testIndex(2),
		"Data/data/" + idxName(5, 3): testIndex(3),
		"Data/data/" + idxName(9, 1): testIndex(9), // the player's own copy of a listed index
	}
	for p, b := range local {
		if b == nil {
			os.Remove(filepath.Join(root, filepath.FromSlash(p)))
			delete(local, p)
		} else {
			os.WriteFile(filepath.Join(root, filepath.FromSlash(p)), b, 0644)
		}
	}
	os.Remove(filepath.Join(root, "Data", "data", "data.000"))
	os.Remove(filepath.Join(root, "Data", "data", idxName(7, 1))) // named by shmem: needed
	os.Remove(filepath.Join(root, "Data", "config", "01", "23", "0123abcd"))
	os.WriteFile(filepath.Join(root, "Utils", "u.txt"), []byte("utilitY"), 0644) // corrupt, same size
	s.hits = map[string]int{}
	repair(root, clientMan)

	for p, want := range map[string]int{"Data/data/data.000": 1, "Data/data/" + idxName(7, 1): 1,
		"Data/config/01/23/0123abcd": 1, "Utils/u.txt": 1, "Data/data/" + idxName(0, 1): 0, "Data/data/" + idxName(5, 1): 0} {
		if s.hits[p] != want {
			t.Errorf("%s downloaded %d times, want %d", p, s.hits[p], want)
		}
	}
	if n := len(s.hits); n != 4 {
		t.Errorf("%d files downloaded, want 4: %v", n, s.hits)
	}
	checkFiles(t, root, map[string][]byte{"Data/data/data.000": files["Data/data/data.000"],
		"Data/data/" + idxName(7, 1): testIndex(1), "Data/config/01/23/0123abcd": files["Data/config/01/23/0123abcd"],
		"Utils/u.txt": files["Utils/u.txt"]})
	checkFiles(t, root, local) // untouched
	if _, err := os.Stat(filepath.Join(root, "Data", "data", idxName(0, 1))); err == nil {
		t.Error("an index version the game deleted came back")
	}

	s.hits = map[string]int{}
	repair(root, clientMan)
	if len(s.hits) != 0 {
		t.Errorf("a second repair downloaded %v", s.hits)
	}
}
