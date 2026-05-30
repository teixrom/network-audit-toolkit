#!/usr/bin/env bash

set -euo pipefail

GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

DISTRO=""
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AUDIT_DIR="$SCRIPT_DIR/audits"
mkdir -p "$AUDIT_DIR"
LOG_FILE="$AUDIT_DIR/install_$(date +%Y%m%d_%H%M%S).log"
exec 2>>"$LOG_FILE"

log() {
    echo "[$(date '+%H:%M:%S')] $*" >> "$LOG_FILE"
}

detect_distro() {
    if command -v apt &>/dev/null; then
        DISTRO="debian"
    elif command -v dnf &>/dev/null; then
        DISTRO="fedora"
    elif command -v yum &>/dev/null; then
        DISTRO="centos"
    elif command -v pacman &>/dev/null; then
        DISTRO="arch"
    elif command -v zypper &>/dev/null; then
        DISTRO="suse"
    else
        DISTRO="unknown"
    fi
}

install_pkg() {
    case "$DISTRO" in
        debian) sudo apt install -y "$@" 2>/dev/null ;;
        fedora) sudo dnf install -y "$@" 2>/dev/null ;;
        centos) sudo yum install -y "$@" 2>/dev/null ;;
        arch)   sudo pacman -S --noconfirm "$@" 2>/dev/null ;;
        suse)   sudo zypper install -y "$@" 2>/dev/null ;;
        *)
            echo -e "${RED}[!] Distro não suportada ($DISTRO). Instale manualmente: $*${RESET}"
            return 1
            ;;
    esac
}

show_banner() {
    clear
    echo -e "${CYAN}=================================================${RESET}"
    echo -e "${CYAN}  Instalação de Dependências${RESET}"
    echo -e "${CYAN}  Network Audit Toolkit${RESET}"
    echo -e "${CYAN}=================================================${RESET}"
    echo ""
}

install_all() {
    echo -e "${YELLOW}[*] Instalando todas as ferramentas...${RESET}"
    log "Iniciando instalação de dependências"
    echo ""

    local base_pkgs=(
        nmap
        netcat-openbsd
        dnsutils
        curl
        wget
        openssl
        whois
        python3
        python3-pip
        bc
    )

    local optional_pkgs=(
        arp-scan
        smbclient
        hydra
        gobuster
        dirb
        nikto
        john
        tcpdump
        hping3
        iptables
    )

    local snmp_pkgs=(
        snmp
        snmp-mibs-downloader
    )

    local enum4linux_pkg=""
    if apt-cache show enum4linux &>/dev/null 2>&1; then
        enum4linux_pkg="enum4linux"
    fi

    echo -e "${CYAN}>>> Base packages${RESET}"
    log "Instalando pacotes base: ${base_pkgs[*]}"
    install_pkg "${base_pkgs[@]}"
    log "Pacotes base instalados"

    echo ""
    echo -e "${CYAN}>>> SNMP packages${RESET}"
    log "Instalando pacotes SNMP: ${snmp_pkgs[*]}"
    install_pkg "${snmp_pkgs[@]}" 2>/dev/null && log "Pacotes SNMP instalados" || log "AVISO: pacotes SNMP parcial"

    echo ""
    echo -e "${CYAN}>>> Optional packages${RESET}"
    for pkg in "${optional_pkgs[@]}"; do
        if command -v "$pkg" &>/dev/null; then
            echo -e "  ${GREEN}[OK]${RESET} $pkg já instalado"
        else
            echo -ne "  ${YELLOW}[*]${RESET} Instalando $pkg... "
            install_pkg "$pkg" 2>/dev/null && echo -e "${GREEN}OK${RESET}" || echo -e "${YELLOW}falhou (opcional)${RESET}"
        fi
    done

    if [ -n "$enum4linux_pkg" ]; then
        echo -ne "  ${YELLOW}[*]${RESET} Instalando enum4linux... "
        install_pkg "enum4linux" 2>/dev/null && echo -e "${GREEN}OK${RESET}" || echo -e "${YELLOW}falhou (opcional)${RESET}"
    fi

    echo ""
    echo -e "${CYAN}>>> Python packages${RESET}"
    pip3 install colorama 2>/dev/null && echo -e "  ${GREEN}[OK]${RESET} colorama" && log "colorama instalado" || echo -e "  ${YELLOW}[!] colorama falhou${RESET}"

    echo ""
    log "Processando SecLists"
    echo -e "${CYAN}>>> Downloading wordlists (SecLists)${RESET}"
    local seclists_dir="/usr/share/seclists"
    if [ ! -d "$seclists_dir" ]; then
        echo -e "  ${YELLOW}[*] Baixando SecLists (pode demorar)...${RESET}"
        sudo mkdir -p "$seclists_dir"
        curl -#L "https://github.com/danielmiessler/SecLists/archive/master.tar.gz" 2>/dev/null \
            | sudo tar xz -C "$seclists_dir" --strip=1 2>/dev/null && \
            echo -e "  ${GREEN}[OK]${RESET} SecLists baixado" && log "SecLists baixado" || \
            echo -e "  ${YELLOW}[!] Download do SecLists falhou (opcional)${RESET}"
    else
        echo -e "  ${GREEN}[OK]${RESET} SecLists já existe"
    fi

    log "Instalação concluída"
    echo ""
    echo -e "${GREEN}=================================================${RESET}"
    echo -e "${GREEN}  Instalação concluída!${RESET}"
    echo -e "${GREEN}=================================================${RESET}"
}

check_status() {
    echo ""
    echo -e "${YELLOW}[*] Verificando ferramentas instaladas...${RESET}"
    echo ""

    local tools=(
        "nmap:nmap"
        "nc:netcat-openbsd"
        "dig:dnsutils"
        "curl:curl"
        "wget:wget"
        "openssl:openssl"
        "whois:whois"
        "python3:python3"
        "pip3:python3-pip"
        "arp-scan:arp-scan"
        "smbclient:smbclient"
        "hydra:hydra"
        "gobuster:gobuster"
        "dirb:dirb"
        "nikto:nikto"
        "john:john"
        "tcpdump:tcpdump"
        "hping3:hping3"
        "snmpwalk:snmp"
        "snmpget:snmp"
        "iptables:iptables"
        "bc:bc"
    )

    local missing_count=0
    local found_count=0

    for entry in "${tools[@]}"; do
        local cmd="${entry%%:*}"
        local pkg="${entry#*:}"
        if command -v "$cmd" &>/dev/null; then
            echo -e "  ${GREEN}[OK]${RESET} $cmd ($pkg)"
            found_count=$((found_count + 1))
        else
            echo -e "  ${RED}[--]${RESET} $cmd ($pkg) - FALTANDO"
            missing_count=$((missing_count + 1))
        fi
    done

    log "Status: $found_count encontradas, $missing_count faltando"
    echo ""
    echo -e "${CYAN}Resumo: $found_count encontradas, $missing_count faltando${RESET}"
    echo ""

    return "$missing_count"
}

show_disclaimer() {
    echo -e "${RED}╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${RED}║${RESET}  ${BOLD}AVISO LEGAL - FERRAMENTA EDUCACIONAL${RESET}              ${RED}║${RESET}"
    echo -e "${RED}║${RESET}                                                    ${RED}║${RESET}"
    echo -e "${RED}║${RESET}  Esta ferramenta é exclusivamente para ${BOLD}FINS${RESET}          ${RED}║${RESET}"
    echo -e "${RED}║${RESET}  ${BOLD}EDUCACIONAIS${RESET} e ${BOLD}TESTES DE SEGURANÇA AUTORIZADOS${RESET}.   ${RED}║${RESET}"
    echo -e "${RED}║${RESET}                                                    ${RED}║${RESET}"
    echo -e "${RED}║${RESET}  ⚠  O uso não autorizado em redes, sistemas ou     ${RED}║${RESET}"
    echo -e "${RED}║${RESET}     dispositivos dos quais você não é proprietário  ${RED}║${RESET}"
    echo -e "${RED}║${RESET}     ou não tem permissão explícita por escrito      ${RED}║${RESET}"
    echo -e "${RED}║${RESET}     para testar é ${BOLD}ILEGAL${RESET} e antiético.              ${RED}║${RESET}"
    echo -e "${RED}║${RESET}                                                    ${RED}║${RESET}"
    echo -e "${RED}║${RESET}  🛡  Use apenas em:                                ${RED}║${RESET}"
    echo -e "${RED}║${RESET}     • Redes próprias                               ${RED}║${RESET}"
    echo -e "${RED}║${RESET}     • Laboratórios de estudo                       ${RED}║${RESET}"
    echo -e "${RED}║${RESET}     • Testes com autorização por escrito           ${RED}║${RESET}"
    echo -e "${RED}║${RESET}                                                    ${RED}║${RESET}"
    echo -e "${RED}║${RESET}  ${YELLOW}O autor não se responsabiliza por qualquer uso${RESET}       ${RED}║${RESET}"
    echo -e "${RED}║${RESET}  ${YELLOW}indevido ou danos causados por esta ferramenta.${RESET}      ${RED}║${RESET}"
    echo -e "${RED}╚══════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo -e "${YELLOW}  Pressione ENTER para confirmar e continuar...${RESET}"
    read -r
    clear
}

main() {
    show_banner
    show_disclaimer

    if [ "$EUID" -eq 0 ]; then
        echo -e "${YELLOW}[!] Executando como root. Verificando sudo...${RESET}"
    fi

    if ! command -v sudo &>/dev/null && [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[!] sudo não encontrado. Execute como root.${RESET}"
        exit 1
    fi

    detect_distro
    echo -e "${GREEN}[+] Distribuição detectada: $DISTRO${RESET}"
    log "Distribuição: $DISTRO"
    echo ""

    echo "  1) Instalar todas as ferramentas"
    echo "  2) Apenas verificar status das ferramentas"
    echo "  3) Sair"
    echo ""

    local install_started=false
    local status_run=false
    while true; do
        echo -n "Selecione (1-3): "
        read choice
        case "$choice" in
            1)
                log ">>> INÍCIO: Instalação completa"
                install_started=true
                install_all
                status_run=true
                check_status
                log ">>> FIM: Instalação completa"
                break
                ;;
            2)
                log ">>> INÍCIO: Verificação de status"
                status_run=true
                check_status
                log ">>> FIM: Verificação de status"
                break
                ;;
            3)
                log "Usuário optou por sair"
                echo -e "${YELLOW}[!] Saindo...${RESET}"
                exit 0
                ;;
            *) echo -e "${RED}Opção inválida${RESET}" ;;
        esac
    done

    if $install_started; then
        log "Pacotes base instalados"
        log "Pacotes opcionais processados"
    fi
    if $status_run; then
        log "Verificação de dependências concluída"
    fi
    log "=== FIM Install ==="
    echo ""
    echo -e "${CYAN}=================================================${RESET}"
    echo -e "${CYAN}  Use: bash network_audit.sh para iniciar${RESET}"
    echo -e "${CYAN}=================================================${RESET}"
    echo -e "${CYAN}  Log: $LOG_FILE${RESET}"
}

main
