#!/usr/bin/env python3
"""
Docker Bridge Service Manager
Stellt sicher, dass der TCP-Bridge immer läuft.
Kann als Windows Task Scheduler Service laufen.
"""

import subprocess
import time
import sys
import os

LISTEN_PORT = 2375
CHECK_INTERVAL = 30  # Sekunden zwischen Checks
BRIDGE_CMD = r"C:\docker-proxy\start-docker-bridge.cmd"

def port_is_listening():
    """Prüfe ob Port 2375 listening ist."""
    try:
        result = subprocess.run(
            ['powershell.exe', '-NoProfile', '-Command',
             f'Get-NetTCPConnection -LocalPort {LISTEN_PORT} -State Listen -ErrorAction SilentlyContinue'],
            capture_output=True,
            timeout=5
        )
        return result.returncode == 0 and len(result.stdout) > 0
    except:
        return False

def start_bridge():
    """Starte den Docker Bridge."""
    try:
        print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Starting bridge...")
        result = subprocess.run(BRIDGE_CMD, capture_output=True, timeout=10)
        if result.returncode == 0:
            print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Bridge started successfully")
            return True
        else:
            print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Bridge start failed: {result.stderr.decode()}")
            return False
    except Exception as e:
        print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Error starting bridge: {e}")
        return False

def main():
    print("[docker-proxy-service] Docker Bridge Service Manager started")
    print(f"[docker-proxy-service] Checking port {LISTEN_PORT} every {CHECK_INTERVAL} seconds")

    # Initial check & start
    if not port_is_listening():
        start_bridge()

    # Keep-alive loop
    consecutive_failures = 0
    while True:
        time.sleep(CHECK_INTERVAL)

        if not port_is_listening():
            consecutive_failures += 1
            print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Port not listening (failure #{consecutive_failures})")

            if consecutive_failures >= 2:
                print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Restarting bridge...")
                start_bridge()
                consecutive_failures = 0
        else:
            consecutive_failures = 0

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n[docker-proxy-service] Shutting down...")
        sys.exit(0)

