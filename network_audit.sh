#!/usr/bin/env bash

set -uo pipefail

GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

DISCLAIMER_ACKNOWLEDGED=false
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AUDIT_DIR="$SCRIPT_DIR/audits"
mkdir -p "$AUDIT_DIR"

LOG_FILE="$AUDIT_DIR/menu_$(date +%Y%m%d_%H%M%S).log"
exec 2>>"$LOG_FILE"

log() {
    echo "[$(date '+%H:%M:%S')] $*" >> "$LOG_FILE"
}

show_disclaimer() {
    $DISCLAIMER_ACKNOWLEDGED && return
    clear
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
    echo -e "${YELLOW}  Ao continuar, você confirma que leu e entendeu este aviso.${RESET}"
    echo ""
    echo -n -e "${CYAN}  Pressione ENTER para confirmar e continuar...${RESET}"
    read -r
    DISCLAIMER_ACKNOWLEDGED=true
    clear
}

MODULES=(
    "01-host_discovery:Descoberta de hosts ativos na rede"
    "02-port_scan:Varredura de portas abertas"
    "03-service_enum:Enumeração de serviços e banners"
    "04-web_audit:Auditoria de servidores web"
    "05-dns_audit:Auditoria de DNS"
    "06-smb_audit:Auditoria de SMB/NetBIOS"
    "07-snmp_audit:Auditoria de SNMP"
    "08-password_audit:Teste de senhas/força bruta"
    "09-ssl_audit:Auditoria de SSL/TLS"
    "10-vulnerability_scan:Varredura de vulnerabilidades"
    "11-firewall_audit:Auditoria de firewall"
    "12-log_audit:Análise de logs"
    "13-config_audit:Auditoria de configuração de ativos"
    "14-traffic_analysis:Análise de tráfego em tempo real"
    "15-wifi_audit:Auditoria de segurança Wi-Fi"
    "16-vuln_assessment:Avaliação de vulnerabilidades (CVE)"
    "17-identity_audit:Auditoria de identidade e políticas"
)

EXECUTED_MODULES=()

cleanup() {
    local total=${#EXECUTED_MODULES[@]}
    log "=== FIM Menu Principal ==="
    log "Módulos executados: $total"
    for m in "${EXECUTED_MODULES[@]}"; do
        log "  - $m"
    done
    echo -e "\n${YELLOW}[!] Saindo...${RESET}"
    echo -e "${CYAN}  Log: $LOG_FILE${RESET}"
    exit 0
}
trap cleanup SIGINT SIGTERM

show_banner() {
    clear
    echo -e "${CYAN}=================================================${RESET}"
    echo -e "${CYAN}       NETWORK AUDIT TOOLKIT${RESET}"
    echo -e "${CYAN}    Suíte de Auditoria de Redes${RESET}"
    echo -e "${CYAN}=================================================${RESET}"
    echo ""
}

show_menu() {
    echo -e "${YELLOW}Selecione um módulo para executar:${RESET}"
    echo ""
    for i in "${!MODULES[@]}"; do
        local num=$((i + 1))
        local dir="${MODULES[$i]%%:*}"
        local desc="${MODULES[$i]#*:}"
        printf "  ${BOLD}%2d)${RESET} %-25s - %s\n" "$num" "$dir" "$desc"
    done
    echo ""
    echo "  ${BOLD} Q)${RESET} Sair"
    echo ""
}

run_module() {
    local module_dir="$1"
    local module_name="$2"
    local script_path="$SCRIPT_DIR/$module_dir"

    if [ ! -d "$script_path" ]; then
        echo -e "${RED}[!] Diretório não encontrado: $script_path${RESET}"
        log "ERRO: diretório $module_dir não encontrado"
        return
    fi

    local script_file=""
    for f in "$script_path"/*.sh; do
        if [ -f "$f" ] && [ "$(basename "$f")" != "resumo.txt" ]; then
            script_file="$f"
            break
        fi
    done

    if [ -z "$script_file" ]; then
        echo -e "${RED}[!] Nenhum script encontrado em $module_dir${RESET}"
        log "ERRO: nenhum script em $module_dir"
        return
    fi

    echo ""
    echo -e "${CYAN}=================================================${RESET}"
    echo -e "${CYAN}  Executando: $module_name${RESET}"
    echo -e "${CYAN}  Script: $(basename "$script_file")${RESET}"
    echo -e "${CYAN}=================================================${RESET}"
    echo ""

    log ">>> INÍCIO: $module_name ($(basename "$script_file"))"
    bash "$script_file"
    local exit_code=$?
    log ">>> FIM: $module_name (código: $exit_code)"
    EXECUTED_MODULES+=("$module_name")

    echo ""
    echo -e "${GREEN}[+] Módulo finalizado (código: $exit_code). Pressione ENTER para voltar ao menu...${RESET}"
    read -r
}

main() {
    log "=== INÍCIO Menu Principal ==="
    show_disclaimer
    while true; do
        show_banner
        show_menu

        echo -n "Escolha uma opção: "
        read choice

        if [[ "$choice" =~ ^[Qq]$ ]]; then
            log "Usuário optou por sair"
            cleanup
            exit 0
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#MODULES[@]}" ]; then
            local idx=$((choice - 1))
            local dir="${MODULES[$idx]%%:*}"
            local desc="${MODULES[$idx]#*:}"
            run_module "$dir" "$desc"
        else
            echo -e "${RED}[!] Opção inválida. Pressione ENTER para continuar...${RESET}"
            read -r
        fi
    done
}

main
