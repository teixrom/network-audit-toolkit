#!/usr/bin/env bash

set -uo pipefail

source "$(dirname "$0")/../utils/common.sh"

# =============================================================================
#  Service Enumeration - Service Detection and Banner Grabbing
#  Interactive script for enumerating services on open ports
# =============================================================================
#  LEGAL DISCLAIMER:
#  This script is for educational purposes and authorized security testing only.
#  Unauthorized use against networks you do not own or have explicit permission
#  to test is illegal. The author is not responsible for any misuse.
# =============================================================================

TARGET=""
ENUM_PORTS=""
ENUM_RESULTS=()
RESULTS_FILE=""

cleanup() {
    echo -e "\n${YELLOW}[!] Limpando...${RESET}"
    cleanup_temp
    log "Cleanup performed"
}
trap cleanup EXIT

enter_target() {
    local prev_port
    prev_port=$(ls -t "$AUDIT_DIR"/port_scan_*.txt 2>/dev/null | head -1)
    local prev_host
    prev_host=$(ls -t "$AUDIT_DIR"/host_discovery_*.txt 2>/dev/null | head -1)

    local options=("Digitar alvo manualmente")
    [ -n "$prev_port" ] && options+=("Carregar da varredura de portas anterior")
    [ -n "$prev_host" ] && options+=("Carregar da descoberta de hosts anterior")

    local choice
    choice=$(select_from_list "Selecione a origem do alvo" "${options[@]}")

    case "$choice" in
        "Digitar alvo manualmente")
            read_input TARGET "IP/hostname alvo"
            ;;
        "Carregar da varredura de portas anterior")
            TARGET=$(grep -m1 "Alvo:" "$prev_port" | cut -d: -f2 | xargs)
            echo -e "${GREEN}[+] Alvo carregado: $TARGET${RESET}"
            if confirm_action "Carregar portas da varredura anterior?"; then
                ENUM_PORTS=$(grep -oP '^\d+' "$prev_port" | paste -sd,)
                echo -e "${GREEN}[+] Portas carregadas: $ENUM_PORTS${RESET}"
            fi
            ;;
        "Carregar da descoberta de hosts anterior")
            TARGET=$(grep -oP '^\d+\.\d+\.\d+\.\d+' "$prev_host" | head -1)
            echo -e "${GREEN}[+] Alvo carregado: $TARGET${RESET}"
            ;;
    esac

    echo -e "${GREEN}[+] Alvo: $TARGET${RESET}"
}

enter_ports() {
    if [ -n "$ENUM_PORTS" ]; then
        echo -e "${GREEN}[+] Portas já carregadas: $ENUM_PORTS${RESET}"
        return
    fi
    read_input ENUM_PORTS "Portas (ex: 21,22,80,443 ou 1-1024)"
    echo -e "${GREEN}[+] Portas: $ENUM_PORTS${RESET}"
}

grab_banner_nc() {
    local target="$1" port="$2" timeout="3"
    timeout "$timeout" nc -w 2 "$target" "$port" 2>/dev/null <<< "" | tr -d '\0' | tr '\n' ' ' | head -c 200 || true
}

grab_banner_curl() {
    local target="$1" port="$2" protocol="$3" timeout="5"
    timeout "$timeout" curl -sS -m 4 "${protocol}://${target}:${port}/" 2>/dev/null | head -c 300 || true
}

enumerate_service() {
    local target="$1" raw_port="$2"
    local port="${raw_port%%/*}"
    local port_num="${port%/*}"

    local service="unknown"
    local banner=""
    local extra=""

    case "$port_num" in
        21)
            service="FTP"
            banner=$(grab_banner_nc "$target" 21)
            if echo "$banner" | grep -qi "ftp"; then
                extra="FTP service detected"
                local anon_check
                anon_check=$(timeout 5 nc -w 2 "$target" 21 2>/dev/null <<< "USER anonymous
PASS anonymous@
QUIT
" | head -5 | tr -d '\0')
                if echo "$anon_check" | grep -qi "230"; then
                    extra="${extra} | Anonymous login: ${GREEN}ENABLED${RESET}"
                else
                    extra="${extra} | Anonymous login: disabled"
                fi
            fi
            ;;
        22)
            service="SSH"
            banner=$(grab_banner_nc "$target" 22)
            if echo "$banner" | grep -qi "ssh"; then
                local version
                version=$(echo "$banner" | grep -oP 'SSH-[0-9.]+[^\s]*' | head -1)
                extra="SSH version: $version"
            fi
            ;;
        23)
            service="Telnet"
            banner=$(grab_banner_nc "$target" 23)
            extra="Telnet service - unencrypted protocol"
            ;;
        25)
            service="SMTP"
            banner=$(grab_banner_nc "$target" 25)
            if echo "$banner" | grep -qi "smtp"; then
                local ehlo
                ehlo=$(timeout 5 nc -w 2 "$target" 25 2>/dev/null <<< "EHLO enum
QUIT
" | tr -d '\0')
                extra="SMTP service detected"
                if echo "$ehlo" | grep -qi "250"; then
                    extra="${extra} | EHLO accepted"
                fi
            fi
            ;;
        80|8080|8000)
            service="HTTP"
            banner=$(grab_banner_curl "$target" "$port_num" "http")
            local headers
            headers=$(timeout 5 curl -sI -m 4 "http://${target}:${port_num}/" 2>/dev/null || true)
            local server
            server=$(echo "$headers" | grep -i "^server:" | head -1 | cut -d: -f2- | xargs)
            local title
            title=$(echo "$banner" | grep -oP '<title>\K[^<]+' | head -1)
            extra=""
            [ -n "$server" ] && extra="Server: $server"
            [ -n "$title" ] && extra="${extra} | Title: $title"
            ;;
        443|8443)
            service="HTTPS"
            banner=$(grab_banner_curl "$target" "$port_num" "https")
            local headers
            headers=$(timeout 5 curl -sI -m 4 "https://${target}:${port_num}/" -k 2>/dev/null || true)
            local server
            server=$(echo "$headers" | grep -i "^server:" | head -1 | cut -d: -f2- | xargs)
            local title
            title=$(echo "$banner" | grep -oP '<title>\K[^<]+' | head -1)
            extra=""
            [ -n "$server" ] && extra="Server: $server"
            [ -n "$title" ] && extra="${extra} | Title: $title"
            ;;
        3306)
            service="MySQL"
            banner=$(grab_banner_nc "$target" 3306)
            if echo "$banner" | grep -qi "mysql"; then
                local version
                version=$(echo "$banner" | tr -d '\0' | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
                extra="MySQL version: $version"
            fi
            ;;
        5432)
            service="PostgreSQL"
            banner=$(grab_banner_nc "$target" 5432)
            if [ -n "$banner" ]; then
                extra="PostgreSQL service detected"
            fi
            ;;
        6379)
            service="Redis"
            banner=$(grab_banner_nc "$target" 6379)
            if echo "$banner" | grep -qi "redis"; then
                extra="Redis service detected"
            fi
            ;;
        110)
            service="POP3"
            banner=$(grab_banner_nc "$target" 110)
            extra="POP3 mail service"
            ;;
        143)
            service="IMAP"
            banner=$(grab_banner_nc "$target" 143)
            extra="IMAP mail service"
            ;;
        389|636)
            service="LDAP"
            banner=$(grab_banner_nc "$target" "$port_num")
            extra="LDAP directory service"
            ;;
        445)
            service="SMB"
            banner=$(grab_banner_nc "$target" 445)
            extra="SMB/CIFS service"
            ;;
        161|162)
            service="SNMP"
            banner=$(grab_banner_nc "$target" "$port_num")
            extra="SNMP service"
            ;;
        53)
            service="DNS"
            banner=$(grab_banner_nc "$target" 53)
            extra="DNS service"
            ;;
        554)
            service="RTSP"
            banner=$(grab_banner_nc "$target" 554)
            extra="RTSP streaming"
            ;;
        *)
            banner=$(grab_banner_nc "$target" "$port_num")
            if [ -n "$banner" ]; then
                service="generic"
                extra="Banner: $(echo "$banner" | head -c 100)"
            fi
            ;;
    esac

    [ -z "$banner" ] && banner="No banner captured"
    banner=$(echo "$banner" | tr -d '\n\r' | xargs | head -c 120)
    extra=$(echo "$extra" | head -c 150)

    ENUM_RESULTS+=("$port_num|$service|$banner|$extra")
}

run_enumeration() {
    echo -e "\n${YELLOW}[*] Iniciando enumeração de serviços...${RESET}"

    IFS=',' read -ra port_list <<< "$ENUM_PORTS"
    # Also handle ranges
    local expanded_ports=()
    for p in "${port_list[@]}"; do
        p=$(echo "$p" | xargs)
        if echo "$p" | grep -q "-"; then
            local start="${p%-*}"
            local end="${p#*-}"
            for ((i=start; i<=end; i++)); do
                expanded_ports+=("$i")
            done
        else
            expanded_ports+=("$p")
        fi
    done

    local total=${#expanded_ports[@]}
    local current=0

    for port in "${expanded_ports[@]}"; do
        current=$((current + 1))
        progress_bar "$current" "$total"
        enumerate_service "$TARGET" "$port"
    done
    printf "\n"

    log "Enumeration completed for $total ports"
}

display_results() {
    echo ""
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${CYAN}  Resultados da Enumeração de Serviços para $TARGET${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    echo ""

    if [ ${#ENUM_RESULTS[@]} -eq 0 ]; then
        echo -e "${YELLOW}[!] Nenhum serviço enumerado.${RESET}"
        return
    fi

    printf "${BOLD}%-8s %-14s %-30s${RESET}\n" "PORTA" "SERVIÇO" "DETALHES"
    echo "------------------------------------------------------------------------"
    for entry in "${ENUM_RESULTS[@]}"; do
        local port="${entry%%|*}"
        local rest="${entry#*|}"
        local svc="${rest%%|*}"
        local rest2="${rest#*|}"
        local banner="${rest2%%|*}"
        local extra="${rest2#*|}"
        local display="$banner"
        [ -n "$extra" ] && display="$extra"
        printf "%-8s %-14s %-30s\n" "$port" "$svc" "$display"
    done
}

run_nmap_version() {
    if ! confirm_action "Executar nmap -sV para detecção detalhada de versão?"; then
        echo -e "${YELLOW}[!] Pulando varredura de versão do nmap${RESET}"
        return
    fi

    echo -e "\n${GREEN}[+] Executando nmap -sV em $TARGET${RESET}"
    run_cmd_with_progress 90 "nmap -sV (detecção de versão)" \
        nmap -sV -p "$ENUM_PORTS" -T4 "$TARGET" -oN - 2>/dev/null
}

save_results() {
    local content
    content="=== Resultados da Enumeração de Serviços ===
Data: $(date)
Alvo: $TARGET

$(for entry in "${ENUM_RESULTS[@]}"; do
    local port="${entry%%|*}"
    local rest="${entry#*|}"
    local svc="${rest%%|*}"
    local rest2="${rest#*|}"
    local banner="${rest2%%|*}"
    local extra="${rest2#*|}"
    echo "Porta $port: $svc | $extra | Banner: $banner"
done)"

    local outfile
    outfile=$(save_results_file "service_enum" "$content")
    [ -n "$outfile" ] && RESULTS_FILE="$outfile"
}

parse_cli_args TARGET _unused_port "$@"

main() {
    log "=== START Service Enumeration ==="
    show_banner "Enumeração de Serviços"
    show_disclaimer
    check_deps "nmap" "nc"

    step "Digite o alvo"
    enter_target

    step "Digite as portas para enumerar"
    enter_ports

    step "Executando enumeração"
    run_enumeration
    log "Enumeração concluída"

    step "Exibir resultados"
    display_results

    step "Detecção de versão com nmap"
    run_nmap_version

    step "Salvar resultados"
    save_results

    echo ""
    log "=== END Service Enumeration ==="
    local resumo_services=""
    for e in "${ENUM_RESULTS[@]}"; do
        resumo_services+="  $e"$'\n'
    done
    save_resumo "Alvo: $TARGET
Portas: $ENUM_PORTS
Serviços encontrados: ${#ENUM_RESULTS[@]}
$resumo_services
Arquivo de resultados: ${RESULTS_FILE:-N/A}"
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${GREEN}  Enumeração de serviços concluída!${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    if [ -n "$RESULTS_FILE" ]; then
        echo -e "  Resultados: $RESULTS_FILE"
    fi
    echo -e "${CYAN}================================================${RESET}"
}

main
