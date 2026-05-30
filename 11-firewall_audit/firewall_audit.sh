#!/usr/bin/env bash

set -uo pipefail

source "$(dirname "$0")/../utils/common.sh"

# =============================================================================
#  Firewall Auditor - Firewall Rules Analysis Tool
#  Interactive script for local and remote firewall auditing
# =============================================================================
#  LEGAL DISCLAIMER:
#  This script is for educational purposes and authorized security testing only.
#  Unauthorized use against networks you do not own or have explicit permission
#  to test is illegal. The author is not responsible for any misuse.
# =============================================================================

TARGET=""
AUDIT_TYPE=""
REPORT_FILE=""

cleanup() {
    echo -e "\n${YELLOW}[!] Limpando...${RESET}"
    cleanup_temp
    log "Limpeza realizada"
}
trap cleanup EXIT

select_target() {
    read_input TARGET "IP do alvo"
    echo -e "${GREEN}[+] Alvo: $TARGET${RESET}"
}

choose_audit_type() {
    step "Escolha o tipo de auditoria"
    echo ""
    echo -e "${YELLOW}[*] Selecione o tipo de auditoria:${RESET}"
    echo ""
    echo "  1) Análise local de regras de firewall (iptables)"
    echo "  2) Detecção remota de firewall (nmap)"
    echo ""

    while true; do
        echo -n "Selecione (1-2): "
        read AUDIT_TYPE
        case "$AUDIT_TYPE" in
            1|2) break ;;
            *) echo -e "${RED}Opção inválida${RESET}" ;;
        esac
    done

    echo -e "${GREEN}[+] Tipo de auditoria: $AUDIT_TYPE${RESET}"
}

analyze_local_rules() {
    step "Análise local de regras de firewall"
    echo ""

    if ! command -v iptables &>/dev/null; then
        echo -e "${RED}[!] iptables não disponível${RESET}"
        log_error "iptables não disponível"
        return
    fi

    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}[!] Executando com sudo para iptables...${RESET}"
    fi

    echo -e "${CYAN}--- Regras iptables Atuais ---${RESET}"
    echo ""
    sudo iptables -L -n -v --line-numbers 2>/dev/null || {
        echo -e "${RED}[!] Falha ao ler regras iptables${RESET}"
        log_error "Falha ao ler iptables"
        return
    }

    echo ""
    echo -e "${CYAN}--- Regras NAT ---${RESET}"
    echo ""
    sudo iptables -t nat -L -n -v --line-numbers 2>/dev/null || true

    echo ""
    echo -e "${CYAN}--- Regras Mangle ---${RESET}"
    echo ""
    sudo iptables -t mangle -L -n -v --line-numbers 2>/dev/null || true

    echo ""
    local policy_count accept_count drop_count reject_count
    policy_count=$(sudo iptables -L -n 2>/dev/null | grep -c "^Chain" || true)
    accept_count=$(sudo iptables -L -n -v 2>/dev/null | grep -c "ACCEPT" || true)
    drop_count=$(sudo iptables -L -n -v 2>/dev/null | grep -c "DROP" || true)
    reject_count=$(sudo iptables -L -n -v 2>/dev/null | grep -c "REJECT" || true)

    echo -e "${CYAN}--- Estatísticas de Regras ---${RESET}"
    echo ""
    echo -e "  Chains:          $policy_count"
    echo -e "  ${GREEN}Regras ACCEPT:   $accept_count${RESET}"
    echo -e "  ${RED}Regras DROP:     $drop_count${RESET}"
    echo -e "  ${YELLOW}Regras REJECT:   $reject_count${RESET}"
}

remote_firewall_detection() {
    step "Detecção remota de firewall"
    echo ""

    check_deps "nmap"

    echo -e "${YELLOW}[*] Executando varreduras de detecção de firewall em $TARGET...${RESET}"
    echo ""

    local tmpdir
    tmpdir=$(mktemp -d)

    echo -e "${CYAN}--- Varredura TCP ACK (detecta filtragem stateful) ---${RESET}"
    echo ""
    timeout 60 nmap -sA -T4 -p 1-1000 "$TARGET" -oN "$tmpdir/ack.txt" 2>/dev/null
    if [ -f "$tmpdir/ack.txt" ]; then
        grep -E "^\d+|Not shown" "$tmpdir/ack.txt" | while IFS= read -r line; do
            local clean
            clean=$(echo "$line" | sed 's/^/  /')
            echo "$clean"
        done
    fi
    echo ""

    local unfiltered_count
    unfiltered_count=$(grep -c "unfiltered" "$tmpdir/ack.txt" 2>/dev/null || echo 0)
    if [ "$unfiltered_count" -gt 0 ]; then
        echo -e "  ${YELLOW}[!] Portas não filtradas detectadas - provável firewall stateless${RESET}"
    else
        echo -e "  ${GREEN}[+] Todas as portas filtradas - firewall stateful detectado${RESET}"
    fi
    echo ""

    echo -e "${CYAN}--- Varredura TCP FIN ---${RESET}"
    echo ""
    timeout 60 nmap -sF -T4 -p 1-1000 "$TARGET" -oN "$tmpdir/fin.txt" 2>/dev/null
    if [ -f "$tmpdir/fin.txt" ]; then
        grep -E "^\d+|Not shown" "$tmpdir/fin.txt" | while IFS= read -r line; do
            local clean
            clean=$(echo "$line" | sed 's/^/  /')
            echo "$clean"
        done
    fi
    echo ""

    echo -e "${CYAN}--- Varredura TCP NULL ---${RESET}"
    echo ""
    timeout 60 nmap -sN -T4 -p 1-1000 "$TARGET" -oN "$tmpdir/null.txt" 2>/dev/null
    if [ -f "$tmpdir/null.txt" ]; then
        grep -E "^\d+|Not shown" "$tmpdir/null.txt" | while IFS= read -r line; do
            local clean
            clean=$(echo "$line" | sed 's/^/  /')
            echo "$clean"
        done
    fi
    echo ""

    echo -e "${CYAN}--- Varredura TCP XMAS ---${RESET}"
    echo ""
    timeout 60 nmap -sX -T4 -p 1-1000 "$TARGET" -oN "$tmpdir/xmas.txt" 2>/dev/null
    if [ -f "$tmpdir/xmas.txt" ]; then
        grep -E "^\d+|Not shown" "$tmpdir/xmas.txt" | while IFS= read -r line; do
            local clean
            clean=$(echo "$line" | sed 's/^/  /')
            echo "$clean"
        done
    fi
    echo ""

    echo -e "${CYAN}--- Varredura UDP (top 50 portas) ---${RESET}"
    echo ""
    timeout 60 nmap -sU -T4 --top-ports 50 "$TARGET" -oN "$tmpdir/udp.txt" 2>/dev/null
    if [ -f "$tmpdir/udp.txt" ]; then
        grep -E "^\d+|Not shown" "$tmpdir/udp.txt" | while IFS= read -r line; do
            local clean
            clean=$(echo "$line" | sed 's/^/  /')
            echo "$clean"
        done
    fi
    echo ""

    echo -e "${CYAN}--- Varredura TCP SYN (referência) ---${RESET}"
    echo ""
    timeout 60 nmap -sS -T4 -p 1-1000 "$TARGET" -oN "$tmpdir/syn.txt" 2>/dev/null
    if [ -f "$tmpdir/syn.txt" ]; then
        grep -E "^\d+|Not shown" "$tmpdir/syn.txt" | while IFS= read -r line; do
            local clean
            clean=$(echo "$line" | sed 's/^/  /')
            echo "$clean"
        done
    fi
    echo ""

    rm -rf "$tmpdir"
}

port_state_analysis() {
    step "Análise de estado das portas"
    echo ""

    echo -e "${YELLOW}[*] Comparando resultados de varredura para inferir regras de firewall...${RESET}"
    echo ""

    local tmpdir
    tmpdir=$(mktemp -d)

    timeout 60 nmap -sS -T4 -p 1-1000 "$TARGET" -oN "$tmpdir/syn.txt" 2>/dev/null
    timeout 60 nmap -sA -T4 -p 1-1000 "$TARGET" -oN "$tmpdir/ack.txt" 2>/dev/null

    local open_ports filtered_ports
    open_ports=$(grep "/open/" "$tmpdir/syn.txt" 2>/dev/null | grep -oP '^\d+' | tr '\n' ',' | sed 's/,$//')
    filtered_ports=$(grep "/filtered" "$tmpdir/syn.txt" 2>/dev/null | grep -oP '^\d+' | tr '\n' ',' | sed 's/,$//')

    echo -e "${CYAN}--- Portas Abertas (varredura SYN) ---${RESET}"
    echo ""
    if [ -n "$open_ports" ]; then
        echo -e "  ${GREEN}$open_ports${RESET}"
    else
        echo -e "  ${YELLOW}Nenhuma detectada${RESET}"
    fi
    echo ""

    echo -e "${CYAN}--- Portas Filtradas (varredura SYN) ---${RESET}"
    echo ""
    if [ -n "$filtered_ports" ]; then
        echo -e "  ${YELLOW}$filtered_ports${RESET}"
    else
        echo -e "  ${GREEN}Nenhuma filtrada${RESET}"
    fi
    echo ""

    local open_count filtered_count
    open_count=$(echo "$open_ports" | tr ',' '\n' | grep -c . || true)
    filtered_count=$(echo "$filtered_ports" | tr ',' '\n' | grep -c . || true)

    echo -e "${CYAN}--- Regras Inferidas ---${RESET}"
    echo ""
    echo -e "  Portas abertas:   $open_count"
    echo -e "  Filtradas:        $filtered_count"
    echo ""

    if [ "$open_count" -eq 0 ] && [ "$filtered_count" -gt 0 ]; then
        echo -e "  ${YELLOW}Todas as portas testadas filtradas - política restritiva${RESET}"
    elif [ "$open_count" -gt 0 ] && [ "$filtered_count" -eq 0 ]; then
        echo -e "  ${YELLOW}Nenhuma filtragem detectada - política permissiva${RESET}"
    else
        echo -e "  ${CYAN}Filtragem seletiva detectada${RESET}"
    fi

    rm -rf "$tmpdir"
}

advanced_tests() {
    step "Testes avançados de firewall"
    echo ""

    if ! command -v hping3 &>/dev/null; then
        echo -e "${YELLOW}[!] hping3 não disponível - pulando testes avançados${RESET}"
        echo -e "${YELLOW}[!] Instale com: sudo apt install hping3${RESET}"
        echo ""
        echo -e "${CYAN}--- Teste ICMP Básico ---${RESET}"
        echo ""
        if ping -c 2 -W 2 "$TARGET" &>/dev/null; then
            echo -e "  ${GREEN}[+] Alvo responde ao ping ICMP${RESET}"
        else
            echo -e "  ${YELLOW}[-] Alvo não responde ao ping ICMP${RESET}"
        fi
        return
    fi

    echo -e "${YELLOW}[*] Executando testes avançados com hping3...${RESET}"
    echo ""

    echo -e "${CYAN}--- Manipulação de Pacotes Fragmentados ---${RESET}"
    echo ""
    if timeout 10 hping3 -c 3 -f -p 80 "$TARGET" 2>/dev/null | grep -q "SA"; then
        echo -e "  ${GREEN}[+] Pacotes fragmentados passam${RESET}"
    else
        echo -e "  ${YELLOW}[-] Pacotes fragmentados bloqueados ou sem resposta${RESET}"
    fi
    echo ""

    echo -e "${CYAN}--- Manipulação de IP Falsificado (SYN) ---${RESET}"
    echo ""
    if timeout 10 hping3 -c 2 --spoof 8.8.8.8 -p 80 "$TARGET" 2>/dev/null | grep -q "SA"; then
        echo -e "  ${RED}[!] Pacotes falsificados aceitos${RESET}"
    else
        echo -e "  ${GREEN}[+] Pacotes falsificados tratados corretamente${RESET}"
    fi
    echo ""

    echo -e "${CYAN}--- Limitação de Taxa ICMP ---${RESET}"
    echo ""
    local icmp_before icmp_after
    icmp_before=$(hping3 -c 3 --icmp "$TARGET" 2>/dev/null | grep -c "reply")
    icmp_after=$(hping3 -c 10 --icmp "$TARGET" 2>/dev/null | grep -c "reply")
    if [ "$icmp_after" -lt "$((icmp_before * 2))" ] && [ "$icmp_before" -gt 0 ]; then
        echo -e "  ${YELLOW}[!] Limitação de taxa ICMP detectada${RESET}"
    elif [ "$icmp_before" -gt 0 ]; then
        echo -e "  ${GREEN}[+] Nenhuma limitação de taxa ICMP detectada${RESET}"
    else
        echo -e "  ${YELLOW}[-] Sem resposta ICMP (possivelmente bloqueado)${RESET}"
    fi
    echo ""

    echo -e "${CYAN}--- Detecção Baseada em TTL ---${RESET}"
    echo ""
    local ttl_result
    ttl_result=$(timeout 10 hping3 -c 2 -t 1 -p 80 "$TARGET" 2>/dev/null)
    if echo "$ttl_result" | grep -q "TTL"; then
        local hop_count
        hop_count=$(echo "$ttl_result" | grep -oP 'TTL\s+\K\d+' | head -1)
        local distance=$((255 - hop_count))
        echo -e "  Saltos estimados até o alvo: $distance"
    fi
}

display_firewall_profile() {
    step "Perfil do firewall"
    echo ""

    echo -e "${CYAN}--- Perfil do Firewall para $TARGET ---${RESET}"
    echo ""

    if [ "$AUDIT_TYPE" = "2" ]; then
        local tmpdir
        tmpdir=$(mktemp -d)
        timeout 60 nmap -sA -T4 -p 1-1000 "$TARGET" -oN "$tmpdir/ack.txt" 2>/dev/null
        timeout 60 nmap -sS -T4 -p 1-1000 "$TARGET" -oN "$tmpdir/syn.txt" 2>/dev/null

        local unfiltered open_count_filtered
        unfiltered=$(grep -c "unfiltered" "$tmpdir/ack.txt" 2>/dev/null || echo 0)
        open_count_filtered=$(grep -c "/open/" "$tmpdir/syn.txt" 2>/dev/null || echo 0)

        echo -e "  ${BOLD}Tipo de Firewall:${RESET}"
        if [ "$unfiltered" -gt 0 ]; then
            echo -e "    ${YELLOW}Firewall stateless${RESET}"
        else
            echo -e "    ${GREEN}Firewall stateful${RESET}"
        fi
        echo ""

        echo -e "  ${BOLD}Regras Detectadas:${RESET}"
        echo -e "    Portas abertas:   $open_count_filtered"
        echo -e "    Filtradas:        $filtered_count"
        echo ""

        local os_guess
        os_guess=$(timeout 30 nmap -O -T4 "$TARGET" 2>/dev/null | grep "OS details" | head -1 | cut -d: -f2- | xargs)
        if [ -n "$os_guess" ]; then
            echo -e "  ${BOLD}Impressão Digital do SO:${RESET}"
            echo -e "    $os_guess"
        fi

        rm -rf "$tmpdir"
    else
        local default_policy
        default_policy=$(iptables -L INPUT -n 2>/dev/null | head -1 | awk '{print $4}' | tr -d '()')
        echo -e "  ${BOLD}Política Padrão INPUT:${RESET} ${default_policy:-desconhecida}"
        echo ""
        echo -e "  ${BOLD}Notas:${RESET}"
        echo -e "    Análise local de iptables concluída acima"
    fi
    echo ""
}

save_report() {
    step "Salvar relatório"
    echo ""

    echo "  1) Gerar e salvar relatório"
    echo "  2) Pular"
    echo ""

    while true; do
        echo -n "Selecione (1-2): "
        read choice
        case "$choice" in
            1)
                local outfile="$AUDIT_DIR/firewall_audit_$(date +%Y%m%d_%H%M%S).txt"
                {
                    echo "=================================================="
                    echo "  Relatório de Auditoria de Firewall"
                    echo "  Alvo: $TARGET"
                    echo "  Data: $(date)"
                    echo "  Tipo de Auditoria: $AUDIT_TYPE"
                    echo "=================================================="
                    echo ""
                    echo "Alvo: $TARGET"
                    echo "Tipo de Auditoria: $([ "$AUDIT_TYPE" = "1" ] && echo "Local (iptables)" || echo "Remota (nmap)")"
                    echo ""
                    echo "--- Resultados ---"
                    echo "Consulte a saída do console para resultados detalhados."
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

parse_cli_args TARGET _unused_port "$@"

main() {
    log "=== INÍCIO Firewall Audit ==="
    show_banner "Firewall Auditor"
    show_disclaimer
    check_deps "nmap" "hping3"

    step "Selecionar alvo"
    select_target

    choose_audit_type

    if [ "$AUDIT_TYPE" = "1" ]; then
        analyze_local_rules
    else
        remote_firewall_detection
        port_state_analysis
    fi

    advanced_tests
    display_firewall_profile
    save_report

    echo ""
    log "=== FIM Auditoria de Firewall ==="
    save_resumo "Alvo: $TARGET
Tipo de auditoria: $([ "$AUDIT_TYPE" = "1" ] && echo "Local (iptables)" || echo "Remota (nmap)")
Relatório: ${REPORT_FILE:-N/A}"
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${GREEN}  Auditoria de firewall concluída!${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    if [ -n "$REPORT_FILE" ]; then
        echo -e "  Relatório: $REPORT_FILE"
    fi
    echo -e "${CYAN}================================================${RESET}"
}

main
