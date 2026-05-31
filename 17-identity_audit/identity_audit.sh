#!/usr/bin/env bash

set -uo pipefail

source "$(dirname "$0")/../utils/common.sh"

TARGET=""
DOMAIN=""
OUTPUT_FILE=""
PORT_RESULTS=""
OPEN_SERVICES=()
HAS_LDAPSEARCH=false
HAS_DIG=false

IDENTITY_PORTS=(389 636 445 135 88 464 1812 1813 3268 3269 123)
IDENTITY_NAMES=("LDAP" "LDAPS" "SMB/AD" "MSRPC" "Kerberos" "Kerberos-Admin" "RADIUS-Auth" "RADIUS-Acct" "GC-LDAP" "GC-LDAPS" "NTP")
IDENTITY_PROTOS=("tcp" "tcp" "tcp" "tcp" "tcp" "tcp" "udp" "udp" "tcp" "tcp" "udp")

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
        echo -n "IP ou hostname do alvo: "
        read input
        if [ -n "$input" ]; then
            TARGET="$input"
            break
        fi
        echo -e "${RED}[!] Alvo nao pode estar vazio${RESET}"
    done

    echo ""
    echo -n "Dominio AD (opcional, para SRV records): "
    read input
    DOMAIN="$input"

    echo -e "${GREEN}[+] Alvo definido: $TARGET${RESET}"
    [ -n "$DOMAIN" ] && echo -e "${GREEN}[+] Dominio: $DOMAIN${RESET}"
    log "Alvo: $TARGET | Dominio: ${DOMAIN:-N/A}"
}

check_dependencies() {
    if command -v ldapsearch &>/dev/null; then
        HAS_LDAPSEARCH=true
        log "ldapsearch disponivel"
    else
        log "ldapsearch nao disponivel - usando nmap para LDAP"
    fi
    if command -v dig &>/dev/null; then
        HAS_DIG=true
        log "dig disponivel"
    else
        log "dig nao disponivel - SRV records pulados"
    fi
}

scan_identity_ports() {
    step "Varredura de servidores de identidade"
    echo ""

    local results=""
    local total=${#IDENTITY_PORTS[@]}
    local current=0

    for i in "${!IDENTITY_PORTS[@]}"; do
        local port=${IDENTITY_PORTS[$i]}
        local name=${IDENTITY_NAMES[$i]}
        local proto=${IDENTITY_PROTOS[$i]}
        current=$((current + 1))
        progress_bar "$current" "$total"

        local nmap_proto=""
        [ "$proto" = "udp" ] && nmap_proto="-sU"

        local status
        status=$(timeout 5 nmap $nmap_proto -p "$port" --host-timeout 5 "$TARGET" 2>/dev/null | grep "^$port" | awk '{print $2}')

        if echo "$status" | grep -q "open"; then
            echo -e "\r  ${GREEN}[ABERTA]${RESET} $name ($port/$proto)"
            results="$results$name|$port|$proto|open\n"
            OPEN_SERVICES+=("$name|$port|$proto")
            log "Servico de identidade encontrado: $name ($port/$proto) em $TARGET"
        elif echo "$status" | grep -q "filtered"; then
            echo -e "\r  ${YELLOW}[FILTRADA]${RESET} $name ($port/$proto)"
            results="$results$name|$port|$proto|filtered\n"
        else
            echo -e "\r  ${YELLOW}[FECHADA]${RESET} $name ($port/$proto)"
            results="$results$name|$port|$proto|closed\n"
        fi
    done

    PORT_RESULTS="$results"
    echo ""
    echo ""

    local found=false
    while IFS='|' read -r svc port proto status; do
        [ -z "$svc" ] && continue
        if [ "$status" = "open" ]; then
            echo -e "  ${GREEN}[+]${RESET} $svc ($port/$proto) — ACESSIVEL"
            found=true
        fi
    done <<< "$(printf "%b" "$results")"
    if ! $found; then
        echo -e "  ${YELLOW}[-] Nenhum servico de identidade acessivel${RESET}"
        log "Nenhum servico de identidade acessivel em $TARGET"
    fi
    echo ""
}

ldap_anonymous_bind() {
    local target="$1"
    local port="$2"
    local using_nmap=false

    if ! $HAS_LDAPSEARCH; then
        using_nmap=true
    fi

    if $using_nmap; then
        local result
        result=$(timeout 10 nmap -p "$port" --script "ldap-rootdse" "$target" 2>/dev/null | grep -E "^\|" || true)
        if [ -n "$result" ]; then
            echo -e "  ${GREEN}[+] Bind anonimo possivel (nmap ldap-rootdse)${RESET}"
            echo "$result" | sed 's/^/      /'
            return 0
        fi
        return 1
    fi

    local result
    result=$(timeout 10 ldapsearch -x -H "ldap://${target}:${port}" -b "" -s base "(objectClass=*)" namingContexts supportedSASLMechanisms 2>/dev/null)
    if [ -n "$result" ] && ! echo "$result" | grep -qi "ldap_bind\|bind must be completed\|insufficient access"; then
        echo -e "  ${GREEN}[+] Bind anonimo PERMITIDO em $target:$port${RESET}"
        echo ""
        local nc
        nc=$(echo "$result" | grep "^namingContexts:" | head -5)
        if [ -n "$nc" ]; then
            echo -e "     ${CYAN}Naming Contexts:${RESET}"
            while IFS= read -r line; do
                echo "       $line"
            done <<< "$nc"
        fi
        local sasl
        sasl=$(echo "$result" | grep "^supportedSASLMechanisms:" | head -5)
        if [ -n "$sasl" ]; then
            echo -e "     ${CYAN}SASL Mechanisms:${RESET}"
            while IFS= read -r line; do
                echo "       $line"
            done <<< "$sasl"
        fi
        log "Bind anonimo LDAP permitido em $target:$port"
        return 0
    else
        local err
        err=$(echo "$result" | grep -i "ldap_bind\|bind must be completed\|insufficient access" | head -1)
        if [ -n "$err" ]; then
            echo -e "  ${YELLOW}[-] Bind anonimo NEGADO:${RESET} $(echo "$err" | sed 's/^[^:]*://')"
        else
            echo -e "  ${YELLOW}[-] Bind anonimo NEGADO${RESET}"
        fi
        log "Bind anonimo LDAP negado em $target:$port"
        return 1
    fi
}

ldap_enumeration() {
    step "Enumeracao LDAP"
    echo ""

    local has_ldap=false
    local has_ldaps=false

    for svc in "${OPEN_SERVICES[@]}"; do
        local name="${svc%%|*}"
        local port
        port=$(echo "$svc" | cut -d'|' -f2)
        [ "$name" = "LDAP" ] && has_ldap=true && ldap_anonymous_bind "$TARGET" "$port"
        [ "$name" = "LDAPS" ] && has_ldaps=true
    done

    if $has_ldaps && ! $has_ldap; then
        echo -e "${YELLOW}[!] LDAPS encontrado mas LDAP nao - tentando bind via STARTTLS...${RESET}"
        if $HAS_LDAPSEARCH; then
            local result
            result=$(timeout 10 ldapsearch -x -H "ldap://${TARGET}:389" -Z -b "" -s base "(objectClass=*)" namingContexts 2>/dev/null)
            if [ -n "$result" ] && ! echo "$result" | grep -qi "bind must be completed\|ldap_bind"; then
                echo -e "  ${GREEN}[+] Bind via STARTTLS possivel${RESET}"
                local nc
                nc=$(echo "$result" | grep "^namingContexts:" | head -3)
                [ -n "$nc" ] && echo "$nc" | sed 's/^/     /'
            fi
        fi
    fi

    if ! $has_ldap && ! $has_ldaps; then
        echo -e "${YELLOW}[-] Nenhum servico LDAP detectado${RESET}"
    fi
    echo ""
}

kerberos_check() {
    step "Verificacao Kerberos"
    echo ""

    local has_krb=false
    for svc in "${OPEN_SERVICES[@]}"; do
        local name="${svc%%|*}"
        local port
        port=$(echo "$svc" | cut -d'|' -f2)
        if [ "$name" = "Kerberos" ] || [ "$name" = "Kerberos-Admin" ]; then
            has_krb=true
            echo -e "  ${GREEN}[+] Kerberos detectado na porta $port${RESET}"
            log "Kerberos detectado em $TARGET:$port"
        fi
    done

    if $has_krb; then
        local krb_result
        krb_result=$(timeout 10 nmap -p 88 --script "krb5-enum-users" "$TARGET" 2>/dev/null | grep -E "^\|" || true)
        if [ -n "$krb_result" ]; then
            echo -e "${CYAN}  --- Enumeracao Kerberos ---${RESET}"
            echo "$krb_result" | sed 's/^/  /'
        fi
        echo ""

        if [ -n "$DOMAIN" ]; then
            echo -e "${CYAN}  --- Verificacao de autenticacao ---${RESET}"
            if command -v kvno &>/dev/null || command -v kinit &>/dev/null; then
                echo -e "  ${YELLOW}[!] Ferramentas Kerberos disponiveis (kinit/kvno)${RESET}"
                echo -e "  Para obter TGT: kinit user@${DOMAIN}"
                echo -e "  Listar tickets: klist"
            else
                echo -e "  ${YELLOW}[!] krb5-user nao instalado - instale para testar autenticacao${RESET}"
            fi
        fi
    else
        echo -e "${YELLOW}[-] Nenhum servico Kerberos detectado${RESET}"
    fi
    echo ""
}

dns_srv_lookup() {
    if [ -z "$DOMAIN" ] || ! $HAS_DIG; then
        return
    fi

    step "Registros SRV de identidade"
    echo ""

    local srv_records=("_ldap._tcp" "_kerberos._tcp" "_kerberos._udp" "_kpasswd._tcp" "_ntp._udp")
    local found=false

    for srv in "${srv_records[@]}"; do
        local result
        result=$(timeout 5 dig +short SRV "${srv}.${DOMAIN}" 2>/dev/null)
        if [ -n "$result" ]; then
            found=true
            echo -e "  ${GREEN}[+]${RESET} $srv.${DOMAIN}"
            while IFS= read -r line; do
                local priority weight port host
                priority=$(echo "$line" | awk '{print $1}')
                weight=$(echo "$line" | awk '{print $2}')
                port=$(echo "$line" | awk '{print $3}')
                host=$(echo "$line" | awk '{print $4}')
                echo -e "     Prioridade: $priority | Peso: $weight | Porta: $port | Host: $host"
            done <<< "$result"
            log "SRV encontrado: $srv.${DOMAIN} -> $result"
        fi
    done

    if ! $found; then
        echo -e "${YELLOW}[-] Nenhum registro SRV encontrado para ${DOMAIN}${RESET}"
        log "Nenhum SRV record para $DOMAIN"
    fi
    echo ""
}

vlan_test() {
    step "Teste de segmentacao VLAN"
    echo ""

    local vlan_found=false

    if [ -d /proc/net/vlan ] && [ "$(ls -A /proc/net/vlan 2>/dev/null)" ]; then
        vlan_found=true
        echo -e "${GREEN}[+] VLANs detectadas em /proc/net/vlan${RESET}"
        log "VLANs detectadas via /proc/net/vlan"
        echo ""
        echo -e "${CYAN}  --- Interfaces VLAN ---${RESET}"
        for vlan_dev in /proc/net/vlan/*; do
            [ "$(basename "$vlan_dev")" = "config" ] && continue
            local vlan_id
            vlan_id=$(grep "^VLAN ID:" "$vlan_dev" 2>/dev/null | awk '{print $3}')
            local vlan_name
            vlan_name=$(basename "$vlan_dev")
            echo -e "  ${GREEN}[+]${RESET} $vlan_name (VLAN ID: ${vlan_id:-N/A})"
        done
        echo ""
    fi

    if command -v ip &>/dev/null; then
        local vlan_links
        vlan_links=$(ip -o link show 2>/dev/null | grep -i "vlan\|\.\d\+" || true)
        if [ -n "$vlan_links" ]; then
            vlan_found=true
            echo -e "${CYAN}  --- Links VLAN via ip ---${RESET}"
            while IFS= read -r line; do
                local iface
                iface=$(echo "$line" | awk -F': ' '{print $2}')
                echo -e "  ${GREEN}[+]${RESET} $iface"
            done <<< "$vlan_links"
            echo ""
        fi
    fi

    if ! $vlan_found; then
        echo -e "${YELLOW}[-] Nenhuma VLAN detectada neste sistema${RESET}"
        echo -e "${YELLOW}[!] Verificacao manual recomendada via switch ou arquivo de configuracao${RESET}"
        echo ""
        echo -e "  ${CYAN}1.${RESET} Verifique a configuracao de switches gerenciaveis"
        echo -e "  ${CYAN}2.${RESET} Consulte o administrador de rede sobre as VLANs configuradas"
        echo -e "  ${CYAN}3.${RESET} Utilize arp-scan ou nmap para mapear segmentos"
        echo -e "  ${CYAN}4.${RESET} Verifique /etc/network/interfaces ou netplan"
        echo ""
        log "Nenhuma VLAN detectada - sugestao de verificacao manual"
    fi

    echo ""
}

show_summary() {
    step "Resumo dos resultados"
    echo ""

    local open_count=0 filtered_count=0 closed_count=0
    local total=0

    echo -e "${CYAN}--- Servicos de Identidade ---${RESET}"
    echo ""
    printf "${BOLD}%-20s %-6s %-5s %s${RESET}\n" "Servico" "Porta" "Proto" "Status"
    echo "---------------------------------------------"

    while IFS='|' read -r svc port proto status; do
        [ -z "$svc" ] && continue
        total=$((total + 1))
        case "$status" in
            open)
                printf "%-20s %-6s %-5s ${GREEN}%-10s${RESET}\n" "$svc" "$port" "$proto" "ABERTA"
                open_count=$((open_count + 1))
                ;;
            filtered)
                printf "%-20s %-6s %-5s ${YELLOW}%-10s${RESET}\n" "$svc" "$port" "$proto" "FILTRADA"
                filtered_count=$((filtered_count + 1))
                ;;
            *)
                printf "%-20s %-6s %-5s ${YELLOW}%-10s${RESET}\n" "$svc" "$port" "$proto" "FECHADA"
                closed_count=$((closed_count + 1))
                ;;
        esac
    done <<< "$(printf "%b" "$PORT_RESULTS")"

    echo ""
    echo -e "  ${GREEN}Abertas: $open_count${RESET}"
    echo -e "  ${YELLOW}Filtradas: $filtered_count${RESET}"
    echo -e "  ${YELLOW}Fechadas: $closed_count${RESET}"
    echo -e "  Total testadas: $total"
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
                    [ -n "$DOMAIN" ] && echo "  Dominio: $DOMAIN"
                    echo "  Data: $(date)"
                    echo "=================================================="
                    echo ""
                    echo "--- Servicos de Identidade ---"
                    echo ""
                    printf "%-20s %-6s %-5s %s\n" "Servico" "Porta" "Proto" "Status"
                    echo "---------------------------------------------"
                    while IFS='|' read -r svc port proto status; do
                        [ -z "$svc" ] && continue
                        printf "%-20s %-6s %-5s %s\n" "$svc" "$port" "$proto" "$status"
                    done <<< "$(printf "%b" "$PORT_RESULTS")"
                    echo ""
                    echo "--- Segmentacao VLAN ---"
                    if [ -d /proc/net/vlan ] && [ "$(ls -A /proc/net/vlan 2>/dev/null)" ]; then
                        echo "VLANs detectadas no sistema local."
                        for vlan_dev in /proc/net/vlan/*; do
                            [ "$(basename "$vlan_dev")" = "config" ] && continue
                            local vlan_id=$(grep "^VLAN ID:" "$vlan_dev" 2>/dev/null | awk '{print $3}')
                            echo "  $(basename "$vlan_dev") (VLAN ID: ${vlan_id:-N/A})"
                        done
                    else
                        echo "Nenhuma VLAN detectada no sistema local."
                        echo "Recomendado: verificacao manual em switches."
                    fi
                    echo ""
                    echo "--- Servicos Acessiveis ---"
                    local found=false
                    while IFS='|' read -r svc port proto status; do
                        [ -z "$svc" ] && continue
                        if [ "$status" = "open" ]; then
                            found=true
                            echo "  [+] $svc ($port/$proto)"
                        fi
                    done <<< "$(printf "%b" "$PORT_RESULTS")"
                    if ! $found; then
                        echo "  Nenhum servico acessivel."
                    fi
                    echo ""
                    echo "--- Resumo ---"
                    local open_count closed_count filtered_count
                    open_count=$(printf "%b" "$PORT_RESULTS" | grep -c "|open" || true)
                    closed_count=$(printf "%b" "$PORT_RESULTS" | grep -c "|closed" || true)
                    filtered_count=$(printf "%b" "$PORT_RESULTS" | grep -c "|filtered" || true)
                    echo "Portas abertas: $open_count"
                    echo "Portas filtradas: $filtered_count"
                    echo "Portas fechadas: $closed_count"
                    echo "Total testadas: $((open_count + closed_count + filtered_count))"
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
    check_dependencies

    get_target

    scan_identity_ports

    if [ ${#OPEN_SERVICES[@]} -gt 0 ]; then
        ldap_enumeration
        kerberos_check
    fi

    dns_srv_lookup
    vlan_test
    show_summary
    export_report

    echo ""
    log "=== FIM Auditoria de Identidade e Politicas ==="
    local svc_summary=""
    while IFS='|' read -r svc port proto status; do
        [ -z "$svc" ] && continue
        svc_summary+="  $svc ($port/$proto): $status"$'\n'
    done <<< "$(printf "%b" "$PORT_RESULTS")"
    save_resumo "Alvo: $TARGET
Dominio: ${DOMAIN:-N/A}
Servicos de identidade testados:
$svc_summary
Servicos acessiveis: $(printf "%b" "$PORT_RESULTS" | grep -c "|open" || echo 0)/${#IDENTITY_PORTS[@]}
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
