@echo off
REM if not defined DOCKER_HOST set "DOCKER_HOST=tcp://127.0.0.1:2375"
REM [Environment]::SetEnvironmentVariable("DOCKER_HOST", "tcp://127.0.0.1:2375", "User")
set "DOCKER_PROXY_ARGS=%*"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0docker-helper.ps1"
exit /b %errorlevel%
