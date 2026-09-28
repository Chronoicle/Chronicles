//go:build !windows

// Console version, for testing the update on the server: launcher --dir <client folder> [restore]
package main

import (
	"fmt"
	"os"
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
	if prepare(root, test) || test {
		return
	}
	startGame(root)
}
