#!/usr/bin/env bash

set -uo pipefail

source "$(dirname "$0")/../utils/common.sh"

# =============================================================================
#  Log Auditor - System & Service Log Analysis Tool
#  Interactive script for analyzing security-relevant log entries
# =============================================================================
#  LEGAL DISCLAIMER:
#  This script is for educational purposes and authorized security auditing only.
#  Use only on systems you own or have explicit permission to audit.
#  The author is not responsible for any misuse.
# =============================================================================

LOG_SOURCE=""
LOG_PATH=""
ANALYSIS_TYPE=""
SYSLOG_CMD=""
HAS_SUDO=false
FINDINGS=()
REPORT_FILE=""

declare -A SEV_COLORS=(
    ["HIGH"]="\e[31m"
    ["MEDIUM"]="\e[33m"
    ["LOW"]="\e[93m"
    ["INFO"]="\e[36m"
)

cleanup() {
    echo -e "\n${YELLOW}[!] Limpando...${RESET}"
    cleanup_temp
    log "Limpeza realizada"
}
trap cleanup EXIT

check_sudo_access() {
    if command -v sudo &>/dev/null && sudo -n true 2>/dev/null; then
        HAS_SUDO=true
    fi
}

read_file() {
    local path="$1"
    if [ ! -r "$path" ] && $HAS_SUDO; then
        sudo cat "$path" 2>/dev/null
    elif [ -r "$path" ]; then
        cat "$path"
    else
        echo ""
    fi
}

select_log_source() {
    step "Selecione a fonte de log"
    echo ""
    echo -e "${YELLOW}[*] Escolha a fonte de log:${RESET}"
    echo ""
    echo "  1) Log do sistema (/var/log/syslog ou journalctl)"
    echo "  2) Log de autenticação (/var/log/auth.log ou journalctl -u ssh)"
    echo "  3) Log de acesso do servidor web (Apache/Nginx)"
    echo "  4) Caminho personalizado de arquivo de log"
    echo ""

    local src_attempts=0
    while [ $src_attempts -lt 10 ]; do
        echo -n "Selecione (1-4): "
        read LOG_SOURCE || true
        case "$LOG_SOURCE" in
            1)
                if [ -f /var/log/syslog ] && [ -r /var/log/syslog ]; then
                    LOG_PATH="/var/log/syslog"
                elif $HAS_SUDO && [ -f /var/log/syslog ]; then
                    LOG_PATH="/var/log/syslog"
                elif command -v journalctl &>/dev/null; then
                    SYSLOG_CMD="journalctl --no-pager -n 5000"
                fi
                if [ -z "$LOG_PATH" ] && [ -z "$SYSLOG_CMD" ]; then
                    echo -e "${RED}[!] Log do sistema não acessível${RESET}"
                    src_attempts=$((src_attempts + 1))
                    continue
                fi
                echo -e "${GREEN}[+] Fonte: Log do sistema${RESET}"
                break
                ;;
            2)
                if [ -f /var/log/auth.log ] && ([ -r /var/log/auth.log ] || $HAS_SUDO); then
                    LOG_PATH="/var/log/auth.log"
                elif command -v journalctl &>/dev/null; then
                    SYSLOG_CMD="journalctl --no-pager -u ssh -n 5000"
                else
                    echo -e "${RED}[!] Log de autenticação não acessível${RESET}"
                    src_attempts=$((src_attempts + 1))
                    continue
                fi
                echo -e "${GREEN}[+] Fonte: Log de autenticação${RESET}"
                break
                ;;
            3)
                local found=false
                for wl in /var/log/apache2/access.log /var/log/httpd/access_log /var/log/nginx/access.log; do
                    if [ -f "$wl" ] && ([ -r "$wl" ] || $HAS_SUDO); then
                        LOG_PATH="$wl"
                        echo -e "${GREEN}[+] Fonte: $wl${RESET}"
                        found=true
                        break
                    fi
                done
                if ! $found; then
                    echo -e "${RED}[!] Nenhum log de servidor web encontrado nos locais padrão${RESET}"
                    echo -e "${YELLOW}[*] Use a opção 4 para especificar um caminho personalizado${RESET}"
                    src_attempts=$((src_attempts + 1))
                    continue
                fi
                break
                ;;
            4)
                local path_attempts=0
                while [ $path_attempts -lt 5 ]; do
                    echo -n "Caminho do arquivo de log: "
                    read custom_path || true
                    custom_path="${custom_path/#\~/$HOME}"
                    if [ -f "$custom_path" ] && ([ -r "$custom_path" ] || $HAS_SUDO); then
                        LOG_PATH="$custom_path"
                        echo -e "${GREEN}[+] Fonte: $custom_path${RESET}"
                        break 2
                    fi
                    echo -e "${RED}Arquivo não encontrado ou não legível${RESET}"
                    path_attempts=$((path_attempts + 1))
                done
                src_attempts=$((src_attempts + 1))
                ;;
            *) echo -e "${RED}Opção inválida${RESET}"
               src_attempts=$((src_attempts + 1)) ;;
        esac
    done
}

select_analysis_type() {
    step "Selecione o tipo de análise"
    echo ""
    echo -e "${YELLOW}[*] Escolha a análise:${RESET}"
    echo ""
    echo "  1) Tentativas de login falhas"
    echo "  2) Endereços IP suspeitos"
    echo "  3) Eventos de falha/reinicialização de serviços"
    echo "  4) Histórico de conexões de rede"
    echo "  5) Todas as anteriores"
    echo ""

    local at_attempts=0
    while [ $at_attempts -lt 10 ]; do
        echo -n "Selecione (1-5): "
        read ANALYSIS_TYPE || true
        case "$ANALYSIS_TYPE" in
            1|2|3|4|5) break ;;
            *) echo -e "${RED}Opção inválida${RESET}"
               at_attempts=$((at_attempts + 1)) ;;
        esac
    done

    echo -e "${GREEN}[+] Tipo de análise: $ANALYSIS_TYPE${RESET}"
}

get_log_content() {
    if [ -n "$SYSLOG_CMD" ]; then
        if $HAS_SUDO; then
            sudo bash -c "$SYSLOG_CMD" 2>/dev/null
        else
            bash -c "$SYSLOG_CMD" 2>/dev/null
        fi
    elif [ -n "$LOG_PATH" ]; then
        read_file "$LOG_PATH"
    fi
}

analyze_failed_logins() {
    echo ""
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${CYAN}  Análise de Logins Falhos${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    echo ""

    local log_data
    log_data=$(get_log_content)
    if [ -z "$log_data" ]; then
        echo -e "${YELLOW}[!] Nenhum dado de log disponível${RESET}"
        return
    fi

    echo -e "${CYAN}--- Tentativas SSH Falhas ---${RESET}"
    echo ""
    local failed_ssh
    failed_ssh=$(echo "$log_data" | grep -i "Failed password\|authentication failure" | head -100)
    if [ -n "$failed_ssh" ]; then
        local total
        total=$(echo "$failed_ssh" | wc -l)
        echo -e "  ${RED}Total de tentativas falhas: $total${RESET}"
        echo ""
        echo -e "${CYAN}--- Top 10 IPs Atacantes ---${RESET}"
        echo ""
        local ips
        ips=$(echo "$failed_ssh" | grep -oP '\d+\.\d+\.\d+\.\d+' | sort | uniq -c | sort -rn | head -10)
        if [ -n "$ips" ]; then
            printf "${BOLD}%-10s %s${RESET}\n" "Tentativas" "Endereço IP"
            echo "------------------------"
            while IFS= read -r line; do
                local count ip
                count=$(echo "$line" | awk '{print $1}')
                ip=$(echo "$line" | awk '{print $2}')
                if [ "$count" -gt 10 ]; then
                    printf "${RED}%-10s %s${RESET}\n" "$count" "$ip"
                    FINDINGS+=("HIGH|$count tentativas SSH falhas de $ip")
                elif [ "$count" -gt 5 ]; then
                    printf "${YELLOW}%-10s %s${RESET}\n" "$count" "$ip"
                    FINDINGS+=("MEDIUM|$count tentativas SSH falhas de $ip")
                else
                    printf "%-10s %s\n" "$count" "$ip"
                fi
            done <<< "$ips"
        fi
        echo ""

        echo -e "${CYAN}--- Padrões de Timestamp ---${RESET}"
        echo ""
        local times
        times=$(echo "$failed_ssh" | grep -oP '(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+\d+\s+\d{2}:\d{2}' | sort -k1,2 | uniq -c | head -15)
        if [ -n "$times" ]; then
            echo "  Períodos de maior atividade:"
            while IFS= read -r line; do
                echo "    $line"
            done <<< "$times"
        fi
    else
        echo -e "  ${GREEN}[+] Nenhuma tentativa de login SSH falha encontrada${RESET}"
    fi

    echo ""
    echo -e "${CYAN}--- Tentativas sudo/su ---${RESET}"
    echo ""
    local sudo_attempts
    sudo_attempts=$(echo "$log_data" | grep -i "sudo\|su:" | grep -iv "session\|COMMAND" | head -30)
    if [ -n "$sudo_attempts" ]; then
        local sudo_count
        sudo_count=$(echo "$sudo_attempts" | wc -l)
        echo -e "  ${YELLOW}Encontradas $sudo_count entradas sudo/su${RESET}"
        echo ""
        echo "$sudo_attempts" | while IFS= read -r line; do
            echo "    $line"
        done
    else
        echo -e "  ${GREEN}[+] Nenhuma falha sudo/su encontrada${RESET}"
    fi
}

analyze_suspicious_ips() {
    echo ""
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${CYAN}  Análise de Endereços IP Suspeitos${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    echo ""

    local log_data
    log_data=$(get_log_content)
    if [ -z "$log_data" ]; then
        echo -e "${YELLOW}[!] Nenhum dado de log disponível${RESET}"
        return
    fi

    local all_ips
    all_ips=$(echo "$log_data" | grep -oP '\d+\.\d+\.\d+\.\d+' | sort | uniq -c | sort -rn | head -20)

    if [ -z "$all_ips" ]; then
        echo -e "${YELLOW}[!] Nenhum endereço IP encontrado nos logs${RESET}"
        return
    fi

    printf "${BOLD}%-10s %-16s %s${RESET}\n" "Contagem" "IP" "Risco"
    echo "----------------------------------------"
    while IFS= read -r line; do
        local cnt ip
        cnt=$(echo "$line" | awk '{print $1}')
        ip=$(echo "$line" | awk '{print $2}')
        local risk="BAIXO"
        if [ "$cnt" -gt 50 ]; then
            risk="${RED}ALTO${RESET}"
        elif [ "$cnt" -gt 20 ]; then
            risk="${YELLOW}MÉDIO${RESET}"
        else
            risk="${GREEN}BAIXO${RESET}"
        fi
        printf "%-10s %-16s %b\n" "$cnt" "$ip" "$risk"
    done <<< "$all_ips"
}

analyze_crashes() {
    echo ""
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${CYAN}  Análise de Falhas de Sistema${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    echo ""

    local log_data
    log_data=$(get_log_content)
    if [ -z "$log_data" ]; then
        echo -e "${YELLOW}[!] Nenhum dado de log disponível${RESET}"
        return
    fi

    local crash_events
    crash_events=$(echo "$log_data" | grep -i "segfault\|panic\|oom\b\|killed process\|call trace\|\bCore was generated\|segmentation fault\|general protection fault\|soft lockup\|hung_task\|kernel BUG" | head -50)
    if [ -n "$crash_events" ]; then
        local crash_count
        crash_count=$(echo "$crash_events" | wc -l)
        echo -e "  ${RED}Encontrados $crash_count eventos potenciais de falha/erro${RESET}"
        echo ""
        echo "$crash_events" | while IFS= read -r line; do
            echo "    $line"
        done
    else
        echo -e "  ${GREEN}[+] Nenhum evento de falha/erro encontrado${RESET}"
    fi

    echo ""
    echo -e "${CYAN}--- Eventos de Serviço (inclui reinicializações agendadas) ---${RESET}"
    echo ""
    local restarts
    restarts=$(echo "$log_data" | grep -i "starting\|stopped\|restart\|reload\|failed to start\|failed to stop\|not running" | head -30)
    if [ -n "$restarts" ]; then
        echo "$restarts" | while IFS= read -r line; do
            echo "    $line"
        done
    else
        echo -e "  ${GREEN}[+] Nenhum evento de reinicialização encontrado${RESET}"
    fi
}

analyze_network() {
    echo ""
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${CYAN}  Histórico de Conexões de Rede${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    echo ""

    echo -e "${CYAN}--- Portas em Escuta Atuais ---${RESET}"
    echo ""
    if command -v ss &>/dev/null; then
        local listening
        listening=$(ss -tlnp 2>/dev/null)
        if [ -n "$listening" ]; then
            echo "$listening" | head -30
        else
            echo -e "${YELLOW}[!] Não foi possível obter portas em escuta${RESET}"
        fi
    elif command -v netstat &>/dev/null; then
        netstat -tlnp 2>/dev/null | head -30 || echo -e "${YELLOW}[!] Não foi possível obter portas em escuta${RESET}"
    else
        echo -e "${YELLOW}[!] Nem ss nem netstat disponíveis${RESET}"
    fi
    echo ""

    echo -e "${CYAN}--- Conexões Atuais ---${RESET}"
    echo ""
    if command -v ss &>/dev/null; then
        local connections
        connections=$(ss -tupn 2>/dev/null)
        if [ -n "$connections" ]; then
            echo "$connections" | head -30
        else
            echo -e "${YELLOW}[!] Nenhuma conexão ativa${RESET}"
        fi
    elif command -v netstat &>/dev/null; then
        netstat -tupn 2>/dev/null | head -30 || echo -e "${YELLOW}[!] Nenhuma conexão ativa${RESET}"
    fi
    echo ""

    echo -e "${CYAN}--- Resumo de Conexões ---${RESET}"
    echo ""
    if command -v ss &>/dev/null; then
        local total_est total_listen
        total_est=$(ss -tupn 2>/dev/null | grep -c "ESTAB" || echo 0)
        total_listen=$(ss -tlnp 2>/dev/null | grep -c "LISTEN" || echo 0)
        echo -e "  Conexões estabelecidas: $total_est"
        echo -e "  Serviços em escuta:     $total_listen"
    fi
}

generate_security_summary() {
    step "Resumo de segurança"
    echo ""

    echo -e "${CYAN}================================================${RESET}"
    echo -e "${CYAN}  Resumo de Segurança${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    echo ""

    if [ ${#FINDINGS[@]} -eq 0 ]; then
        echo -e "  ${GREEN}[+] Nenhum evento de segurança significativo detectado${RESET}"
    else
        echo -e "  ${YELLOW}Achados:${RESET}"
        echo ""
        for f in "${FINDINGS[@]}"; do
            local sev="${f%%|*}"
            local msg="${f#*|}"
            echo -e "  ${SEV_COLORS[$sev]}[$sev]${RESET} $msg"
        done
    fi
    echo ""

    echo "  1) Gerar e salvar relatório"
    echo "  2) Pular"
    echo ""

    local report_attempts=0
    while [ $report_attempts -lt 10 ]; do
        echo -n "Selecione (1-2): "
        read choice || true
        case "$choice" in
            1)
                local outfile="$AUDIT_DIR/log_audit_$(date +%Y%m%d_%H%M%S).txt"
                {
                    echo "=================================================="
                    echo "  Relatório de Auditoria de Logs"
                    echo "  Data: $(date)"
                    echo "=================================================="
                    echo ""
                    echo "Fonte de Log: $LOG_SOURCE"
                    [ -n "$LOG_PATH" ] && echo "Caminho: $LOG_PATH"
                    echo "Análise: $ANALYSIS_TYPE"
                    echo ""
                    echo "--- Achados ---"
                    for f in "${FINDINGS[@]}"; do
                        echo "[${f%%|*}] ${f#*|}"
                    done
                    echo ""
                    echo "--- Resumo ---"
                    echo "Análise concluída com ${#FINDINGS[@]} achados."
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
               report_attempts=$((report_attempts + 1)) ;;
        esac
    done
}

run_analyses() {
    case "$ANALYSIS_TYPE" in
        1) analyze_failed_logins ;;
        2) analyze_suspicious_ips ;;
        3) analyze_crashes ;;
        4) analyze_network ;;
        5)
            analyze_failed_logins
            analyze_suspicious_ips
            analyze_crashes
            analyze_network
            ;;
    esac
}

main() {
    log "=== INÍCIO Auditoria de Logs ==="
    show_banner "Log Auditor"
    show_disclaimer

    check_sudo_access

    select_log_source

    select_analysis_type

    step "Executando análise"
    run_analyses

    generate_security_summary

    echo ""
    log "=== FIM Auditoria de Logs ==="
    local findings_resumo=""
    for f in "${FINDINGS[@]}"; do findings_resumo+="  $f"$'\n'; done
    save_resumo "Fonte de log: $LOG_SOURCE
Caminho: ${LOG_PATH:-journalctl}
Tipo de análise: $ANALYSIS_TYPE
Achados: ${#FINDINGS[@]}
$findings_resumo
Relatório: ${REPORT_FILE:-N/A}"
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${GREEN}  Auditoria de logs concluída!${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    if [ -n "$REPORT_FILE" ]; then
        echo -e "  Relatório: $REPORT_FILE"
    fi
    echo -e "${CYAN}================================================${RESET}"
}

main
