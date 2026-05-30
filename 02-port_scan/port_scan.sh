#!/usr/bin/env bash

set -uo pipefail

source "$(dirname "$0")/../utils/common.sh"

# =============================================================================
#  Port Scanner - Network Port Scanning Tool
#  Interactive script for scanning open ports on target hosts
# =============================================================================
#  LEGAL DISCLAIMER:
#  This script is for educational purposes and authorized security testing only.
#  Unauthorized use against networks you do not own or have explicit permission
#  to test is illegal. The author is not responsible for any misuse.
# =============================================================================

TARGET=""
SCAN_TYPE=""
SCAN_TECHNIQUE=""
OPEN_PORTS=()
RESULTS_FILE=""

cleanup() {
    echo -e "\n${YELLOW}[!] Limpando...${RESET}"
    cleanup_temp
    log "Cleanup performed"
}
trap cleanup EXIT

enter_target() {
    local prev
    prev=$(ls -t "$AUDIT_DIR"/host_discovery_*.txt 2>/dev/null | head -1)
    if [ -n "$prev" ]; then
        echo -e "${CYAN}  Descoberta anterior encontrada: $(basename "$prev")${RESET}"
        if confirm_action "Carregar alvo da descoberta anterior?"; then
            local ips
            ips=$(grep -oP '^\d+\.\d+\.\d+\.\d+' "$prev" | head -10)
            local ip_list=()
            while IFS= read -r ip; do
                [ -n "$ip" ] && ip_list+=("$ip")
            done <<< "$ips"
            if [ ${#ip_list[@]} -gt 0 ]; then
                ip_list+=("Digitar manualmente")
                local choice
                choice=$(select_from_list "Selecione o host" "${ip_list[@]}")
                if [ "$choice" != "Digitar manualmente" ]; then
                    TARGET="$choice"
                fi
            fi
        fi
    fi

    if [ -z "$TARGET" ]; then
        read_input TARGET "IP/hostname alvo"
    fi

    echo -e "${GREEN}[+] Alvo: $TARGET${RESET}"
}

select_scan_type() {
    local types=(
        "Varredura rápida (top 100 portas)"
        "Varredura padrão (top 1000 portas)"
        "Varredura completa (portas 1-65535)"
        "Intervalo de portas personalizado"
    )
    local choice
    choice=$(select_from_list "Selecione o tipo de varredura" "${types[@]}")
    case "${choice:0:1}" in
        1) SCAN_TYPE="quick" ;;
        2) SCAN_TYPE="standard" ;;
        3) SCAN_TYPE="full" ;;
        4)
            SCAN_TYPE="custom"
            read_input CUSTOM_PORTS "Intervalo de portas (ex.: 1-1024 ou 80,443,8080)"
            ;;
    esac
    echo -e "${GREEN}[+] Tipo de varredura: $SCAN_TYPE${RESET}"
}

select_scan_technique() {
    local types=(
        "TCP Connect (-sT) - Handshake completo, sem root"
        "SYN Stealth (-sS) - Meia abertura, rápida, precisa de root"
        "UDP Scan (-sU) - Portas UDP, mais lenta"
    )
    local choice
    choice=$(select_from_list "Selecione a técnica de varredura" "${types[@]}")
    case "${choice:0:1}" in
        1) SCAN_TECHNIQUE="-sT" ;;
        2) SCAN_TECHNIQUE="-sS" ;;
        3) SCAN_TECHNIQUE="-sU" ;;
    esac
    echo -e "${GREEN}[+] Técnica: $SCAN_TECHNIQUE${RESET}"
}

run_scan() {
    echo -e "\n${YELLOW}[*] Executando varredura nmap...${RESET}"

    local ports=""
    local max_progress=0
    case "$SCAN_TYPE" in
        quick) ports="--top-ports 100"; max_progress=40 ;;
        standard) ports="--top-ports 1000"; max_progress=120 ;;
        full) ports="-p-"; max_progress=600 ;;
        custom) ports="-p $CUSTOM_PORTS"; max_progress=120 ;;
    esac

    local extra=""
    if [ "$SCAN_TECHNIQUE" = "-sS" ] || [ "$SCAN_TECHNIQUE" = "-sT" ]; then
        extra="--reason"
    fi

    local tmpfile
    tmpfile=$(mktemp)
    TEMP_FILES+=("$tmpfile")

    nmap $SCAN_TECHNIQUE $ports $extra -T4 -oG "$tmpfile" "$TARGET" 2>/dev/null &
    local pid=$!

    local sec=0
    while kill -0 "$pid" 2>/dev/null; do
        progress_bar "$sec" "$max_progress"
        sec=$((sec + 1))
        [ $sec -ge "$max_progress" ] && break
        sleep 1
    done
    printf "\n"
    wait "$pid" 2>/dev/null || true

    OPEN_PORTS=()
    while IFS= read -r line; do
        if echo "$line" | grep -q "Ports:"; then
            local port_data
            port_data=$(echo "$line" | grep -oP 'Ports: \K.*' || true)
            [ -z "$port_data" ] && continue
            IFS=',' read -ra entries <<< "$port_data"
            for entry in "${entries[@]}"; do
                entry=$(echo "$entry" | xargs)
                local port=$(echo "$entry" | cut -d/ -f1)
                local state=$(echo "$entry" | cut -d/ -f2)
                local service=$(echo "$entry" | cut -d/ -f5)
                [ "$state" != "open" ] && continue
                OPEN_PORTS+=("$port|$state|$service")
            done
        fi
    done < "$tmpfile"
}

display_ports() {
    echo ""
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${CYAN}  Portas Abertas em $TARGET${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    echo ""

    if [ ${#OPEN_PORTS[@]} -eq 0 ]; then
        echo -e "${YELLOW}[!] Nenhuma porta aberta encontrada.${RESET}"
        return
    fi

    printf "${BOLD}%-6s %-15s %-20s${RESET}\n" "PORTA" "ESTADO" "SERVIÇO"
    echo "--------------------------------------------"
    for entry in "${OPEN_PORTS[@]}"; do
        local port="${entry%%|*}"
        local rest="${entry#*|}"
        local state="${rest%%|*}"
        local service="${rest#*|}"
        printf "%-6s %-15s %-20s\n" "$port" "$state" "$service"
    done
}

run_version_detection() {
    if ! confirm_action "Executar detecção de versão nas portas descobertas?"; then
        echo -e "${YELLOW}[!] Pulando detecção de versão${RESET}"
        return
    fi

    local ports=""
    local port_list=()
    for entry in "${OPEN_PORTS[@]}"; do
        port_list+=("${entry%%|*}")
    done
    ports=$(IFS=,; echo "${port_list[*]}")

    if [ -z "$ports" ]; then
        echo -e "${YELLOW}[!] Nenhuma porta para escanear${RESET}"
        return
    fi

    echo -e "\n${GREEN}[+] Executando detecção de versão nas portas: $ports${RESET}"
    run_cmd_with_progress 60 "nmap -sV (detecção de versão)" \
        nmap -sV -p "$ports" -T4 "$TARGET" -oN - 2>/dev/null
}

save_results() {
    local content
    content="=== Resultados da Varredura de Portas ===
Data: $(date)
Alvo: $TARGET
Tipo de varredura: $SCAN_TYPE
Técnica: $SCAN_TECHNIQUE

Portas abertas: ${#OPEN_PORTS[@]}
------------------------------
$(for entry in "${OPEN_PORTS[@]}"; do
    local port="${entry%%|*}"
    local rest="${entry#*|}"
    local state="${rest%%|*}"
    local service="${rest#*|}"
    echo "$port ($service) - $state"
done)"

    local outfile
    outfile=$(save_results_file "port_scan" "$content")
    [ -n "$outfile" ] && RESULTS_FILE="$outfile"
}

parse_cli_args TARGET _unused_port "$@"

main() {
    log "=== START Port Scan ==="
    show_banner "Scanner de Portas"
    show_disclaimer
    check_deps "nmap"

    step "Digite o alvo"
    enter_target

    step "Selecione o tipo de varredura"
    select_scan_type

    step "Selecione a técnica de varredura"
    select_scan_technique

    step "Executando varredura"
    run_scan
    log "Varredura concluída, encontradas ${#OPEN_PORTS[@]} portas abertas"

    step "Exibir resultados"
    display_ports

    if [ ${#OPEN_PORTS[@]} -gt 0 ]; then
        step "Detecção de versão"
        run_version_detection
    fi

    step "Salvar resultados"
    save_results

    echo ""
    log "=== END Port Scan ==="
    save_resumo "Alvo: $TARGET
Tipo de scan: $SCAN_TYPE
Técnica: $SCAN_TECHNIQUE
Portas abertas: ${#OPEN_PORTS[@]}
$(for e in "${OPEN_PORTS[@]}"; do echo "  $e"; done)
Arquivo de resultados: ${RESULTS_FILE:-N/A}"
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${GREEN}  Varredura de portas concluída!${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    if [ -n "$RESULTS_FILE" ]; then
        echo -e "  Resultados: $RESULTS_FILE"
    fi
    echo -e "${CYAN}================================================${RESET}"
}

main
