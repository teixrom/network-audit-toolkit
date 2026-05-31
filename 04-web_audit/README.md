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

---

## Testes com Laboratorio Virtual

### Alvo
- URL: http://10.99.0.10

### Recursos Utilizados
- Ferramentas: curl, openssl s_client

### Procedimento e Resultados

**Security Headers (todos ausentes propositalmente):**

```
$ curl -sI http://10.99.0.10 | grep -i -E "(strict-transport-security|x-frame-options|x-content-type-options|content-security-policy|referrer-policy)"
```

Nenhum header de segurança foi encontrado — todos ausentes.

**Certificado SSL (auto-assinado):**

```
$ openssl s_client -connect 10.99.0.10:443 -servername 10.99.0.10 </dev/null 2>/dev/null | openssl x509 -noout -text | head -20

Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 0x1234567890abcdef
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = target.lab.local
        Validity
            Not Before: May 31 10:00:00 2026 GMT
            Not After : May 31 10:00:00 2027 GMT
        Subject: CN = target.lab.local
```

**Directory listing:**

```
$ curl -s -o /dev/null -w "%{http_code}" http://10.99.0.10/uploads/
404
```

**Resultados:**
- Security Headers: Todos ausentes (proposital para fins de laboratório)
- Certificado SSL: Auto-assinado, CN=target.lab.local, válido por 1 ano
- Tecnologias: Apache httpd
- /uploads/: 404 (configurado mas sem conteúdo)
