#!/usr/bin/env bash

set -uo pipefail

source "$(dirname "$0")/../utils/common.sh"

# =============================================================================
#  DNS Auditor - DNS Security Audit Tool
#  Interactive script for DNS enumeration and security auditing
# =============================================================================
#  LEGAL DISCLAIMER:
#  This script is for educational purposes and authorized security testing only.
#  Unauthorized use against networks you do not own or have explicit permission
#  to test is illegal. The author is not responsible for any misuse.
# =============================================================================

TARGET_DOMAIN=""
DNS_SERVER=""
RECORD_TYPES=()
ZONE_TRANSFER_RESULTS=""
SUBDOMAINS=()
REVERSE_RESULTS=""
OUTPUT_FILE=""
WORDLIST_PATH=""
COMMON_SUBDOMAINS=("www" "mail" "ftp" "admin" "blog" "shop" "api" "cdn" "webmail" "smtp" "pop3" "imap" "vpn" "ssh" "git" "dev" "test" "staging" "beta" "app")

cleanup() {
    echo -e "\n${YELLOW}[!] Limpando...${RESET}"
    cleanup_temp
    log "Cleanup performed"
}
trap cleanup EXIT

enter_domain() {
    read_input TARGET_DOMAIN "Domínio alvo (ex: example.com)"
    echo -e "${GREEN}[+] Domínio: $TARGET_DOMAIN${RESET}"
}

select_dns_server() {
    if confirm_action "Usar servidor DNS personalizado?"; then
        read_input DNS_SERVER "IP do servidor DNS"
        echo -e "${GREEN}[+] Servidor DNS: $DNS_SERVER${RESET}"
    else
        DNS_SERVER=""
        echo -e "${GREEN}[+] Usando resolvedor DNS padrão do sistema${RESET}"
    fi
}

select_record_types() {
    local types=(
        "A (IPv4 address)"
        "AAAA (IPv6 address)"
        "MX (Mail exchange)"
        "NS (Nameservers)"
        "TXT (Text records)"
        "SOA (Start of authority)"
        "CNAME (Canonical name)"
        "TODOS (consultar todos)"
    )
    local choice
    choice=$(select_from_list "Selecione o tipo de registro" "${types[@]}")
    case "${choice:0:1}" in
        1) RECORD_TYPES=("A") ;;
        2) RECORD_TYPES=("AAAA") ;;
        3) RECORD_TYPES=("MX") ;;
        4) RECORD_TYPES=("NS") ;;
        5) RECORD_TYPES=("TXT") ;;
        6) RECORD_TYPES=("SOA") ;;
        7) RECORD_TYPES=("CNAME") ;;
        8) RECORD_TYPES=("A" "AAAA" "MX" "NS" "TXT" "SOA" "CNAME") ;;
    esac
    echo -e "${GREEN}[+] Record types: ${RECORD_TYPES[*]}${RESET}"
}

query_dns() {
    local record_type="$1"
    local query_domain="$2"
    local result=""

    if [ -n "$DNS_SERVER" ]; then
        result=$(dig "@$DNS_SERVER" "$query_domain" "$record_type" +short 2>/dev/null)
    else
        result=$(dig "$query_domain" "$record_type" +short 2>/dev/null)
    fi

    echo "$result"
}

enumerate_records() {
    echo ""
    echo -e "${YELLOW}[*] Enumerando registros DNS para $TARGET_DOMAIN...${RESET}"

    local all_results=""

    for rtype in "${RECORD_TYPES[@]}"; do
        echo -e "\n${CYAN}--- $rtype Records ---${RESET}"
        local records
        records=$(query_dns "$rtype" "$TARGET_DOMAIN")
        if [ -n "$records" ]; then
            echo "$records"
            all_results+="$rtype records for $TARGET_DOMAIN:\n$records\n\n"
        else
            echo -e "${YELLOW}[!] Nenhum registro $rtype encontrado${RESET}"
            all_results+="$rtype records for $TARGET_DOMAIN: None\n"
        fi
    done

    ZONE_TRANSFER_RESULTS="$all_results"
}

zone_transfer_check() {
    echo ""
    echo -e "${YELLOW}[*] Verificando vulnerabilidades de transferência de zona (AXFR)...${RESET}"

    local ns_servers
    if [ -n "$DNS_SERVER" ]; then
        ns_servers=$(dig "@$DNS_SERVER" "$TARGET_DOMAIN" NS +short 2>/dev/null)
    else
        ns_servers=$(dig "$TARGET_DOMAIN" NS +short 2>/dev/null)
    fi

    if [ -z "$ns_servers" ]; then
        echo -e "${YELLOW}[!] Nenhum servidor NS encontrado para $TARGET_DOMAIN${RESET}"
        return
    fi

    echo -e "${GREEN}[+] Servidores NS encontrados:${RESET}"
    echo "$ns_servers" | while IFS= read -r ns; do
        echo "    $ns"
    done

    echo ""
    echo -e "${YELLOW}[*] Tentando transferência de zona em cada NS...${RESET}"
    local found=false

    while IFS= read -r ns; do
        ns="${ns%%.}" 
        local ns_ip
        ns_ip=$(dig "$ns" A +short 2>/dev/null | head -1)
        if [ -z "$ns_ip" ]; then
            ns_ip=$(host "$ns" 2>/dev/null | grep "has address" | head -1 | awk '{print $NF}')
        fi
        [ -z "$ns_ip" ] && ns_ip="$ns"

        echo -ne "  Testando $ns_ip ($ns)... "
        local axfr_result
        axfr_result=$(dig "@$ns_ip" "$TARGET_DOMAIN" AXFR +time=5 +tries=1 2>/dev/null)

        if [ -n "$axfr_result" ] && ! echo "$axfr_result" | grep -qi "Transfer failed\|timed out\|refused\|no servers"; then
            echo -e "${RED}[VULNERÁVEL]${RESET}"
            echo ""
            echo "$axfr_result"
            found=true
        else
            echo -e "${GREEN}[SEGURO]${RESET}"
        fi
    done <<< "$ns_servers"

    if ! $found; then
        echo -e "\n${GREEN}[+] Transferência de zona não permitida - servidor configurado corretamente${RESET}"
    fi
}

subdomain_discovery() {
    local options=(
        "Usar lista interna de subdomínios comuns"
        "Carregar wordlist de arquivo"
        "Pular descoberta de subdomínios"
    )
    local choice
    choice=$(select_from_list "Descoberta de subdomínios" "${options[@]}")

    case "$choice" in
        "${options[0]}")
            subdomain_scan "${COMMON_SUBDOMAINS[@]}"
            ;;
        "${options[1]}")
            read_input wl_path "Caminho da wordlist"
            wl_path="${wl_path/#\~/$HOME}"
            if [ -f "$wl_path" ]; then
                local subs=()
                while IFS= read -r line; do
                    s=$(echo "$line" | xargs)
                    [ -n "$s" ] && subs+=("$s")
                done < "$wl_path"
                if [ ${#subs[@]} -gt 0 ]; then
                    subdomain_scan "${subs[@]}"
                else
                    echo -e "${YELLOW}[!] Wordlist está vazia${RESET}"
                fi
            else
                echo -e "${RED}Arquivo não encontrado${RESET}"
            fi
            ;;
        *)
            echo -e "${YELLOW}[!] Pulando descoberta de subdomínios${RESET}"
            ;;
    esac
}

subdomain_scan() {
    local subs=("$@")
    local total=${#subs[@]}

    echo -e "\n${YELLOW}[*] Testando $total subdomínios em $TARGET_DOMAIN...${RESET}"
    echo ""

    SUBDOMAINS=()
    local count=0

    for sub in "${subs[@]}"; do
        local fqdn="${sub}.${TARGET_DOMAIN}"
        local result
        result=$(query_dns "A" "$fqdn")
        if [ -n "$result" ] && ! echo "$result" | grep -qi "NXDOMAIN\|SERVFAIL\|REFUSED\|no servers could be reached"; then
            local ip
            ip=$(echo "$result" | head -1)
            SUBDOMAINS+=("$fqdn|$ip")
            echo -e "  ${GREEN}[+]${RESET} $fqdn -> $ip"
        fi
        count=$((count + 1))
        progress_bar "$count" "$total"
    done
    printf "\n"

    echo -e "\n${GREEN}[+] Encontrados ${#SUBDOMAINS[@]} subdomínios${RESET}"
}

reverse_dns_lookup() {
    local options=(
        "Consultar IPs encontrados nos registros DNS"
        "Digitar IPs/faixa específicos"
        "Pular consulta reversa"
    )
    local choice
    choice=$(select_from_list "Consulta DNS reversa" "${options[@]}")

    case "$choice" in
        "${options[0]}") reverse_scan_from_records ;;
        "${options[1]}") reverse_manual ;;
        *) echo -e "${YELLOW}[!] Pulando consulta DNS reversa${RESET}" ;;
    esac
}

reverse_scan_from_records() {
    echo -e "\n${YELLOW}[*] Extraindo IPs dos registros DNS...${RESET}"

    local ips=()
    for rtype in "${RECORD_TYPES[@]}"; do
        local records
        records=$(query_dns "$rtype" "$TARGET_DOMAIN")
        while IFS= read -r line; do
            if [[ "$line" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                ips+=("$line")
            fi
        done <<< "$records"
    done

    if [ ${#ips[@]} -eq 0 ]; then
        echo -e "${YELLOW}[!] Nenhum IP para consulta reversa${RESET}"
        return
    fi

    local unique_ips=()
    local seen=""
    for ip in "${ips[@]}"; do
        if ! echo "$seen" | grep -q "$ip"; then
            unique_ips+=("$ip")
            seen="$seen $ip"
        fi
    done

    echo -e "${GREEN}[+] Encontrados ${#unique_ips[@]} IPs únicos${RESET}"
    echo ""

    for ip in "${unique_ips[@]}"; do
        local ptr
        ptr=$(dig -x "$ip" +short 2>/dev/null | head -1)
        if [ -n "$ptr" ]; then
            REVERSE_RESULTS+="$ip -> $ptr\n"
            echo -e "  ${GREEN}[+]${RESET} $ip -> $ptr"
        else
            REVERSE_RESULTS+="$ip -> (no PTR record)\n"
            echo -e "  ${YELLOW}[-]${RESET} $ip -> (no PTR record)"
        fi
    done
}

reverse_manual() {
    echo ""
    echo -e "${YELLOW}[*] Digite IPs (separados por espaço ou faixa CIDR)${RESET}"
    echo -n "IPs: "
    read ip_input

    local ips=()
    for item in $ip_input; do
        if echo "$item" | grep -q "/"; then
            local network prefix
            network=$(echo "$item" | cut -d/ -f1)
            prefix=$(echo "$item" | cut -d/ -f2)
            local base
            base=$(echo "$network" | cut -d. -f1-3)
            local start
            start=$(echo "$network" | cut -d. -f4)
            local size=$((1 << (32 - prefix)))
            for i in $(seq "$start" $((start + size - 1))); do
                [ "$i" -gt 255 ] && break
                ips+=("${base}.${i}")
            done
        elif [[ "$item" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            ips+=("$item")
        fi
    done

    echo -e "\n${YELLOW}[*] Executando consulta reversa em ${#ips[@]} IPs...${RESET}"
    local count=0
    for ip in "${ips[@]}"; do
        local ptr
        ptr=$(dig -x "$ip" +short 2>/dev/null | head -1)
        if [ -n "$ptr" ]; then
            REVERSE_RESULTS+="$ip -> $ptr\n"
            echo -e "  ${GREEN}[+]${RESET} $ip -> $ptr"
        fi
        count=$((count + 1))
        progress_bar "$count" "${#ips[@]}"
    done
    printf "\n"
}

display_results() {
    echo ""
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${CYAN}  Resumo dos Resultados da Auditoria DNS${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    echo ""
    printf "${BOLD}%-20s %-15s %-30s${RESET}\n" "Domínio" "Tipo de Registro" "Valor"
    echo "---------------------------------------------------------------------"

    for rtype in "${RECORD_TYPES[@]}"; do
        local records
        records=$(query_dns "$rtype" "$TARGET_DOMAIN")
        if [ -n "$records" ]; then
            while IFS= read -r line; do
                [ -z "$line" ] && continue
                printf "%-20s %-15s %-30s\n" "$TARGET_DOMAIN" "$rtype" "$line"
            done <<< "$records"
        fi
    done

    if [ ${#SUBDOMAINS[@]} -gt 0 ]; then
        echo ""
        echo -e "${CYAN}--- Subdomínios Descobertos ---${RESET}"
        printf "${BOLD}%-30s %-15s${RESET}\n" "Subdomínio" "Endereço IP"
        echo "-----------------------------------------------"
        for entry in "${SUBDOMAINS[@]}"; do
            local sub="${entry%%|*}"
            local ip="${entry#*|}"
            printf "%-30s %-15s\n" "$sub" "$ip"
        done
    fi

    if [ -n "$REVERSE_RESULTS" ]; then
        echo ""
        echo -e "${CYAN}--- Consultas DNS Reversas ---${RESET}"
        echo -e "$REVERSE_RESULTS"
    fi
}

export_results() {
    local records_section=""
    for rtype in "${RECORD_TYPES[@]}"; do
        records_section+="--- $rtype Records ---\n"
        records_section+="$(query_dns "$rtype" "$TARGET_DOMAIN")\n\n"
    done

    local subs_section=""
    if [ ${#SUBDOMAINS[@]} -gt 0 ]; then
        subs_section="--- Subdomínios Descobertos ---\n"
        for entry in "${SUBDOMAINS[@]}"; do
            subs_section+="$entry\n"
        done
        subs_section+="\n"
    fi

    local rev_section=""
    if [ -n "$REVERSE_RESULTS" ]; then
        rev_section="--- Consultas DNS Reversas ---\n"
        rev_section+="$REVERSE_RESULTS\n"
    fi

    local content
    content="==================================================
  Relatório de Auditoria DNS
  Domínio: $TARGET_DOMAIN
  Servidor DNS: ${DNS_SERVER:-sistema padrão}
  Data: $(date)
==================================================

${records_section}${subs_section}${rev_section}"

    local outfile
    outfile=$(save_results_file "dns_audit" "$content")
    [ -n "$outfile" ] && OUTPUT_FILE="$outfile"
}

parse_cli_args TARGET_DOMAIN _unused_port "$@"

main() {
    log "=== START DNS Audit ==="
    show_banner "DNS Auditor"
    show_disclaimer
    check_deps "dig" "host" "nslookup"

    step "Digite o domínio alvo"
    enter_domain

    step "Selecione o servidor DNS"
    select_dns_server

    step "Selecione os tipos de registro"
    select_record_types

    step "Enumerar registros DNS"
    enumerate_records

    step "Verificação de transferência de zona"
    zone_transfer_check

    step "Descoberta de subdomínios"
    subdomain_discovery

    step "Consulta DNS reversa"
    reverse_dns_lookup

    step "Exibir todos os resultados"
    display_results

    step "Exportar resultados"
    export_results

    echo ""
    log "=== END DNS Audit ==="
    local subs_resumo=""
    for s in "${SUBDOMAINS[@]}"; do
        subs_resumo+="  $s"$'\n'
    done
    save_resumo "Domínio: $TARGET_DOMAIN
Servidor DNS: ${DNS_SERVER:-sistema padrão}
Tipos de registro: ${RECORD_TYPES[*]}
Subdomínios encontrados: ${#SUBDOMAINS[@]}
$subs_resumo
Arquivo de resultados: ${OUTPUT_FILE:-N/A}"
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${GREEN}  Auditoria DNS concluída!${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    if [ -n "$OUTPUT_FILE" ]; then
        echo -e "  Relatório: $OUTPUT_FILE"
    fi
    echo -e "${CYAN}================================================${RESET}"
}

main
