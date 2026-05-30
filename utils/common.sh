#!/usr/bin/env bash

set -uo pipefail

STEP_NUM=0
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
CYAN="\e[36m"
BOLD="\e[1m"
RESET="\e[0m"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
AUDIT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)/audits"
mkdir -p "$AUDIT_DIR"

LOG_FILE="$AUDIT_DIR/$(basename "$SCRIPT_DIR")_$(date +%Y%m%d_%H%M%S).log"
RESUMO_FILE="$SCRIPT_DIR/resumo.txt"
TEMP_FILES=()
exec 2>>"$LOG_FILE"

cleanup_temp() {
    for f in "${TEMP_FILES[@]}"; do
        [ -f "$f" ] && rm -f "$f"
    done
}

save_resumo() {
    local content="$1"
    {
        echo "=================================================="
        echo "  $(basename "$SCRIPT_DIR") - Resumo da Auditoria"
        echo "  Data: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "=================================================="
        echo ""
        echo "$content"
        echo ""
        echo "---"
        echo "Log completo: $LOG_FILE"
    } > "$RESUMO_FILE"
    echo -e "${GREEN}[+] Resumo salvo em: $RESUMO_FILE${RESET}"
}

step() {
    STEP_NUM=$((STEP_NUM + 1))
    echo ""
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${CYAN}  PASSO $STEP_NUM: $*${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    log ">>> PASSO $STEP_NUM: $*"
}

log() {
    echo -e "${YELLOW}[LOG]${RESET} $*" >&1
    echo "[$(date '+%H:%M:%S')] $*" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERRO]${RESET} $*" >&1
    echo "[$(date '+%H:%M:%S')] ERRO: $*" >> "$LOG_FILE"
}

progress_bar() {
    local current=$1 total=$2 width=40
    local pct=$((current * 100 / total))
    local filled=$((pct * width / 100))
    [ "$filled" -gt "$width" ] && filled=$width
    local empty=$((width - filled))
    printf "\r${CYAN}  [${RESET}"
    for ((i=0; i<filled; i++)); do printf "="; done
    printf "${CYAN}"
    for ((i=0; i<empty; i++)); do printf " "; done
    printf "${RESET}${CYAN}] ${GREEN}%3d%%${RESET}" "$pct"
}

run_cmd_with_progress() {
    local max_sec=$1; shift
    local desc=$1; shift
    local tmpfile
    tmpfile=$(mktemp)
    TEMP_FILES+=("$tmpfile")

    echo -e "\n${YELLOW}[*] $desc${RESET}"

    "$@" > "$tmpfile" 2>/dev/null &
    local pid=$!
    local sec=0

    while kill -0 "$pid" 2>/dev/null; do
        progress_bar "$sec" "$max_sec"
        sec=$((sec + 1))
        [ $sec -ge "$max_sec" ] && break
        sleep 1
    done
    printf "\n"
    wait "$pid" 2>/dev/null || true

    cat "$tmpfile"
    rm -f "$tmpfile"
    # shellcheck disable=SC2034
    TEMP_FILES=("${TEMP_FILES[@]/$tmpfile}")
}

confirm_action() {
    local prompt="$1"
    echo ""
    echo -e "${YELLOW}[*] $prompt${RESET}"
    echo ""
    echo "  1) Sim"
    echo "  2) Não"
    echo ""

    while true; do
        echo -n "Selecione (1-2): "
        read choice
        case "$choice" in
            1) return 0 ;;
            2) return 1 ;;
            *) echo -e "${RED}Opção inválida${RESET}" ;;
        esac
    done
}

save_results_file() {
    local default_name="$1"; shift
    local content="$1"

    if confirm_action "Salvar resultados em arquivo?"; then
        local outfile="$AUDIT_DIR/${default_name}_$(date +%Y%m%d_%H%M%S).txt"
        echo "$content" > "$outfile"
        echo -e "${GREEN}[+] Resultados salvos em: $outfile${RESET}"
        log "Resultados exportados para $outfile"
        echo "$outfile"
    else
        echo -e "${YELLOW}[!] Pulando salvamento${RESET}"
        echo ""
    fi
}

read_input() {
    local var_name="$1"; shift
    local prompt="$1"; shift
    local default="${1:-}"

    while true; do
        if [ -n "$default" ]; then
            echo -n "$prompt [$default]: "
        else
            echo -n "$prompt: "
        fi
        read input
        if [ -n "$input" ]; then
            eval "$var_name=\$input"
            break
        elif [ -n "$default" ]; then
            eval "$var_name=\$default"
            break
        fi
        echo -e "${RED}O valor não pode ficar vazio${RESET}"
    done
}

select_from_list() {
    local prompt="$1"; shift
    local items=("$@")
    local i

    echo ""
    echo -e "${YELLOW}[*] $prompt${RESET}"
    echo ""
    for i in "${!items[@]}"; do
        echo "  $((i+1))) ${items[$i]}"
    done
    echo ""

    while true; do
        echo -n "Selecione (1-${#items[@]}): "
        read choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#items[@]}" ]; then
            echo "${items[$((choice-1))]}"
            return 0
        fi
        echo -e "${RED}Opção inválida${RESET}"
    done
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}[!] Execute como root: sudo $0${RESET}"
        log "ERRO: script executado sem root"
        exit 1
    fi
    log "Root OK"
}

check_deps() {
    local missing=()
    for dep in "$@"; do
        if ! command -v "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done
    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}[!] Dependências faltando: ${missing[*]}${RESET}"
        log "ERRO: dependencias faltando: ${missing[*]}"
        exit 1
    fi
    log "Dependencias OK"
}

parse_target_url() {
    local url="$1"
    local proto host port
    proto=$(echo "$url" | grep -oP '^https' || echo "http")
    host=$(echo "$url" | sed -E 's|^https?://||' | cut -d/ -f1 | cut -d: -f1)
    port=$(echo "$url" | sed -E 's|^https?://||' | cut -d: -f2 | cut -d/ -f1)
    [ -z "$port" ] && [ "$proto" = "https" ] && port=443
    [ -z "$port" ] && [ "$proto" = "http" ] && port=80
    echo "$proto|$host|$port"
}

load_previous_target() {
    local audit_name="$1"
    local pattern="$2"
    local prev
    prev=$(ls -t "$AUDIT_DIR"/${audit_name}_*.txt 2>/dev/null | head -1)
    if [ -n "$prev" ] && grep -q "$pattern" "$prev" 2>/dev/null; then
        echo "$prev"
    fi
}

DISCLAIMER_ACKNOWLEDGED=false

show_disclaimer() {
    $DISCLAIMER_ACKNOWLEDGED && return
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

show_banner() {
    clear
    local title="${1:-Network Auditor}"
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${CYAN}  $title${RESET}"
    echo -e "${CYAN}  $(basename "$SCRIPT_DIR")${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    echo ""
}

parse_cli_args() {
    local -n _target_var=$1; shift
    local -n _port_var=$1; shift

    while [ $# -gt 0 ]; do
        case "$1" in
            -t|--target)
                _target_var="$2"; shift 2 ;;
            -p|--port)
                _port_var="$2"; shift 2 ;;
            -h|--help)
                echo "Uso: $0 [-t TARGET] [-p PORT]"
                echo "  -t, --target   IP, hostname ou URL alvo"
                echo "  -p, --port     Porta (opcional, default varia por módulo)"
                exit 0 ;;
            *)
                if [ -z "$_target_var" ]; then
                    _target_var="$1"
                fi
                shift ;;
        esac
    done
}
