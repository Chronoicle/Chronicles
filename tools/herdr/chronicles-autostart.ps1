# Windows login: start the Herdr server in the background, then the desktop team (chronicles-herdr.ps1 next to this file).
# Started by the Startup-folder shortcut "Chronicles herdr team"; open the team with `herdr` in Windows Terminal.
# Copy both scripts to ~\.local\bin. Log: %APPDATA%\herdr\autostart.log
# Herdr's own agent resume must be off ([session] resume_agents_on_restore = false in config.toml): it can't give
# help-helper its Pro account or a seat its model.

$log = Join-Path $env:APPDATA 'herdr\autostart.log'
$herdr = (Get-Command herdr -CommandType Application | Select-Object -First 1).Source
function Test-Server { (& $herdr status server 2>&1 | Out-String) -match 'status: running' }

"$(Get-Date -Format s) autostart" | Add-Content $log
if (-not (Test-Server)) {
    Start-Process $herdr -ArgumentList 'server' -WindowStyle Hidden
    for ($i = 0; $i -lt 30 -and -not (Test-Server); $i++) { Start-Sleep 1 }
}
$env:HERDR_ENV = '1'
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'chronicles-herdr.ps1') *>&1 | Add-Content $log
