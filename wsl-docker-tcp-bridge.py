#!/usr/bin/env python3
"""
TCP-to-Unix-Socket Bridge für WSL Docker.
Exponiert die WSL Docker-Socket unter localhost:2375
für Windows-Java-Prozesse (Maven digest-plugin, etc).
"""

import socket
import subprocess
import threading
import sys
import os
import signal

WSL_DOCKER_SOCKET = "/var/run/docker.sock"
LISTEN_PORT = 2375
LISTEN_HOST = "127.0.0.1"

def forward_connection(client_socket, addr):
    """Proxy-Verbindung vom TCP-Client zur WSL Docker-Socket."""
    try:
        # Verbinde zu WSL Docker-Socket
        wsl_socket = socket.socket(socket.AF_UNIX)
        wsl_socket.connect(WSL_DOCKER_SOCKET)
        
        def relay(src, dst, name):
            try:
                while True:
                    data = src.recv(4096)
                    if not data:
                        break
                    dst.sendall(data)
            except:
                pass
            finally:
                src.close()
                dst.close()
        
        # Bidirektionales Relaying in Threads
        t1 = threading.Thread(target=relay, args=(client_socket, wsl_socket, "client->docker"))
        t2 = threading.Thread(target=relay, args=(wsl_socket, client_socket, "docker->client"))
        t1.daemon = True
        t2.daemon = True
        t1.start()
        t2.start()
        
    except Exception as e:
        print(f"[ERROR] Connection failed: {e}", file=sys.stderr)
        client_socket.close()

def run_server():
    """Starte TCP-Listen-Server."""
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    
    try:
        server.bind((LISTEN_HOST, LISTEN_PORT))
        server.listen(5)
        print(f"[INFO] Docker socket exposed at tcp://{LISTEN_HOST}:{LISTEN_PORT}")
        print(f"[INFO] Forwarding to: {WSL_DOCKER_SOCKET}")
        
        while True:
            client, addr = server.accept()
            print(f"[DEBUG] Incoming connection from {addr}")
            t = threading.Thread(target=forward_connection, args=(client, addr))
            t.daemon = True
            t.start()
            
    except KeyboardInterrupt:
        print("[INFO] Shutting down...")
    except Exception as e:
        print(f"[ERROR] Server error: {e}", file=sys.stderr)
    finally:
        server.close()

if __name__ == "__main__":
    # Prüfe, ob Docker-Socket existiert
    if not os.path.exists(WSL_DOCKER_SOCKET):
        print(f"[ERROR] Docker socket not found: {WSL_DOCKER_SOCKET}", file=sys.stderr)
        sys.exit(1)
    
    run_server()

