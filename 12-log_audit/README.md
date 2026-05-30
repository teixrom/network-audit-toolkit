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
