#!/usr/bin/env bash

set -uo pipefail

source "$(dirname "$0")/../utils/common.sh"

TARGET=""
OUTPUT_FILE=""
IDENTITY_PORTS=(389 636 445 1812 1813)
IDENTITY_NAMES=("LDAP" "LDAPS" "AD/NetBIOS" "RADIUS-Auth" "RADIUS-Acct")
PORT_RESULTS=""

cleanup() {
    echo -e "\n${YELLOW}[!] Limpando...${RESET}"
    cleanup_temp
    log "Limpeza realizada"
}
trap cleanup EXIT

get_target() {
    step "Definir alvo"
    echo ""

    while true; do
        echo -n "Digite o IP ou hostname do alvo: "
        read input
        if [ -n "$input" ]; then
            TARGET="$input"
            break
        fi
        echo -e "${RED}[!] Alvo nao pode estar vazio${RESET}"
    done

    echo -e "${GREEN}[+] Alvo definido: $TARGET${RESET}"
    log "Alvo: $TARGET"
}

check_identity_ports() {
    step "Verificacao de servidores de identidade"
    echo ""

    local results=""
    echo -e "${CYAN}--- Testando conectividade ---${RESET}"
    echo ""

    local total=${#IDENTITY_PORTS[@]}
    local current=0

    for i in "${!IDENTITY_PORTS[@]}"; do
        local port=${IDENTITY_PORTS[$i]}
        local name=${IDENTITY_NAMES[$i]}
        current=$((current + 1))
        progress_bar "$current" "$total"

        local status
        status=$(timeout 5 nmap -p "$port" --host-timeout 5 "$TARGET" 2>/dev/null | grep "^$port" | awk '{print $2}')
        if echo "$status" | grep -q "open"; then
            echo -e "\r  ${GREEN}[ABERTA]${RESET} $name ($port)"
            results="$results$name|$port|open\n"
        else
            echo -e "\r  ${YELLOW}[FECHADA]${RESET} $name ($port)"
            results="$results$name|$port|closed\n"
        fi
    done

    PORT_RESULTS="$results"

    echo ""
    echo ""
    echo -e "${CYAN}--- Servicos de identidade encontrados ---${RESET}"
    echo ""
    local found=false
    while IFS='|' read -r svc port status; do
        [ -z "$svc" ] && continue
        if [ "$status" = "open" ]; then
            echo -e "  ${GREEN}[+]${RESET} $svc esta ACESSIVEL na porta $port"
            found=true
        fi
    done <<< "$(printf "%b" "$results")"
    if ! $found; then
        echo -e "  ${YELLOW}[-] Nenhum servico de identidade acessivel${RESET}"
        log "Nenhum servico de identidade acessivel em $TARGET"
    fi
    echo ""
}

vlan_test() {
    step "Teste de segmentacao VLAN"
    echo ""

    if command -v vlan &>/dev/null; then
        echo -e "${GREEN}[+] Comando vlan detectado - realizando descoberta basica${RESET}"
        log "Comando vlan disponivel"

        local vlan_info
        vlan_info=$(vlan info 2>/dev/null || vlan list 2>/dev/null || true)

        if [ -n "$vlan_info" ]; then
            echo ""
            echo -e "${CYAN}--- Informacoes VLAN ---${RESET}"
            echo ""
            echo "$vlan_info" | head -30
        else
            echo -e "${YELLOW}[!] Nao foi possivel obter informacoes VLAN com o comando atual${RESET}"
            log "vlan command nao retornou dados"
        fi
    else
        echo -e "${YELLOW}[!] Comando 'vlan' nao encontrado${RESET}"
        echo -e "${YELLOW}[!] Verificacao manual recomendada:${RESET}"
        echo ""
        echo -e "  ${CYAN}1.${RESET} Verifique a configuracao de switches gerenciaveis"
        echo -e "  ${CYAN}2.${RESET} Consulte o administrador de rede sobre as VLANs configuradas"
        echo -e "  ${CYAN}3.${RESET} Utilize ferramentas como arp-scan ou nmap para mapear segmentos"
        echo -e "  ${CYAN}4.${RESET} Verifique o arquivo /etc/network/interfaces (Linux)"
        echo ""
        log "Comando vlan nao disponivel - sugestao de verificacao manual"
    fi
}

show_summary() {
    step "Resumo dos resultados"
    echo ""

    local total=${#IDENTITY_PORTS[@]}
    local open_count=0
    local closed_count=0

    echo -e "${CYAN}--- Portas de Servicos de Identidade ---${RESET}"
    echo ""
    printf "${BOLD}%-15s %-10s %s${RESET}\n" "Servico" "Porta" "Status"
    echo "-------------------------------------"

    while IFS='|' read -r svc port status; do
        [ -z "$svc" ] && continue
        if [ "$status" = "open" ]; then
            printf "%-15s %-10s ${GREEN}%-10s${RESET}\n" "$svc" "$port" "ABERTA"
            open_count=$((open_count + 1))
        else
            printf "%-15s %-10s ${YELLOW}%-10s${RESET}\n" "$svc" "$port" "FECHADA"
            closed_count=$((closed_count + 1))
        fi
    done <<< "$(printf "%b" "$PORT_RESULTS")"

    echo ""
    echo -e "  ${GREEN}Abertas: $open_count${RESET}"
    echo -e "  ${YELLOW}Fechadas: $closed_count${RESET}"
    echo -e "  Total: $total"
}

export_report() {
    step "Exportar relatorio"
    echo ""

    echo "  1) Salvar relatorio"
    echo "  2) Pular"
    echo ""

    while true; do
        echo -n "Selecione (1-2): "
        read choice
        case "$choice" in
            1)
                OUTPUT_FILE="$AUDIT_DIR/identity_audit_$(date +%Y%m%d_%H%M%S).txt"
                mkdir -p "$AUDIT_DIR" 2>/dev/null
                {
                    echo "=================================================="
                    echo "  Relatorio - Auditoria de Identidade e Politicas"
                    echo "  Alvo: $TARGET"
                    echo "  Data: $(date)"
                    echo "=================================================="
                    echo ""
                    echo "--- Portas de Identidade ---"
                    echo ""
                    printf "%-15s %-10s %s\n" "Servico" "Porta" "Status"
                    echo "-------------------------------------"
                    while IFS='|' read -r svc port status; do
                        [ -z "$svc" ] && continue
                        printf "%-15s %-10s %s\n" "$svc" "$port" "$status"
                    done <<< "$(printf "%b" "$PORT_RESULTS")"
                    echo ""
                    echo "--- Segmentacao VLAN ---"
                    echo "Teste de VLAN realizado: $(command -v vlan &>/dev/null && echo 'Sim' || echo 'Nao (recomendado verificacao manual)')"
                    echo ""
                    echo "--- Resumo ---"
                    local open_count closed_count
                    open_count=$(printf "%b" "$PORT_RESULTS" | grep -c "open" || true)
                    closed_count=$(printf "%b" "$PORT_RESULTS" | grep -c "closed" || true)
                    echo "Portas abertas: $open_count"
                    echo "Portas fechadas: $closed_count"
                    echo "Total de portas testadas: $((open_count + closed_count))"
                } > "$OUTPUT_FILE"
                echo -e "${GREEN}[+] Relatorio salvo em: $OUTPUT_FILE${RESET}"
                log "Relatorio salvo em $OUTPUT_FILE"
                break
                ;;
            2)
                echo -e "${YELLOW}[!] Pulando exportacao${RESET}"
                OUTPUT_FILE="/dev/null"
                break
                ;;
            *) echo -e "${RED}Opcao invalida${RESET}" ;;
        esac
    done
}

main() {
    log "=== INICIO Auditoria de Identidade e Politicas ==="
    show_banner "Auditoria de Identidade e Politicas"
    show_disclaimer
    check_deps "nmap"

    get_target

    check_identity_ports

    vlan_test

    show_summary

    export_report

    echo ""
    log "=== FIM Auditoria de Identidade e Politicas ==="
    save_resumo "Alvo: $TARGET
Servicos de identidade testados:
$(printf "%b" "$PORT_RESULTS" | while IFS='|' read -r svc port status; do [ -n "$svc" ] && echo "  $svc ($port): $status"; done)
Relatorio: ${OUTPUT_FILE:-N/A}"

    echo -e "${CYAN}================================================${RESET}"
    echo -e "${GREEN}  Auditoria de Identidade e Politicas concluida!${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    if [ -n "$OUTPUT_FILE" ] && [ "$OUTPUT_FILE" != "/dev/null" ]; then
        echo -e "  Relatorio: $OUTPUT_FILE"
    fi
    echo -e "${CYAN}================================================${RESET}"
}

main
