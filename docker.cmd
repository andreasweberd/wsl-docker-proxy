@echo off
set "DOCKER_PROXY_ARGS=%*"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0docker-helper.ps1"
exit /b %errorlevel%
