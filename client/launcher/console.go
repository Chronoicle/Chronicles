//go:build !windows

// Console version, for testing on the server: launcher --dir <client folder> [restore|repair]. A --dir folder without
// a client (no .build.info) gets the whole client installed into it first (no picker).
package main

import (
	"fmt"
	"os"
	"syscall"
)

func run(root string, args []string, test bool) {
	defer func() {
		if r := recover(); r != nil {
			fmt.Println("\nERROR:", r)
			os.Exit(1)
		}
	}()
	progress = func(text string, pct float64) { fmt.Printf("%3.0f%%  %s\n", pct, text) }
	if len(args) > 0 && args[0] == "restore" {
		restore(root)
		fmt.Println("Original client restored.")
		return
	}
	man, newer := checkLauncher(test)
	if newer {
		return
	}
	if test && !installed(root) {
		base, files := fetchClient(man)
		installClient(root, base, files)
	}
	if len(args) > 0 && args[0] == "repair" {
		repair(root, man)
	}
	prepare(root, man, test)
	if !test {
		startGame(root)
	}
}

// diskFree returns the bytes this user may still write on dir's file system, -1 when it cannot tell.
func diskFree(dir string) int64 {
	var st syscall.Statfs_t
	if syscall.Statfs(dir, &st) != nil {
		return -1
	}
	return int64(st.Bavail) * int64(st.Bsize)
}
