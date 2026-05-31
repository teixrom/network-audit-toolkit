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
- **Host Discovery:** 10.99.0.0/24 (rede do laboratorio)
- **Demais modulos:** 10.99.0.10 (target container)
- **Servidores auxiliares:** LDAP=10.99.0.12, DNS=10.99.0.13, SNMP=10.99.0.14

### Evidencia de Execucao do Modulo

```
================================================
  SSL/TLS Auditor
  09-ssl_audit
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
  Pressione ENTER para confirmar e continuar...[LOG] Dependencias OK
================================================
  PASSO 1: Digite o alvo
================================================
Alvo (ex: example.com:443, https://example.com): [+] Alvo: 10.99.0.10:443
================================================
  PASSO 2: Análise do certificado
================================================
[*] Buscando certificado SSL/TLS...
--- Detalhes do Certificado ---
  Assunto:      subject=C = BR, ST = SP, L = SaoPaulo, O = Lab, CN = target.lab.local
  Emissor:       issuer=C = BR, ST = SP, L = SaoPaulo, O = Lab, CN = target.lab.local
[!] Limpando...
```

> Output capturado em 2026-05-31 13:40:43 - execucao automatizada via `lab/run_tests.sh`
