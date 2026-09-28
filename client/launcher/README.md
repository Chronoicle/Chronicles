# Launcher (source)

The Chronicles launcher (`Launcher.exe`): keeps the custom 7.3.5 client on the server's build, keeps `Wow-64_Custom.exe`
and loose addon files up to date, updates itself, starts the game. Built on the server in `~/launcher` (Go in `~/go`):

    GOROOT=$HOME/go GOPATH=$HOME/go PATH=$HOME/go/bin:$PATH GOOS=windows GOARCH=amd64 \
      go build -ldflags "-H windowsgui -X main.server=http://patch.chronicles-wow.com -X main.portal=chronicles-wow.com" -o Launcher_new.exe

Test builds add `-X main.selfUpdates=no`. The console build (`go build` on Linux) runs `launcher --dir <client folder>`
for testing the update on the server. Publishing = copy to `~/cdn/launcher/Launcher.exe` and set `launcher_md5` in
`~/cdn/launcher/manifest.json`: every launcher replaces itself with it, so test first and keep the previous exe.
