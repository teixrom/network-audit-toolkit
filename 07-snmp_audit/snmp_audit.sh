#!/usr/bin/env bash

set -uo pipefail

source "$(dirname "$0")/../utils/common.sh"

# =============================================================================
#  SNMP Auditor - SNMP Security Audit Tool
#  Interactive script for SNMP protocol security auditing
# =============================================================================
#  LEGAL DISCLAIMER:
#  This script is for educational purposes and authorized security testing only.
#  Unauthorized use against networks you do not own or have explicit permission
#  to test is illegal. The author is not responsible for any misuse.
# =============================================================================

TARGET=""
SNMP_PORT_OPEN=false
COMMUNITY=""
SNMP_VERSION=""
OUTPUT_FILE=""

COMMUNITIES=("public" "private" "community" "manager" "admin" "snmp" "c0mrade" "all" "read" "write" "test" "security" "monitor" "netman" "manager" "server" "root" "user")

cleanup() {
    echo -e "\n${YELLOW}[!] Limpando...${RESET}"
    cleanup_temp
    log "Cleanup performed"
}
trap cleanup EXIT

enter_target() {
    read_input TARGET "Alvo (IP ou hostname)"
    echo -e "${GREEN}[+] Alvo: $TARGET${RESET}"
}

check_udp_161() {
    echo -e "\n${YELLOW}[*] Verificando porta UDP 161 (SNMP)...${RESET}"

    if command -v nmap &>/dev/null; then
        local result
        result=$(nmap -sU -p 161 --max-retries 1 -T4 "$TARGET" 2>/dev/null)
        if echo "$result" | grep -q "161/udp.*open"; then
            SNMP_PORT_OPEN=true
            echo -e "  ${GREEN}[+] Porta UDP 161 está ABERTA${RESET}"
        else
            echo -e "  ${RED}[-] Porta UDP 161 está FECHADA ou FILTRADA${RESET}"
        fi
    else
        echo -e "  ${YELLOW}[!] nmap não disponível, pulando verificação UDP${RESET}"
        SNMP_PORT_OPEN=true
    fi
}

brute_community() {
    echo -e "\n${YELLOW}[*] Testando strings de comunidade SNMP comuns...${RESET}"

    local found=false
    local total=${#COMMUNITIES[@]}
    local count=0

    for comm in "${COMMUNITIES[@]}"; do
        local result
        result=$(timeout 3 snmpget -v 1 -c "$comm" -On "$TARGET" 1.3.6.1.2.1.1.1.0 2>/dev/null)

        if [ -n "$result" ]; then
            echo -e "  ${GREEN}[+] String de comunidade encontrada: ${BOLD}$comm${RESET}"
            COMMUNITY="$comm"
            found=true
            break
        fi

        if [ "$count" -gt 0 ] && [ $((count % 5)) -eq 0 ]; then
            result=$(timeout 3 snmpget -v 2c -c "$comm" -On "$TARGET" 1.3.6.1.2.1.1.1.0 2>/dev/null)
            if [ -n "$result" ]; then
                echo -e "  ${GREEN}[+] String de comunidade encontrada (v2c): ${BOLD}$comm${RESET}"
                COMMUNITY="$comm"
                found=true
                break
            fi
        fi

        count=$((count + 1))
        progress_bar "$count" "$total"
    done
    printf "\n"

    if ! $found; then
        echo -e "\n  ${YELLOW}[!] Nenhuma string de comunidade comum funcionou${RESET}"
        echo ""
        echo -e "  ${YELLOW}[*] Digite a string de comunidade manualmente ou pressione Enter para pular:${RESET}"
        echo -n "  Comunidade: "
        read manual_comm
        if [ -n "$manual_comm" ]; then
            COMMUNITY="$manual_comm"
            local test_result
            test_result=$(timeout 3 snmpget -v 2c -c "$COMMUNITY" -On "$TARGET" 1.3.6.1.2.1.1.1.0 2>/dev/null)
            if [ -n "$test_result" ]; then
                echo -e "  ${GREEN}[+] Comunidade '$COMMUNITY' funciona${RESET}"
                found=true
            else
                echo -e "  ${RED}[-] Comunidade '$COMMUNITY' não funcionou${RESET}"
            fi
        fi
    fi

    if ! $found; then
        echo -e "\n  ${RED}[!] Nenhuma string de comunidade válida encontrada. Auditoria SNMP limitada.${RESET}"
        log_error "No valid SNMP community for $TARGET"
    fi
}

detect_snmp_version() {
    echo -e "\n${YELLOW}[*] Detectando suporte a versão SNMP...${RESET}"

    local versions=""

    if timeout 3 snmpget -v 1 -c "$COMMUNITY" -On "$TARGET" 1.3.6.1.2.1.1.1.0 2>/dev/null | grep -q "."; then
        versions+="v1 "
    fi

    if timeout 3 snmpget -v 2c -c "$COMMUNITY" -On "$TARGET" 1.3.6.1.2.1.1.1.0 2>/dev/null | grep -q "."; then
        versions+="v2c "
    fi

    if command -v snmpwalk &>/dev/null; then
        local v3_check
        v3_check=$(timeout 5 snmpwalk -v 3 -l authNoPriv -u test -A test -a MD5 -On "$TARGET" 1.3.6.1.2.1.1.1.0 2>/dev/null)
        if [ -n "$v3_check" ]; then
            versions+="v3 "
        fi
    fi

    if [ -n "$versions" ]; then
        SNMP_VERSION="$versions"
        echo -e "  ${GREEN}[+] Versões SNMP suportadas: $SNMP_VERSION${RESET}"
    else
        echo -e "  ${RED}[-] Não foi possível detectar a versão SNMP${RESET}"
        SNMP_VERSION="Unknown"
    fi
}

mib_walk_system() {
    echo ""
    echo -e "${YELLOW}[*] MIB Walk - Informações do Sistema${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    local sys_descr
    sys_descr=$(snmpget -v 2c -c "$COMMUNITY" -Ovq "$TARGET" 1.3.6.1.2.1.1.1.0 2>/dev/null)
    [ -n "$sys_descr" ] && echo -e "  ${GREEN}[+]${RESET} Descrição do Sistema: $sys_descr" && log "sysDescr: $sys_descr"

    local sys_name
    sys_name=$(snmpget -v 2c -c "$COMMUNITY" -Ovq "$TARGET" 1.3.6.1.2.1.1.5.0 2>/dev/null)
    [ -n "$sys_name" ] && echo -e "  ${GREEN}[+]${RESET} Nome do Sistema: $sys_name" && log "sysName: $sys_name"

    local sys_location
    sys_location=$(snmpget -v 2c -c "$COMMUNITY" -Ovq "$TARGET" 1.3.6.1.2.1.1.6.0 2>/dev/null)
    [ -n "$sys_location" ] && echo -e "  ${GREEN}[+]${RESET} Localização do Sistema: $sys_location" && log "sysLocation: $sys_location"

    local sys_contact
    sys_contact=$(snmpget -v 2c -c "$COMMUNITY" -Ovq "$TARGET" 1.3.6.1.2.1.1.4.0 2>/dev/null)
    [ -n "$sys_contact" ] && echo -e "  ${GREEN}[+]${RESET} Contato do Sistema: $sys_contact" && log "sysContact: $sys_contact"

    local sys_uptime
    sys_uptime=$(snmpget -v 2c -c "$COMMUNITY" -Ovq "$TARGET" 1.3.6.1.2.1.1.3.0 2>/dev/null)
    [ -n "$sys_uptime" ] && echo -e "  ${GREEN}[+]${RESET} Tempo de Atividade do Sistema: $sys_uptime"

    local sys_services
    sys_services=$(snmpget -v 2c -c "$COMMUNITY" -Ovq "$TARGET" 1.3.6.1.2.1.1.7.0 2>/dev/null)
    [ -n "$sys_services" ] && echo -e "  ${GREEN}[+]${RESET} Serviços do Sistema: $sys_services"
}

mib_walk_interfaces() {
    echo ""
    echo -e "${YELLOW}[*] MIB Walk - Interfaces de Rede${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    local if_number
    if_number=$(snmpget -v 2c -c "$COMMUNITY" -Ovq "$TARGET" 1.3.6.1.2.1.2.1.0 2>/dev/null)
    [ -n "$if_number" ] && echo -e "  ${GREEN}[+]${RESET} Número de interfaces: $if_number"

    local if_table
    if_table=$(timeout 10 snmpwalk -v 2c -c "$COMMUNITY" -Ovq "$TARGET" 1.3.6.1.2.1.2.2.1.2 2>/dev/null)
    if [ -n "$if_table" ]; then
        while IFS= read -r line; do
            local idx desc
            idx=$(echo "$line" | grep -oP '^\d+')
            desc=$(echo "$line" | sed 's/^\d+\s*//')
            echo -e "  ${GREEN}[+]${RESET} Interface $idx: $desc"
        done <<< "$if_table"
    fi

    local ip_table
    ip_table=$(timeout 10 snmpwalk -v 2c -c "$COMMUNITY" -Ovq "$TARGET" 1.3.6.1.2.1.4.20.1.1 2>/dev/null)
    if [ -n "$ip_table" ]; then
        echo ""
        echo -e "  ${YELLOW}[*] Endereços IP configurados:${RESET}"
        while IFS= read -r line; do
            [ -n "$line" ] && echo -e "    $line"
        done <<< "$ip_table"
    fi
}

mib_walk_processes() {
    echo ""
    echo -e "${YELLOW}[*] MIB Walk - Processos em Execução${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    local hrswrun
    hrswrun=$(timeout 10 snmpwalk -v 2c -c "$COMMUNITY" -Ovq "$TARGET" 1.3.6.1.2.1.25.4.2.1.2 2>/dev/null)
    if [ -n "$hrswrun" ]; then
        while IFS= read -r line; do
            [ -n "$line" ] && echo -e "  ${GREEN}[+]${RESET} Processo: $line"
        done <<< "$hrswrun"
    else
        echo -e "  ${YELLOW}[!] Nenhuma informação de processo disponível${RESET}"
    fi
}

mib_walk_software() {
    echo ""
    echo -e "${YELLOW}[*] MIB Walk - Software Instalado${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    local software
    software=$(timeout 15 snmpwalk -v 2c -c "$COMMUNITY" -Ovq "$TARGET" 1.3.6.1.2.1.25.6.3.1.2 2>/dev/null)
    if [ -n "$software" ]; then
        while IFS= read -r line; do
            [ -n "$line" ] && echo -e "  ${GREEN}[+]${RESET} Software: $line"
        done <<< "$software"
    else
        echo -e "  ${YELLOW}[!] Nenhum inventário de software disponível${RESET}"
    fi
}

mib_walk_ports() {
    echo ""
    echo -e "${YELLOW}[*] MIB Walk - Portas TCP/UDP Abertas${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    echo "  ${YELLOW}[*] Portas de escuta TCP:${RESET}"
    local tcp_listen
    tcp_listen=$(timeout 10 snmpwalk -v 2c -c "$COMMUNITY" -Ovq "$TARGET" 1.3.6.1.2.1.6.13.1.1 2>/dev/null)
    if [ -n "$tcp_listen" ]; then
        while IFS= read -r line; do
            [ -n "$line" ] && echo -e "    $line"
        done <<< "$tcp_listen"
    else
        echo -e "    ${YELLOW}[!] Não disponível${RESET}"
    fi

    echo ""
    echo "  ${YELLOW}[*] Portas de escuta UDP:${RESET}"
    local udp_listen
    udp_listen=$(timeout 10 snmpwalk -v 2c -c "$COMMUNITY" -Ovq "$TARGET" 1.3.6.1.2.1.7.5.1.1 2>/dev/null)
    if [ -n "$udp_listen" ]; then
        while IFS= read -r line; do
            [ -n "$line" ] && echo -e "    $line"
        done <<< "$udp_listen"
    else
        echo -e "    ${YELLOW}[!] Não disponível${RESET}"
    fi
}

mib_walk_users() {
    echo ""
    echo -e "${YELLOW}[*] MIB Walk - Contas de Usuário${RESET}"
    echo -e "${CYAN}----------------------------------------${RESET}"

    local users
    users=$(timeout 10 snmpwalk -v 2c -c "$COMMUNITY" -Ovq "$TARGET" 1.3.6.1.4.1.77.1.2.25 2>/dev/null)
    if [ -n "$users" ]; then
        while IFS= read -r line; do
            [ -n "$line" ] && echo -e "  ${GREEN}[+]${RESET} Usuário: $line"
        done <<< "$users"
    else
        echo -e "  ${YELLOW}[!] Nenhuma informação de usuário via SAM${RESET}"
    fi

    local hr_users
    hr_users=$(timeout 10 snmpwalk -v 2c -c "$COMMUNITY" -Ovq "$TARGET" 1.3.6.1.2.1.25.4.2.1.2 2>/dev/null | head -20)
}

display_sections() {
    echo ""
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${CYAN}  Informações Descobertas via SNMP${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    echo ""

    if [ -z "$COMMUNITY" ]; then
        echo -e "${RED}[!] Nenhuma string de comunidade disponível - sem dados para exibir${RESET}"
        return
    fi

    mib_walk_system
    mib_walk_interfaces
    mib_walk_processes
    mib_walk_software
    mib_walk_ports
    mib_walk_users

    echo ""
    echo -e "${YELLOW}[!] Nota de Segurança:${RESET}"
    echo -e "  Se a string de comunidade é padrão (public/private), o dispositivo"
    echo -e "  expõe informações detalhadas do sistema para qualquer pessoa na rede."
}

export_results() {
    echo ""
    echo -e "${YELLOW}[*] Exportar resultados${RESET}"
    echo ""
    echo "  1) Salvar em arquivo"
    echo "  2) Pular"
    echo ""

    while true; do
        echo -n "Selecione (1-2): "
        read choice
        case "$choice" in
            1)
                local outfile="$AUDIT_DIR/snmp_audit_$(date +%Y%m%d_%H%M%S).txt"
                {
                    echo "=================================================="
                    echo "  Relatório de Auditoria SNMP"
                    echo "  Alvo: $TARGET"
                    echo "  Data: $(date)"
                    echo "=================================================="
                    echo ""
                    echo "UDP 161 Aberta: $SNMP_PORT_OPEN"
                    echo "String de Comunidade: $COMMUNITY"
                    echo "Versões SNMP: $SNMP_VERSION"
                    echo ""
                    echo "--- Informações do Sistema ---"
                    snmpget -v 2c -c "$COMMUNITY" -Ovq "$TARGET" 1.3.6.1.2.1.1.1.0 2>/dev/null
                    snmpget -v 2c -c "$COMMUNITY" -Ovq "$TARGET" 1.3.6.1.2.1.1.5.0 2>/dev/null
                    snmpget -v 2c -c "$COMMUNITY" -Ovq "$TARGET" 1.3.6.1.2.1.1.6.0 2>/dev/null
                    echo ""
                    echo "--- Interfaces ---"
                    timeout 10 snmpwalk -v 2c -c "$COMMUNITY" -Ovq "$TARGET" 1.3.6.1.2.1.2.2.1.2 2>/dev/null
                } > "$outfile"
                echo -e "${GREEN}[+] Relatório salvo em: $outfile${RESET}"
                log "Report saved to $outfile"
                OUTPUT_FILE="$outfile"
                break
                ;;
            2)
                echo -e "${YELLOW}[!] Pulando exportação${RESET}"
                break
                ;;
            *) echo -e "${RED}Opção inválida${RESET}" ;;
        esac
    done
}

main() {
    log "=== START SNMP Audit ==="
    show_banner "SNMP Auditor"
    show_disclaimer
    check_deps "snmpwalk" "snmpget" "nmap"

    step "Digite o alvo"
    enter_target

    step "Verificação da porta UDP 161"
    check_udp_161
    ! $SNMP_PORT_OPEN && exit 1

    step "Descoberta de string de comunidade"
    brute_community

    step "Detecção de versão SNMP"
    [ -n "$COMMUNITY" ] && detect_snmp_version

    step "MIB walk e coleta de dados"
    display_sections

    step "Exportar resultados"
    export_results

    echo ""
    log "=== END SNMP Audit ==="
    save_resumo "Alvo: $TARGET
Porta UDP 161 aberta: $SNMP_PORT_OPEN
Community string: $COMMUNITY
Versões SNMP: $SNMP_VERSION
Arquivo de resultados: ${OUTPUT_FILE:-N/A}"
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${GREEN}  Auditoria SNMP concluída!${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    if [ -n "$OUTPUT_FILE" ]; then
        echo -e "  Relatório: $OUTPUT_FILE"
    fi
    echo -e "${CYAN}================================================${RESET}"
}

main
