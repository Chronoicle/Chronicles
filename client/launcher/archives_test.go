package main

import (
	"os"
	"path/filepath"
	"testing"
)

// cleanupArchives removes only data.NNN archives no index references; everything else, even a name that merely
// starts with "data.", is left alone.
func TestCleanupArchives(t *testing.T) {
	data := t.TempDir()
	for name, body := range map[string]string{
		"data.000": "referenced", "data.001": "orphan", "data.002": "also orphan",
		"shmem": "not an archive", "data.abc": "not three digits", "data.1234": "too many digits",
	} {
		if err := os.WriteFile(filepath.Join(data, name), []byte(body), 0644); err != nil {
			t.Fatal(err)
		}
	}
	ix := &index{records: map[string][]byte{}}
	ix.set(make([]byte, 9), 0, 0, 30) // references archive 0 only

	cleanupArchives(data, []*index{ix})

	for name, wantGone := range map[string]bool{
		"data.000": false, "data.001": true, "data.002": true,
		"shmem": false, "data.abc": false, "data.1234": false,
	} {
		_, err := os.Stat(filepath.Join(data, name))
		if gone := os.IsNotExist(err); gone != wantGone {
			t.Errorf("%s: gone=%v, want %v", name, gone, wantGone)
		}
	}
}

// A folder matching the data.NNN name (never a real archive) is left alone: cleanupArchives only removes files.
func TestCleanupArchivesLeavesFolders(t *testing.T) {
	data := t.TempDir()
	if err := os.Mkdir(filepath.Join(data, "data.005"), 0755); err != nil {
		t.Fatal(err)
	}
	cleanupArchives(data, []*index{{records: map[string][]byte{}}})
	if _, err := os.Stat(filepath.Join(data, "data.005")); err != nil {
		t.Errorf("data.005 folder was removed: %v", err)
	}
}
