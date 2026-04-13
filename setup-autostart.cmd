@echo off
REM Setup script - Autostart installieren (braucht Admin-Rechte beim ersten Mal)

setlocal enabledelayedexpansion

echo [docker-proxy] Installiere Autostart...

REM Prüfe ob Task bereits existiert
schtasks /query /tn "Docker-Bridge-Startup" >nul 2>&1
if errorlevel 0 (
    echo [docker-proxy] Autostart ist bereits installiert.
    exit /b 0
)

REM Prüfe auf Admin-Rechte
net session >nul 2>&1
if errorlevel 1 (
    echo [docker-proxy] WARNUNG: Bitte diese Datei als Administrator ausführen:
    echo   Rechtsklick ^> "Als Administrator ausführen"
    echo [docker-proxy] Oder führe aus:
    echo   schtasks /create /tn "Docker-Bridge-Startup" /tr "C:\docker-proxy\start-docker-bridge.cmd" /sc onstart /rl highest /f
    exit /b 1
)

REM Erstelle die Task
schtasks /create /tn "Docker-Bridge-Startup" /tr "C:\docker-proxy\start-docker-bridge.cmd" /sc onstart /rl highest /f
if errorlevel 0 (
    echo [docker-proxy] SUCCESS: Docker Bridge Autostart installiert!
    echo [docker-proxy] Bridge startet jetzt nach jedem Reboot automatisch.
) else (
    echo [docker-proxy] FEHLER: Autostart konnte nicht installiert werden.
    exit /b 1
)

exit /b 0

