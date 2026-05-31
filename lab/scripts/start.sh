#!/bin/bash

echo "[*] Inicializando servicos do target de auditoria..."

# Criar diretorios de runtime
mkdir -p /var/run/mysqld /var/run/apache2 /var/lock/apache2 /var/log/apache2
chown mysql:mysql /var/run/mysqld

# Iniciar MariaDB
echo "[+] Iniciando MariaDB..."
mysqld_safe --skip-grant-tables &
sleep 4
mysql -u root -e "FLUSH PRIVILEGES; ALTER USER 'root'@'localhost' IDENTIFIED BY 'root'; FLUSH PRIVILEGES;" 2>/dev/null || true

# Iniciar Apache
echo "[+] Iniciando Apache..."
. /etc/apache2/envvars
/usr/sbin/apache2 -D FOREGROUND &
sleep 2

# Iniciar SSH
echo "[+] Iniciando SSH..."
/usr/sbin/sshd

# Iniciar vsFTPd
echo "[+] Iniciando vsFTPd..."
/usr/sbin/vsftpd &

# Iniciar SNMP
echo "[+] Iniciando SNMP..."
/usr/sbin/snmpd -Lsd -Lf /dev/null -u snmp -I -smux -p /var/run/snmpd.pid -f &

echo ""
echo "============================================"
echo "  TARGET LAB PRONTO"
echo "============================================"
echo "  SSH:     admin:admin | root:toor"
echo "  HTTP:    http://10.99.0.10"
echo "  HTTPS:   https://10.99.0.10"
echo "  FTP:     anonymous / ftpuser:ftp123"
echo "  MySQL:   root:root | appuser:app123"
echo "  SNMP:    public (ro)"
echo "============================================"
echo ""

tail -f /dev/null
