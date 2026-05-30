#!/usr/bin/env bash

set -uo pipefail

source "$(dirname "$0")/../utils/common.sh"

# =============================================================================
#  Password Auditor - Brute Force Password Testing Tool
#  Interactive script for authorized password strength testing
# =============================================================================
#  LEGAL DISCLAIMER:
#  This script is for educational purposes and authorized security testing only.
#  Unauthorized use against networks you do not own or have explicit permission
#  to test is illegal. The author is not responsible for any misuse.
#  WARNING: Brute force attacks can lock accounts. Use responsibly.
# =============================================================================

TARGETS=()
SERVICE=""
SERVICE_PORT=""
USERNAME=""
USER_LIST=""
WORDLIST=""
THREADS=5
DELAY=1
OUTPUT_FILE=""
CRACKED=()

declare -A SERVICE_MAP=(
    ["SSH"]="22"
    ["FTP"]="21"
    ["HTTP Basic Auth"]="80"
    ["HTTP POST Form"]="80"
    ["RDP"]="3389"
    ["Telnet"]="23"
    ["SMB"]="445"
    ["MySQL"]="3306"
)

SERVICE_NAMES=("SSH" "FTP" "HTTP Basic Auth" "HTTP POST Form" "RDP" "Telnet" "SMB" "MySQL")

cleanup() {
    echo -e "\n${YELLOW}[!] Limpando...${RESET}"
    cleanup_temp
    log "Cleanup performed"
}
trap cleanup EXIT

select_target() {
    local options=("IP único" "Faixa de IP (CIDR)" "Carregar de arquivo")
    local choice
    choice=$(select_from_list "Selecione o tipo de alvo" "${options[@]}")

    case "$choice" in
        "IP único")
            read_input ip "IP alvo"
            TARGETS+=("$ip")
            ;;
        "Faixa de IP (CIDR)")
            read_input cidr "Faixa CIDR (ex: 192.168.1.0/24)"
            if command -v nmap &>/dev/null; then
                local iplist
                iplist=$(nmap -sL -n "$cidr" 2>/dev/null | grep -v "Nmap done" | grep -oP '\d+\.\d+\.\d+\.\d+')
                while IFS= read -r ip; do
                    [ -n "$ip" ] && TARGETS+=("$ip")
                done <<< "$iplist"
            else
                local network base last prefix
                network=$(echo "$cidr" | cut -d/ -f1)
                base=$(echo "$network" | cut -d. -f1-3)
                last=$(echo "$network" | cut -d. -f4)
                prefix=$(echo "$cidr" | cut -d/ -f2)
                local size=$((1 << (32 - prefix)))
                for i in $(seq "$last" $((last + size - 1))); do
                    [ "$i" -gt 255 ] && break
                    TARGETS+=("${base}.${i}")
                done
            fi
            echo -e "${GREEN}[+] Carregados ${#TARGETS[@]} IPs da faixa${RESET}"
            ;;
        *)
            read_input filepath "Caminho do arquivo"
            filepath="${filepath/#\~/$HOME}"
            if [ -f "$filepath" ]; then
                while IFS= read -r line; do
                    ip=$(echo "$line" | xargs)
                    [ -n "$ip" ] && TARGETS+=("$ip")
                done < "$filepath"
                echo -e "${GREEN}[+] Carregados ${#TARGETS[@]} alvos do arquivo${RESET}"
            else
                echo -e "${RED}Arquivo não encontrado${RESET}"
            fi
            ;;
    esac

    echo -e "${GREEN}[+] Alvos: ${TARGETS[*]}${RESET}"
}

select_service() {
    local names=()
    for i in "${!SERVICE_NAMES[@]}"; do
        local svc="${SERVICE_NAMES[$i]}"
        names+=("$svc (porta ${SERVICE_MAP[$svc]})")
    done
    local choice
    choice=$(select_from_list "Selecione o serviço" "${names[@]}")
    SERVICE="${choice%% (*}"
    SERVICE_PORT="${SERVICE_MAP[$SERVICE]}"

    if [ "$SERVICE" = "HTTP POST Form" ]; then
        read_input FORM_URL "URL de login (ex: http://target.com/login.php)"
        read_input FORM_PARAMS "Parâmetros POST (ex: user=^USER^&pass=^PASS^)"
        read_input FORM_FAIL "String de falha (texto em login falho)"
    fi

    if [ "$SERVICE" = "HTTP Basic Auth" ]; then
        read_input BASIC_URL "URL para Basic Auth (ex: http://target.com/protegido)"
    fi

    echo -e "${GREEN}[+] Serviço: $SERVICE (porta $SERVICE_PORT)${RESET}"
}

select_username() {
    local options=("Usuário único" "Arquivo de lista de usuários" "Padrões comuns")
    local choice
    choice=$(select_from_list "Selecione a origem do usuário" "${options[@]}")

    case "$choice" in
        "Usuário único")
            read_input USERNAME "Usuário"
            ;;
        "Arquivo de lista de usuários")
            read_input ul_path "Caminho da lista de usuários"
            ul_path="${ul_path/#\~/$HOME}"
            if [ -f "$ul_path" ]; then
                USER_LIST="$ul_path"
                local count; count=$(wc -l < "$USER_LIST")
                echo -e "${GREEN}[+] Carregados $count usuários de $ul_path${RESET}"
            else
                echo -e "${RED}Arquivo não encontrado${RESET}"
            fi
            ;;
        *)
            local tmpfile; tmpfile=$(mktemp)
            TEMP_FILES+=("$tmpfile")
            printf "admin\nroot\nadministrator\nuser\ntest\noperator\nbackup\nnobody\nguest\nsupport\n" > "$tmpfile"
            USER_LIST="$tmpfile"
            echo -e "${GREEN}[+] Usando nomes de usuário padrão comuns${RESET}"
            ;;
    esac
}

select_wordlist() {
    local options=("rockyou.txt (locais comuns)" "Baixar rockyou do repositório" "Caminho personalizado")
    local choice
    choice=$(select_from_list "Selecione a wordlist" "${options[@]}")

    case "$choice" in
        "${options[0]}")
            local locations=(
                "/usr/share/wordlists/rockyou.txt"
                "/usr/share/wordlists/rockyou.txt.gz"
                "/usr/share/wordlists/rockyou"
                "/usr/share/seclists/Passwords/Common-Passwords/10k-most-common.txt"
                "/usr/share/seclists/Passwords/rockyou.txt"
                "$HOME/wordlists/rockyou.txt"
            )
            local found=false
            for loc in "${locations[@]}"; do
                if [ -f "$loc" ]; then
                    if [[ "$loc" == *.gz ]]; then
                        local tmp; tmp=$(mktemp)
                        TEMP_FILES+=("$tmp")
                        gunzip -c "$loc" > "$tmp" 2>/dev/null && WORDLIST="$tmp"
                    else
                        WORDLIST="$loc"
                    fi
                    echo -e "${GREEN}[+] Wordlist encontrada: $WORDLIST${RESET}"
                    found=true
                    break
                fi
            done
            if ! $found; then
                echo -e "${YELLOW}[!] Nenhuma wordlist encontrada em locais comuns${RESET}"
                if confirm_action "Baixar wordlist de exemplo?"; then
                    choice="${options[1]}"
                else
                    choice="${options[2]}"
                fi
            fi
            ;;
        "${options[1]}")
            local dl_path="$AUDIT_DIR/rockyou.txt"
            if [ ! -f "$dl_path" ]; then
                echo -e "${YELLOW}[!] Baixando wordlist de exemplo (~10k senhas comuns)...${RESET}"
                curl -#L -o "$dl_path" "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Passwords/Common-Passwords/10k-most-common.txt" 2>/dev/null || {
                    echo -e "${RED}[!] Falha no download${RESET}"
                    return
                }
            fi
            WORDLIST="$dl_path"
            echo -e "${GREEN}[+] Wordlist baixada: $WORDLIST${RESET}"
            ;;
        *)
            read_input wl_path "Caminho da wordlist"
            wl_path="${wl_path/#\~/$HOME}"
            if [ -f "$wl_path" ]; then
                WORDLIST="$wl_path"
                local count; count=$(wc -l < "$WORDLIST")
                echo -e "${GREEN}[+] Wordlist carregada: $WORDLIST ($count entradas)${RESET}"
            else
                echo -e "${RED}Arquivo não encontrado${RESET}"
            fi
            ;;
    esac
}

configure_rate_limit() {
    echo ""
    echo -e "${YELLOW}[*] Configurar limitação de taxa${RESET}"
    echo ""
    echo -e "  Threads atuais: $THREADS"
    echo -e "  Atraso atual: ${DELAY}s"
    echo ""

    echo -n "Threads [1-50] ($THREADS): "
    read t_input
    [ -n "$t_input" ] && [[ "$t_input" =~ ^[0-9]+$ ]] && [ "$t_input" -ge 1 ] && [ "$t_input" -le 50 ] && THREADS="$t_input"

    echo -n "Atraso entre tentativas em segundos (0-10) [$DELAY]: "
    read d_input
    [ -n "$d_input" ] && [[ "$d_input" =~ ^[0-9]+(\.[0-9]+)?$ ]] && [ "$(echo "$d_input <= 10" | bc -l)" -eq 1 ] && DELAY="$d_input"

    echo -e "${GREEN}[+] Limite de taxa: $THREADS threads, ${DELAY}s de atraso${RESET}"
}

run_hydra() {
    local target="$1"
    echo -e "\n${YELLOW}[*] Executando hydra contra $target...${RESET}"

    local hydra_args=()
    hydra_args+=("-t" "$THREADS")
    [ "$(echo "$DELAY > 0" | bc -l)" -eq 1 ] && hydra_args+=("-w" "$DELAY")

    if [ -n "$USER_LIST" ]; then
        hydra_args+=("-L" "$USER_LIST")
    else
        hydra_args+=("-l" "$USERNAME")
    fi

    hydra_args+=("-P" "$WORDLIST")

    case "$SERVICE" in
        "SSH") hydra_args+=("ssh://$target:$SERVICE_PORT") ;;
        "FTP") hydra_args+=("ftp://$target:$SERVICE_PORT") ;;
        "HTTP Basic Auth") hydra_args+=("http-get://$target:$SERVICE_PORT/$BASIC_URL") ;;
        "HTTP POST Form") hydra_args+=("http-post-form://$target:$SERVICE_PORT/$FORM_URL:$FORM_PARAMS:$FORM_FAIL") ;;
        "RDP") hydra_args+=("rdp://$target:$SERVICE_PORT") ;;
        "Telnet") hydra_args+=("telnet://$target:$SERVICE_PORT") ;;
        "SMB") hydra_args+=("smb://$target:$SERVICE_PORT") ;;
        "MySQL") hydra_args+=("mysql://$target:$SERVICE_PORT") ;;
    esac

    local tmpfile; tmpfile=$(mktemp)
    TEMP_FILES+=("$tmpfile")

    echo -e "  ${CYAN}hydra ${hydra_args[*]}${RESET}"
    echo ""

    hydra "${hydra_args[@]}" -o "$tmpfile" 2>/dev/null &
    local pid=$!
    local sec=0

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${YELLOW}Executando... %ds${RESET}" "$sec"
        sec=$((sec + 1))
        [ $sec -ge 300 ] && break
        sleep 1
    done
    printf "\n"
    wait "$pid" 2>/dev/null || true

    if [ -s "$tmpfile" ]; then
        local found
        found=$(grep -c "host:" "$tmpfile" 2>/dev/null || echo 0)
        if [ "$found" -gt 0 ]; then
            while IFS= read -r line; do
                CRACKED+=("$target|$line")
                echo -e "  ${RED}[!]${RESET} $line"
            done < "$tmpfile"
        else
            echo -e "  ${YELLOW}[-] Nenhuma credencial encontrada para $target${RESET}"
        fi
    else
        echo -e "  ${YELLOW}[-] Hydra não produziu saída para $target${RESET}"
    fi
}

display_cracked() {
    echo ""
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${CYAN}  Credenciais Quebradas${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    echo ""

    if [ ${#CRACKED[@]} -eq 0 ]; then
        echo -e "${YELLOW}[!] Nenhuma credencial foi quebrada${RESET}"
        return
    fi

    printf "${BOLD}%-20s %-30s${RESET}\n" "Alvo" "Credencial"
    echo "--------------------------------------------------------------"
    for entry in "${CRACKED[@]}"; do
        local target="${entry%%|*}"
        local cred="${entry#*|}"
        printf "%-20s %-30s\n" "$target" "$cred"
    done
}

save_results() {
    local cracked_section="Nenhuma"
    if [ ${#CRACKED[@]} -gt 0 ]; then
        cracked_section=""
        for entry in "${CRACKED[@]}"; do
            cracked_section+="$entry\n"
        done
    fi

    local content
    content="==================================================
  Relatório de Auditoria de Senhas
  Data: $(date)
==================================================

Alvos: ${TARGETS[*]}
Serviço: $SERVICE (porta $SERVICE_PORT)
Threads: $THREADS
Atraso: ${DELAY}s

--- Credenciais Quebradas ---
$cracked_section"

    local outfile
    outfile=$(save_results_file "password_audit" "$content")
    [ -n "$outfile" ] && OUTPUT_FILE="$outfile"
}

parse_cli_args _unused_target _unused_port "$@"

main() {
    log "=== START Password Audit ==="
    show_banner "Password Auditor"
    show_disclaimer
    check_deps "hydra"

    step "Selecione o(s) alvo(s)"
    select_target

    step "Selecione o serviço"
    select_service

    step "Selecione o usuário"
    select_username

    step "Selecione a wordlist"
    select_wordlist

    step "Configurar limitação de taxa"
    configure_rate_limit

    step "Executar hydra"
    for target in "${TARGETS[@]}"; do
        run_hydra "$target"
    done

    step "Exibir credenciais quebradas"
    display_cracked

    step "Salvar resultados"
    save_results

    echo ""
    log "=== END Password Audit ==="
    local cracked_resumo=""
    for c in "${CRACKED[@]}"; do cracked_resumo+="  $c"$'\n'; done
    save_resumo "Alvos: ${TARGETS[*]}
Serviço: $SERVICE (porta $SERVICE_PORT)
Threads: $THREADS
Delay: ${DELAY}s
Credenciais encontradas: ${#CRACKED[@]}
$cracked_resumo
Arquivo de resultados: ${OUTPUT_FILE:-N/A}"
    echo -e "${CYAN}================================================${RESET}"
    echo -e "${GREEN}  Auditoria de senhas concluída!${RESET}"
    echo -e "${CYAN}================================================${RESET}"
    if [ -n "$OUTPUT_FILE" ]; then
        echo -e "  Relatório: $OUTPUT_FILE"
    fi
    echo -e "${CYAN}================================================${RESET}"
}

main
