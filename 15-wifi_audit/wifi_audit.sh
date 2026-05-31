#!/usr/bin/env bash

set -uo pipefail

source "$(dirname "$0")/../utils/common.sh"

# =============================================================================
#  WiFi Auditor - Wireless Perimeter Security Audit Tool
#  Scans and audits wireless access points for security weaknesses
# =============================================================================
#  LEGAL DISCLAIMER:
#  This script is for educational purposes and authorized security testing only.
#  Unauthorized use against networks you do not own or have explicit permission
#  to test is illegal. The author is not responsible for any misuse.
# =============================================================================

WIFI_INTERFACE=""
REPORT_FILE=""
SCAN_RESULTS=""
KNOWN_SSIDS=()

cleanup() {
    echo -e "\n${YELLOW}[!] Limpando...${RESET}"
    cleanup_temp
    log "Limpeza realizada"
}
trap cleanup EXIT

detect_wifi_interfaces() {
    echo -e "${YELLOW}[*] Detectando interfaces Wi-Fi...${RESET}"

    local interfaces
    interfaces=$(iw dev 2>/dev/null | grep "Interface" | awk '{print $2}')

    if [ -z "$interfaces" ]; then
        interfaces=$(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | while IFS= read -r iface; do
            if iw dev "$iface" info &>/dev/null 2>&1; then
                echo "$iface"
            fi
        done)
    fi

    echo "$interfaces"
}

list_wifi_interfaces() {
    step "Listar interfaces Wi-Fi disponíveis"
    echo ""
    echo -e "${YELLOW}[*] Interfaces Wi-Fi detectadas:${RESET}"
    echo ""

    local interfaces
    interfaces=$(detect_wifi_interfaces)

    if [ -z "$interfaces" ]; then
        echo -e "${RED}[!] Nenhuma interface Wi-Fi encontrada${RESET}"
        log_error "Nenhuma interface Wi-Fi encontrada"
        echo ""
        echo -e "${YELLOW}[*] Este sistema pode não ter placas Wi-Fi ou os drivers necessários.${RESET}"
        echo -e "${YELLOW}[*] Certifique-se de que o hardware Wi-Fi está presente e habilitado.${RESET}"
        exit 1
    fi

    local i=1
    local iface_list=()
    while IFS= read -r iface; do
        [ -z "$iface" ] && continue
        local state
        state=$(ip -o link show "$iface" 2>/dev/null | awk '{print $9}')
        echo -e "  $i) $iface  [${state}]"
        iface_list+=("$iface")
        i=$((i + 1))
    done <<< "$interfaces"

    echo ""

    if [ "$i" -eq 2 ]; then
        WIFI_INTERFACE="${iface_list[0]}"
        echo -e "${GREEN}[+] Única interface detectada: $WIFI_INTERFACE${RESET}"
        log "Interface Wi-Fi selecionada automaticamente: $WIFI_INTERFACE"
        return
    fi

    local if_attempts=0
    while [ $if_attempts -lt 10 ]; do
        echo -n "Selecione a interface (1-$((i - 1))): "
        read choice || true
        if [ "$choice" -ge 1 ] && [ "$choice" -le "$((i - 1))" ] 2>/dev/null; then
            WIFI_INTERFACE="${iface_list[$((choice - 1))]}"
            echo -e "${GREEN}[+] Interface selecionada: $WIFI_INTERFACE${RESET}"
            log "Interface Wi-Fi selecionada: $WIFI_INTERFACE"
            break
        fi
        echo -e "${RED}Opção inválida${RESET}"
        if_attempts=$((if_attempts + 1))
    done
}

ask_known_ssids() {
    echo ""
    echo -e "${YELLOW}[*] Deseja informar SSIDs conhecidos para detectar Rogue APs?${RESET}"
    echo -e "${YELLOW}    (Redes legítimas da sua organização)${RESET}"
    echo ""
    echo -n "Informe os SSIDs conhecidos separados por vírgula (ou Enter para pular): "
    read input || true
    if [ -n "$input" ]; then
        IFS=',' read -ra ssids <<< "$input"
        for ssid in "${ssids[@]}"; do
            ssid=$(echo "$ssid" | xargs)
            [ -n "$ssid" ] && KNOWN_SSIDS+=("$ssid")
        done
        if [ ${#KNOWN_SSIDS[@]} -gt 0 ]; then
            echo -e "${GREEN}[+] ${#KNOWN_SSIDS[@]} SSID(s) conhecido(s) registrado(s)${RESET}"
        fi
    fi
}

scan_wifi() {
    step "Escaneando redes Wi-Fi"
    echo ""
    echo -e "${YELLOW}[*] Iniciando varredura em $WIFI_INTERFACE...${RESET}"
    echo -e "${YELLOW}[*] Isso pode levar alguns segundos...${RESET}"
    echo ""

    SCAN_RESULTS=$(iwlist "$WIFI_INTERFACE" scanning 2>&1)
    local exit_code=$?

    if [ "$exit_code" -ne 0 ] || echo "$SCAN_RESULTS" | grep -qi "no scan results\|Interface doesn't support scanning\|Operation not permitted"; then
        echo -e "${RED}[!] Falha ao escanear redes Wi-Fi${RESET}"
        log_error "Falha ao escanear Wi-Fi em $WIFI_INTERFACE"
        echo ""
        echo -e "${YELLOW}[*] Possíveis causas:${RESET}"
        echo -e "  - Interface não suporta modo monitor/scanning"
        echo -e "  - Permissões insuficientes (tente com sudo)"
        echo -e "  - Driver Wi-Fi não compatível"
        exit 1
    fi

    local ap_count
    ap_count=$(echo "$SCAN_RESULTS" | grep -c "ESSID:" || true)
    echo -e "${GREEN}[+] Varredura concluída: $ap_count AP(s) encontrado(s)${RESET}"
    log "Varredura concluida: $ap_count APs encontrados"
}

parse_and_display_aps() {
    step "Analisar pontos de acesso encontrados"
    echo ""
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${CYAN}  Pontos de Acesso Encontrados${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    echo ""

    local ap_count=0
    local wep_count=0
    local wpa1_count=0
    local open_count=0
    local weak_count=0
    local rogue_count=0
    local cell_data=""
    local cell_index=0

    while IFS= read -r line; do
        if echo "$line" | grep -q "Cell "; then
            [ -n "$cell_data" ] && process_ap "$cell_data"
            cell_data="$line"
            cell_index=$((cell_index + 1))
        elif echo "$line" | grep -q "ESSID:"; then
            cell_data="$cell_data"$'\n'"$line"
        elif echo "$line" | grep -q "Channel:"; then
            cell_data="$cell_data"$'\n'"$line"
        elif echo "$line" | grep -q "Signal level\|Quality="; then
            cell_data="$cell_data"$'\n'"$line"
        elif echo "$line" | grep -q "Encryption key:\|IE:.*WPA\|IE:.*WPA2\|IE:.*WEP\|Group Cipher\|Pairwise Ciphers\|Authentication Suites"; then
            cell_data="$cell_data"$'\n'"$line"
        fi
    done <<< "$SCAN_RESULTS"

    [ -n "$cell_data" ] && process_ap "$cell_data"

    echo ""
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${CYAN}  Resumo da Auditoria Wi-Fi${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    echo ""
    echo -e "  ${BOLD}Total de APs encontrados:${RESET} $ap_count"
    echo ""
    echo -e "  ${RED}WEP:           $wep_count${RESET}"
    echo -e "  ${YELLOW}WPA1:          $wpa1_count${RESET}"
    echo -e "  ${RED}Aberto (Open): $open_count${RESET}"
    echo -e "  ${GREEN}WPA2/WPA3:     $((ap_count - wep_count - wpa1_count - open_count))${RESET}"
    echo ""
    echo -e "  ${RED}APs com criptografia fraca: $weak_count${RESET}"
    echo -e "  ${YELLOW}Possíveis Rogue APs:       $rogue_count${RESET}"
    echo ""

    if [ "$weak_count" -gt 0 ]; then
        echo -e "${RED}⚠  Recomendação: Atualizar todos os APs com WEP/WPA1 para WPA2 ou WPA3.${RESET}"
    fi
    if [ "$open_count" -gt 0 ]; then
        echo -e "${RED}⚠  Redes abertas representam risco de segurança elevado.${RESET}"
    fi
    if [ "$rogue_count" -gt 0 ]; then
        echo -e "${RED}⚠  Possíveis Rogue APs detectados. Investigar imediatamente.${RESET}"
    fi
}

process_ap() {
    local data="$1"
    ap_count=$((ap_count + 1))

    local essid=""
    local channel=""
    local signal=""
    local encryption=""
    local is_weak=false
    local is_rogue=false

    while IFS= read -r line; do
        if echo "$line" | grep -q "ESSID:"; then
            essid=$(echo "$line" | sed 's/.*ESSID:"\(.*\)"/\1/')
            [ "$essid" = "" ] && essid="<oculto>"
        elif echo "$line" | grep -q "Channel:"; then
            channel=$(echo "$line" | grep -oP 'Channel:\s*\K\d+')
        elif echo "$line" | grep -q "Signal level"; then
            signal=$(echo "$line" | grep -oP 'Signal level[=:]\s*-?\d+' || echo "$line" | grep -oP 'Signal level=\K-?\d+')
            if [ -z "$signal" ]; then
                signal=$(echo "$line" | grep -oP 'Quality=\d+/\d+')
            fi
        elif echo "$line" | grep -q "Encryption key:"; then
            local enc_key
            enc_key=$(echo "$line" | grep -oP 'Encryption key:\K\w+')
            [ "$enc_key" = "on" ] && encryption="Criptografado" || encryption="Aberto"
        elif echo "$line" | grep -qi "IE:.*WEP"; then
            encryption="WEP"
            is_weak=true
        elif echo "$line" | grep -qi "IE:.*WPA2"; then
            if [ -z "$encryption" ] || [ "$encryption" != "WPA3" ]; then
                encryption="WPA2"
            fi
        elif echo "$line" | grep -qi "IE:.*WPA3"; then
            encryption="WPA3"
        elif echo "$line" | grep -qi "IE:.*802.1X"; then
            encryption="${encryption:-802.1X}"
        fi
    done <<< "$data"

    if echo "$data" | grep -qi "IE:.*WPA" && ! echo "$data" | grep -qi "IE:.*WPA2" && ! echo "$data" | grep -qi "IE:.*WPA3"; then
        if [ "$encryption" != "WEP" ] && [ "$encryption" != "Aberto" ]; then
            encryption="WPA1"
            is_weak=true
        fi
    fi

    [ "$encryption" = "WEP" ] && wep_count=$((wep_count + 1))
    [ "$encryption" = "WPA1" ] && wpa1_count=$((wpa1_count + 1))
    [ "$encryption" = "Aberto" ] && open_count=$((open_count + 1))
    $is_weak && weak_count=$((weak_count + 1))

    if [ "$essid" != "<oculto>" ] && [ "$essid" != "" ]; then
        for known in "${KNOWN_SSIDS[@]}"; do
            if [ "$essid" != "$known" ] && (echo "$essid" | grep -qi "$known" || echo "$known" | grep -qi "$essid"); then
                if [ "$essid" != "$known" ]; then
                    is_rogue=true
                    rogue_count=$((rogue_count + 1))
                fi
            fi
        done
        if [ ${#KNOWN_SSIDS[@]} -eq 0 ] && [ "$encryption" = "Aberto" ]; then
            is_rogue=true
            rogue_count=$((rogue_count + 1))
        fi
    fi

    echo -e "${CYAN}--- AP #$ap_count ---${RESET}"
    echo -e "  SSID:       ${BOLD}$essid${RESET}"
    echo -e "  Canal:      $channel"
    echo -e "  Sinal:      $signal"
    echo -e "  Criptografia: $encryption"

    if $is_weak; then
        echo -e "  ${RED}⚠  Criptografia fraca/obsoleta!${RESET}"
    fi
    if $is_rogue; then
        echo -e "  ${RED}🚨 Possível Rogue AP detectado!${RESET}"
    fi
    echo ""
}

save_report() {
    echo ""
    echo "  1) Gerar e salvar relatório"
    echo "  2) Pular"
    echo ""

    local sr_attempts=0
    while [ $sr_attempts -lt 10 ]; do
        echo -n "Selecione (1-2): "
        read choice || true
        case "$choice" in
            1)
                local outfile="$AUDIT_DIR/wifi_audit_$(date +%Y%m%d_%H%M%S).txt"
                {
                    echo "=================================================="
                    echo "  Relatório de Auditoria Wi-Fi"
                    echo "  Data: $(date)"
                    echo "  Interface: $WIFI_INTERFACE"
                    echo "=================================================="
                    echo ""
                    echo "--- Pontos de Acesso Encontrados ---"
                    echo "$SCAN_RESULTS" | grep -E "Cell |ESSID:|Channel:|Signal level|Encryption key:" | sed 's/^/  /'
                    echo ""
                    echo "--- Resumo ---"
                    echo "Total de APs: $ap_count"
                    echo "WEP: $wep_count"
                    echo "WPA1: $wpa1_count"
                    echo "Aberto (Open): $open_count"
                    echo "Rogue APs suspeitos: $rogue_count"
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
            *) echo -e "${RED}Opção inválida${RESET}"
               sr_attempts=$((sr_attempts + 1)) ;;
        esac
    done
}

main() {
    log "=== INÍCIO Auditoria Wi-Fi ==="
    show_banner "Auditoria Wi-Fi"
    show_disclaimer

    check_deps "iwlist"

    list_wifi_interfaces

    ask_known_ssids

    scan_wifi

    parse_and_display_aps

    save_report

    echo ""
    log "=== FIM Auditoria Wi-Fi ==="

    save_resumo "Interface: $WIFI_INTERFACE
Total de APs: $ap_count
WEP: $wep_count
WPA1: $wpa1_count
Aberto (Open): $open_count
Rogue APs: $rogue_count
Relatório: ${REPORT_FILE:-N/A}"

    echo -e "${CYAN}================================================${RESET}"
    echo -e "${GREEN}  Auditoria Wi-Fi concluída!${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    if [ -n "$REPORT_FILE" ]; then
        echo -e "  Relatório: $REPORT_FILE"
    fi
    echo -e "${CYAN}================================================${RESET}"
}

main
