#!/usr/bin/env bash

set -uo pipefail

source "$(dirname "$0")/../utils/common.sh"

# =============================================================================
#  Web Auditor - Web Server Security Audit Tool
#  Interactive script for auditing web server security
# =============================================================================
#  LEGAL DISCLAIMER:
#  This script is for educational purposes and authorized security testing only.
#  Unauthorized use against networks you do not own or have explicit permission
#  to test is illegal. The author is not responsible for any misuse.
# =============================================================================

TARGET_URL=""
TARGET_HOST=""
TARGET_PORT=""
TARGET_PROTO=""
HEADERS_RAW=""
REPORT_FILE=""

cleanup() {
    echo -e "\n${YELLOW}[!] Limpando...${RESET}"
    cleanup_temp
    log "Cleanup performed"
}
trap cleanup EXIT

enter_target() {
    read_input TARGET_URL "URL alvo (ex: http://example.com, https://example.com:8443)"

    TARGET_PROTO=$(echo "$TARGET_URL" | grep -oP '^https' || echo "http")
    TARGET_HOST=$(echo "$TARGET_URL" | sed -E 's|^https?://||' | cut -d/ -f1 | cut -d: -f1)
    TARGET_PORT=$(echo "$TARGET_URL" | sed -E 's|^https?://||' | cut -d: -f2 | cut -d/ -f1)
    [ -z "$TARGET_PORT" ] && [ "$TARGET_PROTO" = "https" ] && TARGET_PORT=443
    [ -z "$TARGET_PORT" ] && [ "$TARGET_PROTO" = "http" ] && TARGET_PORT=80

    echo -e "${GREEN}[+] Alvo: $TARGET_PROTO://$TARGET_HOST:$TARGET_PORT${RESET}"
}

analyze_headers() {
    echo -e "\n${YELLOW}[*] Obtendo cabeçalhos HTTP...${RESET}"

    local url="${TARGET_PROTO}://${TARGET_HOST}:${TARGET_PORT}/"
    if [ "$TARGET_PROTO" = "https" ]; then
        HEADERS_RAW=$(timeout 10 curl -sI -k -L "$url" 2>/dev/null)
    else
        HEADERS_RAW=$(timeout 10 curl -sI -L "$url" 2>/dev/null)
    fi

    if [ -z "$HEADERS_RAW" ]; then
        echo -e "${RED}[!] Falha ao obter cabeçalhos de $url${RESET}"
        log_error "Failed to fetch headers from $url"
        return
    fi

    echo ""
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${CYAN}  Cabeçalhos de Resposta HTTP${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    echo ""
    echo "$HEADERS_RAW"
    echo ""

    log "Headers fetched from $url"

    echo -e "${CYAN}================================================${RESET}"
    echo -e "${CYAN}  Análise de Cabeçalhos de Segurança${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    echo ""

    local has_hsts=false
    local has_xframe=false
    local has_xss=false
    local has_content_type=false
    local has_csp=false
    local has_referrer=false
    local has_permissions=false
    local has_transport=false

    if echo "$HEADERS_RAW" | grep -qi "^strict-transport-security:"; then
        echo -e "  ${GREEN}[OK]${RESET} HSTS (Strict-Transport-Security) configurado"
        has_hsts=true
    else
        echo -e "  ${RED}[!]${RESET} HSTS (Strict-Transport-Security) ${RED}AUSENTE${RESET}"
    fi

    if echo "$HEADERS_RAW" | grep -qi "^x-frame-options:"; then
        echo -e "  ${GREEN}[OK]${RESET} X-Frame-Options configurado"
        has_xframe=true
    else
        echo -e "  ${RED}[!]${RESET} X-Frame-Options ${RED}AUSENTE${RESET} - risco de clickjacking"
    fi

    if echo "$HEADERS_RAW" | grep -qi "^x-xss-protection:"; then
        echo -e "  ${GREEN}[OK]${RESET} X-XSS-Protection configurado"
        has_xss=true
    else
        echo -e "  ${YELLOW}[!]${RESET} X-XSS-Protection ausente (obsoleto mas ainda usado)"
    fi

    if echo "$HEADERS_RAW" | grep -qi "^x-content-type-options:"; then
        echo -e "  ${GREEN}[OK]${RESET} X-Content-Type-Options configurado"
        has_content_type=true
    else
        echo -e "  ${RED}[!]${RESET} X-Content-Type-Options ${RED}AUSENTE${RESET} - risco de MIME sniffing"
    fi

    if echo "$HEADERS_RAW" | grep -qi "^content-security-policy:"; then
        echo -e "  ${GREEN}[OK]${RESET} Content-Security-Policy configurado"
        has_csp=true
    else
        echo -e "  ${RED}[!]${RESET} Content-Security-Policy ${RED}AUSENTE${RESET} - risco de XSS"
    fi

    if echo "$HEADERS_RAW" | grep -qi "^referrer-policy:"; then
        echo -e "  ${GREEN}[OK]${RESET} Referrer-Policy configurado"
        has_referrer=true
    else
        echo -e "  ${YELLOW}[!]${RESET} Referrer-Policy ausente"
    fi

    if echo "$HEADERS_RAW" | grep -qi "^permissions-policy:"; then
        echo -e "  ${GREEN}[OK]${RESET} Permissions-Policy configurado"
        has_permissions=true
    else
        echo -e "  ${YELLOW}[!]${RESET} Permissions-Policy ausente"
    fi

    if [ "$TARGET_PROTO" = "https" ]; then
        if echo "$HEADERS_RAW" | grep -qi "^strict-transport-security:"; then
            echo -e "  ${GREEN}[OK]${RESET} HSTS configurado sobre HTTPS"
        fi
    fi

    echo ""
    local server_header
    server_header=$(echo "$HEADERS_RAW" | grep -i "^server:" | head -1 | sed 's/^[Ss][Ee][Rr][Vv][Ee][Rr]:\s*//')
    if [ -n "$server_header" ]; then
        echo -e "  ${YELLOW}[!]${RESET} Versão do servidor exposta: ${YELLOW}$server_header${RESET}"
        echo -e "  ${YELLOW}[*]${RESET} Considere ocultar a versão do servidor em produção"
    fi

    local cookie_lines
    cookie_lines=$(echo "$HEADERS_RAW" | grep -i "^set-cookie:")
    if [ -n "$cookie_lines" ]; then
        echo ""
        echo -e "  ${CYAN}--- Análise de Cookies ---${RESET}"
        while IFS= read -r cookie; do
            local cname
            cname=$(echo "$cookie" | sed 's/^[Ss][Ee][Tt]-[Cc][Oo][Oo][Kk][Ii][Ee]:\s*//' | cut -d= -f1)
            local flags=""
            if ! echo "$cookie" | grep -qi "secure"; then
                flags="${flags}${RED}[Sem Secure]${RESET} "
            fi
            if ! echo "$cookie" | grep -qi "httponly"; then
                flags="${flags}${RED}[Sem HttpOnly]${RESET} "
            fi
            if ! echo "$cookie" | grep -qi "samesite"; then
                flags="${flags}${YELLOW}[Sem SameSite]${RESET} "
            fi
            if [ -n "$flags" ]; then
                echo -e "  ${YELLOW}[!]${RESET} Cookie '$cname': $flags"
            else
                echo -e "  ${GREEN}[OK]${RESET} Cookie '$cname': flags de segurança presentes"
            fi
        done <<< "$cookie_lines"
    fi

    echo ""
    local score=0
    $has_hsts && score=$((score+1))
    $has_xframe && score=$((score+1))
    $has_xss && score=$((score+1))
    $has_content_type && score=$((score+1))
    $has_csp && score=$((score+1))
    $has_referrer && score=$((score+1))
    $has_permissions && score=$((score+1))

    local grade="F"
    if [ "$score" -ge 6 ]; then grade="A"; elif [ "$score" -ge 5 ]; then grade="B"; elif [ "$score" -ge 4 ]; then grade="C"; elif [ "$score" -ge 3 ]; then grade="D"; elif [ "$score" -ge 1 ]; then grade="E"; fi

    echo -e "  ${CYAN}Pontuação de Segurança: $score/7 (Nota: ${BOLD}$grade${RESET}${CYAN})${RESET}"
}

dir_brute_force() {
    echo ""
    echo -e "${YELLOW}[*] Força bruta de diretórios/arquivos${RESET}"
    echo ""

    if command -v gobuster &>/dev/null; then
        local tool="gobuster"
    elif command -v dirb &>/dev/null; then
        local tool="dirb"
    else
        echo -e "${YELLOW}[!] gobuster nem dirb encontrados. Instale com:${RESET}"
        echo -e "  ${CYAN}sudo apt install gobuster dirb${RESET}"
        confirm_action "Continuar sem força bruta?" && return
        return
    fi

    local wordlist=""
    local extensions="php,html,txt,zip,bak,old,xml,json,asp,aspx,jsp,do,action"

    echo "  Ferramenta: $tool"
    echo ""

    local wl_options=(
        "Wordlist comum (/usr/share/wordlists/dirb/common.txt)"
        "directory-list-2.3-medium (baixar)"
        "Caminho personalizado"
    )
    local wl_choice
    wl_choice=$(select_from_list "Selecione a wordlist" "${wl_options[@]}")

    case "$wl_choice" in
        "${wl_options[0]}")
            wordlist="/usr/share/wordlists/dirb/common.txt"
            [ ! -f "$wordlist" ] && wordlist="/usr/share/dirb/wordlists/common.txt"
            if [ ! -f "$wordlist" ]; then
                echo -e "${RED}Wordlist não encontrada${RESET}"
                return
            fi
            ;;
        "${wl_options[1]}")
            local dl_path="$AUDIT_DIR/directory-list-2.3-medium.txt"
            if [ ! -f "$dl_path" ]; then
                echo -e "${YELLOW}[!] Baixando directory-list-2.3-medium.txt...${RESET}"
                curl -#L -o "$dl_path" "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/directory-list-2.3-medium.txt" 2>/dev/null || {
                    echo -e "${RED}[!] Download falhou${RESET}"
                    return
                }
            fi
            wordlist="$dl_path"
            ;;
        *)
            read_input wordlist "Caminho da wordlist" ""
            wordlist="${wordlist/#\~/$HOME}"
            [ ! -f "$wordlist" ] && echo -e "${RED}Arquivo não encontrado${RESET}" && return
            ;;
    esac

    read_input custom_ext "Extensões (separadas por vírgula)" "$extensions"
    [ -n "$custom_ext" ] && extensions="$custom_ext"

    local url="${TARGET_PROTO}://${TARGET_HOST}:${TARGET_PORT}/"
    echo ""
    echo -e "\n${YELLOW}[*] Executando força bruta de diretórios...${RESET}"

    if [ "$tool" = "gobuster" ]; then
        run_cmd_with_progress 120 "gobuster dir (força bruta)" \
            gobuster dir -u "$url" -w "$wordlist" -x "$extensions" -t 20 -q 2>/dev/null
    else
        run_cmd_with_progress 120 "dirb (força bruta)" \
            dirb "$url" "$wordlist" -w 2>/dev/null
    fi
}

detect_technologies() {
    echo ""
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${CYAN}  Detecção de Tecnologias Web${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    echo ""

    local url="${TARGET_PROTO}://${TARGET_HOST}:${TARGET_PORT}/"
    local headers="$HEADERS_RAW"
    local body
    if [ "$TARGET_PROTO" = "https" ]; then
        body=$(timeout 10 curl -s -k -L "$url" 2>/dev/null || true)
    else
        body=$(timeout 10 curl -s -L "$url" 2>/dev/null || true)
    fi

    local techs=()

    if echo "$headers" | grep -qi "^server:"; then
        local srv
        srv=$(echo "$headers" | grep -i "^server:" | head -1 | cut -d: -f2- | xargs)
        techs+=("Server: $srv")
    fi

    if echo "$headers" | grep -qi "^x-powered-by:"; then
        local powered
        powered=$(echo "$headers" | grep -i "^x-powered-by:" | head -1 | cut -d: -f2- | xargs)
        techs+=("X-Powered-By: $powered")
    fi

    if echo "$headers" | grep -qi "^x-generator:"; then
        local gen
        gen=$(echo "$headers" | grep -i "^x-generator:" | head -1 | cut -d: -f2- | xargs)
        techs+=("Generator: $gen")
    fi

    if [ -n "$body" ]; then
        if echo "$body" | grep -qi "wp-content\|wp-includes\|wordpress"; then
            techs+=("CMS: WordPress")
        fi
        if echo "$body" | grep -qi "Joomla!\|com_content\|com_modules"; then
            techs+=("CMS: Joomla")
        fi
        if echo "$body" | grep -qi "Drupal\|drupal.js\|drupal.org"; then
            techs+=("CMS: Drupal")
        fi
        if echo "$body" | grep -qi "Shopify\|shopify."; then
            techs+=("E-commerce: Shopify")
        fi
        if echo "$body" | grep -qi "Magento\|magestore\|Mage."; then
            techs+=("E-commerce: Magento")
        fi
        if echo "$body" | grep -qi "csrf-token.*name.*csrf"; then
            techs+=("Framework: CSRF protection detected")
        fi
    fi

    if [ ${#techs[@]} -eq 0 ]; then
        echo -e "  ${YELLOW}[!] Nenhuma tecnologia específica detectada${RESET}"
    else
        for tech in "${techs[@]}"; do
            echo -e "  ${GREEN}[+]${RESET} $tech"
        done
    fi
}

check_ssl() {
    if [ "$TARGET_PROTO" != "https" ]; then
        echo -e "\n${YELLOW}[!] O alvo não é HTTPS, pulando verificação SSL${RESET}"
        return
    fi

    echo ""
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${CYAN}  Verificação de Certificado SSL/TLS${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    echo ""

    if command -v openssl &>/dev/null; then
        local cert_info
        cert_info=$(timeout 10 openssl s_client -connect "${TARGET_HOST}:${TARGET_PORT}" -servername "$TARGET_HOST" </dev/null 2>/dev/null)

        if [ -n "$cert_info" ]; then
            local subject
            subject=$(echo "$cert_info" | openssl x509 -noout -subject 2>/dev/null)
            local issuer
            issuer=$(echo "$cert_info" | openssl x509 -noout -issuer 2>/dev/null)
            local dates
            dates=$(echo "$cert_info" | openssl x509 -noout -dates 2>/dev/null)
            local expire_epoch
            expire_epoch=$(echo "$cert_info" | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
            local expiry_date
            expiry_date=$(date -d "$expire_epoch" +%s 2>/dev/null || echo 0)
            local now
            now=$(date +%s)
            local days_left=$(( (expiry_date - now) / 86400 ))

            echo -e "  Subject: ${CYAN}$subject${RESET}"
            echo -e "  Issuer:  ${CYAN}$issuer${RESET}"
            echo ""
            echo "$dates"
            echo ""

            if [ "$days_left" -lt 0 ]; then
                echo -e "  ${RED}[!] Certificado EXPIRADO há ${days_left#-} dias${RESET}"
            elif [ "$days_left" -lt 30 ]; then
                echo -e "  ${YELLOW}[!] Certificado expira em $days_left dias (em breve)${RESET}"
            else
                echo -e "  ${GREEN}[OK]${RESET} Certificado válido por mais $days_left dias"
            fi

            local cn
            cn=$(echo "$subject" | grep -oP 'CN\s*=\s*\K[^,]+' | head -1)
            if [ -n "$cn" ] && [ "$cn" != "$TARGET_HOST" ]; then
                echo -e "  ${YELLOW}[!]${RESET} CN incompatível: cert=$cn, host=$TARGET_HOST"
            fi
        else
            echo -e "${RED}[!] Falha ao obter certificado SSL${RESET}"
        fi
    else
        echo -e "${YELLOW}[!] openssl não disponível${RESET}"
    fi
}

find_forms() {
    echo ""
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${CYAN}  Descoberta de Formulários${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    echo ""

    local url="${TARGET_PROTO}://${TARGET_HOST}:${TARGET_PORT}/"
    local body
    if [ "$TARGET_PROTO" = "https" ]; then
        body=$(timeout 10 curl -s -k -L "$url" 2>/dev/null || true)
    else
        body=$(timeout 10 curl -s -L "$url" 2>/dev/null || true)
    fi

    if [ -z "$body" ]; then
        echo -e "${YELLOW}[!] Não foi possível obter o corpo da página${RESET}"
        return
    fi

    local form_count=0
    while IFS= read -r form_block; do
        local action method
        action=$(echo "$form_block" | grep -oP 'action="\K[^"]+' | head -1)
        method=$(echo "$form_block" | grep -oP 'method="\K[^"]+' | head -1)
        [ -z "$action" ] && action="(default)"
        [ -z "$method" ] && method="GET"
        local input_count
        input_count=$(echo "$form_block" | grep -cP '<input|<select|<textarea' || true)
        form_count=$((form_count + 1))
        echo -e "  ${GREEN}[Form $form_count]${RESET} action=$action method=$method inputs=$input_count"
    done < <(echo "$body" | grep -oP '<form[^>]*>.*?</form>' || true)

    if [ "$form_count" -eq 0 ]; then
        echo -e "  ${YELLOW}[!] Nenhum formulário detectado na página principal${RESET}"
    else
        echo -e "\n  ${CYAN}Total: $form_count formulário(s) detectado(s)${RESET}"
    fi
}

generate_report() {
    local server_header
    server_header=$(echo "$HEADERS_RAW" | grep -i "^server:" | head -1 | sed 's/^[Ss][Ee][Rr][Vv][Ee][Rr]:\s*//')

    local content
    content="==================================================
  Relatório de Auditoria Web
  Alvo: $TARGET_URL
  Data: $(date)
==================================================

--- Cabeçalhos ---
$HEADERS_RAW

--- Análise de Segurança ---
HSTS: $(echo "$HEADERS_RAW" | grep -qi "^strict-transport-security:" && echo "Presente" || echo "Ausente")
X-Frame-Options: $(echo "$HEADERS_RAW" | grep -qi "^x-frame-options:" && echo "Presente" || echo "Ausente")
X-XSS-Protection: $(echo "$HEADERS_RAW" | grep -qi "^x-xss-protection:" && echo "Presente" || echo "Ausente")
X-Content-Type-Options: $(echo "$HEADERS_RAW" | grep -qi "^x-content-type-options:" && echo "Presente" || echo "Ausente")
Content-Security-Policy: $(echo "$HEADERS_RAW" | grep -qi "^content-security-policy:" && echo "Presente" || echo "Ausente")
Referrer-Policy: $(echo "$HEADERS_RAW" | grep -qi "^referrer-policy:" && echo "Presente" || echo "Ausente")
Permissions-Policy: $(echo "$HEADERS_RAW" | grep -qi "^permissions-policy:" && echo "Presente" || echo "Ausente")
$(if [ -n "$server_header" ]; then echo "Server Header: $server_header"; fi)

--- Tecnologias ---
Protocolo: $TARGET_PROTO
Porta: $TARGET_PORT
--- SSL ---
$(if [ "$TARGET_PROTO" = "https" ]; then echo "SSL/TLS habilitado"; else echo "SSL/TLS não habilitado"; fi)"

    local outfile
    outfile=$(save_results_file "web_audit" "$content")
    [ -n "$outfile" ] && REPORT_FILE="$outfile"
}

parse_cli_args TARGET_URL _unused_port "$@"

main() {
    log "=== START Web Audit ==="
    show_banner "Auditor Web"
    show_disclaimer
    check_deps "curl" "openssl"

    step "Digite a URL alvo"
    enter_target

    step "Análise de cabeçalhos HTTP"
    analyze_headers

    step "Detecção de tecnologias web"
    detect_technologies

    step "Verificação SSL/TLS"
    check_ssl

    step "Descoberta de formulários"
    find_forms

    step "Força bruta de diretórios"
    dir_brute_force

    step "Gerar relatório"
    generate_report

    echo ""
    log "=== END Web Audit ==="
    save_resumo "Alvo: $TARGET_URL
Host: $TARGET_HOST
Porta: $TARGET_PORT
Protocolo: $TARGET_PROTO
Relatório: ${REPORT_FILE:-N/A}"
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${GREEN}  Auditoria web concluída!${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    if [ -n "$REPORT_FILE" ]; then
        echo -e "  Relatório: $REPORT_FILE"
    fi
    echo -e "${CYAN}================================================${RESET}"
}

main
