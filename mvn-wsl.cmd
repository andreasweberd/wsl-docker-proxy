#!/bin/bash
# Wrapper script to run Maven inside WSL
# This avoids all Docker socket/Java-Docker-API issues

# Gehe zum Windows-Projektpfad
cd "$(wslpath -a "$1")" || exit 1
shift

# Starte Maven mit allen Argumenten
mvn "$@"

