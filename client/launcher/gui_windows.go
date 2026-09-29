// The launcher window: ui.html (the website's Legion theme) in a borderless WebView2 window. The page calls the
// Go functions bound below; Go updates the page with Eval (setStatus, setProgress, setReady, setError, setNews, setRealm).
package main

import (
	"bytes"
	"embed"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"sync/atomic"
	"syscall"
	"time"
	"unsafe"

	webview "github.com/jchv/go-webview2"
)

//go:embed ui.html
var uiHTML string

//go:embed art
var art embed.FS // the page's images (the website's img/legion/ art and the Chronicles seal)

var (
	user32           = syscall.NewLazyDLL("user32.dll")
	setWindowLongPtr = user32.NewProc("SetWindowLongPtrW")
	setWindowPos     = user32.NewProc("SetWindowPos")
	releaseCapture   = user32.NewProc("ReleaseCapture")
	postMessage      = user32.NewProc("PostMessageW")
	sendMessage      = user32.NewProc("SendMessageW")
	showWindow       = user32.NewProc("ShowWindow")
	loadImage        = user32.NewProc("LoadImageW")
	messageBox       = user32.NewProc("MessageBoxW")
	getDpiForWindow  = user32.NewProc("GetDpiForWindow")
	getSystemMetrics = user32.NewProc("GetSystemMetrics")
	kernel32         = syscall.NewLazyDLL("kernel32.dll")
	getModuleHandle  = kernel32.NewProc("GetModuleHandleW")
	getDiskFreeSpace = kernel32.NewProc("GetDiskFreeSpaceExW")
	createMutex      = kernel32.NewProc("CreateMutexW")
	waitForObject    = kernel32.NewProc("WaitForSingleObject")
	shell32          = syscall.NewLazyDLL("shell32.dll")
	browseForFolder  = shell32.NewProc("SHBrowseForFolderW")
	pathFromIDList   = shell32.NewProc("SHGetPathFromIDListW")
	coTaskMemFree    = syscall.NewLazyDLL("ole32.dll").NewProc("CoTaskMemFree")
)

const configFile = "launcher.json" // next to Launcher.exe: {"game_folder": "...", "limit_mbps": 5}

// minLimitMBps is the lowest speed limit: below it an in-memory download (a game update file, the launcher's own
// update: get() has a 10 minute timeout for the whole body) could not finish in time and would use up its tries.
const minLimitMBps = 0.5

type launcherConfig struct {
	GameFolder string  `json:"game_folder"`
	LimitMBps  float64 `json:"limit_mbps,omitempty"` // download speed limit in MB/s, 0 = unlimited
}

// oneLauncher makes sure only one launcher runs (two would download into the same .part files). A launcher that
// hands over (self-update, install) exits right after starting the next one, so wait a little for it first.
func oneLauncher() bool {
	name, _ := syscall.UTF16PtrFromString("ChroniclesLauncher")
	h, _, err := createMutex.Call(0, 1, uintptr(unsafe.Pointer(name)))
	if h == 0 || err != syscall.ERROR_ALREADY_EXISTS {
		return true // ours (or no mutex at all: don't block the player)
	}
	r, _, _ := waitForObject.Call(h, 15000)
	return r != 0x102 // WAIT_TIMEOUT: another launcher is really running (the handle stays open until exit)
}

func run(root string, args []string, test bool) {
	if !oneLauncher() {
		alert("The Chronicles launcher is already running.")
		return
	}
	cfgPath := filepath.Join(exeDir(), configFile)
	var cfg launcherConfig
	if b, err := os.ReadFile(cfgPath); err == nil && json.Unmarshal(b, &cfg) == nil && cfg.GameFolder != "" && !test {
		root = cfg.GameFolder
	}
	if cfg.LimitMBps < 0 {
		cfg.LimitMBps = 0
	} else if cfg.LimitMBps > 0 {
		cfg.LimitMBps = min(max(cfg.LimitMBps, minLimitMBps), 1000) // a hand-edited launcher.json
	}
	dl.SetLimit(int64(cfg.LimitMBps * 1e6))
	// saveCfg changes cfg (setup's goroutine and the Settings bindings both do) and writes launcher.json through a
	// .tmp file: a crash mid-write must not leave an empty launcher.json (the next start would forget the game folder)
	var cfgMu sync.Mutex
	saveCfg := func(change func()) error {
		cfgMu.Lock()
		defer cfgMu.Unlock()
		change()
		b, err := json.Marshal(cfg)
		if err != nil {
			return err
		}
		if err := os.WriteFile(cfgPath+".tmp", b, 0644); err != nil {
			return err
		}
		return os.Rename(cfgPath+".tmp", cfgPath)
	}

	if len(args) > 0 && args[0] == "restore" { // old way, from the first launcher's guide
		func() {
			defer func() {
				if r := recover(); r != nil {
					alert(fmt.Sprint(r))
					os.Exit(1)
				}
			}()
			restore(root)
		}()
		alert("Original client restored. Start Wow-64_Patched.exe as before.")
		return
	}

	cache, _ := os.UserCacheDir()
	w := webview.NewWithOptions(webview.WebViewOptions{
		AutoFocus: true,
		DataPath:  filepath.Join(cache, "ChroniclesLauncher"), // browser data, not in the WoW folder
		WindowOptions: webview.WindowOptions{
			Title: "Chronicles", Width: 1240, Height: 740, Center: true,
		},
	})
	if w == nil {
		alert("This launcher needs the Microsoft Edge WebView2 Runtime (Windows 10/11 normally have it).\n\n" +
			"The download page opens now: install it, then start the launcher again.")
		openURL("https://go.microsoft.com/fwlink/p/?LinkId=2124703")
		return
	}
	defer w.Destroy()
	hwnd := uintptr(w.Window())
	borderless(hwnd)
	setIcon(hwnd)

	eval := func(fn string, args ...any) {
		parts := make([]string, len(args))
		for i, a := range args {
			b, _ := json.Marshal(a)
			parts[i] = string(b)
		}
		js := fn + "(" + strings.Join(parts, ",") + ")"
		w.Dispatch(func() { w.Eval(js) })
	}
	say = func(text string) { eval("setStatus", text) }
	progress = func(text string, pct float64) { eval("setProgress", text, pct) }
	downloading = func(on bool) { eval("setDownloading", on) } // the pause button

	// setup: no client here. The player chooses (install dialog in ui.html): install the game into a folder they pick,
	// or pick the 7.3.5 client they already have. The folder is saved in launcher.json right away (an interrupted install
	// goes on there on the next start, without asking again); once the client is there, a copy of this launcher in that
	// folder takes over. False: this launcher should exit (handed over, or the player quit).
	installChoice := make(chan string, 1)
	setup := func(man Manifest) bool {
		base, files := fetchClient(man)
		cfgMu.Lock()
		dir := cfg.GameFolder
		cfgMu.Unlock()
		if dir == "" || !started(dir) {
			size := int64(0)
			for _, f := range files {
				size += f.Size
			}
			say("World of Warcraft: Legion is not installed yet")
			eval("askInstall", fmt.Sprintf("%.1f GB", float64(size)/1e9))
			for dir = ""; dir == ""; {
				choice := <-installChoice
				if choice == "quit" {
					return false
				}
				title := fmt.Sprintf("Choose where to install World of Warcraft: Legion (%.1f GB): a Chronicles folder is "+
					"created there.", float64(size)/1e9)
				if choice == "existing" {
					title = "Choose your World of Warcraft: Legion 7.3.5 folder (the one with Wow-64.exe and .build.info)."
				}
				picked := make(chan string, 1)
				w.Dispatch(func() { picked <- pickFolder(hwnd, title) })
				p := <-picked
				switch {
				case p == "": // cancelled: choose again
				case choice == "existing" && !isClient(p):
					eval("installMsg", "That folder has no World of Warcraft: Legion 7.3.5 client (build 26972). "+
						"Choose the folder with Wow-64.exe and .build.info, or install the game.")
				case choice == "existing":
					dir = p
				default:
					dir = installDir(p)
				}
			}
			eval("closeInstall")
			// also replaces a launcher.json that named a folder without a client; without it, picking the same folder
			// again goes on there too (installDir)
			saveCfg(func() { cfg.GameFolder = dir })
		}
		if !installed(dir) {
			defer func() {
				if r := recover(); r != nil {
					if s, ok := r.(string); ok && strings.HasPrefix(s, noSpace) {
						saveCfg(func() { cfg.GameFolder = "" }) // the next refresh asks for another folder
					}
					panic(r)
				}
			}()
			installClient(dir, base, files)
		}
		if sameDir(dir, exeDir()) {
			root = dir // this launcher's own folder: go on here
			return true
		}
		startCopy(dir)
		return false
	}

	var repairing atomic.Bool // check every client file first ("Launcher.exe repair" or the Repair button)
	repairing.Store(len(args) > 0 && args[0] == "repair")
	var busy atomic.Bool
	var ready atomic.Bool
	check := func() {
		if !busy.CompareAndSwap(false, true) {
			return
		}
		defer busy.Store(false)
		defer func() {
			if r := recover(); r != nil {
				eval("setError", fmt.Sprint(r))
			}
		}()
		ready.Store(false)
		dl.Resume() // setBusy clears the page's pause button: no download of this check may wait for it
		eval("setBusy")
		man, newer := checkLauncher(test)
		if newer || (!test && !installed(root) && man.Client != "" && !setup(man)) {
			w.Dispatch(w.Terminate) // another launcher took over, or no client wanted
			return
		}
		if repairing.Swap(false) { // a failed repair is not run again on every refresh
			repair(root, man)
		}
		prepare(root, man, test)
		ready.Store(true)
		eval("setReady")
	}
	refresh := func() { // news and realm status; failures just leave the old ones
		var news, status any
		if b, err := get("/launcher/news.json", nil); err == nil && json.Unmarshal(b, &news) == nil {
			eval("setNews", news)
		}
		if b, err := get("/launcher/status.json", nil); err == nil && json.Unmarshal(b, &status) == nil {
			eval("setRealm", status)
		} else {
			eval("setRealm", map[string]any{"online": false, "text": "Realm offline"})
		}
	}

	w.Bind("drag", func() { // move the window like its title bar was dragged
		releaseCapture.Call()
		postMessage.Call(hwnd, 0x00A1 /* WM_NCLBUTTONDOWN */, 2 /* HTCAPTION */, 0)
	})
	w.Bind("minimize", func() { showWindow.Call(hwnd, 6 /* SW_MINIMIZE */) })
	w.Bind("quit", w.Terminate)
	w.Bind("openUrl", openURL)
	w.Bind("refresh", func() { go refresh(); go check() })
	w.Bind("play", func() {
		if !ready.Load() {
			return
		}
		go func() {
			defer func() {
				if r := recover(); r != nil {
					eval("setError", fmt.Sprint(r))
				}
			}()
			say("Starting the game...")
			startGame(root)
			time.Sleep(2 * time.Second)
			w.Dispatch(w.Terminate)
		}()
	})
	w.Bind("installChoice", func(choice string) { // the install dialog's buttons: install | existing | quit
		select {
		case installChoice <- choice:
		default: // setup is still busy with the last one
		}
	})
	w.Bind("getFolder", func() string { return root })
	// pause / resume every download (transfer.go); quitting while paused is safe: the .part files keep what came
	w.Bind("pauseDownload", func() { dl.Pause(); eval("setPaused", true) })
	w.Bind("resumeDownload", func() { dl.Resume(); eval("setPaused", false) })
	w.Bind("getLimit", func() float64 {
		cfgMu.Lock()
		defer cfgMu.Unlock()
		return cfg.LimitMBps
	})
	w.Bind("setLimit", func(mbps float64) string { // applied at once, also to a running download
		if mbps != 0 && (mbps < minLimitMBps || mbps > 1000) {
			return "Choose a limit between 0.5 and 1000 MB/s, or Unlimited."
		}
		dl.SetLimit(int64(mbps * 1e6))
		if err := saveCfg(func() { cfg.LimitMBps = mbps }); err != nil {
			return "Cannot save the setting: " + err.Error()
		}
		return ""
	})
	// bindings run on the window thread, so the modal folder dialog can open right here
	w.Bind("browseFolder", func() string {
		return pickFolder(hwnd, "Choose your World of Warcraft: Legion 7.3.5 folder (the one with Wow-64.exe and .build.info).")
	})
	w.Bind("setFolder", func(dir string) string {
		dir = strings.Trim(strings.TrimSpace(dir), `"`)
		if !isClient(dir) {
			return "That folder has no World of Warcraft: Legion 7.3.5 client: pick the folder with Wow-64.exe and .build.info."
		}
		if err := saveCfg(func() { cfg.GameFolder = dir }); err != nil {
			return "Cannot save the setting: " + err.Error()
		}
		root = dir
		go check()
		return ""
	})
	w.Bind("repairClient", func() string {
		if busy.Load() {
			return "Wait until the update is done."
		}
		if !installed(root) {
			return "There is no client in this folder to repair."
		}
		repairing.Store(true)
		go check()
		return ""
	})
	w.Bind("restoreClient", func() string {
		if busy.Load() {
			return "Wait until the update is done."
		}
		msg := ""
		func() {
			defer func() {
				if r := recover(); r != nil {
					msg = fmt.Sprint(r)
				}
			}()
			restore(root)
		}()
		if msg == "" {
			ready.Store(false)
			eval("setError", "Original client restored: start Wow-64_Patched.exe to play without the launcher, or press ⟳ to update again.")
		}
		return msg
	})

	// the first update check and news once the page's script runs: Evals before that are lost (the page with its
	// inlined art takes a moment), and one of them may be the install dialog. After 15 s they start anyway (a page
	// script that never got there must not leave the launcher idle); once only.
	var start sync.Once
	begin := func() { start.Do(func() { go refresh(); go check() }) }
	w.Bind("pageReady", begin)
	time.AfterFunc(15*time.Second, begin)
	w.SetHtml(inlineArt(uiHTML))
	go func() {
		for range time.Tick(30 * time.Second) {
			refresh()
		}
	}()
	w.Run()
}

// inlineArt turns the page's art/<file> references into data URIs of the embedded files: SetHtml has no folder to load
// them from. (ui.html opened from its own folder, for a preview, loads them as they are.)
func inlineArt(html string) string {
	files, _ := art.ReadDir("art")
	for _, f := range files {
		b, _ := art.ReadFile("art/" + f.Name())
		mime := map[string]string{".jpg": "image/jpeg", ".png": "image/png", ".webp": "image/webp"}[filepath.Ext(f.Name())]
		html = strings.ReplaceAll(html, "art/"+f.Name(), "data:"+mime+";base64,"+base64.StdEncoding.EncodeToString(b))
	}
	return html
}

// borderless drops the Windows frame (the page draws its own title bar: drag, minimize, close) and sizes the window
// 1240x740 at the screen's scaling, centered. The exe is per-monitor DPI aware (go-winres gui manifest).
// ponytail: size follows the DPI at start only; handle WM_DPICHANGED if people drag it between monitors of different scaling.
func borderless(hwnd uintptr) {
	const style = 0x80000000 | 0x10000000 | 0x02000000 | 0x00080000 | 0x00020000 // POPUP|VISIBLE|CLIPCHILDREN|SYSMENU|MINIMIZEBOX
	gwlStyle := -16
	setWindowLongPtr.Call(hwnd, uintptr(gwlStyle), style)
	dpi := uintptr(96)
	if getDpiForWindow.Find() == nil { // Windows 10 1607+
		if d, _, _ := getDpiForWindow.Call(hwnd); d > 0 {
			dpi = d
		}
	}
	w, h := 1240*dpi/96, 740*dpi/96
	sw, _, _ := getSystemMetrics.Call(0) // SM_CXSCREEN
	sh, _, _ := getSystemMetrics.Call(1)
	x, y := (int(sw)-int(w))/2, (int(sh)-int(h))/2
	setWindowPos.Call(hwnd, 0, uintptr(max(x, 0)), uintptr(max(y, 0)), w, h, 0x0004|0x0020) // NOZORDER|FRAMECHANGED
}

// setIcon uses the exe's own icon (go-winres names it APP) for the title bar and the taskbar.
func setIcon(hwnd uintptr) {
	inst, _, _ := getModuleHandle.Call(0)
	name, _ := syscall.UTF16PtrFromString("APP")
	big, _, _ := loadImage.Call(inst, uintptr(unsafe.Pointer(name)), 1 /* IMAGE_ICON */, 0, 0, 0x0040|0x8000 /* DEFAULTSIZE|SHARED */)
	small, _, _ := loadImage.Call(inst, uintptr(unsafe.Pointer(name)), 1, 16, 16, 0x8000)
	sendMessage.Call(hwnd, 0x0080 /* WM_SETICON */, 1, big)
	sendMessage.Call(hwnd, 0x0080, 0, small)
}

// pickFolder shows the Windows folder picker and returns the chosen folder, "" on cancel. Run it on the window's
// thread (w.Dispatch): the new-style dialog needs COM there, which go-webview2 set up (CoInitializeEx, apartment
// threaded, in its init on the locked main thread).
func pickFolder(owner uintptr, title string) string {
	t, _ := syscall.UTF16PtrFromString(title)
	var name, dir [260]uint16
	bi := struct { // BROWSEINFOW
		owner, root   uintptr
		name, title   *uint16
		flags         uint32
		callback, arg uintptr
		image         int32
	}{owner: owner, name: &name[0], title: t, flags: 0x1 | 0x40 /* BIF_RETURNONLYFSDIRS|BIF_NEWDIALOGSTYLE */}
	pidl, _, _ := browseForFolder.Call(uintptr(unsafe.Pointer(&bi)))
	if pidl == 0 {
		return ""
	}
	defer coTaskMemFree.Call(pidl)
	if ok, _, _ := pathFromIDList.Call(pidl, uintptr(unsafe.Pointer(&dir[0]))); ok == 0 {
		return ""
	}
	return syscall.UTF16ToString(dir[:])
}

// diskFree returns the bytes this user may still write on dir's drive, -1 when Windows cannot tell.
func diskFree(dir string) int64 {
	p, _ := syscall.UTF16PtrFromString(dir)
	var free uint64
	if ok, _, _ := getDiskFreeSpace.Call(uintptr(unsafe.Pointer(p)), uintptr(unsafe.Pointer(&free)), 0, 0); ok == 0 {
		return -1
	}
	return int64(free)
}

// sameDir tells whether a and b are the same folder (also through a subst drive, a junction or a short name).
func sameDir(a, b string) bool {
	sa, err := os.Stat(a)
	sb, err2 := os.Stat(b)
	return err == nil && err2 == nil && os.SameFile(sa, sb)
}

// startCopy copies this launcher into dir (the new client's folder) and starts it there: from now on that copy is the
// player's launcher. The downloaded one stays where it is. Another Launcher.exe there (another server's?) is kept as
// Launcher.exe.bak (the first one only, like backup()). A launcher.json there would send the copy to another folder.
func startCopy(dir string) {
	exe, err := os.Executable()
	must(err)
	b, err := os.ReadFile(exe)
	must(err)
	dst := filepath.Join(dir, "Launcher.exe")
	if old, err := os.ReadFile(dst); err != nil || !bytes.Equal(old, b) {
		if _, bakErr := os.Stat(dst + ".bak"); err == nil && os.IsNotExist(bakErr) {
			must(os.Rename(dst, dst+".bak"))
		}
		must(os.WriteFile(dst+".new", b, 0755)) // then renamed: a cut-off copy never becomes the player's Launcher.exe
		must(os.Rename(dst+".new", dst))
	}
	os.Remove(filepath.Join(dir, configFile))
	cmd := exec.Command(dst)
	cmd.Dir = dir
	must(cmd.Start())
}

func openURL(u string) {
	if strings.HasPrefix(u, "https://") || strings.HasPrefix(u, "http://") {
		exec.Command("rundll32", "url.dll,FileProtocolHandler", u).Start()
	}
}

func alert(text string) {
	t, _ := syscall.UTF16PtrFromString(text)
	c, _ := syscall.UTF16PtrFromString("Chronicles")
	messageBox.Call(0, uintptr(unsafe.Pointer(t)), uintptr(unsafe.Pointer(c)), 0x30 /* MB_ICONWARNING */)
}
