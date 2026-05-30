#!/usr/bin/env bash

set -uo pipefail

source "$(dirname "$0")/../utils/common.sh"

# =============================================================================
#  Traffic Analyzer - Real-time Network Traffic Capture & Analysis Tool
#  Captures and analyzes network traffic using tcpdump
# =============================================================================
#  LEGAL DISCLAIMER:
#  This script is for educational purposes and authorized security testing only.
#  Unauthorized use against networks you do not own or have explicit permission
#  to test is illegal. The author is not responsible for any misuse.
# =============================================================================

INTERFACE=""
DURATION=30
CAPTURE_FILE=""
REPORT_FILE=""
TEMP_DIR=""

cleanup() {
    echo -e "\n${YELLOW}[!] Limpando...${RESET}"
    [ -n "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
    cleanup_temp
    log "Limpeza realizada"
}
trap cleanup EXIT

list_interfaces() {
    step "Listar interfaces de rede disponíveis"
    echo ""
    echo -e "${YELLOW}[*] Interfaces de rede disponíveis:${RESET}"
    echo ""

    local interfaces
    interfaces=$(ip -o link show | awk -F': ' '{print $2}' | sed 's/@.*//')
    local i=1
    local iface_list=()

    while IFS= read -r iface; do
        local state
        state=$(ip -o link show "$iface" | awk '{print $9}')
        local ip_addr
        ip_addr=$(ip -o -4 addr show "$iface" 2>/dev/null | awk '{print $4}' | head -1)
        ip_addr="${ip_addr:-N/A}"
        echo -e "  $i) $iface  [${state}]  IP: $ip_addr"
        iface_list+=("$iface")
        i=$((i + 1))
    done <<< "$interfaces"

    echo ""

    while true; do
        echo -n "Selecione a interface (1-$((i - 1))): "
        read choice
        if [ "$choice" -ge 1 ] && [ "$choice" -le "$((i - 1))" ] 2>/dev/null; then
            INTERFACE="${iface_list[$((choice - 1))]}"
            echo -e "${GREEN}[+] Interface selecionada: $INTERFACE${RESET}"
            log "Interface selecionada: $INTERFACE"
            break
        fi
        echo -e "${RED}Opção inválida${RESET}"
    done
}

select_duration() {
    echo ""
    echo -e "${YELLOW}[*] Duração da captura (10-120 segundos, padrão 30):${RESET}"
    echo ""
    echo -n "Duração em segundos [30]: "
    read input
    if [ -n "$input" ]; then
        if [ "$input" -ge 10 ] && [ "$input" -le 120 ] 2>/dev/null; then
            DURATION=$input
        else
            echo -e "${RED}Valor inválido. Usando padrão: 30 segundos${RESET}"
            DURATION=30
        fi
    fi
    echo -e "${GREEN}[+] Duração da captura: $DURATION segundos${RESET}"
    log "Duracao da captura: $DURATION segundos"
}

capture_traffic() {
    step "Capturar tráfego de rede"
    echo ""
    echo -e "${YELLOW}[*] Iniciando captura em $INTERFACE por $DURATION segundos...${RESET}"
    echo ""

    TEMP_DIR=$(mktemp -d)
    CAPTURE_FILE="$TEMP_DIR/capture.pcap"

    tcpdump -i "$INTERFACE" -w "$CAPTURE_FILE" -c 10000 2>/dev/null &
    local TCPDUMP_PID=$!

    local elapsed=0
    while [ "$elapsed" -lt "$DURATION" ]; do
        if ! kill -0 "$TCPDUMP_PID" 2>/dev/null; then
            break
        fi
        sleep 1
        elapsed=$((elapsed + 1))
        progress_bar "$elapsed" "$DURATION"
    done
    echo ""

    kill "$TCPDUMP_PID" 2>/dev/null
    wait "$TCPDUMP_PID" 2>/dev/null

    if [ ! -f "$CAPTURE_FILE" ] || [ ! -s "$CAPTURE_FILE" ]; then
        echo -e "${RED}[!] Nenhum pacote capturado${RESET}"
        log_error "Nenhum pacote capturado"
        exit 1
    fi

    local pkt_count
    pkt_count=$(tcpdump -r "$CAPTURE_FILE" 2>/dev/null | wc -l)
    echo -e "${GREEN}[+] Captura concluída: $pkt_count pacotes capturados${RESET}"
    log "Captura concluida: $pkt_count pacotes"
}

analyze_traffic() {
    step "Analisar tráfego capturado"
    echo ""
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${CYAN}  Análise de Tráfego${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    echo ""

    local pkt_count
    pkt_count=$(tcpdump -r "$CAPTURE_FILE" 2>/dev/null | wc -l)
    echo -e "  ${BOLD}Total de pacotes:${RESET} $pkt_count"
    echo ""

    echo -e "${CYAN}--- Top 10 IPs Origem ---${RESET}"
    echo ""
    local top_ips
    top_ips=$(tcpdump -r "$CAPTURE_FILE" -nn 2>/dev/null | grep -oP 'IP\s+\K(\d+\.\d+\.\d+\.\d+)' | sort | uniq -c | sort -rn | head -10)
    if [ -n "$top_ips" ]; then
        printf "  ${BOLD}%-10s %s${RESET}\n" "Pacotes" "Endereço IP"
        echo "  ------------------------"
        while IFS= read -r line; do
            local cnt ip
            cnt=$(echo "$line" | awk '{print $1}')
            ip=$(echo "$line" | awk '{print $2}')
            if [ "$cnt" -gt 100 ]; then
                printf "  ${RED}%-10s %s${RESET}\n" "$cnt" "$ip"
            elif [ "$cnt" -gt 50 ]; then
                printf "  ${YELLOW}%-10s %s${RESET}\n" "$cnt" "$ip"
            else
                printf "  %-10s %s\n" "$cnt" "$ip"
            fi
        done <<< "$top_ips"
    else
        echo -e "  ${YELLOW}Não foi possível extrair IPs de origem${RESET}"
    fi
    echo ""

    echo -e "${CYAN}--- Tráfego Broadcast/Multicast ---${RESET}"
    echo ""
    local broadcast_count
    broadcast_count=$(tcpdump -r "$CAPTURE_FILE" -nn 2>/dev/null | grep -c "broadcast\|255\.255\.255\.255\|224\.\|239\." || true)
    local multicast_count
    multicast_count=$(tcpdump -r "$CAPTURE_FILE" -nn 2>/dev/null | grep -c "224\.\|239\." || true)
    echo -e "  Pacotes broadcast:  $broadcast_count"
    echo -e "  Pacotes multicast:  $multicast_count"
    local bm_warning=false
    if [ "$broadcast_count" -gt 50 ]; then
        echo -e "  ${YELLOW}[!] Alto volume de broadcast detectado (possível storm)${RESET}"
        bm_warning=true
    fi
    if [ "$multicast_count" -gt 100 ]; then
        echo -e "  ${YELLOW}[!] Alto volume de multicast detectado${RESET}"
        bm_warning=true
    fi
    echo ""

    echo -e "${CYAN}--- Distribuição de Protocolos ---${RESET}"
    echo ""
    local tcp_count udp_count icmp_count other_count
    tcp_count=$(tcpdump -r "$CAPTURE_FILE" 2>/dev/null | grep -ci "TCP" || true)
    udp_count=$(tcpdump -r "$CAPTURE_FILE" 2>/dev/null | grep -ci "UDP" || true)
    icmp_count=$(tcpdump -r "$CAPTURE_FILE" 2>/dev/null | grep -ci "ICMP" || true)
    other_count=$((pkt_count - tcp_count - udp_count - icmp_count))
    [ "$other_count" -lt 0 ] && other_count=0

    echo -e "  TCP:  $tcp_count ($(awk "BEGIN{printf \"%.1f%%\", ($tcp_count/$pkt_count)*100}"))"
    echo -e "  UDP:  $udp_count ($(awk "BEGIN{printf \"%.1f%%\", ($udp_count/$pkt_count)*100}"))"
    echo -e "  ICMP: $icmp_count ($(awk "BEGIN{printf \"%.1f%%\", ($icmp_count/$pkt_count)*100}"))"
    echo -e "  Outros: $other_count ($(awk "BEGIN{printf \"%.1f%%\", ($other_count/$pkt_count)*100}"))"
    echo ""

    echo -e "${CYAN}--- Portas TCP/UDP Mais Frequentes ---${RESET}"
    echo ""
    local top_ports
    top_ports=$(tcpdump -r "$CAPTURE_FILE" -nn 2>/dev/null | grep -oP '\.\d+ > \.' | sort | uniq -c | sort -rn | head -10)
    if [ -n "$top_ports" ]; then
        printf "  ${BOLD}%-10s %s${RESET}\n" "Pacotes" "Porta"
        echo "  ------------------------"
        while IFS= read -r line; do
            printf "  %-10s %s\n" "$(echo "$line" | awk '{print $1}')" "$(echo "$line" | awk '{print $2}')"
        done <<< "$top_ports"
    else
        echo -e "  ${YELLOW}Não foi possível extrair portas${RESET}"
    fi
    echo ""

    echo -e "${CYAN}--- Resumo da Captura ---${RESET}"
    echo ""
    local capture_size
    capture_size=$(du -h "$CAPTURE_FILE" | awk '{print $1}')
    local duration_s=$DURATION
    local pkt_per_sec
    pkt_per_sec=$(awk "BEGIN{printf \"%.1f\", $pkt_count / $duration_s}")
    echo -e "  Interface:         $INTERFACE"
    echo -e "  Duração:           $duration_s segundos"
    echo -e "  Pacotes capturados: $pkt_count"
    echo -e "  Média:             $pkt_per_sec pacotes/segundo"
    echo -e "  Tamanho do arquivo: $capture_size"
    echo ""

    if $bm_warning; then
        echo -e "  ${YELLOW}[!] Tráfego broadcast/multicast elevado pode indicar problemas de rede${RESET}"
    fi
    if [ "$tcp_count" -gt "$((udp_count * 2))" ] && [ "$udp_count" -gt 0 ]; then
        echo -e "  ${GREEN}[+] Predominância de TCP (comportamento típico)${RESET}"
    elif [ "$udp_count" -gt "$((tcp_count * 2))" ]; then
        echo -e "  ${YELLOW}[!] Alto volume de UDP pode indicar streaming ou atividade anômala${RESET}"
    fi
}

save_report() {
    echo ""
    echo "  1) Gerar e salvar relatório"
    echo "  2) Pular"
    echo ""

    while true; do
        echo -n "Selecione (1-2): "
        read choice
        case "$choice" in
            1)
                local outfile="$AUDIT_DIR/traffic_analysis_$(date +%Y%m%d_%H%M%S).txt"
                {
                    echo "=================================================="
                    echo "  Relatório de Análise de Tráfego"
                    echo "  Data: $(date)"
                    echo "=================================================="
                    echo ""
                    echo "Interface: $INTERFACE"
                    echo "Duração: $DURATION segundos"
                    echo ""
                    echo "--- Estatísticas ---"
                    local pkt_count
                    pkt_count=$(tcpdump -r "$CAPTURE_FILE" 2>/dev/null | wc -l)
                    echo "Total de pacotes: $pkt_count"
                    echo ""
                    echo "--- Top 10 IPs Origem ---"
                    tcpdump -r "$CAPTURE_FILE" -nn 2>/dev/null | grep -oP 'IP\s+\K(\d+\.\d+\.\d+\.\d+)' | sort | uniq -c | sort -rn | head -10
                    echo ""
                    echo "--- Distribuição de Protocolos ---"
                    local tcp_count udp_count icmp_count
                    tcp_count=$(tcpdump -r "$CAPTURE_FILE" 2>/dev/null | grep -ci "TCP" || true)
                    udp_count=$(tcpdump -r "$CAPTURE_FILE" 2>/dev/null | grep -ci "UDP" || true)
                    icmp_count=$(tcpdump -r "$CAPTURE_FILE" 2>/dev/null | grep -ci "ICMP" || true)
                    echo "TCP: $tcp_count"
                    echo "UDP: $udp_count"
                    echo "ICMP: $icmp_count"
                } > "$outfile"
                echo -e "${GREEN}[+] Relatório salvo em: $outfile${RESET}"
                log "Relatório salvo em $outfile"
                REPORT_FILE="$outfile"
                break
                ;;
            2)
                echo -e "${YELLOW}[!] Pulando geração de relatório${RESET}"
                break
                ;;
            *) echo -e "${RED}Opção inválida${RESET}" ;;
        esac
    done
}

main() {
    log "=== INÍCIO Análise de Tráfego ==="
    show_banner "Análise de Tráfego"
    show_disclaimer

    check_root

    check_deps "tcpdump"

    list_interfaces

    select_duration

    capture_traffic

    analyze_traffic

    save_report

    echo ""
    log "=== FIM Análise de Tráfego ==="

    local pkt_count
    pkt_count=$(tcpdump -r "$CAPTURE_FILE" 2>/dev/null | wc -l 2>/dev/null || echo 0)

    save_resumo "Interface: $INTERFACE
Duração: $DURATION segundos
Pacotes capturados: $pkt_count
Relatório: ${REPORT_FILE:-N/A}"

    echo -e "${CYAN}================================================${RESET}"
    echo -e "${GREEN}  Análise de tráfego concluída!${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    if [ -n "$REPORT_FILE" ]; then
        echo -e "  Relatório: $REPORT_FILE"
    fi
    echo -e "${CYAN}================================================${RESET}"
}

main
