#!/usr/bin/env bash

set -uo pipefail

source "$(dirname "$0")/../utils/common.sh"

SERVICE_LIST=""
OUTPUT_FILE=""

cleanup() {
    echo -e "\n${YELLOW}[!] Limpando...${RESET}"
    cleanup_temp
    log "Limpeza realizada"
}
trap cleanup EXIT

create_sample_file() {
    local sample="/tmp/servicos_exemplo.txt"
    cat > "$sample" << 'EOF'
80 http Apache 2.4.41
443 https Apache 2.4.41
22 ssh OpenSSH 8.0
3306 mysql MySQL 5.7.30
6379 redis Redis 6.0
5432 postgresql PostgreSQL 12.3
EOF
    echo "$sample"
}

query_searchsploit() {
    local service="$1"
    local version="$2"
    local query="$service $version"
    if command -v searchsploit &>/dev/null; then
        searchsploit --disable-colour "$query" 2>/dev/null
    fi
}

query_circl_api() {
    local product="$1"
    local url="https://cve.circl.lu/api/cvefor/${product}"
    curl -s --connect-timeout 10 --max-time 15 "$url" 2>/dev/null
}

severity_label() {
    local cvss="$1"
    local label="LOW"
    local color="GREEN"
    if (( $(echo "$cvss >= 9.0" | bc -l 2>/dev/null) )); then
        label="CRITICAL"
        color="RED"
    elif (( $(echo "$cvss >= 7.0" | bc -l 2>/dev/null) )); then
        label="HIGH"
        color="RED"
    elif (( $(echo "$cvss >= 4.0" | bc -l 2>/dev/null) )); then
        label="MEDIUM"
        color="YELLOW"
    fi
    echo "$label"
}

get_severity_color() {
    local sev="$1"
    case "$sev" in
        CRITICAL|HIGH) echo -e "${RED}" ;;
        MEDIUM) echo -e "${YELLOW}" ;;
        *) echo -e "${GREEN}" ;;
    esac
}

get_service_file() {
    step "Arquivo de servicos"
    echo ""
    echo -e "${YELLOW}[*] Informe o caminho do arquivo com a lista de servicos${RESET}"
    echo -e "${CYAN}  Formato (uma por linha): porta protocolo servico versao${RESET}"
    echo -e "${CYAN}  Exemplo: 80 http Apache 2.4.41${RESET}"
    echo ""

    while true; do
        echo -n "Caminho do arquivo (ou 0 para criar um modelo): "
        read input
        if [ "$input" = "0" ]; then
            local sample
            sample=$(create_sample_file)
            echo -e "${GREEN}[+] Arquivo modelo criado em: $sample${RESET}"
            SERVICE_LIST="$sample"
            break
        fi
        if [ -f "$input" ]; then
            SERVICE_LIST="$input"
            break
        fi
        echo -e "${RED}[!] Arquivo nao encontrado. Tente novamente ou digite 0 para criar um modelo.${RESET}"
    done

    local count
    count=$(wc -l < "$SERVICE_LIST")
    echo -e "${GREEN}[+] Total de servicos a analisar: $count${RESET}"
    log "Arquivo de servicos: $SERVICE_LIST ($count servicos)"
}

parse_cve_json() {
    local json="$1"
    echo "$json" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if isinstance(data, list):
        for item in data:
            cve_id = item.get('id', 'N/A')
            cvss = item.get('cvss', 0) or 0
            summary = item.get('summary', '')[:100]
            print(f'{cve_id}|{cvss}|{summary}')
    elif isinstance(data, dict):
        cve_id = data.get('id', 'N/A')
        cvss = data.get('cvss', 0) or 0
        summary = data.get('summary', '')[:100]
        print(f'{cve_id}|{cvss}|{summary}')
except:
    pass
" 2>/dev/null
}

analyze_services() {
    step "Analise de vulnerabilidades"
    echo ""

    local has_searchsploit=false
    if command -v searchsploit &>/dev/null; then
        has_searchsploit=true
        echo -e "${GREEN}[+] searchsploit detectado${RESET}"
        log "searchsploit disponivel"
    else
        echo -e "${YELLOW}[!] searchsploit nao encontrado - usando API Circl.lu${RESET}"
        log "searchsploit nao disponivel, usando API Circl.lu"
    fi

    local total_lines
    total_lines=$(wc -l < "$SERVICE_LIST")
    local current=0

    local all_critical=""
    local all_high=""
    local all_medium=""
    local all_low=""

    while IFS= read -r line; do
        [ -z "$line" ] && continue
        current=$((current + 1))
        progress_bar "$current" "$total_lines"

        local port proto service version
        port=$(echo "$line" | awk '{print $1}')
        proto=$(echo "$line" | awk '{print $2}')
        service=$(echo "$line" | awk '{print $3}')
        version=$(echo "$line" | awk '{print $4}')

        echo ""
        echo -e "${CYAN}--- Analisando $service $version ($port/$proto) ---${RESET}"

        local cve_results=""
        if $has_searchsploit; then
            cve_results=$(query_searchsploit "$service" "$version")
        fi

        local api_results=""
        if [ -z "$cve_results" ] || ! $has_searchsploit; then
            api_results=$(query_circl_api "$service" 2>/dev/null)
            if [ -z "$api_results" ] || [ "$api_results" = "null" ]; then
                api_results=$(query_circl_api "${service}%20${version}" 2>/dev/null)
            fi
        fi

        if [ -z "$cve_results" ] && [ -z "$api_results" ]; then
            echo -e "${YELLOW}  [-] Nenhuma vulnerabilidade encontrada ou falha na consulta${RESET}"
            log "Nenhum resultado para $service $version"
            continue
        fi

        if [ -n "$api_results" ] && [ "$api_results" != "null" ]; then
            local parsed
            parsed=$(parse_cve_json "$api_results")
            if [ -n "$parsed" ]; then
                while IFS='|' read -r cve_id cvss summary; do
                    [ -z "$cve_id" ] && continue
                    local sev_label
                    sev_label=$(severity_label "$cvss")
                    local sev_color
                    sev_color=$(get_severity_color "$sev_label")
                    echo -e "  ${sev_color}[$sev_label]${RESET} $cve_id (CVSS: $cvss)"
                    [ -n "$summary" ] && echo -e "         ${summary}"

                    local entry="$service $version | $cve_id | CVSS: $cvss | $summary"
                    case "$sev_label" in
                        CRITICAL) all_critical="$all_critical\n$entry" ;;
                        HIGH) all_high="$all_high\n$entry" ;;
                        MEDIUM) all_medium="$all_medium\n$entry" ;;
                        *) all_low="$all_low\n$entry" ;;
                    esac
                done <<< "$parsed"
            fi
        fi

        if [ -n "$cve_results" ]; then
            echo "$cve_results" | while IFS= read -r cline; do
                [ -z "$cline" ] && continue
                echo -e "  $cline"
            done
            local searchsploit_count
            searchsploit_count=$(echo "$cve_results" | grep -c "CVE-" 2>/dev/null || echo 0)
            log "searchsploit retornou $searchsploit_count resultados para $service $version"
        fi
    done < "$SERVICE_LIST"
    echo ""

    echo -e "\n${CYAN}=== Resumo de Vulnerabilidades ===${RESET}"
    echo ""

    local has_results=false
    if [ -n "$all_critical" ]; then
        has_results=true
        echo -e "${RED}CRITICAL:${RESET}"
        while IFS= read -r cr; do
            [ -n "$cr" ] && echo -e "  ${RED}[!]${RESET} $cr"
        done <<< "$(echo -e "$all_critical")"
        echo ""
    fi
    if [ -n "$all_high" ]; then
        has_results=true
        echo -e "${RED}HIGH:${RESET}"
        while IFS= read -r hr; do
            [ -n "$hr" ] && echo -e "  ${RED}[!]${RESET} $hr"
        done <<< "$(echo -e "$all_high")"
        echo ""
    fi
    if [ -n "$all_medium" ]; then
        has_results=true
        echo -e "${YELLOW}MEDIUM:${RESET}"
        while IFS= read -r mr; do
            [ -n "$mr" ] && echo -e "  ${YELLOW}[!]${RESET} $mr"
        done <<< "$(echo -e "$all_medium")"
        echo ""
    fi
    if [ -n "$all_low" ]; then
        has_results=true
        echo -e "${GREEN}LOW:${RESET}"
        while IFS= read -r lr; do
            [ -n "$lr" ] && echo -e "  ${GREEN}[!]${RESET} $lr"
        done <<< "$(echo -e "$all_low")"
        echo ""
    fi

    if ! $has_results; then
        echo -e "${YELLOW}[-] Nenhuma vulnerabilidade encontrada ou todas as consultas falharam${RESET}"
    fi

    save_results "critical" "$all_critical"
    save_results "high" "$all_high"
    save_results "medium" "$all_medium"
    save_results "low" "$all_low"
}

save_results() {
    local severity="$1"
    local content="$2"
    if [ -n "$content" ]; then
        echo "Severidade: $severity" >> "$OUTPUT_FILE"
        echo "$content" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
}

generate_remediation() {
    step "Recomendacoes de remediacao"
    echo ""
    echo -e "${CYAN}Boas praticas gerais:${RESET}"
    echo ""
    echo -e "  ${GREEN}[*]${RESET} Mantenha todos os servicos atualizados com as ultimas versoes estaveis"
    echo -e "  ${GREEN}[*]${RESET} Aplique patches de seguranca assim que disponiveis"
    echo -e "  ${GREEN}[*]${RESET} Desative servicos e portas nao utilizados"
    echo -e "  ${GREEN}[*]${RESET} Implemente firewalls de aplicacao (WAF) para servicos web"
    echo -e "  ${GREEN}[*]${RESET} Utilize segmentacao de rede para isolar servicos criticos"
    echo -e "  ${GREEN}[*]${RESET} Configure autenticacao multifator (MFA) quando possivel"
    echo -e "  ${GREEN}[*]${RESET} Monitore logs e alertas de seguranca continuamente"
    echo -e "  ${GREEN}[*]${RESET} Realize varreduras de vulnerabilidades periodicas"
    echo -e "  ${GREEN}[*]${RESET} Siga as recomendacoes do CIS Benchmark para cada servico"
    echo -e "  ${GREEN}[*]${RESET} Estabeleca um processo formal de gestao de vulnerabilidades"
    echo ""

    {
        echo ""
        echo "--- Recomendacoes de Remediacao ---"
        echo ""
        echo "Boas praticas gerais:"
        echo "- Mantenha todos os servicos atualizados com as ultimas versoes estaveis"
        echo "- Aplique patches de seguranca assim que disponiveis"
        echo "- Desative servicos e portas nao utilizados"
        echo "- Implemente firewalls de aplicacao (WAF) para servicos web"
        echo "- Utilize segmentacao de rede para isolar servicos criticos"
        echo "- Configure autenticacao multifator (MFA) quando possivel"
        echo "- Monitore logs e alertas de seguranca continuamente"
        echo "- Realize varreduras de vulnerabilidades periodicas"
        echo "- Siga as recomendacoes do CIS Benchmark para cada servico"
        echo "- Estabeleca um processo formal de gestao de vulnerabilidades"
    } >> "$OUTPUT_FILE"
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
                OUTPUT_FILE="$AUDIT_DIR/vuln_assessment_$(date +%Y%m%d_%H%M%S).txt"
                mkdir -p "$AUDIT_DIR" 2>/dev/null
                {
                    echo "=================================================="
                    echo "  Relatorio - Avaliacao de Vulnerabilidades"
                    echo "  Data: $(date)"
                    echo "=================================================="
                    echo ""
                    echo "Arquivo de servicos: $SERVICE_LIST"
                    echo "Total de servicos analisados: $(wc -l < "$SERVICE_LIST")"
                    echo ""
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
    log "=== INICIO Avaliacao de Vulnerabilidades ==="
    show_banner "Avaliacao de Vulnerabilidades"
    show_disclaimer
    check_deps "curl" "python3"

    get_service_file

    export_report

    analyze_services

    generate_remediation

    echo ""
    log "=== FIM Avaliacao de Vulnerabilidades ==="
    save_resumo "Arquivo de servicos: $SERVICE_LIST
Total de servicos: $(wc -l < "$SERVICE_LIST")
Relatorio: ${OUTPUT_FILE:-N/A}"

    echo -e "${CYAN}================================================${RESET}"
    echo -e "${GREEN}  Avaliacao de Vulnerabilidades concluida!${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    if [ -n "$OUTPUT_FILE" ] && [ "$OUTPUT_FILE" != "/dev/null" ]; then
        echo -e "  Relatorio: $OUTPUT_FILE"
    fi
    echo -e "${CYAN}================================================${RESET}"
}

main
