# 04 - Web Auditor

Auditoria de segurança de servidores web.

## Conceitos

### Security Headers
Cabeçalhos HTTP que protegem contra ataques comuns:

| Header | Protege contra | Risco se ausente |
|--------|---------------|------------------|
| `Strict-Transport-Security` | Rebaixamento de HTTPS | MITM |
| `X-Frame-Options` | Clickjacking | IFrame malicioso |
| `X-Content-Type-Options` | MIME sniffing | Execução de script |
| `Content-Security-Policy` | XSS, injeção | Vários vetores |
| `Referrer-Policy` | Vazamento de URL | Privacidade |

### Server Disclosure
O header `Server` pode revelar versões específicas do servidor web, auxiliando atacantes a identificar vulnerabilidades conhecidas.

### Directory Brute Force
Técnica que testa milhares de caminhos comuns para descobrir arquivos e diretórios ocultos.

### SSL/TLS
Verifica validade do certificado, data de expiração e correspondência do CN (Common Name) com o hostname.

### Form Discovery
Extrai formulários HTML da página principal para identificar pontos de entrada de dados.

## Uso

```bash
bash web_audit.sh
```

Não requer privilégios root.

## Dependências

- `curl` - Requisições HTTP/HTTPS
- `openssl` - Análise de certificados SSL
- `gobuster` ou `dirb` (opcional) - Brute force de diretórios

### Instalação

```bash
sudo apt update
sudo apt install -y curl openssl gobuster dirb
```

## Saída

Relatório completo contendo:
- Headers HTTP e análise de segurança
- Tecnologias web detectadas
- Status do certificado SSL
- Formulários encontrados
- Diretórios descobertos (se brute force utilizado)
