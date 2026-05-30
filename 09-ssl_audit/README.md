# 09 - SSL/TLS Auditor

Auditoria de configuração SSL/TLS de servidores.

## Conceitos

### SSL/TLS
Protocolos criptográficos que garantem comunicações seguras na rede. SSL (Secure Sockets Layer) foi substituído pelo TLS (Transport Layer Security).

### Validação de Certificado
| Campo | Descrição |
|-------|-----------|
| Subject | Entidade para quem o certificado foi emitido |
| Issuer | Autoridade Certificadora (CA) que emitiu |
| Validade | Período de vigência (Not Before / Not After) |
| SAN | Subject Alternative Names - domínios adicionais cobertos |
| Chain | Cadeia de certificados até a raiz confiável |

### Versões de Protocolo

| Protocolo | Segurança | Status |
|-----------|-----------|--------|
| SSLv2 | Quebrado | Nunca usar |
| SSLv3 | Quebrado (POODLE) | Nunca usar |
| TLSv1.0 | Fraco (BEAST) | Evitar |
| TLSv1.1 | Fraco | Evitar |
| TLSv1.2 | Seguro | Recomendado |
| TLSv1.3 | Mais seguro | Recomendado |

### Força de Cifras
- **Fracas:** RC4, DES, 3DES, EXPORT - nunca devem ser usadas
- **PFS (Perfect Forward Secrecy):** ECDHE, DHE - garantem que chave de sessão não seja comprometida mesmo que chave privada vaze
- **HSTS:** Força navegadores a usarem HTTPS

### Heartbleed (CVE-2014-0160)
Vulnerabilidade crítica no OpenSSL que permite vazamento de memória do servidor.

## Uso

```bash
bash ssl_audit.sh
```

## Dependências

- `openssl` - Conexão e análise de certificados
- `nmap` - Enumeração de cifras e teste Heartbleed
- `curl` - Verificação de HSTS

### Instalação

```bash
sudo apt update
sudo apt install -y openssl nmap curl
```

## Saída

Relatório completo contendo:
- Detalhes do certificado (subject, issuer, validade, SAN, chain)
- Status de cada versão de protocolo
- Cifras suportadas
- Testes de segurança (cifras fracas, PFS, HSTS, Heartbleed)
- Rating geral (PASS/WARN/FAIL) com nota A-F
