@echo off
REM Startet die WSL-Docker-TCP-Bridge im Hintergrund
REM Dies exponiert den WSL Docker-Daemon unter tcp://127.0.0.1:2375
REM für Java-Prozesse wie Maven digest-plugin

setlocal EnableDelayedExpansion

REM Prüfe ob Bridge bereits läuft
netstat -ano 2>nul | findstr /R ":2375.*LISTENING" >nul
if not errorlevel 1 (
    echo [docker-proxy-bridge] Bridge already running on port 2375
    exit /b 0
)

echo [docker-proxy-bridge] Starting WSL Docker TCP bridge...

REM Starte Python-Skript im WSL als Daemon
wsl python3 -u %~dp0wsl-docker-tcp-bridge.py > "%~dp0wsl-docker-bridge.log" 2>&1 &

timeout /t 2 /nobreak >nul
echo [docker-proxy-bridge] Bridge started. Set: $env:DOCKER_HOST="tcp://127.0.0.1:2375"

