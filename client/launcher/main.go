// Launcher for the server's custom 7.3.5 client build. Run it from the WoW folder (next to Wow-64_Patched.exe).
//
// On every start: ask the server which build is current (manifest.json). If this client is not on it yet, download
// the build's files and add them to this client's own local storage (a new data.NNN archive, one index version up
// for each touched bucket, shmem pointing at those versions, the build config, .build.info). Then start the game with
// Wow-64_Custom.exe (downloaded if missing or outdated). "Launcher.exe restore" puts the original .build.info and
// shmem back (the first backups it made), which makes the client use its original build again.
package main

import (
	"bytes"
	"crypto/md5"
	"encoding/binary"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"
)

var server = "http://184.174.37.33:8099" // patch/CDN server (ldflags -X main.server=... to change)

var portal = "184.174.37.33" // login server for WTF/Config.wtf "SET portal" (ldflags -X main.portal=... to change)

var selfUpdates = "yes" // "no" for test builds (-X main.selfUpdates=no): they would replace themselves with the live launcher

const (
	idxFileSize  = 0x110000
	shmemVersion = 272 // offset of the 16 index versions in shmem
	baseVersion  = "7.3.5.26972"
	backupSuffix = ".launcher-backup"
	gameExe      = "Wow-64_Custom.exe"
)

type Manifest struct {
	Build       string `json:"build"`        // build config key
	Blobs       []Blob `json:"blobs"`        // BLTE files of this build that stock clients do not have, in archive order
	Exe         string `json:"exe"`          // path of Wow-64_Custom.exe on the server
	ExeMD5      string `json:"exe_md5"`      // its md5
	ExeSize     int64  `json:"exe_size"`     // its size (for the progress bar)
	Launcher    string `json:"launcher"`     // path of the current Launcher.exe on the server
	LauncherMD5 string `json:"launcher_md5"` // its md5: a different one replaces this launcher
	Message     string `json:"message"`      // shown to the player, optional
}

type Blob struct {
	EKey string `json:"ekey"`
	Size int64  `json:"size"`
	Name string `json:"name"`
}

// UI hooks: the window (gui_windows.go) replaces these; the console version prints.
var (
	say      = func(text string) { fmt.Println(text) }
	progress = func(text string, pct float64) {}
)

func main() {
	root, args, test := exeDir(), os.Args[1:], false
	if len(args) > 1 && args[0] == "--dir" { // testing: use another folder, patch only, do not start the game
		root, args, test = args[1], args[2:], true
	}
	run(root, args, test)
}

// prepare brings the client in root up to the server's build and makes sure the game exe is there. It returns true
// when a newer launcher was started instead (this one should exit). Errors panic with a message for the player.
func prepare(root string, test bool) bool {
	say("Checking for updates...")
	man := fetchManifest()
	if !test && selfUpdates == "yes" && selfUpdate(man) {
		return true
	}
	info := readBuildInfo(root)
	if info.version != baseVersion {
		panic(fmt.Sprintf("this client is version %q; the server needs %s", info.version, baseVersion))
	}
	needBuild := info.buildKey != man.Build || !configExists(root, man.Build)
	needExe := !test && !exeOK(root, man)
	t := &tracker{start: time.Now()}
	if needBuild {
		for _, bl := range man.Blobs {
			t.total += bl.Size
		}
	}
	if needExe {
		t.total += man.ExeSize
	}
	if needBuild {
		update(root, info, man, t)
	}
	if needExe {
		downloadExe(root, man, t)
	}
	setPortal(root)
	if man.Message != "" {
		say(man.Message)
	} else {
		say("Ready to play")
	}
	progress("", 100)
	return false
}

// startGame runs Wow-64_Custom.exe from root (absolute path: Go refuses to run a program found relative to the
// current folder).
func startGame(root string) {
	dir, err := filepath.Abs(root)
	must(err)
	cmd := exec.Command(filepath.Join(dir, gameExe))
	cmd.Dir = dir
	must(cmd.Start())
}

func exeDir() string {
	exe, err := os.Executable()
	if err != nil {
		return "."
	}
	return filepath.Dir(exe)
}

// tracker turns downloaded bytes into the progress bar: percent of all bytes this run downloads, speed and time left.
type tracker struct {
	label        string
	done, total  int64
	start, shown time.Time
}

func (t *tracker) add(n int64) {
	t.done += n
	if time.Since(t.shown) < 100*time.Millisecond && t.done < t.total {
		return
	}
	t.shown = time.Now()
	pct, text := 0.0, t.label
	if t.total > 0 {
		pct = min(100, 100*float64(t.done)/float64(t.total))
		text += fmt.Sprintf("  •  %.1f / %.1f MB", float64(t.done)/1e6, float64(t.total)/1e6)
		if secs := time.Since(t.start).Seconds(); secs > 1 && t.done > 0 && t.done < t.total {
			left := time.Duration(float64(t.total-t.done)/(float64(t.done)/secs)) * time.Second
			text += "  •  " + left.Round(time.Second).String() + " left"
		}
	}
	progress(text, pct)
}

// ---------------------------------------------------------------- update

func update(root string, info buildInfo, man Manifest, t *tracker) {
	data := filepath.Join(root, "Data", "data")
	shmemPath := filepath.Join(data, "shmem")
	backup(filepath.Join(root, ".build.info"))
	backup(shmemPath)
	shmem, err := os.ReadFile(shmemPath)
	must(err)
	if len(shmem) < shmemVersion+64 || binary.LittleEndian.Uint32(shmem) != 4 {
		panic("unexpected Data/data/shmem (start the game once with Wow-64_Patched.exe, close it, then try again)")
	}

	// 1) the build config
	cfg := download("/tpr/wow/config/"+man.Build[0:2]+"/"+man.Build[2:4]+"/"+man.Build, nil)
	if hex.EncodeToString(md5sum(cfg)) != man.Build {
		panic("build config download is corrupt")
	}
	cfgDir := filepath.Join(root, "Data", "config", man.Build[0:2], man.Build[2:4])
	must(os.MkdirAll(cfgDir, 0755))
	must(os.WriteFile(filepath.Join(cfgDir, man.Build), cfg, 0644))

	// 2) the files, into a new archive after the highest one this client uses
	versions := make([]uint32, 16)
	for b := range versions {
		versions[b] = binary.LittleEndian.Uint32(shmem[shmemVersion+4*b:])
	}
	indexes := make([]*index, 16)
	archive := 0
	for b := 0; b < 16; b++ {
		indexes[b] = readIndex(filepath.Join(data, idxName(b, versions[b])))
		if a := indexes[b].maxArchive(); a >= archive {
			archive = a + 1
		}
	}
	for {
		if _, err := os.Stat(filepath.Join(data, fmt.Sprintf("data.%03d", archive))); err != nil {
			break
		}
		archive++ // a leftover archive file: keep it, use the next number
	}
	var arch bytes.Buffer
	touched := map[int]bool{}
	for _, bl := range man.Blobs {
		t.label = "Downloading " + bl.Name
		say(t.label)
		blte := download("/tpr/wow/data/"+bl.EKey[0:2]+"/"+bl.EKey[2:4]+"/"+bl.EKey, t)
		ekey, _ := hex.DecodeString(bl.EKey)
		if int64(len(blte)) != bl.Size || !bytes.Equal(blteKey(blte), ekey) {
			panic("download of " + bl.Name + " is corrupt")
		}
		offset := arch.Len()
		arch.Write(localHeader(ekey, uint32(30+len(blte)), archive, uint32(offset)))
		arch.Write(blte)
		b := bucket(ekey)
		indexes[b].set(ekey[:9], archive, uint32(offset), uint32(30+len(blte)))
		touched[b] = true
	}
	say("Installing the update...")
	must(os.WriteFile(filepath.Join(data, fmt.Sprintf("data.%03d", archive)), arch.Bytes(), 0644))

	// 3) one index version up for each touched bucket, and shmem naming those versions
	for b := range touched {
		versions[b]++
		must(os.WriteFile(filepath.Join(data, idxName(b, versions[b])), indexes[b].bytes(), 0644))
		binary.LittleEndian.PutUint32(shmem[shmemVersion+4*b:], versions[b])
	}
	must(os.WriteFile(shmemPath, shmem, 0644))

	// 4) .build.info last: until now the client still starts its old build
	must(os.WriteFile(filepath.Join(root, ".build.info"), []byte(strings.ReplaceAll(info.raw, info.buildKey, man.Build)), 0644))
}

func restore(root string) {
	for _, p := range []string{filepath.Join(root, ".build.info"), filepath.Join(root, "Data", "data", "shmem")} {
		b, err := os.ReadFile(p + backupSuffix)
		if err != nil {
			panic("no backup of " + p + " (the launcher never changed this client)")
		}
		must(os.WriteFile(p, b, 0644))
	}
}

func backup(p string) {
	if _, err := os.Stat(p + backupSuffix); err == nil {
		return // keep the first (original) backup
	}
	b, err := os.ReadFile(p)
	must(err)
	must(os.WriteFile(p+backupSuffix, b, 0644))
}

func exeOK(root string, man Manifest) bool {
	b, err := os.ReadFile(filepath.Join(root, gameExe))
	return err == nil && hex.EncodeToString(md5sum(b)) == man.ExeMD5
}

func downloadExe(root string, man Manifest, t *tracker) {
	t.label = "Downloading " + gameExe
	say(t.label)
	b := download(man.Exe, t)
	if hex.EncodeToString(md5sum(b)) != man.ExeMD5 {
		panic(gameExe + " download is corrupt")
	}
	must(os.WriteFile(filepath.Join(root, gameExe), b, 0755))
}

// A newer launcher on the server replaces this one: the running exe is renamed (Windows allows that), the new one
// written in its place and started with the same arguments. The renamed old one is deleted on the next start.
func selfUpdate(man Manifest) bool {
	exe, err := os.Executable()
	if err != nil {
		return false
	}
	os.Remove(exe + ".old")
	cur, err := os.ReadFile(exe)
	if err != nil || man.Launcher == "" || hex.EncodeToString(md5sum(cur)) == man.LauncherMD5 {
		return false
	}
	t := &tracker{label: "Updating the launcher", start: time.Now()}
	say(t.label + "...")
	b := download(man.Launcher, t)
	if hex.EncodeToString(md5sum(b)) != man.LauncherMD5 {
		panic("Launcher.exe download is corrupt")
	}
	must(os.Rename(exe, exe+".old"))
	if err := os.WriteFile(exe, b, 0755); err != nil {
		os.Rename(exe+".old", exe)
		panic(err.Error())
	}
	must(exec.Command(exe, os.Args[1:]...).Start())
	return true
}

// ---------------------------------------------------------------- .build.info / manifest / http

type buildInfo struct{ raw, buildKey, version string }

func readBuildInfo(root string) buildInfo {
	b, err := os.ReadFile(filepath.Join(root, ".build.info"))
	if err != nil {
		panic("no .build.info here: put Launcher.exe in the World of Warcraft folder")
	}
	lines := strings.Split(strings.ReplaceAll(string(b), "\r", ""), "\n")
	head := strings.Split(lines[0], "|")
	col := func(name string) int {
		for i, h := range head {
			if strings.HasPrefix(h, name+"!") {
				return i
			}
		}
		panic("unexpected .build.info")
	}
	active, key, ver := col("Active"), col("Build Key"), col("Version")
	for _, l := range lines[1:] {
		f := strings.Split(l, "|")
		if len(f) > ver && f[active] == "1" {
			return buildInfo{string(b), f[key], f[ver]}
		}
	}
	panic("no active build in .build.info")
}

func configExists(root, key string) bool {
	_, err := os.Stat(filepath.Join(root, "Data", "config", key[0:2], key[2:4], key))
	return err == nil
}

func fetchManifest() Manifest {
	var m Manifest
	must(json.Unmarshal(download("/launcher/manifest.json", nil), &m))
	if !regexp.MustCompile(`^[0-9a-f]{32}$`).MatchString(m.Build) {
		panic("bad manifest from the server")
	}
	return m
}

// download fetches path from the server, retrying a few times. t (optional) counts the bytes for the progress bar;
// when it has no total yet, the server's Content-Length becomes the total.
func download(path string, t *tracker) []byte {
	var lastErr error
	for try := 0; try < 3; try++ {
		b, err := get(path, t)
		if err == nil {
			return b
		}
		lastErr = err
		time.Sleep(2 * time.Second)
	}
	panic(fmt.Sprintf("cannot download %s: %v (is the server up?)", path, lastErr))
}

func get(path string, t *tracker) ([]byte, error) {
	resp, err := (&http.Client{Timeout: 10 * time.Minute}).Get(server + path)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		return nil, errors.New(resp.Status)
	}
	if t == nil {
		return io.ReadAll(resp.Body)
	}
	if t.total == 0 && resp.ContentLength > 0 {
		t.total = resp.ContentLength
	}
	var buf bytes.Buffer
	got := int64(0)
	chunk := make([]byte, 64<<10)
	for {
		n, err := resp.Body.Read(chunk)
		buf.Write(chunk[:n])
		got += int64(n)
		t.add(int64(n))
		if err == io.EOF {
			return buf.Bytes(), nil
		}
		if err != nil {
			t.add(-got) // this attempt's bytes do not count
			return nil, err
		}
	}
}

// ---------------------------------------------------------------- local storage (wowdev.wiki/CASC)

type index struct {
	header  []byte            // HeaderHashSize bytes after the first 8
	pad     int               // offset of EntriesSize
	records map[string][]byte // 9 byte key -> 5 byte offset (BE) + 4 byte size (LE)
}

func idxName(b int, v uint32) string { return fmt.Sprintf("%02x%08x.idx", b, v) }

func readIndex(p string) *index {
	d, err := os.ReadFile(p)
	if err != nil {
		panic("missing " + filepath.Base(p) + " (the client storage is incomplete; run a repair or restore)")
	}
	hsize := int(binary.LittleEndian.Uint32(d))
	pos := (8 + hsize + 15) &^ 15
	esize := int(binary.LittleEndian.Uint32(d[pos:]))
	if d[8+4] != 4 || d[8+5] != 5 || d[8+6] != 9 || d[8+7] != 30 {
		panic("unexpected index format in " + filepath.Base(p))
	}
	ix := &index{header: append([]byte{}, d[8:8+hsize]...), pad: pos, records: map[string][]byte{}}
	for k := 0; k < esize/18; k++ {
		e := d[pos+8+18*k : pos+8+18*(k+1)]
		ix.records[string(e[:9])] = append([]byte{}, e[9:]...)
	}
	return ix
}

func (ix *index) maxArchive() int {
	m := 0
	for _, v := range ix.records {
		packed := uint64(v[0])<<32 | uint64(binary.BigEndian.Uint32(v[1:5]))
		if a := int(packed >> 30); a > m {
			m = a
		}
	}
	return m
}

func (ix *index) set(key []byte, archive int, offset, size uint32) {
	packed := uint64(archive)<<30 | uint64(offset)
	v := make([]byte, 9)
	v[0] = byte(packed >> 32)
	binary.BigEndian.PutUint32(v[1:5], uint32(packed))
	binary.LittleEndian.PutUint32(v[5:], size)
	ix.records[string(key)] = v
}

func (ix *index) bytes() []byte {
	keys := make([]string, 0, len(ix.records))
	for k := range ix.records {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	var entries bytes.Buffer
	var pc, pb uint32
	for _, k := range keys {
		e := append([]byte(k), ix.records[k]...)
		pc, pb = hashlittle2(e, pc, pb)
		entries.Write(e)
	}
	out := make([]byte, idxFileSize)
	hc, _ := hashlittle2(ix.header, 0, 0)
	binary.LittleEndian.PutUint32(out[0:], uint32(len(ix.header)))
	binary.LittleEndian.PutUint32(out[4:], hc)
	copy(out[8:], ix.header)
	binary.LittleEndian.PutUint32(out[ix.pad:], uint32(entries.Len()))
	binary.LittleEndian.PutUint32(out[ix.pad+4:], pc)
	copy(out[ix.pad+8:], entries.Bytes())
	return out
}

func bucket(k []byte) int {
	var i byte
	for _, b := range k[:9] {
		i ^= b
	}
	return int((i & 0xf) ^ (i >> 4))
}

var checksumTable = [16]uint32{
	0x049396b8, 0x72a82a9b, 0xee626cca, 0x9917754f, 0x15de40b1, 0xf5a8a9b6, 0x421eac7e, 0xa9d55c9a,
	0x317fd40c, 0x04faf80d, 0x3d6be971, 0x52933cfd, 0x27f64b7d, 0xc6f5c11b, 0xd5757e3a, 0x6c388745,
}

// 30 byte header before each file in a local data.NNN archive
func localHeader(ekey []byte, size uint32, archive int, archiveOffset uint32) []byte {
	h := make([]byte, 30)
	for i := 0; i < 16; i++ {
		h[i] = ekey[15-i]
	}
	binary.LittleEndian.PutUint32(h[16:], size)
	a, _ := hashlittle2(h[:0x16], 0x3D6BE971, 0)
	binary.LittleEndian.PutUint32(h[0x16:], a)
	offset := (archiveOffset & 0x3fffffff) | uint32(archive&3)<<30
	var enc [4]byte
	binary.LittleEndian.PutUint32(enc[:], checksumTable[(offset+0x1e)&0xf]^(offset+0x1e))
	var hashed, out [4]byte
	for i := uint32(0); i < 0x1a; i++ {
		hashed[(i+offset)&3] ^= h[i]
	}
	for j := uint32(0); j < 4; j++ {
		i := j + 0x1a + offset
		out[j] = hashed[i&3] ^ enc[i&3]
	}
	copy(h[0x1a:], out[:])
	return h
}

// encoded key of a BLTE file: md5 of its header (block table), or of the whole file without one
func blteKey(b []byte) []byte {
	if len(b) < 8 || string(b[:4]) != "BLTE" {
		return nil
	}
	hs := binary.BigEndian.Uint32(b[4:])
	if hs == 0 {
		return md5sum(b)
	}
	return md5sum(b[:hs])
}

func md5sum(b []byte) []byte { s := md5.Sum(b); return s[:] }

func rot(x uint32, k uint) uint32 { return x<<k | x>>(32-k) }

// Bob Jenkins' lookup3 hashlittle2, as CASC uses it. Returns (pc, pb).
func hashlittle2(data []byte, pc, pb uint32) (uint32, uint32) {
	length := len(data)
	a := 0xdeadbeef + uint32(length) + pc
	b, c := a, a+pb
	i := 0
	for length > 12 {
		a += binary.LittleEndian.Uint32(data[i:])
		b += binary.LittleEndian.Uint32(data[i+4:])
		c += binary.LittleEndian.Uint32(data[i+8:])
		a -= c
		a ^= rot(c, 4)
		c += b
		b -= a
		b ^= rot(a, 6)
		a += c
		c -= b
		c ^= rot(b, 8)
		b += a
		a -= c
		a ^= rot(c, 16)
		c += b
		b -= a
		b ^= rot(a, 19)
		a += c
		c -= b
		c ^= rot(b, 4)
		b += a
		length -= 12
		i += 12
	}
	if length == 0 {
		return c, b
	}
	var tail [12]byte
	copy(tail[:], data[i:])
	a += binary.LittleEndian.Uint32(tail[0:])
	b += binary.LittleEndian.Uint32(tail[4:])
	c += binary.LittleEndian.Uint32(tail[8:])
	c ^= b
	c -= rot(b, 14)
	a ^= c
	a -= rot(c, 11)
	b ^= a
	b -= rot(a, 25)
	c ^= b
	c -= rot(b, 16)
	a ^= c
	a -= rot(c, 4)
	b ^= a
	b -= rot(a, 14)
	c ^= b
	c -= rot(b, 24)
	return c, b
}

func must(err error) {
	if err != nil {
		panic(err.Error())
	}
}

// setPortal points the client at our login server: WTF/Config.wtf gets "SET portal" with the current address (players
// set it by hand before; the server moved to a new IP on 2026-09-28). An existing portal line is replaced, else added.
func setPortal(root string) {
	p := filepath.Join(root, "WTF", "Config.wtf")
	b, err := os.ReadFile(p)
	if err != nil && !os.IsNotExist(err) {
		return
	}
	want := `SET portal "` + portal + `"`
	lines := strings.Split(strings.ReplaceAll(string(b), "\r\n", "\n"), "\n")
	found, changed := false, false
	for i, l := range lines {
		if strings.HasPrefix(strings.ToLower(strings.TrimSpace(l)), "set portal ") {
			found = true
			if strings.TrimSpace(l) != want {
				lines[i], changed = want, true
			}
		}
	}
	if !found {
		if n := len(lines); n > 0 && lines[n-1] == "" {
			lines = append(lines[:n-1], want, "")
		} else {
			lines = append(lines, want)
		}
		changed = true
	}
	if !changed {
		return
	}
	if os.MkdirAll(filepath.Dir(p), 0755) == nil {
		os.WriteFile(p, []byte(strings.Join(lines, "\r\n")), 0644)
	}
}
