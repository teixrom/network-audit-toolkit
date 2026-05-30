#!/usr/bin/env bash

set -uo pipefail

source "$(dirname "$0")/../utils/common.sh"

# =============================================================================
#  Host Discovery - Network Host Detection Tool
# =============================================================================

RESULTS_FILE=""
INTERFACE=""
TARGET_NETWORK=""
SCAN_TYPE=""
DISCOVERED_HOSTS=()

cleanup() {
    echo -e "\n${YELLOW}[!] Limpando...${RESET}"
    cleanup_temp
    log "Cleanup performed"
}
trap cleanup EXIT

list_ifaces() {
    ip -o link show | awk -F': ' '!/lo|^[0-9]+: lo/{print $2}'
}

select_interface() {
    local ifaces=()
    while IFS= read -r line; do
        ifaces+=("$line")
    done < <(list_ifaces)

    if [ ${#ifaces[@]} -eq 0 ]; then
        echo -e "${RED}[!] Nenhuma interface de rede encontrada${RESET}"
        exit 1
    fi

    INTERFACE=$(select_from_list "Selecione a interface de rede" "${ifaces[@]}")
    echo -e "${GREEN}[+] Interface selecionada: $INTERFACE${RESET}"
}

select_scan_type() {
    local types=(
        "Varredura ARP (rede local) - Rápida, endereços MAC"
        "Varredura ICMP - Ping sweep tradicional"
        "TCP SYN Ping - Ignora firewalls (porta 80/443)"
    )
    local choice
    choice=$(select_from_list "Selecione o tipo de varredura" "${types[@]}")
    case "${choice:0:1}" in
        1) SCAN_TYPE="arp" ;;
        2) SCAN_TYPE="icmp" ;;
        3) SCAN_TYPE="tcp" ;;
    esac
    echo -e "${GREEN}[+] Tipo de varredura: $SCAN_TYPE${RESET}"
}

enter_target_network() {
    read_input TARGET_NETWORK "Rede alvo" ""
    echo -e "${GREEN}[+] Alvo: $TARGET_NETWORK${RESET}"
}

run_arp_scan() {
    echo -e "\n${YELLOW}[*] Executando varredura ARP em $TARGET_NETWORK...${RESET}"

    local tmpfile
    tmpfile=$(mktemp)
    TEMP_FILES+=("$tmpfile")

    if command -v arp-scan &>/dev/null; then
        echo -e "${GREEN}[+] Usando arp-scan (mais rápido)${RESET}"
        arp-scan --interface="$INTERFACE" "$TARGET_NETWORK" 2>/dev/null > "$tmpfile" &
    else
        echo -e "${YELLOW}[!] arp-scan não encontrado, usando descoberta ARP do nmap${RESET}"
        nmap -sn -PR --send-eth -e "$INTERFACE" "$TARGET_NETWORK" -oG "$tmpfile" 2>/dev/null &
    fi
    local pid=$!

    local sec=0
    while kill -0 "$pid" 2>/dev/null; do
        progress_bar "$sec" 60
        sec=$((sec + 1))
        [ $sec -ge 60 ] && break
        sleep 1
    done
    printf "\n"
    wait "$pid" 2>/dev/null || true

    DISCOVERED_HOSTS=()
    if command -v arp-scan &>/dev/null; then
        while IFS= read -r line; do
            local ip mac vendor
            ip=$(echo "$line" | awk '{print $1}')
            mac=$(echo "$line" | awk '{print $2}')
            vendor=$(echo "$line" | awk '{for(i=3;i<=NF;i++) printf "%s ",$i; print ""}' | xargs)
            [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || continue
            DISCOVERED_HOSTS+=("$ip|$mac|$vendor")
        done < "$tmpfile"
    else
        while IFS= read -r line; do
            if echo "$line" | grep -q "Host:"; then
                local ip
                ip=$(echo "$line" | grep -oP '(?<=Host: )\S+')
                local mac=""
                local vendor=""
                if echo "$line" | grep -q "MAC:"; then
                    mac=$(echo "$line" | grep -oP '(?<=MAC: )\S+')
                    vendor=$(echo "$line" | grep -oP '(?<=MAC: )\S+ \K.*')
                fi
                [ -n "$ip" ] && DISCOVERED_HOSTS+=("$ip|$mac|$vendor")
            fi
        done < "$tmpfile"
    fi
}

run_icmp_sweep() {
    echo -e "\n${YELLOW}[*] Executando varredura ICMP em $TARGET_NETWORK...${RESET}"

    local cidr=""
    if echo "$TARGET_NETWORK" | grep -q "/"; then
        cidr=$(echo "$TARGET_NETWORK" | cut -d/ -f2)
    fi

    if [ -n "$cidr" ] && [ "$cidr" -le 24 ]; then
        run_cmd_with_progress 120 "Varrendo com nmap -sn (ICMP)" \
            nmap -sn -PE -PP -PM --send-eth -e "$INTERFACE" "$TARGET_NETWORK" -oG - 2>/dev/null

        local tmpfile
        tmpfile=$(mktemp)
        TEMP_FILES+=("$tmpfile")
        nmap -sn -PE -PP -PM --send-eth -e "$INTERFACE" "$TARGET_NETWORK" -oG "$tmpfile" 2>/dev/null

        while IFS= read -r line; do
            if echo "$line" | grep -q "Host:"; then
                local ip
                ip=$(echo "$line" | grep -oP '(?<=Host: )\S+')
                [ -n "$ip" ] && DISCOVERED_HOSTS+=("$ip||")
            fi
        done < "$tmpfile"
    else
        local network base start end
        if echo "$TARGET_NETWORK" | grep -q "/"; then
            network=$(echo "$TARGET_NETWORK" | cut -d/ -f1)
            base=$(echo "$network" | rev | cut -d. -f2- | rev)
            start=$(echo "$network" | cut -d. -f4)
            end=255
        elif echo "$TARGET_NETWORK" | grep -q "-"; then
            base=$(echo "$TARGET_NETWORK" | cut -d. -f1-3)
            start=$(echo "$TARGET_NETWORK" | grep -oP '\d+$' | head -1)
            end=$(echo "$TARGET_NETWORK" | grep -oP '\d+$' | tail -1)
        else
            echo -e "${RED}[!] Formato de rede não reconhecido: $TARGET_NETWORK${RESET}"
            return
        fi

        if command -v fping &>/dev/null; then
            echo -e "${GREEN}[+] Usando fping para varredura rápida${RESET}"
            local targets=()
            for i in $(seq "$start" "$end"); do
                targets+=("${base}.${i}")
            done
            local tmpfile
            tmpfile=$(mktemp)
            TEMP_FILES+=("$tmpfile")
            fping -c 1 -t 100 -a "${targets[@]}" 2>/dev/null > "$tmpfile"
            while IFS= read -r ip; do
                [ -n "$ip" ] && DISCOVERED_HOSTS+=("$ip||")
            done < "$tmpfile"
        else
            echo -e "${GREEN}[+] Usando ping sequencial (instale fping para mais rapidez)${RESET}"
            local total=$((end - start + 1))
            local cur=0
            for i in $(seq "$start" "$end"); do
                local ip="${base}.${i}"
                if ping -c 1 -W 1 "$ip" &>/dev/null; then
                    DISCOVERED_HOSTS+=("$ip||")
                fi
                cur=$((cur + 1))
                progress_bar "$cur" "$total"
            done
            printf "\n"
        fi
    fi
}

run_tcp_syn_ping() {
    echo -e "\n${YELLOW}[*] Executando ping TCP SYN em $TARGET_NETWORK...${RESET}"

    local tmpfile
    tmpfile=$(mktemp)
    TEMP_FILES+=("$tmpfile")

    run_cmd_with_progress 120 "Escaneando com nmap -sn -PS" \
        nmap -sn -PS80,443,22 --send-eth -e "$INTERFACE" "$TARGET_NETWORK" -oG "$tmpfile" 2>/dev/null

    while IFS= read -r line; do
        if echo "$line" | grep -q "Host:"; then
            local ip
            ip=$(echo "$line" | grep -oP '(?<=Host: )\S+')
            [ -n "$ip" ] && DISCOVERED_HOSTS+=("$ip||")
        fi
    done < "$tmpfile"
}

display_hosts() {
    echo ""
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${CYAN}  Hosts Descobertos (${#DISCOVERED_HOSTS[@]})${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    echo ""

    if [ ${#DISCOVERED_HOSTS[@]} -eq 0 ]; then
        echo -e "${YELLOW}[!] Nenhum host descoberto.${RESET}"
        return
    fi

    printf "${BOLD}%-4s %-18s %-20s %-30s${RESET}\n" "#" "Endereço IP" "Endereço MAC" "Fabricante"
    echo "------------------------------------------------------------------------------"
    for i in "${!DISCOVERED_HOSTS[@]}"; do
        local ip="${DISCOVERED_HOSTS[$i]%%|*}"
        local rest="${DISCOVERED_HOSTS[$i]#*|}"
        local mac="${rest%%|*}"
        local vendor="${rest#*|}"
        printf "%-4d %-18s %-20s %-30s\n" $((i+1)) "$ip" "$mac" "$vendor"
    done
}

scan_specific_host() {
    echo ""
    echo -e "${YELLOW}[*] Selecione um host para varredura detalhada${RESET}"

    local ips=()
    for i in "${!DISCOVERED_HOSTS[@]}"; do
        ips+=("${DISCOVERED_HOSTS[$i]%%|*}")
    done
    ips+=("Pular")

    local choice
    choice=$(select_from_list "Selecione o host (ou Pular)" "${ips[@]}")
    [ "$choice" = "Pular" ] && return

    echo -e "\n${GREEN}[+] Escaneando $choice...${RESET}"
    echo -e "\n${CYAN}--- Varredura rápida de portas (top 100 portas) ---${RESET}"
    nmap --top-ports 100 -T4 "$choice" 2>/dev/null
    echo -e "\n${GREEN}[+] Varredura detalhada concluída para $choice${RESET}"
}

export_results() {
    local content
    content="=== Resultados da Descoberta de Hosts ===
Data: $(date)
Interface: $INTERFACE
Tipo de varredura: $SCAN_TYPE
Alvo: $TARGET_NETWORK

Hosts descobertos: ${#DISCOVERED_HOSTS[@]}
------------------------------
$(for host in "${DISCOVERED_HOSTS[@]}"; do echo "$host"; done)"

    local outfile
    outfile=$(save_results_file "host_discovery" "$content")
    [ -n "$outfile" ] && RESULTS_FILE="$outfile"
}

parse_cli_args TARGET_NETWORK _unused_port "$@"

main() {
    log "=== START Host Discovery ==="
    show_banner "Descoberta de Hosts"
    show_disclaimer
    check_root
    check_deps "nmap"

    step "Selecione a interface de rede"
    select_interface

    step "Selecione o tipo de varredura"
    select_scan_type

    step "Digite a rede alvo"
    enter_target_network

    step "Executando varredura"
    case "$SCAN_TYPE" in
        arp) run_arp_scan ;;
        icmp) run_icmp_sweep ;;
        tcp) run_tcp_syn_ping ;;
    esac
    log "Scan completed, discovered ${#DISCOVERED_HOSTS[@]} hosts"

    step "Exibir resultados"
    display_hosts

    step "Exportar resultados"
    export_results

    if [ ${#DISCOVERED_HOSTS[@]} -gt 0 ]; then
        step "Varredura detalhada de host"
        scan_specific_host
    fi

    echo ""
    log "=== END Host Discovery ==="
    save_resumo "Alvo: $TARGET_NETWORK
Tipo de scan: $SCAN_TYPE
Interface: $INTERFACE
Hosts descobertos: ${#DISCOVERED_HOSTS[@]}
$(for h in "${DISCOVERED_HOSTS[@]}"; do echo "  $h"; done)
Arquivo de resultados: ${RESULTS_FILE:-N/A}"
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${GREEN}  Descoberta de hosts concluída!${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    if [ -n "$RESULTS_FILE" ]; then
        echo -e "  Resultados: $RESULTS_FILE"
    fi
    echo -e "${CYAN}================================================${RESET}"
}

main
