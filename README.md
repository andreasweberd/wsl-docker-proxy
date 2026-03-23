# docker-proxy

Tools to make a Docker daemon running inside WSL usable from Windows tools (especially Java/Maven workflows).

This repository combines **two main approaches**:

1. **CLI wrapping** (`docker.cmd` + `docker-helper.ps1`) so Windows commands transparently execute `docker` inside WSL.
2. **TCP exposure / bridging** to expose the WSL Docker Unix socket at `tcp://127.0.0.1:2375` for clients that cannot use Unix sockets (for example some Java Docker integrations).

---

## Why this exists

In mixed Windows + WSL development setups, the Docker daemon often runs only in WSL (`/var/run/docker.sock`).
Some Windows processes can call WSL directly, but others (notably Java tooling/plugins) expect a TCP Docker endpoint.

This project provides helper scripts to bridge that gap.

---

## What is in this repo

- `docker.cmd`  
  Windows entrypoint that captures Docker CLI arguments and forwards them to PowerShell.

- `docker-helper.ps1`  
  Parses CLI args, converts Windows volume mounts like `C:\path:/container` to WSL mounts like `/mnt/c/path:/container`, then runs `wsl docker ...`.

- `start-docker-bridge.cmd`  
  Starts a Python TCP bridge in the background (listening on `127.0.0.1:2375`) and writes logs to `wsl-docker-bridge.log`.

- `wsl-docker-tcp-bridge.py`  
  TCP-to-Unix-socket proxy:
  - listens on `127.0.0.1:2375`
  - forwards traffic to `/var/run/docker.sock`

- `expose-docker-socket.ps1`  
  Alternative method using `socat` inside WSL and an optional Windows firewall rule (`WSL Docker Proxy`).

- `configure-docker-tcp.sh`, `daemon.json`, `docker-override.conf`  
  Alternative daemon-level configuration files to make Docker itself listen on TCP (`127.0.0.1:2375`).

- `mvn-wsl.cmd`  
  A Maven-in-WSL wrapper script (note: file extension is `.cmd`, but content is Bash style).

- `wsl-docker-bridge.log`  
  Runtime log for the Python bridge.

---

## Architecture

### A) Docker CLI wrapper path

```text
Windows shell
  -> docker.cmd
    -> docker-helper.ps1
      -> wsl docker <args>
         -> WSL Docker daemon (/var/run/docker.sock)
```

### B) TCP bridge path

```text
Windows app/tool (DOCKER_HOST=tcp://127.0.0.1:2375)
  -> Python bridge (wsl-docker-tcp-bridge.py)
     -> /var/run/docker.sock (WSL)
        -> Docker daemon
```

---

## Requirements

- Windows with WSL installed
- A Linux distro in WSL
- Docker daemon available inside WSL (`/var/run/docker.sock`)
- For TCP options:
  - Python 3 in WSL (for `wsl-docker-tcp-bridge.py`), or
  - `socat` in WSL (for `expose-docker-socket.ps1`)

Optional:
- PowerShell execution policy that allows running local scripts, or use `-ExecutionPolicy Bypass` as already done in `docker.cmd`.

---

## Setup modes (important)

### Mode A (default): CLI wrapper via `docker.cmd`

Use this for normal day-to-day Docker CLI work from Windows.

- No daemon reconfiguration required.
- No `daemon.json` copy step required.
- `docker.cmd` does **not** auto-install or auto-copy `daemon.json` on first call.
- If `DOCKER_HOST` is not already set, `docker.cmd` sets a default of `tcp://127.0.0.1:2375` for the current CMD session.

### Mode B (optional): TCP endpoint for tools that require `DOCKER_HOST`

Use this only if a client cannot work through `wsl docker` and explicitly requires `tcp://...`.

You have three alternatives:

1. Python bridge (`start-docker-bridge.cmd`)
2. `socat` bridge (`expose-docker-socket.ps1`)
3. Daemon-level TCP listener via `configure-docker-tcp.sh`

For option 3, the copy happens only when you run the script in WSL. The script writes `/tmp/daemon.json` and runs:

```bash
sudo cp /tmp/daemon.json /etc/docker/daemon.json
sudo service docker restart
```

---

## Usage

### 1) Mode A: Use Docker from Windows via wrapper

Run through `docker.cmd` (or rename/alias it to `docker` in your PATH order):

```powershell
C:\docker-proxy\docker.cmd ps
C:\docker-proxy\docker.cmd run --rm -v C:\Users\me\project:/work alpine ls /work
```

Enable debug output for argument conversion:

```powershell
$env:DOCKER_PROXY_DEBUG="1"
C:\docker-proxy\docker.cmd run --rm -v C:\temp:/data alpine ls /data
```

If needed, you can still override `DOCKER_HOST` explicitly before calling `docker.cmd`.

### 2) Mode B option 1: Start local TCP bridge (Python)

```powershell
C:\docker-proxy\start-docker-bridge.cmd
$env:DOCKER_HOST="tcp://127.0.0.1:2375"
docker version
```

Logs are written to `wsl-docker-bridge.log`.

### 3) Mode B option 2: Alternative bridge via socat

```powershell
powershell -ExecutionPolicy Bypass -File C:\docker-proxy\expose-docker-socket.ps1 -Port 2375
$env:DOCKER_HOST="tcp://localhost:2375"
docker info
```

To stop/remove firewall rule created by that script:

```powershell
powershell -ExecutionPolicy Bypass -File C:\docker-proxy\expose-docker-socket.ps1 -Stop
```

### 4) Mode B option 3: Enable daemon-level TCP listener (optional)

Run inside WSL:

```bash
cd /mnt/c/docker-proxy
chmod +x configure-docker-tcp.sh
./configure-docker-tcp.sh
```

This is an explicit install/configuration step and is not triggered by `docker.cmd`.

---

## Known issue from current log

`wsl-docker-bridge.log` currently contains:

```text
python3: can't open file '/mnt/c/Users/.../C:docker-proxywsl-docker-tcp-bridge.py': [Errno 2] No such file or directory
```

This indicates a **path translation problem** when launching `wsl-docker-tcp-bridge.py` from `start-docker-bridge.cmd`.
The Windows path (`%~dp0...`) is being interpreted incorrectly in WSL.

### Practical fix

Use explicit WSL path conversion (`wslpath`) before calling Python, for example:

```powershell
wsl python3 -u "$(wsl wslpath -a 'C:\docker-proxy\wsl-docker-tcp-bridge.py')"
```

Or in batch logic, convert `%~dp0` to a WSL path first and call Python with that converted path.

---

## Troubleshooting

- `docker: command not found` in WSL:
  - install Docker CLI/daemon in WSL distro and verify `wsl docker ps`.

- `Docker socket not found: /var/run/docker.sock`:
  - start Docker daemon in WSL (`sudo service docker start` or distro-specific method).

- `Cannot connect to tcp://127.0.0.1:2375`:
  - verify bridge is running and listening:

```powershell
Get-NetTCPConnection -LocalPort 2375 -State Listen
```

- Port conflict on `2375`:
  - stop the conflicting process or choose another port in scripts.

- Volume mount path wrong inside container:
  - use wrapper mode and check conversion logic in `docker-helper.ps1`.

---

## Security notes

Exposing Docker over TCP is sensitive, because Docker API access is highly privileged.

- Prefer binding to `127.0.0.1` only (as in this repo).
- Do **not** expose `2375` to external networks.
- If broader access is required, use proper authentication/TLS instead of plain TCP.
- Stop the bridge when not needed.

---

## Suggested workflow

For day-to-day terminal usage, prefer the CLI wrapper (`docker.cmd`).
For tools that strictly require `DOCKER_HOST=tcp://...`, run one of the bridge methods and keep it localhost-only.

---

## Maintenance notes

- `mvn-wsl.cmd` currently contains Bash syntax despite `.cmd` extension. Treat it as a draft or rename/rewrite depending on intended shell.
- If both daemon-level TCP config and user-space bridge are enabled, keep setup simple and avoid duplicated listeners.

---

## License

This project is licensed under the MIT License. See `LICENSE` for details.
