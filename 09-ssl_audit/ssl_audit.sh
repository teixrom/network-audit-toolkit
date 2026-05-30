#!/usr/bin/env bash

set -uo pipefail

source "$(dirname "$0")/../utils/common.sh"

# =============================================================================
#  SSL/TLS Auditor - SSL/TLS Security Audit Tool
#  Interactive script for auditing SSL/TLS configuration
# =============================================================================
#  LEGAL DISCLAIMER:
#  This script is for educational purposes and authorized security testing only.
#  Unauthorized use against networks you do not own or have explicit permission
#  to test is illegal. The author is not responsible for any misuse.
# =============================================================================

TARGET_HOST=""
TARGET_PORT=""
TARGET_PROTO=""
CERT_INFO=""
REPORT_FILE=""

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

cleanup() {
    echo -e "\n${YELLOW}[!] Limpando...${RESET}"
    cleanup_temp
    log "Limpeza realizada"
}
trap cleanup EXIT

enter_target() {
    while true; do
        read_input input "Alvo (ex: example.com:443, https://example.com)"
        input=$(echo "$input" | sed -E 's|^https?://||' | sed -E 's|^ssl://||')
        if echo "$input" | grep -q ":"; then
            TARGET_HOST=$(echo "$input" | cut -d: -f1)
            TARGET_PORT=$(echo "$input" | cut -d: -f2)
        else
            TARGET_HOST="$input"
            TARGET_PORT="443"
        fi
        TARGET_PORT=$(echo "$TARGET_PORT" | grep -oP '^\d+')
        if [ -n "$TARGET_PORT" ]; then
            break
        fi
        echo -e "${RED}Porta inválida${RESET}"
    done

    echo -e "${GREEN}[+] Alvo: $TARGET_HOST:$TARGET_PORT${RESET}"
}

fetch_certificate() {
    echo -e "\n${YELLOW}[*] Buscando certificado SSL/TLS...${RESET}"

    CERT_INFO=$(timeout 15 openssl s_client -connect "${TARGET_HOST}:${TARGET_PORT}" -servername "$TARGET_HOST" </dev/null 2>/dev/null)

    if [ -z "$CERT_INFO" ]; then
        echo -e "${RED}[!] Falha ao conectar ou obter certificado${RESET}"
        log_error "Falha ao obter certificado de $TARGET_HOST:$TARGET_PORT"
        return 1
    fi
    log "Certificado obtido de $TARGET_HOST:$TARGET_PORT"
    return 0
}

analyze_certificate() {
    step "Análise do certificado"
    echo ""

    if ! fetch_certificate; then
        echo -e "${RED}[!] Não é possível analisar o certificado sem conexão${RESET}"
        return
    fi

    local cert_pem
    cert_pem=$(echo "$CERT_INFO" | sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p')

    if [ -z "$cert_pem" ]; then
        echo -e "${RED}[!] Nenhum dado de certificado recebido${RESET}"
        return
    fi

    local subject issuer start_date end_date serial fingerprint
    subject=$(echo "$cert_pem" | openssl x509 -noout -subject 2>/dev/null)
    issuer=$(echo "$cert_pem" | openssl x509 -noout -issuer 2>/dev/null)
    start_date=$(echo "$cert_pem" | openssl x509 -noout -startdate 2>/dev/null | cut -d= -f2)
    end_date=$(echo "$cert_pem" | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
    serial=$(echo "$cert_pem" | openssl x509 -noout -serial 2>/dev/null | cut -d= -f2)
    fingerprint=$(echo "$cert_pem" | openssl x509 -noout -fingerprint -sha256 2>/dev/null | cut -d= -f2)

    echo -e "${CYAN}--- Detalhes do Certificado ---${RESET}"
    echo ""
    echo -e "  ${BOLD}Assunto:${RESET}      $subject"
    echo -e "  ${BOLD}Emissor:${RESET}       $issuer"
    echo -e "  ${Bold}Serial:${RESET}       $serial"
    echo -e "  ${BOLD}SHA256 FP:${RESET}    $fingerprint"
    echo ""

    echo -e "${CYAN}--- Período de Validade ---${RESET}"
    echo ""
    echo -e "  ${BOLD}Não Antes de:${RESET} $start_date"
    echo -e "  ${BOLD}Não Depois de:${RESET}  $end_date"

    local expire_epoch now days_left
    expire_epoch=$(date -d "$end_date" +%s 2>/dev/null || echo 0)
    now=$(date +%s)
    days_left=$(( (expire_epoch - now) / 86400 ))

    echo ""
    if [ "$days_left" -lt 0 ]; then
        echo -e "  ${RED}[FAIL]${RESET} Certificado EXPIRADO há $(( -days_left )) dias"
        FAIL_COUNT=$((FAIL_COUNT + 1))
    elif [ "$days_left" -lt 30 ]; then
        echo -e "  ${YELLOW}[AVISO]${RESET} Certificado expira em $days_left dias (menos de 30)"
        WARN_COUNT=$((WARN_COUNT + 1))
    else
        echo -e "  ${GREEN}[PASS]${RESET} Certificado válido por mais $days_left dias"
        PASS_COUNT=$((PASS_COUNT + 1))
    fi

    echo ""
    echo -e "${CYAN}--- Nomes Alternativos do Sujeito (SAN) ---${RESET}"
    echo ""
    local sans
    sans=$(echo "$cert_pem" | openssl x509 -noout -ext subjectAltName 2>/dev/null)
    if [ -n "$sans" ]; then
        echo "$sans" | grep -oP 'DNS:[^,]+' | sed 's/DNS:/  - /'
    else
        local cn
        cn=$(echo "$subject" | grep -oP 'CN\s*=\s*\K[^,]+' | head -1)
        [ -n "$cn" ] && echo -e "  - $cn (apenas CN, sem extensão SAN)"
    fi

    echo ""
    echo -e "${CYAN}--- Cadeia do Certificado ---${RESET}"
    echo ""
    echo "$CERT_INFO" | sed -n '/Certificate chain/,/---/p' | head -20

    echo ""
    local subject_hash
    subject_hash=$(echo "$subject" | grep -oP 'CN\s*=\s*\K[^,]+' | head -1)
    local issuer_hash
    issuer_hash=$(echo "$issuer" | grep -oP 'CN\s*=\s*\K[^,]+' | head -1)
    if [ "$subject_hash" = "$issuer_hash" ] || echo "$issuer" | grep -qi "$subject_hash"; then
        echo -e "  ${YELLOW}[AVISO]${RESET} Certificado autoassinado detectado"
        WARN_COUNT=$((WARN_COUNT + 1))
    fi
}

check_protocols() {
    step "Verificação de suporte a protocolos"
    echo ""

    local protocols=("ssl2" "ssl3" "tls1" "tls1_1" "tls1_2" "tls1_3")
    local names=("SSLv2" "SSLv3" "TLSv1.0" "TLSv1.1" "TLSv1.2" "TLSv1.3")
    local obsolete=("ssl2" "ssl3" "tls1" "tls1_1")
    local results=()

    for i in "${!protocols[@]}"; do
        local proto="${protocols[$i]}"
        local pname="${names[$i]}"
        printf "  Testando %-10s ... " "$pname"

        local is_obsolete=0
        for o in "${obsolete[@]}"; do
            [ "$proto" = "$o" ] && is_obsolete=1 && break
        done

        if [ "$proto" = "tls1_3" ]; then
            local result
            result=$(timeout 5 openssl s_client -connect "${TARGET_HOST}:${TARGET_PORT}" -servername "$TARGET_HOST" -tls1_3 </dev/null 2>/dev/null)
            if echo "$result" | grep -q "^CONNECTED"; then
                echo -e "${GREEN}SUPORTADO${RESET}"
                results+=("$pname|PASS")
                PASS_COUNT=$((PASS_COUNT + 1))
            else
                echo -e "${GREEN}não suportado${RESET}"
                results+=("$pname|PASS")
                PASS_COUNT=$((PASS_COUNT + 1))
            fi
        else
            local flag
            flag=$(echo "$proto" | tr '[:lower:]' '[:upper:]')
            local result
            result=$(timeout 5 openssl s_client -connect "${TARGET_HOST}:${TARGET_PORT}" -servername "$TARGET_HOST" "-${flag}" </dev/null 2>/dev/null)
            if echo "$result" | grep -q "^CONNECTED"; then
                if [ "$is_obsolete" -eq 1 ]; then
                    echo -e "${RED}SUPORTADO${RESET}"
                    results+=("$pname|FAIL")
                    FAIL_COUNT=$((FAIL_COUNT + 1))
                else
                    echo -e "${GREEN}SUPORTADO${RESET}"
                    results+=("$pname|PASS")
                    PASS_COUNT=$((PASS_COUNT + 1))
                fi
            else
                echo -e "${GREEN}não suportado${RESET}"
                results+=("$pname|PASS")
                PASS_COUNT=$((PASS_COUNT + 1))
            fi
        fi
    done

    echo ""
    echo -e "${CYAN}--- Resumo de Protocolos ---${RESET}"
    echo ""
    printf "${BOLD}%-12s %s${RESET}\n" "Protocolo" "Status"
    echo "------------------------"
    for r in "${results[@]}"; do
        local p="${r%%|*}"
        local s="${r#*|}"
        if [ "$s" = "PASS" ]; then
            printf "%-12s ${GREEN}%-15s${RESET}\n" "$p" "Não suportado (OK)"
        else
            printf "%-12s ${RED}%-15s${RESET}\n" "$p" "SUPORTADO (RUIM)"
        fi
    done
}

enum_ciphers() {
    step "Enumeração de cifras"
    echo ""

    local ciphers
    ciphers=$(timeout 30 nmap --script ssl-enum-ciphers -p "${TARGET_PORT}" "$TARGET_HOST" 2>/dev/null)

    if [ -n "$ciphers" ]; then
        echo "$ciphers" | grep -A 100 "| ssl-enum-ciphers" | while IFS= read -r line; do
            local clean
            clean=$(echo "$line" | sed 's/^|[ _]//' | sed 's/^[[:space:]]*//')
            [ -n "$clean" ] && echo "  $clean"
        done
    else
        echo -e "${YELLOW}[!] Nmap ssl-enum-ciphers indisponível, usando openssl...${RESET}"
        echo ""
        local cipher_list
        cipher_list=$(timeout 15 openssl ciphers 'ALL:eNULL' 2>/dev/null | tr ':' '\n')
        local count=0
        while IFS= read -r cipher; do
            [ -z "$cipher" ] && continue
            local result
            result=$(timeout 3 openssl s_client -connect "${TARGET_HOST}:${TARGET_PORT}" -servername "$TARGET_HOST" -cipher "$cipher" </dev/null 2>/dev/null)
            if echo "$result" | grep -q "^CONNECTED"; then
                echo -e "  ${GREEN}[+]${RESET} $cipher"
                count=$((count + 1))
            fi
        done <<< "$cipher_list"
        [ "$count" -eq 0 ] && echo -e "  ${YELLOW}[!] Nenhuma cifra pôde ser testada${RESET}"
    fi
}

security_checks() {
    step "Verificações de segurança"
    echo ""

    echo -e "${CYAN}--- Detecção de Cifras Fracas ---${RESET}"
    echo ""
    local weak_names=("RC4" "DES" "3DES" "EXPORT")
    for weak in "${weak_names[@]}"; do
        local result
        result=$(timeout 5 openssl s_client -connect "${TARGET_HOST}:${TARGET_PORT}" -servername "$TARGET_HOST" -cipher "$weak" </dev/null 2>/dev/null)
        if echo "$result" | grep -q "^CONNECTED"; then
            echo -e "  ${RED}[FAIL]${RESET} cifra $weak suportada"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        else
            echo -e "  ${GREEN}[PASS]${RESET} cifra $weak não suportada"
            PASS_COUNT=$((PASS_COUNT + 1))
        fi
    done

    echo ""
    echo -e "${CYAN}--- Perfect Forward Secrecy (PFS) ---${RESET}"
    echo ""
    local pfs_ciphers
    pfs_ciphers=$(timeout 5 openssl s_client -connect "${TARGET_HOST}:${TARGET_PORT}" -servername "$TARGET_HOST" -cipher "ECDHE" </dev/null 2>/dev/null)
    if echo "$pfs_ciphers" | grep -q "^CONNECTED"; then
        echo -e "  ${GREEN}[PASS]${RESET} Cifras ECDHE (PFS) suportadas"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo -e "  ${YELLOW}[INFO]${RESET} Cifras ECDHE não detectadas no teste básico"
    fi

    local dhe_ciphers
    dhe_ciphers=$(timeout 5 openssl s_client -connect "${TARGET_HOST}:${TARGET_PORT}" -servername "$TARGET_HOST" -cipher "DHE" </dev/null 2>/dev/null)
    if echo "$dhe_ciphers" | grep -q "^CONNECTED"; then
        echo -e "  ${GREEN}[PASS]${RESET} Cifras DHE (PFS) suportadas"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo -e "  ${YELLOW}[INFO]${RESET} Cifras DHE não detectadas no teste básico"
    fi

    echo ""
    echo -e "${CYAN}--- Verificação de Cabeçalho HSTS ---${RESET}"
    echo ""
    local hsts_check
    hsts_check=$(timeout 10 curl -sI -k "https://${TARGET_HOST}:${TARGET_PORT}/" 2>/dev/null | grep -i "^strict-transport-security:")
    if [ -n "$hsts_check" ]; then
        echo -e "  ${GREEN}[PASS]${RESET} Cabeçalho HSTS presente"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        echo -e "  ${YELLOW}[AVISO]${RESET} Cabeçalho HSTS ausente"
        WARN_COUNT=$((WARN_COUNT + 1))
    fi

    echo ""
    echo -e "${CYAN}--- Teste Heartbleed ---${RESET}"
    echo ""
    local heartbleed
    heartbleed=$(timeout 15 nmap --script ssl-heartbleed -p "${TARGET_PORT}" "$TARGET_HOST" 2>/dev/null)
    if echo "$heartbleed" | grep -qi "VULNERABLE\|NOT VULNERABLE"; then
        if echo "$heartbleed" | grep -qi "State: VULNERABLE\|is VULNERABLE"; then
            echo -e "  ${RED}[FAIL]${RESET} Servidor VULNERÁVEL ao Heartbleed"
            FAIL_COUNT=$((FAIL_COUNT + 1))
        elif echo "$heartbleed" | grep -qi "NOT VULNERABLE"; then
            echo -e "  ${GREEN}[PASS]${RESET} Servidor não vulnerável ao Heartbleed"
            PASS_COUNT=$((PASS_COUNT + 1))
        fi
    else
        local simple_test
        simple_test=$(timeout 10 openssl s_client -connect "${TARGET_HOST}:${TARGET_PORT}" -servername "$TARGET_HOST" -tlsextdebug </dev/null 2>&1)
        if echo "$simple_test" | grep -qi "heartbeat"; then
            echo -e "  ${YELLOW}[INFO]${RESET} Extensão Heartbeat presente (normal em TLS moderno - não indica necessariamente vuln Heartbleed)"
        else
            echo -e "  ${YELLOW}[INFO]${RESET} Não foi possível determinar o status do Heartbleed"
        fi
    fi
}

display_summary() {
    step "Resumo dos resultados"
    echo ""

    local total=$((PASS_COUNT + WARN_COUNT + FAIL_COUNT))
    [ "$total" -eq 0 ] && total=1
    local pass_pct=$((PASS_COUNT * 100 / total))
    local warn_pct=$((WARN_COUNT * 100 / total))
    local fail_pct=$((FAIL_COUNT * 100 / total))

    echo -e "${CYAN}--- Classificação de Segurança ---${RESET}"
    echo ""
    echo -e "  ${GREEN}PASS: $PASS_COUNT ($pass_pct%)${RESET}"
    echo -e "  ${YELLOW}AVISO: $WARN_COUNT ($warn_pct%)${RESET}"
    echo -e "  ${RED}FAIL: $FAIL_COUNT ($fail_pct%)${RESET}"
    echo ""

    local grade="F"
    if [ "$fail_pct" -eq 0 ] && [ "$warn_pct" -le 20 ]; then grade="A"
    elif [ "$fail_pct" -le 10 ] && [ "$warn_pct" -le 30 ]; then grade="B"
    elif [ "$fail_pct" -le 20 ] && [ "$warn_pct" -le 40 ]; then grade="C"
    elif [ "$fail_pct" -le 30 ] && [ "$warn_pct" -le 50 ]; then grade="D"
    elif [ "$fail_pct" -le 50 ]; then grade="E"
    fi

    echo -e "  ${BOLD}Nota Geral: $grade${RESET}"
}

export_report() {
    step "Exportar relatório"
    echo ""

    local cert_summary
    cert_summary=$(echo "$CERT_INFO" | openssl x509 -noout -subject -issuer -dates -fingerprint -sha256 2>/dev/null || echo "N/A")

    local content
    content="==================================================
  Relatório de Auditoria SSL/TLS
  Alvo: $TARGET_HOST:$TARGET_PORT
  Data: $(date)
==================================================

--- Certificado ---
$cert_summary

--- Protocolos ---
Testado: $TARGET_HOST:$TARGET_PORT

--- Resumo ---
PASS: $PASS_COUNT
AVISO: $WARN_COUNT
FAIL: $FAIL_COUNT
Total de testes: $((PASS_COUNT + WARN_COUNT + FAIL_COUNT))"

    local outfile
    outfile=$(save_results_file "ssl_audit" "$content")
    [ -n "$outfile" ] && REPORT_FILE="$outfile"
}

parse_cli_args TARGET_HOST TARGET_PORT "$@"

main() {
    log "=== INÍCIO Auditoria SSL/TLS ==="
    show_banner "SSL/TLS Auditor"
    show_disclaimer
    check_deps "openssl" "nmap" "curl"

    step "Digite o alvo"
    enter_target

    analyze_certificate

    check_protocols

    enum_ciphers

    security_checks

    display_summary

    export_report

    echo ""
    log "=== FIM Auditoria SSL/TLS ==="
    save_resumo "Alvo: $TARGET_HOST:$TARGET_PORT
PASS: $PASS_COUNT
AVISO: $WARN_COUNT
FAIL: $FAIL_COUNT
Total de testes: $((PASS_COUNT + WARN_COUNT + FAIL_COUNT))
Relatório: ${REPORT_FILE:-N/A}"
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${GREEN}  Auditoria SSL/TLS concluída!${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    if [ -n "$REPORT_FILE" ]; then
        echo -e "  Relatório: $REPORT_FILE"
    fi
    echo -e "${CYAN}================================================${RESET}"
}

main
