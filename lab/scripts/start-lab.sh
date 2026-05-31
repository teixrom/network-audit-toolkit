#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LAB_DIR="$(dirname "$SCRIPT_DIR")"

echo "============================================"
echo "  Network Audit Toolkit - Laboratorio"
echo "============================================"
echo ""

# Verificar Docker/podman
if command -v podman &>/dev/null && podman ps &>/dev/null 2>&1; then
    DOCKER="podman"
    COMPOSE="podman-compose"
    echo "[*] Usando Podman"
elif command -v docker &>/dev/null && docker ps &>/dev/null 2>&1; then
    DOCKER="docker"
    if docker compose version &>/dev/null 2>&1; then
        COMPOSE="docker compose"
    else
        COMPOSE="docker-compose"
    fi
    echo "[*] Usando Docker"
else
    echo "[!] Docker ou Podman nao encontrados."
    echo "    Instale: sudo apt install docker.io docker-compose"
    echo "    ou:      sudo apt install podman podman-compose"
    exit 1
fi

echo "[*] Construindo e iniciando containers..."
echo ""
cd "$LAB_DIR"

$COMPOSE up -d --build

echo ""
echo "============================================"
echo "  Laboratorio pronto!"
echo "============================================"
echo ""
echo "  Container    IP             Servicos"
echo "  -----------------------------------------------"
echo "  target       10.99.0.10     SSH/HTTP/HTTPS/FTP/MySQL/SNMP"
echo "  smb          10.99.0.11     SMB (445/139)"
echo "  ldap         10.99.0.12     LDAP (389/636)"
echo "  dns          10.99.0.13     DNS (53)"
echo "  snmp         10.99.0.14     SNMP (161)"
echo ""
echo "  Credenciais:"
echo "    target - SSH:   admin:admin   |   root:toor"
echo "    target - FTP:   anonymous     |   ftpuser:ftp123"
echo "    target - MySQL: root:root     |   appuser:app123"
echo "    target - SNMP:  public (ro)"
echo "    smb    - SMB:   admin:secret123  |  user:password"
echo "    ldap   - LDAP:  cn=admin,dc=lab,dc=local / admin123"
echo "    ldap   - LDAP:  cn=reader,dc=lab,dc=local / reader123"
echo ""
echo "  Para testar os modulos, execute do host:"
echo "    sudo bash ../network_audit.sh"
echo ""
echo "  Exemplo de alvos:"
echo "    Modulo 1 (host discovery): 10.99.0.0/24"
echo "    Modulo 2 (port scan):      10.99.0.10"
echo "    Modulo 4 (web audit):      http://10.99.0.10"
echo "    Modulo 5 (dns audit):      10.99.0.13 / lab.local"
echo "    Modulo 7 (snmp audit):     10.99.0.14"
echo "    Modulo 8 (password):       10.99.0.10 - SSH admin"
echo "    Modulo 17 (identity):      10.99.0.12 / lab.local"
echo ""
echo "  Para parar: $SCRIPT_DIR/stop-lab.sh"
echo "============================================"
