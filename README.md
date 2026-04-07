# docker-proxy

Use Docker running in WSL from Windows tools (for example IntelliJ plugins) via a local TCP bridge on `127.0.0.1:2375`.

## Recommended mode (team standard)

This repository is now standardized on one mode:

- Start `start-docker-bridge.cmd`
- Set `DOCKER_HOST=tcp://127.0.0.1:2375`
- Use Docker from Windows tools

The bridge forwards traffic to WSL Docker socket `/var/run/docker.sock`.

## Quick start

```powershell
C:\docker-proxy\start-docker-bridge.cmd
$env:DOCKER_HOST = "tcp://127.0.0.1:2375"
docker version
```

For GUI tools like IntelliJ (launched from Start Menu), set it once per user:

```powershell
[Environment]::SetEnvironmentVariable("DOCKER_HOST", "tcp://127.0.0.1:2375", "User")
```

Restart IntelliJ afterwards.

## Important note about `docker.cmd`

`docker.cmd` is an optional wrapper that runs `wsl docker ...` directly.
It is useful for CLI volume path conversion, but it is not the primary bridge path for IDE tools.

## Files kept in this repo

- `start-docker-bridge.cmd` - starts the bridge robustly via WSL `nohup`
- `wsl-docker-tcp-bridge.py` - TCP-to-Unix socket proxy implementation
- `docker.cmd` + `docker-helper.ps1` - optional Windows CLI wrapper
- `DOCKER_BRIDGE.md` - handover text for new AI sessions / colleagues
- `LICENSE` - MIT

## Troubleshooting

- Bridge not reachable:

```powershell
Get-NetTCPConnection -LocalPort 2375 -State Listen -ErrorAction SilentlyContinue
Get-Content C:\docker-proxy\wsl-docker-bridge.log -Tail 50
```

- If log shows `Connection refused`, Docker in WSL is not accepting socket connections. Start/fix Docker in WSL first.

- If `docker version` still shows only client output in PowerShell, check which command is resolved:

```powershell
Get-Command docker -All
```

If it resolves to `C:\docker-proxy\docker.cmd`, that call goes through the WSL wrapper.

## License

MIT, see `LICENSE`.
