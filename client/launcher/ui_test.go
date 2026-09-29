package main

import (
	"encoding/base64"
	"os"
	"regexp"
	"testing"
)

// Every art/<file> ui.html names is in art/ (the launcher inlines them), every file there is used, and the inlined
// page stays under WebView2's 2 MB limit for SetHtml (NavigateToString).
func TestUIArt(t *testing.T) {
	html, err := os.ReadFile("ui.html")
	if err != nil {
		t.Fatal(err)
	}
	used := map[string]bool{}
	for _, m := range regexp.MustCompile(`art/([A-Za-z0-9_.-]+\.(?:jpg|png|webp))`).FindAllStringSubmatch(string(html), -1) {
		used[m[1]] = true
	}
	files, err := os.ReadDir("art")
	if err != nil {
		t.Fatal(err)
	}
	size := len(html)
	for _, f := range files {
		if !used[f.Name()] {
			t.Errorf("art/%s is not used by ui.html", f.Name())
		}
		delete(used, f.Name())
		st, _ := f.Info()
		size += base64.StdEncoding.EncodedLen(int(st.Size()))
	}
	for name := range used {
		t.Errorf("ui.html uses art/%s, which is missing", name)
	}
	if size > 2_000_000 {
		t.Errorf("inlined page is %d bytes, WebView2's SetHtml takes 2 MB at most", size)
	}
}
