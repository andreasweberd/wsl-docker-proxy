@echo off
REM Erstelle eine Windows Scheduled Task für automatischen Docker Bridge Start
REM Läuft mit Admin-Rechten nach jedem Reboot

setlocal enabledelayedexpansion

REM Prüfe auf Admin-Rechte
net session >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Diese Datei muss mit Administrator-Rechten ausgeführt werden.
    echo [INFO] Bitte als Administrator starten.
    exit /b 1
)

echo [INFO] Installiere Docker Bridge Autostart...

REM Erstelle die Scheduled Task
schtasks /create /tn "Docker-Bridge-Startup" /tr "C:\docker-proxy\start-docker-bridge.cmd" /sc onstart /rl highest /f

if errorlevel 0 (
    echo [SUCCESS] Docker Bridge Autostart installiert!
    echo [INFO] Der Docker Bridge wird nach jedem Reboot automatisch gestartet.
    schtasks /query /tn "Docker-Bridge-Startup"
) else (
    echo [ERROR] Fehler beim Installieren der Autostart-Task.
    exit /b 1
)

exit /b 0

