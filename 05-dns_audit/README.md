# 05 - Auditoria de DNS

Ferramenta interativa para enumeração de DNS e auditoria de segurança.

## Funcionalidades

- **Enumeração de múltiplos registros**: Consulta registros A, AAAA, MX, NS, TXT, SOA, CNAME
- **Verificação de transferência de zona (AXFR)**: Testa se servidores DNS permitem transferências de zona não autorizadas
- **Descoberta de subdomínios**: Força bruta de subdomínios comuns ou uso de wordlist personalizada
- **Consulta DNS reversa**: Resolução de registros PTR para IPs descobertos
- **Servidor DNS personalizado**: Consulta a qualquer resolvedor DNS especificado

## Tipos de Registro DNS

| Tipo  | Descrição                          | Uso                          |
|-------|------------------------------------|------------------------------|
| A     | Mapeamento de endereço IPv4        | Resolver hostname para IP    |
| AAAA  | Mapeamento de endereço IPv6        | Resolver hostname para IPv6  |
| MX    | Servidores de correio              | Identificar infraestrutura de email |
| NS    | Registros de nameserver            | Identificar servidores DNS   |
| TXT   | Dados de texto arbitrário (SPF, DKIM) | Verificação de segurança de email |
| SOA   | Start of authority                 | Informações administrativas da zona |
| CNAME | Nome canônico (alias)              | Aliases de domínio           |

## Transferências de Zona (AXFR)

Uma transferência de zona (AXFR) é um mecanismo para replicar bancos de dados DNS. Se mal configurada, qualquer host pode solicitar uma cópia completa da zona DNS, revelando todos os hosts e subdomínios.

**Risco**: Divulgação completa do mapa de rede

**Correção**: Restringir AXFR apenas a servidores DNS secundários autorizados.

## Descoberta de Subdomínios

A descoberta de subdomínios tenta encontrar entradas DNS que podem expor superfície de ataque adicional. Usa prefixos comuns (www, mail, admin, api, dev, etc.) ou uma wordlist fornecida pelo usuário.

## Dependências

- `dig` (dnsutils)
- `host`
- `nslookup`

---



## Testes com Laboratorio Virtual

### Alvo
- **Host Discovery:** 10.99.0.0/24 (rede do laboratorio)
- **Demais modulos:** 10.99.0.10 (target container)
- **Servidores auxiliares:** LDAP=10.99.0.12, DNS=10.99.0.13, SNMP=10.99.0.14

### Evidencia de Execucao do Modulo

```
================================================
  DNS Auditor
  05-dns_audit
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
  PASSO 1: Digite o domínio alvo
================================================
Domínio alvo (ex: example.com): [+] Domínio: lab.local
================================================
  PASSO 2: Selecione o servidor DNS
================================================
[*] Usar servidor DNS personalizado?
  1) Sim
  2) Não
Selecione (1-2): Opção inválida
Selecione (1-2): Opção inválida
Selecione (1-2): [+] Usando resolvedor DNS padrão do sistema
================================================
  PASSO 3: Selecione os tipos de registro
================================================
[*] Selecione o tipo de registro
  1) A (IPv4 address)
  2) AAAA (IPv6 address)
  3) MX (Mail exchange)
  4) NS (Nameservers)
  5) TXT (Text records)
  6) SOA (Start of authority)
  7) CNAME (Canonical name)
  8) TODOS (consultar todos)
Selecione (1-8): [+] Record types: AAAA
================================================
  PASSO 4: Enumerar registros DNS
================================================
[*] Enumerando registros DNS para lab.local...
--- AAAA Records ---
[!] Nenhum registro AAAA encontrado
================================================
  PASSO 5: Verificação de transferência de zona
================================================
```

> Output capturado em 2026-05-31 13:40:43 - execucao automatizada via `lab/run_tests.sh`
