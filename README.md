# Network Audit Toolkit

Uma suíte completa de scripts de auditoria de redes, organizada em módulos independentes seguindo as boas práticas de segurança e auditoria.

## Estrutura do Projeto

```
network_audit/
├── README.md                    # Este arquivo
├── audits/                      # Resultados de auditorias
├── utils/                       # Utilitários compartilhados
│
├── 01-host_discovery/           # Descoberta de hosts ativos
├── 02-port_scan/                # Varredura de portas
├── 03-service_enum/             # Enumeração de serviços
├── 04-web_audit/                # Auditoria de servidores web
├── 05-dns_audit/                # Auditoria de DNS
├── 06-smb_audit/                # Auditoria de SMB/NetBIOS
├── 07-snmp_audit/               # Auditoria de SNMP
├── 08-password_audit/           # Teste de senhas/força bruta
├── 09-ssl_audit/                # Auditoria de SSL/TLS
├── 10-vulnerability_scan/       # Varredura de vulnerabilidades
├── 11-firewall_audit/           # Auditoria de firewall
├── 12-log_audit/                # Análise de logs
├── 13-config_audit/             # Auditoria de configuração de ativos
├── 14-traffic_analysis/         # Análise de tráfego em tempo real
├── 15-wifi_audit/               # Auditoria de segurança Wi-Fi
├── 16-vuln_assessment/          # Avaliação de vulnerabilidades (CVE)
└── 17-identity_audit/           # Auditoria de identidade e políticas
```

## Testes com Laboratorio Virtual

O projeto inclui um laboratorio Docker/Podman para validacao dos modulos:

```bash
# Subir laboratorio (5 containers)
cd lab && sudo docker-compose up -d

# Executar bateria completa de testes automatizados
sudo bash lab/run_tests.sh

# Atualizar READMEs com evidencias
bash lab/update_readmes.sh
```

### Infraestrutura do Lab

| Container | IP | Servicos |
|-----------|-----|----------|
| target | 10.99.0.10 | FTP(21), SSH(22), HTTP(80), HTTPS(443) |
| ldap | 10.99.0.12 | LDAP(389), LDAPS(636) |
| dns | 10.99.0.13 | DNS(53/TCP+UDP) |
| snmp | 10.99.0.14 | SNMP(161/UDP) |
| smb | 10.99.0.11 | SMB(139,445) — instavel no podman |

### Resultados da Bateria de Testes

| Modulo | Status | Evidencia |
|--------|--------|-----------|
| 01 Host Discovery | OK | Host 10.99.0.10 descoberto via TCP SYN ping |
| 02 Port Scan | OK | Portas 21,22,80,443 abertas |
| 03 Service Enum | OK | vsftpd, OpenSSH 8.4p1, Apache httpd |
| 04 Web Audit | OK | Headers de seguranca analisados |
| 05 DNS Audit | OK | Registros DNS consultados no servidor 10.99.0.13 |
| 06 SMB Audit | EXIT(1) | Container SMB indisponivel |
| 07 SNMP Audit | OK | Community strings testadas em 10.99.0.14 |
| 08 Password Audit | OK | Wordlist baixada + SSH testado |
| 09 SSL Audit | EXIT(1) | Certificado auto-assinado obtido (CN=target.lab.local) |
| 10 Vulnerability Scan | OK | Portas 21,22,80,443 com versoes detectadas |
| 11 Firewall Audit | EXIT(1) | Perfil stateful identificado |
| 12 Log Audit | OK | Log do sistema analisado |
| 13 Config Audit | OK | Configuracao simulada auditada |
| 14 Traffic Analysis | OK | Captura na interface podman1 |
| 15 WiFi Audit | EXIT(1) | Sem interface wifi no host |
| 16 Vuln Assessment | OK | Arquivo de servicos gerado e analisado |
| 17 Identity Audit | OK | LDAP bind anonimo, root DSE, SRV records |

> Detalhes completos com output real em cada `XX-modulo/README.md` secao "Testes com Laboratorio Virtual".

## Metodologia

Esta suíte segue a metodologia clássica de auditoria:

1. **Reconhecimento** — Identificar hosts, serviços e superfície de ataque
2. **Enumeração** — Detalhar versões, configurações e portas abertas
3. **Avaliação** — Testar senhas fracas, configurações incorretas, vulnerabilidades conhecidas
4. **Análise** — Correlacionar dados, identificar padrões, gerar relatório

## Pré-requisitos

### Instalação no Linux (Debian/Ubuntu)

```bash
sudo apt update
sudo apt install -y nmap netcat-openbsd dnsutils snmp snmp-mibs-downloader \
  hydra medusa curl wget openssl whois nikto gobuster dirb john \
  tcpdump python3 python3-pip
```

### Instalação via pip

```bash
pip3 install colorama
```

## Como usar

### Menu principal (recomendado)

```bash
bash network_audit.sh
```

### Executar módulo diretamente

Cada módulo é independente e possui seu próprio README com instruções detalhadas.

```bash
# Executar um módulo específico
cd 01-host_discovery
sudo bash host_discovery.sh
```

Alguns módulos requerem privilégios **root** (indicado em cada README).

### Instalação de dependências

```bash
sudo bash install.sh
```

### Resultados

Cada módulo salva um `resumo.txt` em sua própria pasta com os resultados da auditoria.
Logs completos com timestamp são salvos no diretório `audits/`.

## ⚠️ Aviso Legal

**ESTAS FERRAMENTAS SÃO EXCLUSIVAMENTE PARA FINS EDUCACIONAIS E TESTES DE SEGURANÇA AUTORIZADOS.**

O uso não autorizado destas ferramentas em redes, sistemas ou dispositivos dos quais você não é proprietário ou não tem permissão explícita por escrito para testar é **ILEGAL** e antiético.

**Use apenas em:**
- Redes próprias
- Laboratórios de estudo
- Testes com autorização por escrito

O autor não se responsabiliza por qualquer uso indevido ou danos causados por estas ferramentas.
