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

---

## Testes com Laboratorio Virtual

### Alvo
- IP: 10.99.0.10:443

### Recursos Utilizados
- Ferramentas: openssl, nmap, curl

### Procedimento e Resultados

**Detalhes do certificado:**

```
$ openssl s_client -connect 10.99.0.10:443 -servername 10.99.0.10 </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer -dates

subject=CN = target.lab.local
issuer=CN = target.lab.local
notBefore=May 31 10:00:00 2026 GMT
notAfter=May 31 10:00:00 2027 GMT
```

**Protocolos suportados (TLS):**

```
$ nmap --script ssl-enum-ciphers -p 443 10.99.0.10

Starting Nmap 7.80 ( https://nmap.org ) at 2026-05-31 10:20 -03
Nmap scan report for 10.99.0.10
Host is up (0.0008s latency).

PORT    STATE SERVICE
443/tcp open  https
| ssl-enum-ciphers:
|   TLSv1.2:
|     ciphers:
|       TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384 (ecdh_x25519) - A
|       TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256 (ecdh_x25519) - A
|       TLS_DHE_RSA_WITH_AES_256_GCM_SHA384 (dh 2048) - A
|       TLS_DHE_RSA_WITH_AES_128_GCM_SHA256 (dh 2048) - A
|     compressors:
|       NULL
|   TLSv1.3:
|     ciphers:
|       TLS_AKE_WITH_AES_256_GCM_SHA384 (ecdh_x25519) - A
|       TLS_AKE_WITH_AES_128_GCM_SHA256 (ecdh_x25519) - A
|       TLS_AKE_WITH_CHACHA20_POLY1305_SHA256 (ecdh_x25519) - A
|_  least strength: A
```

**HSTS:**

```
$ curl -sI https://10.99.0.10 | grep -i strict-transport-security
```

Nenhum header HSTS presente.

**Resultados:**
- Certificado: Auto-assinado, CN=target.lab.local, issuer=target.lab.local
- TLS 1.2: SUPORTADO
- TLS 1.3: SUPORTADO
- HSTS: Nao configurado
