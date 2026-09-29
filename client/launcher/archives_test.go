package main

import (
	"os"
	"path/filepath"
	"testing"
)

// cleanupArchives removes only data.NNN archives no index references and below the highest referenced one;
// everything else, even a name that merely starts with "data.", is left alone.
func TestCleanupArchives(t *testing.T) {
	data := t.TempDir()
	for name, body := range map[string]string{
		"data.000": "referenced", "data.001": "orphan", "data.002": "also orphan", "data.003": "referenced (top)",
		"data.004": "above the top: the game's", "shmem": "not an archive", "data.abc": "not three digits",
		"data.1234": "too many digits",
	} {
		if err := os.WriteFile(filepath.Join(data, name), []byte(body), 0644); err != nil {
			t.Fatal(err)
		}
	}
	ix := &index{records: map[string][]byte{}}
	ix.set(make([]byte, 9), 0, 0, 30) // references archives 0 and 3
	ix.set([]byte{1, 0, 0, 0, 0, 0, 0, 0, 0}, 3, 0, 30)

	cleanupArchives(data, []*index{ix})

	for name, wantGone := range map[string]bool{
		"data.000": false, "data.001": true, "data.002": true, "data.003": false, "data.004": false,
		"shmem": false, "data.abc": false, "data.1234": false,
	} {
		_, err := os.Stat(filepath.Join(data, name))
		if gone := os.IsNotExist(err); gone != wantGone {
			t.Errorf("%s: gone=%v, want %v", name, gone, wantGone)
		}
	}
}

// An index that listed a key twice lost one copy's archive in the map: then nothing is removed.
func TestCleanupArchivesDuplicateKey(t *testing.T) {
	data := t.TempDir()
	if err := os.WriteFile(filepath.Join(data, "data.000"), []byte("maybe the lost copy"), 0644); err != nil {
		t.Fatal(err)
	}
	ix := &index{records: map[string][]byte{}, dup: true}
	ix.set(make([]byte, 9), 1, 0, 30)
	cleanupArchives(data, []*index{ix})
	if _, err := os.Stat(filepath.Join(data, "data.000")); err != nil {
		t.Errorf("data.000 was removed: %v", err)
	}
}

// A folder matching the data.NNN name (never a real archive) is left alone: cleanupArchives only removes files.
func TestCleanupArchivesLeavesFolders(t *testing.T) {
	data := t.TempDir()
	if err := os.Mkdir(filepath.Join(data, "data.005"), 0755); err != nil {
		t.Fatal(err)
	}
	ix := &index{records: map[string][]byte{}}
	ix.set(make([]byte, 9), 9, 0, 30)
	cleanupArchives(data, []*index{ix})
	if _, err := os.Stat(filepath.Join(data, "data.005")); err != nil {
		t.Errorf("data.005 folder was removed: %v", err)
	}
}
