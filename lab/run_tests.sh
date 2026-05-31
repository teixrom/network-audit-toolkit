#!/usr/bin/env bash
set -uo pipefail

ROOT="/home/teixrom/projetos/network_audit"
AUDIT_DIR="$ROOT/audits"
EVIDENCE_DIR="$AUDIT_DIR/evidencias"
mkdir -p "$EVIDENCE_DIR"

rm -f "$AUDIT_DIR"/*.txt "$AUDIT_DIR"/*.log
rm -f "$EVIDENCE_DIR"/*.log
rm -f "$ROOT"/*/resumo.txt 2>/dev/null

clean_log() {
    local raw="$1"; local clean="${raw%.log}.clean.log"
    [ ! -f "$raw" ] && return
    sed -E 's/\x1b\[[0-9;]*[a-zA-Z]//g' "$raw" > "$clean"
    sed -i 's/\r//g' "$clean"
    sed -i '/^[[:space:]]*$/d' "$clean"
}

TARGET="10.99.0.10"
DNS="10.99.0.13"
LDAP="10.99.0.12"
SNMP="10.99.0.14"
DOM="lab.local"

echo ""
echo "============================================"
echo "  TESTES AUTOMATIZADOS - network_audit"
echo "============================================"
echo ""

run_mod() {
    local num="$1"; local name="$2"; local script="$3"; local inputs="$4"; local timeout_val="${5:-120}"
    printf "  %-28s" "[$num] $name"
    local outfile="$EVIDENCE_DIR/${num}-${name}.log"
    rm -f "$ROOT/$num-$name/resumo.txt" 2>/dev/null
    echo -e "$inputs" | timeout "$timeout_val" bash "$ROOT/$script" > "$outfile" 2>&1
    local rc=$?; clean_log "$outfile"
    local marker; local lines=0
    [ -f "${outfile%.log}.clean.log" ] && lines=$(wc -l < "${outfile%.log}.clean.log")
    if [ $rc -eq 124 ]; then marker="TIMEOUT"
    elif [ $rc -ne 0 ]; then marker="EXIT($rc)"
    else marker="OK"
    fi
    echo "$marker  ($lines linhas)"
    tail -2 "${outfile%.log}.clean.log" 2>/dev/null | sed 's/^/    -> /'
}

# disclaimer() + menu options + end options
ENTER=""

run_mod "01" "host_discovery" "01-host_discovery/host_discovery.sh" "$ENTER
5
3
$TARGET
2" 120

run_mod "02" "port_scan" "02-port_scan/port_scan.sh" "$ENTER
2
$TARGET
1
2
2" 120

run_mod "03" "service_enum" "03-service_enum/service_enum.sh" "$ENTER
1
$TARGET
22,80,443,21
2" 120

run_mod "04" "web_audit" "04-web_audit/web_audit.sh" "$ENTER
http://$TARGET
8
2" 180

run_mod "05" "dns_audit" "05-dns_audit/dns_audit.sh" "$ENTER
$DOM
$DNS
8
2
2" 120

run_mod "06" "smb_audit" "06-smb_audit/smb_audit.sh" "$ENTER
$TARGET
2" 60

run_mod "07" "snmp_audit" "07-snmp_audit/snmp_audit.sh" "$ENTER
$SNMP
2" 180

# 08: IP unico(1) -> target -> SSH(1) -> usuario unico(1) -> admin -> download wordlist(2) -> save(2)
run_mod "08" "password_audit" "08-password_audit/password_audit.sh" "$ENTER
1
$TARGET
1
1
admin
2
2
2" 180

run_mod "09" "ssl_audit" "09-ssl_audit/ssl_audit.sh" "$ENTER
$TARGET
443
2
2" 120

run_mod "10" "vulnerability_scan" "10-vulnerability_scan/vulnerability_scan.sh" "$ENTER
1
$TARGET
2
2
2" 300

run_mod "11" "firewall_audit" "11-firewall_audit/firewall_audit.sh" "$ENTER
1
$TARGET
2" 180

run_mod "12" "log_audit" "12-log_audit/log_audit.sh" "$ENTER
1
5
2" 120

run_mod "13" "config_audit" "13-config_audit/config_audit.sh" "$ENTER
1
2" 120

run_mod "14" "traffic_analysis" "14-traffic_analysis/traffic_analysis.sh" "$ENTER
6
10
2" 180

run_mod "15" "wifi_audit" "15-wifi_audit/wifi_audit.sh" "$ENTER
2" 30

run_mod "16" "vuln_assessment" "16-vuln_assessment/vuln_assessment.sh" "$ENTER
0
1
2
2" 180

run_mod "17" "identity_audit" "17-identity_audit/identity_audit.sh" "$ENTER
$LDAP
$DOM
1
2
2
2" 180

echo ""
echo "============================================"
echo "  RESUMO"
echo "============================================"
for f in "$EVIDENCE_DIR"/*.clean.log; do
    name=$(basename "$f" .clean.log)
    lines=$(wc -l < "$f")
    printf "  %-28s %5d linhas\n" "$name" "$lines"
done
echo ""
echo "Logs: $EVIDENCE_DIR"
