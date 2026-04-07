@echo off
setlocal EnableDelayedExpansion

REM Check in WSL if port 2375 is already listening.
wsl sh -lc "ss -lnt 'sport = :2375' | grep -q 2375"
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
start "docker-proxy-bridge" /b wsl python3 -u "!BRIDGE_PY!" > "%~dp0wsl-docker-bridge.log" 2>&1

timeout /t 2 /nobreak >nul
wsl sh -lc "ss -lnt 'sport = :2375' | grep -q 2375"
if errorlevel 1 (
    echo [docker-proxy-bridge] ERROR: Bridge did not start. See wsl-docker-bridge.log
    exit /b 1
)

echo [docker-proxy-bridge] Bridge started. Set DOCKER_HOST=tcp://127.0.0.1:2375
exit /b 0
