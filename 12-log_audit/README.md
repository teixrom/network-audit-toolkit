# 12 - Log Auditor

Ferramenta de análise de logs de sistema e serviços para identificar Indicadores de Compromisso (IOCs).

## Conceitos

### Indicadores de Compromisso (IOCs)

| Indicador | Descrição | Severidade |
|-----------|-----------|------------|
| Múltiplas falhas de login | Brute force SSH/sudo | HIGH |
| IPs suspeitos | Conexões de origens incomuns | MEDIUM |
| Crashs de serviço | Possível exploração | HIGH |
| Conexões anômalas | Backdoors, C2 | CRITICAL |
| Horários atípicos | Atividade fora do expediente | MEDIUM |

### Padrões Comuns em Logs

#### SSH Brute Force
```
Failed password for root from 192.168.1.100 port 22 ssh2
Failed password for admin from 192.168.1.100 port 22 ssh2
```

#### Ataques Web
```
GET /wp-admin/admin-ajax.php HTTP/1.1" 404
GET /etc/passwd HTTP/1.1" 404
```

#### Conexões Suspeitas
```
Connection from 10.0.0.5:4444 to localhost:31337
```

### Fontes de Log

| Fonte | Localização Padrão | Conteúdo |
|-------|-------------------|----------|
| System | `/var/log/syslog`, `journalctl` | Eventos gerais do sistema |
| Auth | `/var/log/auth.log`, `journalctl -u ssh` | Autenticações |
| Apache | `/var/log/apache2/access.log` | Requisições HTTP |
| Nginx | `/var/log/nginx/access.log` | Requisições HTTP |

### Comandos de Rede

| Comando | Função |
|---------|--------|
| `ss -tlnp` | Portas em escuta |
| `ss -tupn` | Conexões ativas |
| `lsof -i` | Arquivos abertos de rede |
| `netstat -an` | Tabela de conexões |

## Uso

```bash
bash log_audit.sh
```

Não requer root para logs acessíveis; usa sudo automaticamente quando disponível.

## Dependências

- Ferramentas built-in: `journalctl`, `last`, `grep`, `awk`, `ss`

### Instalação (utilitários adicionais)

```bash
sudo apt update
sudo apt install -y systemd util-linux
```

## Saída

Relatório completo contendo:
- Tentativas de login falhas com top 10 IPs atacantes
- IPs suspeitos com contagem e nível de risco
- Eventos de crash/restart de serviços
- Portas em escuta e conexões ativas
- Resumo de segurança com findings

---



## Testes com Laboratorio Virtual

### Alvo
- **Host Discovery:** 10.99.0.0/24 (rede do laboratorio)
- **Demais modulos:** 10.99.0.10 (target container)
- **Servidores auxiliares:** LDAP=10.99.0.12, DNS=10.99.0.13, SNMP=10.99.0.14

### Evidencia de Execucao do Modulo

```
================================================
  Log Auditor
  12-log_audit
================================================
╔══════════════════════════════════════════════════════╗
║  AVISO LEGAL - FERRAMENTA EDUCACIONAL              ║
║                                                    ║
║  Esta ferramenta é exclusivamente para FINS          ║
║  EDUCACIONAIS e TESTES DE SEGURANÇA AUTORIZADOS.   ║
║                                                    ║
║  ⚠  O uso não autorizado em redes, sistemas ou     ║
║     dispositivos dos quais você não é proprietário  ║
║     ou não tem permissão explícita por escrito      ║
║     para testar é ILEGAL e antiético.              ║
║                                                    ║
║  🛡  Use apenas em:                                ║
║     • Redes próprias                               ║
║     • Laboratórios de estudo                       ║
║     • Testes com autorização por escrito           ║
║                                                    ║
║  O autor não se responsabiliza por qualquer uso       ║
║  indevido ou danos causados por esta ferramenta.      ║
╚══════════════════════════════════════════════════════╝
  Ao continuar, você confirma que leu e entendeu este aviso.
  Pressione ENTER para confirmar e continuar...
================================================
  PASSO 1: Selecione a fonte de log
================================================
[*] Escolha a fonte de log:
  1) Log do sistema (/var/log/syslog ou journalctl)
  2) Log de autenticação (/var/log/auth.log ou journalctl -u ssh)
  3) Log de acesso do servidor web (Apache/Nginx)
  4) Caminho personalizado de arquivo de log
Selecione (1-4): [+] Fonte: Log do sistema
================================================
  PASSO 2: Selecione o tipo de análise
================================================
[*] Escolha a análise:
  1) Tentativas de login falhas
  2) Endereços IP suspeitos
  3) Eventos de falha/reinicialização de serviços
  4) Histórico de conexões de rede
  5) Todas as anteriores
Selecione (1-5): [+] Tipo de análise: 5
================================================
  PASSO 3: Executando análise
================================================
================================================
  Análise de Logins Falhos
================================================
--- Tentativas SSH Falhas ---
  [+] Nenhuma tentativa de login SSH falha encontrada
--- Tentativas sudo/su ---
  [+] Nenhuma falha sudo/su encontrada
================================================
  Análise de Endereços IP Suspeitos
================================================
Contagem   IP               Risco
----------------------------------------
31         0.0.0.0          MÉDIO
```

> Output capturado em 2026-05-31 13:40:43 - execucao automatizada via `lab/run_tests.sh`
