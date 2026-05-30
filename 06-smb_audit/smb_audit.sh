#!/usr/bin/env bash

set -uo pipefail

source "$(dirname "$0")/../utils/common.sh"

# =============================================================================
#  SMB Auditor - SMB Security Audit Tool
#  Interactive script for SMB protocol security auditing
# =============================================================================
#  LEGAL DISCLAIMER:
#  This script is for educational purposes and authorized security testing only.
#  Unauthorized use against networks you do not own or have explicit permission
#  to test is illegal. The author is not responsible for any misuse.
# =============================================================================

TARGET=""
SMB_PORTS_OPEN=false
SMB_VERSION=""
NULL_SESSION_OK=false
SHARES=()
USERS=()
OS_VERSION=""
OUTPUT_FILE=""

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

check_ports() {
    echo -e "\n${YELLOW}[*] Verificando portas SMB (139, 445)...${RESET}"

    local ports_open=0

    for port in 139 445; do
        timeout 2 bash -c "echo >/dev/tcp/$TARGET/$port" 2>/dev/null && {
            echo -e "  ${GREEN}[+] Porta $port está ABERTA${RESET}"
            ports_open=$((ports_open + 1))
        } || {
            echo -e "  ${RED}[-] Porta $port está FECHADA${RESET}"
        }
    done

    if [ "$ports_open" -eq 0 ]; then
        echo -e "\n${YELLOW}[!] Nenhuma porta SMB aberta. Tentando scan SYN do nmap...${RESET}"
        if command -v nmap &>/dev/null; then
            local nmap_result
            nmap_result=$(nmap -p 139,445 -T4 "$TARGET" 2>/dev/null)
            for port in 139 445; do
                if echo "$nmap_result" | grep -q "${port}/tcp.*open"; then
                    echo -e "  ${GREEN}[+] Porta $port está ABERTA (nmap)${RESET}"
                    ports_open=$((ports_open + 1))
                fi
            done
        fi
    fi

    if [ "$ports_open" -gt 0 ]; then
        SMB_PORTS_OPEN=true
    else
        echo -e "\n${RED}[!] Portas SMB fechadas. Abortando auditoria SMB.${RESET}"
        log_error "SMB ports closed on $TARGET"
    fi
}

detect_smb_version() {
    echo -e "\n${YELLOW}[*] Detectando versão SMB...${RESET}"

    if command -v nmap &>/dev/null; then
        local script_result
        script_result=$(nmap -p 445 --script smb-protocols "$TARGET" 2>/dev/null)

        if echo "$script_result" | grep -q "SMBv1"; then
            SMB_VERSION+="SMBv1 "
        fi
        if echo "$script_result" | grep -q "SMBv2"; then
            SMB_VERSION+="SMBv2 "
        fi
        if echo "$script_result" | grep -q "SMBv3"; then
            SMB_VERSION+="SMBv3 "
        fi
    fi

    if [ -z "$SMB_VERSION" ]; then
        local raw
        raw=$(timeout 5 bash -c "echo -ne '\x00\x00\x00\xa0\xfe\x53\x4d\x42\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00' >/dev/tcp/$TARGET/445" 2>&1) || true
        [ -n "$raw" ] && SMB_VERSION="SMBv1 (detected via raw socket)"
    fi

    if [ -n "$SMB_VERSION" ]; then
        echo -e "  ${GREEN}[+] Versão SMB: $SMB_VERSION${RESET}"
    else
        echo -e "  ${YELLOW}[!] Não foi possível determinar a versão SMB${RESET}"
        SMB_VERSION="Unknown"
    fi
}

test_null_session() {
    echo -e "\n${YELLOW}[*] Testando sessão nula (conexão SMB sem credenciais)...${RESET}"

    if command -v smbclient &>/dev/null; then
        local result
        result=$(timeout 5 smbclient -L "//$TARGET" -N -W WORKGROUP 2>&1 || true)

        if echo "$result" | grep -qi "Sharename\|Anonymous\|Workgroup\|Domain\["; then
            NULL_SESSION_OK=true
            echo -e "  ${RED}[!] SESSÃO NULA É POSSÍVEL!${RESET}"
            echo -e "  ${RED}[!] Alvo permite conexões SMB anônimas${RESET}"
        else
            echo -e "  ${GREEN}[+] Sessão nula não permitida (acesso negado)${RESET}"
        fi
    else
        echo -e "  ${YELLOW}[!] smbclient não instalado, tentando verificação raw /dev/tcp...${RESET}"
        local raw_check
        raw_check=$(timeout 3 bash -c "echo >/dev/tcp/$TARGET/445" 2>&1 || true)
        if [ -n "$raw_check" ]; then
            echo -e "  ${YELLOW}[!] Porta aberta, mas smbclient é necessário para teste de sessão nula${RESET}"
        fi
    fi
}

enumerate_shares() {
    echo -e "\n${YELLOW}[*] Enumerando compartilhamentos SMB...${RESET}"

    if $NULL_SESSION_OK && command -v smbclient &>/dev/null; then
        local share_list
        share_list=$(timeout 10 smbclient -L "//$TARGET" -N -W WORKGROUP 2>/dev/null)

        if [ -n "$share_list" ]; then
            while IFS= read -r line; do
                if echo "$line" | grep -qE '^\s+\S+\s+Disk$|^\s+\S+\s+IPC$|^\s+\S+\s+Printer'; then
                    local share_name
                    share_name=$(echo "$line" | awk '{print $1}')
                    local share_type
                    share_type=$(echo "$line" | awk '{print $2}')
                    SHARES+=("$share_name|$share_type")
                    echo -e "  ${GREEN}[+]${RESET} $share_name ($share_type)"
                fi
            done <<< "$share_list"
        fi
    fi

    if [ ${#SHARES[@]} -eq 0 ]; then
        if command -v nmap &>/dev/null; then
            echo -e "  ${YELLOW}[!] Tentando nmap smb-enum-shares...${RESET}"
            local nmap_shares
            nmap_shares=$(nmap -p 445 --script smb-enum-shares "$TARGET" 2>/dev/null)
            while IFS= read -r line; do
                if echo "$line" | grep -qP '^\s+\S+'; then
                    local share_name
                    share_name=$(echo "$line" | awk '{print $1}' | sed 's/://')
                    local share_note
                    share_note=$(echo "$line" | sed 's/^[^:]*://' | xargs)
                    if [ -n "$share_name" ] && [ ${#share_name} -gt 1 ]; then
                        SHARES+=("$share_name|$share_note")
                        echo -e "  ${GREEN}[+]${RESET} $share_name - $share_note"
                    fi
                fi
            done <<< "$nmap_shares"
        fi
    fi

    if [ ${#SHARES[@]} -eq 0 ]; then
        echo -e "  ${YELLOW}[!] Nenhum compartilhamento encontrado${RESET}"
    fi
}

enumerate_users() {
    echo -e "\n${YELLOW}[*] Enumerando usuários via SMB...${RESET}"

    if command -v nmap &>/dev/null; then
        local users_result
        users_result=$(nmap -p 445 --script smb-enum-users "$TARGET" 2>/dev/null)

        local in_users=false
        while IFS= read -r line; do
            if echo "$line" | grep -q "Users$"; then
                in_users=true
                continue
            fi
            if $in_users; then
                if echo "$line" | grep -qP '^\s+\w'; then
                    local user
                    user=$(echo "$line" | xargs)
                    USERS+=("$user")
                    echo -e "  ${GREEN}[+]${RESET} User: $user"
                fi
                if echo "$line" | grep -q "^[^ ]"; then
                    in_users=false
                fi
            fi
        done <<< "$users_result"
    fi

    if command -v enum4linux &>/dev/null; then
        echo -e "  ${YELLOW}[!] Executando enum4linux para enumeração de usuários...${RESET}"
        local enum_out
        enum_out=$(timeout 30 enum4linux -U "$TARGET" 2>/dev/null)
        while IFS= read -r line; do
            if echo "$line" | grep -qP '^user:\[\S+\]'; then
                local user
                user=$(echo "$line" | grep -oP 'user:\[\K[^\]]+')
                if [ -n "$user" ]; then
                    USERS+=("$user")
                    echo -e "  ${GREEN}[+]${RESET} User: $user"
                fi
            fi
        done <<< "$enum_out"
    fi

    if [ ${#USERS[@]} -eq 0 ]; then
        echo -e "  ${YELLOW}[!] Nenhum usuário encontrado${RESET}"
    fi
}

detect_os() {
    echo -e "\n${YELLOW}[*] Detectando versão do SO via SMB...${RESET}"

    if command -v nmap &>/dev/null; then
        local os_result
        os_result=$(nmap -p 445 --script smb-os-discovery "$TARGET" 2>/dev/null)

        OS_VERSION=$(echo "$os_result" | grep -i "OS:\|LanManager\|Windows\|Samba" | head -5)

        if [ -n "$OS_VERSION" ]; then
            echo -e "  ${GREEN}[+] SO/Versão:${RESET}"
            echo "$OS_VERSION" | while IFS= read -r line; do
                echo "    $line"
            done
        else
            echo -e "  ${YELLOW}[!] Não foi possível determinar a versão do SO${RESET}"
            OS_VERSION="Unknown"
        fi
    else
        echo -e "  ${YELLOW}[!] nmap não disponível, não é possível detectar o SO${RESET}"
        OS_VERSION="Unknown"
    fi
}

display_recommendations() {
    echo ""
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${CYAN}  Avaliação de Segurança${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    echo ""

    local risk="Low"
    local issues=()

    if echo "$SMB_VERSION" | grep -qi "SMBv1"; then
        risk="High"
        issues+=("SMBv1 enabled - vulnerable to EternalBlue (MS17-010)")
    fi

    if $NULL_SESSION_OK; then
        risk="High"
        issues+=("Null sessions allowed - anonymous access possible")
    fi

    if [ ${#SHARES[@]} -gt 0 ]; then
        for share in "${SHARES[@]}"; do
            local sname="${share%%|*}"
            if [ "$sname" != "IPC$" ] && [ "$sname" != "ADMIN$" ]; then
                issues+=("Share '$sname' is accessible - verify access controls")
            fi
        done
    fi

    if [ ${#USERS[@]} -gt 0 ]; then
        if [ "$risk" != "High" ]; then risk="Medium"; fi
        issues+=("${#USERS[@]} user(s) enumerated - review account exposure")
    fi

    if [ ${#issues[@]} -gt 0 ]; then
        echo -e "  ${BOLD}Nível de Risco: ${RED}$risk${RESET}${RESET}"
        echo ""
        echo -e "  ${BOLD}Problemas Encontrados:${RESET}"
        for issue in "${issues[@]}"; do
            echo -e "    ${RED}[!]${RESET} $issue"
        done
    else
        echo -e "  ${GREEN}[+] Nenhum problema SMB significativo detectado${RESET}"
    fi

    echo ""
    echo -e "  ${CYAN}Recomendações:${RESET}"
    echo "    1. Desabilitar SMBv1 se estiver habilitado"
    echo "    2. Restringir acesso SMB com regras de firewall"
    echo "    3. Desabilitar sessões nulas (restringir acesso anônimo)"
    echo "    4. Usar senhas fortes para contas locais"
    echo "    5. Aplicar as últimas correções de segurança"
    echo "    6. Limitar compartilhamentos expostos apenas ao necessário"
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
                local outfile="$AUDIT_DIR/smb_audit_$(date +%Y%m%d_%H%M%S).txt"
                {
                    echo "=================================================="
                    echo "  Relatório de Auditoria SMB"
                    echo "  Alvo: $TARGET"
                    echo "  Data: $(date)"
                    echo "=================================================="
                    echo ""
                    echo "Portas Abertas: $SMB_PORTS_OPEN"
                    echo "Versão SMB: $SMB_VERSION"
                    echo "Sessão Nula: $NULL_SESSION_OK"
                    echo "Versão do SO: $OS_VERSION"
                    echo ""
                    echo "--- Compartilhamentos ---"
                    for share in "${SHARES[@]}"; do
                        echo "$share"
                    done
                    echo ""
                    echo "--- Usuários ---"
                    for user in "${USERS[@]}"; do
                        echo "$user"
                    done
                    echo ""
                    echo "--- Problemas de Segurança ---"
                    if echo "$SMB_VERSION" | grep -qi "SMBv1"; then
                        echo "[ALTO] SMBv1 habilitado - vulnerável ao EternalBlue"
                    fi
                    if $NULL_SESSION_OK; then
                        echo "[ALTO] Sessões nulas permitidas"
                    fi
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
    log "=== START SMB Audit ==="
    show_banner "SMB Auditor"
    show_disclaimer
    check_deps "nmap"

    step "Digite o alvo"
    enter_target

    step "Verificação de portas (139, 445)"
    check_ports
    ! $SMB_PORTS_OPEN && exit 1

    step "Detecção de versão SMB"
    detect_smb_version

    step "Teste de sessão nula"
    test_null_session

    step "Enumeração de compartilhamentos"
    enumerate_shares

    step "Enumeração de usuários"
    enumerate_users

    step "Detecção de versão do SO"
    detect_os

    step "Recomendações de segurança"
    display_recommendations

    step "Exportar resultados"
    export_results

    echo ""
    log "=== END SMB Audit ==="
    local shares_resumo=""
    for s in "${SHARES[@]}"; do shares_resumo+="  $s"$'\n'; done
    local users_resumo=""
    for u in "${USERS[@]}"; do users_resumo+="  $u"$'\n'; done
    save_resumo "Alvo: $TARGET
Portas SMB abertas: $SMB_PORTS_OPEN
Versão SMB: $SMB_VERSION
Sessão nula: $NULL_SESSION_OK
SO: $OS_VERSION
Compartilhamentos:
$shares_resumo
Usuários:
$users_resumo
Arquivo de resultados: ${OUTPUT_FILE:-N/A}"
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${GREEN}  Auditoria SMB concluída!${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    if [ -n "$OUTPUT_FILE" ]; then
        echo -e "  Relatório: $OUTPUT_FILE"
    fi
    echo -e "${CYAN}================================================${RESET}"
}

main
