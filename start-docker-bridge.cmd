@echo off
setlocal EnableDelayedExpansion

REM Check on Windows if port 2375 is already listening.
powershell -NoProfile -Command "if (Get-NetTCPConnection -LocalPort 2375 -State Listen -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }"
if not errorlevel 1 (
    echo [docker-proxy-bridge] Bridge already running on port 2375
    exit /b 0
)

set "BRIDGE_WIN=%~dp0wsl-docker-tcp-bridge.py"
set "BRIDGE_WIN=%BRIDGE_WIN:\=/%"
for /f "delims=" %%I in ('wsl wslpath -a "%BRIDGE_WIN%"') do set "BRIDGE_PY=%%I"

if not defined BRIDGE_PY (
    echo [docker-proxy-bridge] ERROR: Could not resolve WSL path for bridge script.
    exit /b 1
)

echo [docker-proxy-bridge] Starting WSL Docker TCP bridge...

REM Best effort cleanup for stale bridge processes from prior sessions.
powershell -NoProfile -Command "$targets = @(); $targets += Get-CimInstance Win32_Process -Filter \"Name='python.exe'\" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match 'wsl-docker-tcp-bridge\.py' }; $targets += Get-CimInstance Win32_Process -Filter \"Name='wsl.exe'\" -ErrorAction SilentlyContinue | Where-Object { $_.CommandLine -match 'wsl-docker-tcp-bridge\.py' }; if ($targets) { $targets | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue } }"

start "docker-proxy-bridge" /b wsl python3 -u "!BRIDGE_PY!" > "%~dp0wsl-docker-bridge.log" 2>&1

REM Wait up to 15s until Windows can actually connect to 127.0.0.1:2375.
set "READY=0"
for /l %%I in (1,1,15) do (
    powershell -NoProfile -Command "try { $r = Invoke-WebRequest -UseBasicParsing http://127.0.0.1:2375/_ping -TimeoutSec 1; if ($r.Content -eq 'OK') { exit 0 } else { exit 1 } } catch { exit 1 }"
    if not errorlevel 1 (
        set "READY=1"
        goto :ready
    )
    timeout /t 1 /nobreak >nul
)

:ready
if not "!READY!"=="1" (
    echo [docker-proxy-bridge] ERROR: Bridge did not start. See wsl-docker-bridge.log
    exit /b 1
)

echo [docker-proxy-bridge] Bridge started. Set DOCKER_HOST=tcp://127.0.0.1:2375
exit /b 0
