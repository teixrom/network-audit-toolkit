#!/usr/bin/env bash

set -uo pipefail

source "$(dirname "$0")/../utils/common.sh"

# =============================================================================
#  Configuration Auditor - Network Device Config Analysis Tool
#  Analyzes simulated switch/router configuration files for security issues
# =============================================================================
#  LEGAL DISCLAIMER:
#  This script is for educational purposes and authorized security testing only.
#  Unauthorized use against networks you do not own or have explicit permission
#  to test is illegal. The author is not responsible for any misuse.
# =============================================================================

SAMPLE_CONFIG="
hostname Core-Switch
enable password admin
username admin password admin
username cisco password cisco
username operator password password
!
interface vlan 1
 ip address 192.168.1.1 255.255.255.0
 no shutdown
!
line vty 0 4
 password cisco
 login
 transport input telnet
!
line con 0
 password cisco
 login
!
snmp-server community public RO
snmp-server community private RW
snmp-server enable traps
snmp-server host 192.168.1.100 public
!
ip http server
ip http port 80
!
access-list 100 permit ip any any
access-list 101 permit tcp any host 10.0.0.1 eq 22
access-list 101 permit tcp any host 10.0.0.2 eq 443
access-list 102 deny ip host 10.0.0.5 any
!
interface GigabitEthernet0/1
 ip access-group 100 in
!
ip ssh version 1
ip domain-name network.local
crypto key generate rsa
!
ip route 0.0.0.0 0.0.0.0 192.168.1.254
!
logging buffered 4096
logging console warnings
!
ntp server 192.168.1.100
!

interface GigabitEthernet0/2
 description link-to-branch
 ip address 10.0.1.1 255.255.255.252
 no shutdown
!
line vty 5 15
 password cisco
 login
 transport input ssh
!
no ip domain-lookup
!
banner motd ^C
Unauthorized access prohibited
^C
"

CONFIG_PATH=""
CONFIG_CONTENT=""
REPORT_FILE=""
FINDINGS=()

CLEANUP_TEMP=""

cleanup() {
    echo -e "\n${YELLOW}[!] Limpando...${RESET}"
    cleanup_temp
    log "Cleanup performed"
}
trap cleanup EXIT

load_config() {
    step "Carregar arquivo de configuração"
    echo ""
    echo -e "${YELLOW}[*] Selecione a fonte do arquivo de configuração:${RESET}"
    echo ""
    echo "  1) Usar configuração simulada padrão (embutida)"
    echo "  2) Informar caminho de um arquivo de configuração"
    echo ""

    while true; do
        echo -n "Selecione (1-2): "
        read choice
        case "$choice" in
            1)
                CONFIG_CONTENT="$SAMPLE_CONFIG"
                echo -e "${GREEN}[+] Usando configuração simulada padrão${RESET}"
                log "Usando configuração simulada padrão"
                break
                ;;
            2)
                while true; do
                    echo -n "Caminho do arquivo: "
                    read custom_path
                    custom_path="${custom_path/#\~/$HOME}"
                    if [ -f "$custom_path" ] && [ -r "$custom_path" ]; then
                        CONFIG_CONTENT=$(cat "$custom_path")
                        CONFIG_PATH="$custom_path"
                        echo -e "${GREEN}[+] Configuração carregada de: $custom_path${RESET}"
                        log "Configuracao carregada de $custom_path"
                        break 2
                    fi
                    echo -e "${RED}Arquivo não encontrado ou não legível${RESET}"
                done
                ;;
            *) echo -e "${RED}Opção inválida${RESET}" ;;
        esac
    done
}

check_default_passwords() {
    step "Verificar senhas padrão"
    echo ""
    echo -e "${CYAN}--- Buscando credenciais padrão/padrão ---${RESET}"
    echo ""

    local found=false

    if echo "$CONFIG_CONTENT" | grep -qi "password admin\|username.*admin.*password.*admin"; then
        echo -e "  ${RED}[ALTO] Senha 'admin' detectada (configuração padrão)${RESET}"
        FINDINGS+=("ALTO|Senha 'admin' detectada")
        found=true
    fi

    if echo "$CONFIG_CONTENT" | grep -qi "password cisco\|username.*cisco.*password"; then
        echo -e "  ${RED}[ALTO] Senha 'cisco' detectada (configuração padrão)${RESET}"
        FINDINGS+=("ALTO|Senha 'cisco' detectada")
        found=true
    fi

    if echo "$CONFIG_CONTENT" | grep -qi "password password\|username.*password.*password"; then
        echo -e "  ${RED}[ALTO] Senha 'password' detectada (configuração padrão)${RESET}"
        FINDINGS+=("ALTO|Senha 'password' detectada")
        found=true
    fi

    if echo "$CONFIG_CONTENT" | grep -qi "enable password\|enable secret 5\|enable secret 4"; then
        local enable_pw
        enable_pw=$(echo "$CONFIG_CONTENT" | grep -i "enable password\|enable secret" | head -3)
        echo -e "  ${YELLOW}[MÉDIO] Senha enable configurada: $enable_pw${RESET}"
        FINDINGS+=("MEDIO|Senha enable encontrada - verificar complexidade")
        found=true
    fi

    local snmp_count
    snmp_count=$(echo "$CONFIG_CONTENT" | grep -ci "snmp-server community")
    if [ "$snmp_count" -gt 0 ]; then
        echo -e "  ${YELLOW}[MÉDIO] $snmp_count comunidades SNMP encontradas (verificar se são padrão)${RESET}"
        FINDINGS+=("MEDIO|$snmp_count comunidades SNMP encontradas")
        found=true
    fi

    if ! $found; then
        echo -e "  ${GREEN}[+] Nenhuma credencial padrão óbvia encontrada${RESET}"
    fi
}

check_insecure_protocols() {
    step "Identificar protocolos inseguros"
    echo ""
    echo -e "${CYAN}--- Verificando protocolos inseguros ---${RESET}"
    echo ""

    local found=false

    if echo "$CONFIG_CONTENT" | grep -qi "transport input telnet"; then
        echo -e "  ${RED}[ALTO] Telnet habilitado (protocolo inseguro - substituir por SSH)${RESET}"
        FINDINGS+=("ALTO|Telnet habilitado - substituir por SSH")
        found=true
    fi

    if echo "$CONFIG_CONTENT" | grep -qi "ip http server"; then
        echo -e "  ${YELLOW}[MÉDIO] Servidor HTTP habilitado (usar HTTPS se possível)${RESET}"
        FINDINGS+=("MEDIO|Servidor HTTP habilitado")
        found=true
    fi

    if echo "$CONFIG_CONTENT" | grep -qi "snmp-server community.*RO\|snmp-server community.*RW"; then
        local snmp_ver
        snmp_ver=$(echo "$CONFIG_CONTENT" | grep -i "snmp-server" | head -1)
        echo -e "  ${YELLOW}[MÉDIO] SNMP v1/v2c detectado (usar SNMPv3 com criptografia)${RESET}"
        FINDINGS+=("MEDIO|SNMP v1/v2c detectado - migrar para SNMPv3")
        found=true
    fi

    if echo "$CONFIG_CONTENT" | grep -qi "ip ssh version 1"; then
        echo -e "  ${RED}[ALTO] SSH versão 1 habilitado (versão insegura - usar SSH v2)${RESET}"
        FINDINGS+=("ALTO|SSH v1 habilitado - migrar para SSH v2")
        found=true
    fi

    if echo "$CONFIG_CONTENT" | grep -qi "service dhcp"; then
        echo -e "  ${YELLOW}[MÉDIO] Serviço DHCP habilitado no equipamento${RESET}"
        FINDINGS+=("MEDIO|Servico DHCP habilitado")
        found=true
    fi

    if ! $found; then
        echo -e "  ${GREEN}[+] Nenhum protocolo inseguro detectado${RESET}"
    fi
}

check_permissive_rules() {
    step "Alertar sobre regras de firewall permissivas"
    echo ""
    echo -e "${CYAN}--- Verificando regras de acesso permissivas ---${RESET}"
    echo ""

    local found=false

    local any_any
    any_any=$(echo "$CONFIG_CONTENT" | grep -i "access-list.*any any" | grep -i permit)
    if [ -n "$any_any" ]; then
        echo -e "  ${RED}[ALTO] Regra 'permit any any' encontrada (extremamente permissiva):${RESET}"
        while IFS= read -r line; do
            echo -e "    ${RED}$line${RESET}"
        done <<< "$any_any"
        local count
        count=$(echo "$any_any" | wc -l)
        FINDINGS+=("ALTO|$count regra(s) 'permit any any' encontrada(s)")
        found=true
    fi

    local permit_any
    permit_any=$(echo "$CONFIG_CONTENT" | grep -i "permit ip any\|permit tcp any\|permit udp any\|permit icmp any")
    if [ -n "$permit_any" ]; then
        echo -e "  ${YELLOW}[MÉDIO] Regras 'permit any' detectadas (revisar necessidade):${RESET}"
        while IFS= read -r line; do
            echo -e "    ${YELLOW}$line${RESET}"
        done <<< "$permit_any"
        found=true
    fi

    local implicit_deny
    implicit_deny=$(echo "$CONFIG_CONTENT" | grep -ci "access-list.*deny any any")
    if [ "$implicit_deny" -eq 0 ] && echo "$CONFIG_CONTENT" | grep -qi "access-list"; then
        if echo "$CONFIG_CONTENT" | grep -qi "access-list 100\|access-list 101\|access-list 102\|ip access-group"; then
            echo -e "  ${YELLOW}[MÉDIO] ACLs configuradas sem 'deny any any' explícito (depende de deny implícito)${RESET}"
            FINDINGS+=("MEDIO|ACLs sem deny any any explicito")
            found=true
        fi
    fi

    if ! $found; then
        echo -e "  ${GREEN}[+] Nenhuma regra excessivamente permissiva encontrada${RESET}"
    fi
}

show_summary() {
    step "Resumo dos achados"
    echo ""
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${CYAN}  Sumário da Auditoria de Configuração${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    echo ""

    local alto=0 medio=0

    for f in "${FINDINGS[@]}"; do
        local sev="${f%%|*}"
        local msg="${f#*|}"
        if [ "$sev" = "ALTO" ]; then
            alto=$((alto + 1))
        elif [ "$sev" = "MEDIO" ]; then
            medio=$((medio + 1))
        fi
    done

    local total=$((alto + medio))

    echo -e "  ${BOLD}Total de achados: $total${RESET}"
    echo ""
    echo -e "  ${RED}Alta prioridade:   $alto${RESET}"
    echo -e "  ${YELLOW}Média prioridade:  $medio${RESET}"
    echo ""

    if [ "$total" -gt 0 ]; then
        echo -e "${BOLD}Detalhamento:${RESET}"
        echo ""
        for f in "${FINDINGS[@]}"; do
            local sev="${f%%|*}"
            local msg="${f#*|}"
            if [ "$sev" = "ALTO" ]; then
                echo -e "  ${RED}[$sev]${RESET} $msg"
            else
                echo -e "  ${YELLOW}[$sev]${RESET} $msg"
            fi
        done
        echo ""
    fi

    echo -e "${BOLD}Recomendações:${RESET}"
    echo ""
    if [ "$alto" -gt 0 ]; then
        echo -e "  - Remover senhas padrão e substituir por senhas fortes"
    fi
    if echo "$CONFIG_CONTENT" | grep -qi "transport input telnet"; then
        echo -e "  - Substituir Telnet por SSH em todas as linhas VTY"
    fi
    if echo "$CONFIG_CONTENT" | grep -qi "snmp-server community"; then
        echo -e "  - Migrar SNMP para v3 com autenticação e criptografia"
    fi
    if echo "$CONFIG_CONTENT" | grep -qi "ip ssh version 1"; then
        echo -e "  - Configurar SSH versão 2 (ip ssh version 2)"
    fi
    if echo "$CONFIG_CONTENT" | grep -qi "access-list.*any any" | grep -qi permit; then
        echo -e "  - Restringir ACLs permissivas com regras mais específicas"
    fi
    echo -e "  - Auditar regularmente as configurações dos equipamentos"
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
                local outfile="$AUDIT_DIR/config_audit_$(date +%Y%m%d_%H%M%S).txt"
                {
                    echo "=================================================="
                    echo "  Relatório de Auditoria de Configuração"
                    echo "  Data: $(date)"
                    echo "=================================================="
                    echo ""
                    echo "Fonte: ${CONFIG_PATH:-Configuração simulada padrão}"
                    echo ""
                    echo "--- Achados ---"
                    for f in "${FINDINGS[@]}"; do
                        echo "[${f%%|*}] ${f#*|}"
                    done
                    echo ""
                    local alto=0 medio=0
                    for f in "${FINDINGS[@]}"; do
                        local sev="${f%%|*}"
                        if [ "$sev" = "ALTO" ]; then
                            alto=$((alto + 1))
                        elif [ "$sev" = "MEDIO" ]; then
                            medio=$((medio + 1))
                        fi
                    done
                    echo "--- Estatísticas ---"
                    echo "Total de achados: $((alto + medio))"
                    echo "Alta prioridade: $alto"
                    echo "Média prioridade: $medio"
                    echo ""
                    echo "--- Recomendações ---"
                    echo "- Substituir senhas padrão"
                    echo "- Desabilitar protocolos inseguros (Telnet, HTTP, SNMP v1/v2)"
                    echo "- Restringir ACLs permissivas"
                    echo "- Manter firmware atualizado"
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
    log "=== INÍCIO Auditoria de Configuração ==="
    show_banner "Auditoria de Configuração"
    show_disclaimer

    load_config

    check_default_passwords

    check_insecure_protocols

    check_permissive_rules

    show_summary

    save_report

    echo ""
    log "=== FIM Auditoria de Configuração ==="

    local resumo_content="Fonte: ${CONFIG_PATH:-Configuração simulada padrão}
Total de achados: ${#FINDINGS[@]}
"
    for f in "${FINDINGS[@]}"; do
        resumo_content+="  $f"$'\n'
    done
    resumo_content+="Relatório: ${REPORT_FILE:-N/A}"

    save_resumo "$resumo_content"

    echo -e "${CYAN}================================================${RESET}"
    echo -e "${GREEN}  Auditoria de configuração concluída!${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    if [ -n "$REPORT_FILE" ]; then
        echo -e "  Relatório: $REPORT_FILE"
    fi
    echo -e "${CYAN}================================================${RESET}"
}

main
