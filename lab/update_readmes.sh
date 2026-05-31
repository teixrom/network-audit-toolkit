#!/usr/bin/env bash
set -uo pipefail

ROOT="/home/teixrom/projetos/network_audit"
EVIDENCE="$ROOT/audits/evidencias"

strip_ansi() { sed -E 's/\x1b\[[0-9;]*[a-zA-Z]//g'; }

echo ""
echo "Atualizando READMEs com evidencias reais..."
echo ""

for num in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17; do
    mod_dir=$(echo "$ROOT"/"$num"-*/)
    [ ! -d "$mod_dir" ] && continue
    mod_name=$(basename "$mod_dir" | sed 's/^[0-9]*-//')
    readme="$mod_dir/README.md"
    ev_file="$EVIDENCE/${num}-${mod_name}.clean.log"
    [ ! -f "$ev_file" ] && ev_file="$EVIDENCE/${num}-*.clean.log"
    ev_file=$(ls "$EVIDENCE"/${num}-*.clean.log 2>/dev/null | head -1)
    [ -z "$ev_file" ] && { echo "  [SKIP] $num: no evidence"; continue; }

    # Extrair evidencias: remover [LOG], progress bars, linhas vazias repetidas
    evidence=$(strip_ansi < "$ev_file" \
        | grep -v '^\[LOG\]' \
        | grep -v '^  \[.*\] *[0-9]*%' \
        | grep -vE '^  =+$' \
        | sed 's/\r//g' \
        | awk 'NF{p=1} p' \
        | head -60)

    # Encontrar a linha da secao de testes
    section_line=$(grep -n "## Testes com Laboratorio" "$readme" | head -1 | cut -d: -f1)
    if [ -z "$section_line" ]; then
        echo "  [SKIP] $num: no 'Testes' section in README"
        continue
    fi

    # Guardar cabecalho ate a secao
    head -n $((section_line - 1)) "$readme" > /tmp/readme_new.txt

    # Novo conteudo da secao de testes
    cat >> /tmp/readme_new.txt << EOSE

## Testes com Laboratorio Virtual

### Alvo
- **Host Discovery:** 10.99.0.0/24 (rede do laboratorio)
- **Demais modulos:** 10.99.0.10 (target container)
- **Servidores auxiliares:** LDAP=10.99.0.12, DNS=10.99.0.13, SNMP=10.99.0.14

### Evidencia de Execucao do Modulo

\`\`\`
$evidence
\`\`\`

> Output capturado em $(date '+%Y-%m-%d %H:%M:%S') - execucao automatizada via \`lab/run_tests.sh\`
EOSE

    mv /tmp/readme_new.txt "$readme"
    echo "  [OK] $num $mod_name ($(echo "$evidence" | wc -l) linhas)"
done

echo ""
echo "READMES atualizados."
