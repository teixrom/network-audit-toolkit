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
- **Host Discovery:** 10.99.0.0/24 (rede do laboratorio)
- **Demais modulos:** 10.99.0.10 (target container)
- **Servidores auxiliares:** LDAP=10.99.0.12, DNS=10.99.0.13, SNMP=10.99.0.14

### Evidencia de Execucao do Modulo

```
================================================
  Auditor Web
  04-web_audit
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
  PASSO 1: Digite a URL alvo
================================================
URL alvo (ex: http://example.com, https://example.com:8443): [+] Alvo: http://10.99.0.10:10.99.0.10
================================================
  PASSO 2: Análise de cabeçalhos HTTP
================================================
[*] Obtendo cabeçalhos HTTP...
[!] Falha ao obter cabeçalhos de http://10.99.0.10:10.99.0.10/
[ERRO] Failed to fetch headers from http://10.99.0.10:10.99.0.10/
================================================
  PASSO 3: Detecção de tecnologias web
================================================
================================================
  Detecção de Tecnologias Web
================================================
  [!] Nenhuma tecnologia específica detectada
================================================
  PASSO 4: Verificação SSL/TLS
================================================
[!] O alvo não é HTTPS, pulando verificação SSL
================================================
  PASSO 5: Descoberta de formulários
================================================
================================================
  Descoberta de Formulários
================================================
[!] Não foi possível obter o corpo da página
================================================
  PASSO 6: Força bruta de diretórios
================================================
[*] Força bruta de diretórios/arquivos
  Ferramenta: gobuster
[*] Selecione a wordlist
  1) Wordlist comum (/usr/share/wordlists/dirb/common.txt)
```

> Output capturado em 2026-05-31 13:40:43 - execucao automatizada via `lab/run_tests.sh`
