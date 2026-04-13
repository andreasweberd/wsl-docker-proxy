# Docker Bridge - Hand-off for new sessions

Use this file as the copy/paste context for colleagues or a new AI chat.

## Fast start

```powershell
C:\docker-proxy\start-docker-bridge.cmd
$env:DOCKER_HOST = "tcp://127.0.0.1:2375"
docker version
```

## Autostart einrichten (nach Reboot automatisch)

✅ **Autostart ist bereits installiert!** Der Docker Bridge startet jetzt nach jedem Reboot automatisch.

Verknüpfung: `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\Docker-Bridge-Startup.lnk`

## One-time setup for IntelliJ / GUI apps

```powershell
[Environment]::SetEnvironmentVariable("DOCKER_HOST", "tcp://127.0.0.1:2375", "User")
```

Restart IntelliJ after setting it.

## Block to paste into a new AI session

> Context for this session:
>
> - Docker must be used via local bridge `tcp://127.0.0.1:2375`.
> - Start command: `C:\docker-proxy\start-docker-bridge.cmd`
> - Then set `DOCKER_HOST=tcp://127.0.0.1:2375` in the current shell/process.
> - Verify with `docker version` or `docker ps`.
> - If connection fails, check `C:\docker-proxy\wsl-docker-bridge.log`.

## Check status

```powershell
Get-NetTCPConnection -LocalPort 2375 -State Listen -ErrorAction SilentlyContinue
```

## Stop bridge

```powershell
$pid2375 = (Get-NetTCPConnection -LocalPort 2375 -State Listen).OwningProcess
Stop-Process -Id $pid2375 -Force
```

## Notes

- Bridge is localhost-only.
- `docker.cmd` is optional and uses `wsl docker ...`; for IDE integration prefer the bridge path.
