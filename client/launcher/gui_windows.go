// The launcher window: ui.html (the Chronicles design by Amibari) in a borderless WebView2 window. The page calls the
// Go functions bound below; Go updates the page with Eval (setStatus, setProgress, setReady, setError, setNews, setRealm).
package main

import (
	_ "embed"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync/atomic"
	"syscall"
	"time"
	"unsafe"

	webview "github.com/jchv/go-webview2"
)

//go:embed ui.html
var uiHTML string

//go:embed logo.jpg
var logoJPG []byte

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
	getModuleHandle  = syscall.NewLazyDLL("kernel32.dll").NewProc("GetModuleHandleW")
)

const configFile = "launcher.json" // next to Launcher.exe: {"game_folder": "..."}

type launcherConfig struct {
	GameFolder string `json:"game_folder"`
}

func run(root string, args []string, test bool) {
	cfgPath := filepath.Join(exeDir(), configFile)
	var cfg launcherConfig
	if b, err := os.ReadFile(cfgPath); err == nil && json.Unmarshal(b, &cfg) == nil && cfg.GameFolder != "" && !test {
		root = cfg.GameFolder
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
		eval("setBusy")
		if prepare(root, test) {
			w.Dispatch(w.Terminate) // a newer launcher took over
			return
		}
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
	w.Bind("getFolder", func() string { return root })
	w.Bind("setFolder", func(dir string) string {
		dir = strings.Trim(strings.TrimSpace(dir), `"`)
		if _, err := os.Stat(filepath.Join(dir, ".build.info")); err != nil {
			return "That folder has no .build.info: pick the World of Warcraft folder (the one with Wow-64.exe)."
		}
		b, _ := json.Marshal(launcherConfig{GameFolder: dir})
		if err := os.WriteFile(cfgPath, b, 0644); err != nil {
			return "Cannot save the setting: " + err.Error()
		}
		root = dir
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

	html := strings.Replace(uiHTML, "LOGO_DATA_URI", "data:image/jpeg;base64,"+base64.StdEncoding.EncodeToString(logoJPG), -1)
	w.SetHtml(html)
	go refresh()
	go check()
	go func() {
		for range time.Tick(30 * time.Second) {
			refresh()
		}
	}()
	w.Run()
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
