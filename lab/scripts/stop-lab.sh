#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

if command -v podman &>/dev/null && podman ps &>/dev/null 2>&1; then
    COMPOSE="podman-compose"
elif command -v docker &>/dev/null && docker ps &>/dev/null 2>&1; then
    if docker compose version &>/dev/null 2>&1; then
        COMPOSE="docker compose"
    else
        COMPOSE="docker-compose"
    fi
else
    echo "[!] Docker ou Podman nao encontrados."
    exit 1
fi

echo "[*] Parando laboratorio..."
cd "$LAB_DIR"
$COMPOSE down -v
echo "[+] Laboratorio parado e limpo."
