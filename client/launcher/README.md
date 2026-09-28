# Launcher (source)

The Chronicles launcher (`Launcher.exe`): keeps the custom 7.3.5 client on the server's build, keeps `Wow-64_Custom.exe`
and loose addon files up to date, updates itself, starts the game. Built on the server in `~/launcher` (Go in `~/go`),
with the patch server over https:

    GOROOT=$HOME/go GOPATH=$HOME/go PATH=$HOME/go/bin:$PATH GOOS=windows GOARCH=amd64 \
      go build -ldflags "-H windowsgui -X main.server=https://patch.chronicles-wow.com -X main.portal=chronicles-wow.com" -o Launcher_new.exe

Test builds add `-X main.selfUpdates=no`. The console build (`go build` on Linux) runs `launcher --dir <client folder>`
for testing the update on the server. Publishing = copy to `~/cdn/launcher/Launcher.exe` and set `launcher_md5` in
`~/cdn/launcher/manifest.json`: every launcher replaces itself with it, so test first and keep the previous exe.

## Client install and repair

Started from a folder without a client (no `.build.info`) while the manifest has a `"client"` list (without one it
says to put Launcher.exe in the World of Warcraft folder, as before), the launcher installs the whole client. The
player picks a folder; the client goes into the picked folder itself when it is empty, is named Chronicles, holds a
7.3.5 client (a retail or Classic `.build.info` does not count) or holds an interrupted install (no `.build.info`, but
`Data/` or a `.part` file), else into `<picked>\Chronicles`. That folder is saved in `launcher.json` right away, so the
next start goes on there without asking. The free space is checked, every listed file is downloaded (4 at a time,
through `<file>.part`, continued with HTTP Range, md5 checked, synced to disk, `.build.info` last); network errors are
retried (waits up to 30 s) until 10 minutes pass without a byte. Then it copies itself into that folder as
`Launcher.exe` (another `Launcher.exe` there is kept as `Launcher.exe.bak`), starts that copy (which updates the client
as usual and shows Play) and exits.

`Launcher.exe repair` (in the client folder) checks the client against the list, then updates as usual. The rule (see
`repair` in `client.go`): it never touches `.build.info`, `Data/data/shmem` or `*.launcher-backup`, and never
overwrites a file in `Data/data/` (the launcher's updates and the game change those: new archives and index versions,
shmem, old index versions deleted). In `Data/data/` it only downloads a listed file that is missing and needed: a
`data.NNN` archive, or the index version the current shmem names. Every other listed file (`Data/config`,
`Data/indices`, `Data/enGB`, `Data/ruRU`, `Utils`, `BlizzardError.exe`) is checked by size and md5 and fixed.

Console test: `launcher --dir <empty folder>` installs into that folder, `launcher --dir <folder> repair` repairs.

**Publishing a client:** `manifest.json` gets `"client": "/client/client.json"`; the patch server serves the client
folder under `/client/<path>` (Range requests answered with 206). The list may only name `.build.info`,
`BlizzardError.exe` and files under `Data/` or `Utils/`, each path part only `A-Z a-z 0-9 _ . -`, not ending in `.` or
`.part` (anything else, e.g. `WTF/`, `Cache/`, an exe or a space, makes every launcher reject the list). It leaves out
the in-game browser's profile (`Utils/cache/`, `Utils/cookies/`, `Utils/logs/`) and the launcher's backups
(`*.launcher-backup`: they name index files the game has deleted). Regenerate it after any change to the client folder:

    cd <client folder> && python3 -c '
    import hashlib, json, os
    ok = lambda p: (p in (".build.info", "BlizzardError.exe") or p.startswith(("Data/", "Utils/"))) and not (
        p.startswith(("Utils/cache/", "Utils/cookies/", "Utils/logs/")) or p.endswith((".part", ".launcher-backup")))
    files = []
    for d, _, names in os.walk("."):
        for n in names:
            p = os.path.relpath(os.path.join(d, n)).replace(os.sep, "/")
            if ok(p):
                h = hashlib.md5()
                with open(p, "rb") as f:
                    for b in iter(lambda: f.read(1 << 20), b""): h.update(b)
                files.append({"path": p, "size": os.path.getsize(p), "md5": h.hexdigest()})
    json.dump({"files": sorted(files, key=lambda f: f["path"])}, open("client.json", "w"))'

Changing or adding `Data/data/` files in a published client only reaches new installs (repair never overwrites them);
new game data goes out as a build update (the manifest's blobs), as before.
