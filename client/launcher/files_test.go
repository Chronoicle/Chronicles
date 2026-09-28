package main

import (
	"crypto/md5"
	"encoding/hex"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
)

// The manifest's addon files: a stale file is downloaded, a current one is not, a path outside Interface/AddOns panics.
func TestAddonFiles(t *testing.T) {
	body := []byte("## Interface: 70300\n")
	sum := md5.Sum(body)
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/launcher/files/Interface/AddOns/Shop/Shop.toc" {
			http.NotFound(w, r)
			return
		}
		w.Write(body)
	}))
	defer srv.Close()
	server = srv.URL

	root := t.TempDir()
	man := Manifest{Files: []File{{Path: "Interface/AddOns/Shop/Shop.toc", MD5: hex.EncodeToString(sum[:]), Size: int64(len(body))}}}
	stale := staleFiles(root, man)
	if len(stale) != 1 {
		t.Fatalf("want 1 stale file, got %d", len(stale))
	}
	downloadFiles(root, stale, &tracker{})
	got, err := os.ReadFile(filepath.Join(root, "Interface", "AddOns", "Shop", "Shop.toc"))
	if err != nil || string(got) != string(body) {
		t.Fatalf("file not written: %v", err)
	}
	if len(staleFiles(root, man)) != 0 {
		t.Fatal("a current file is stale")
	}

	for _, bad := range []string{"../evil.exe", "Interface/AddOns/../../Wow.exe", "/etc/passwd", "WTF/Config.wtf", "Interface/AddOnsX/a.lua"} {
		if addonPath(root, bad) != "" {
			t.Errorf("path %q accepted", bad)
		}
	}
}
