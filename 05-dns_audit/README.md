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
- IP: 10.99.0.13 (DNS server)
- Domínio: lab.local

### Recursos Utilizados
- Ferramentas: dig, nslookup, host

### Procedimento e Resultados

**Transferencia de Zona (AXFR):**

```
$ dig axfr lab.local @10.99.0.13

; <<>> DiG 9.18.28 <<>> axfr lab.local @10.99.0.13
;; global options: +cmd
lab.local.              3600    IN      SOA     dns.lab.local. admin.lab.local. 2026053101 3600 900 86400 3600
lab.local.              3600    IN      NS      dns.lab.local.
dns.lab.local.          3600    IN      A       10.99.0.13
ldap.lab.local.         3600    IN      A       10.99.0.12
smb.lab.local.          3600    IN      A       10.99.0.11
snmp.lab.local.         3600    IN      A       10.99.0.14
target.lab.local.       3600    IN      A       10.99.0.10
_ldap._tcp.lab.local.   3600    IN      SRV     0 100 389 ldap.lab.local.
_kerberos._tcp.lab.local. 3600  IN      SRV     0 100 88  ldap.lab.local.
lab.local.              3600    IN      SOA     dns.lab.local. admin.lab.local. 2026053101 3600 900 86400 3600
```

**VULNERAVEL** — Transferencia de zona completa liberada.

**Reverse DNS:**

```
$ dig -x 10.99.0.10 @10.99.0.13 +short
target.lab.local.

$ dig -x 10.99.0.11 @10.99.0.13 +short
smb.lab.local.

$ dig -x 10.99.0.12 @10.99.0.13 +short
ldap.lab.local.
```

**Resultados:**
- Zone Transfer (AXFR): VULNERAVEL — zona completa disponivel sem restricao
- Registros encontrados: SOA, NS, A (dns, ldap, smb, snmp, target), SRV (_ldap, _kerberos)
- Reverse DNS: target.lab.local, smb.lab.local, ldap.lab.local
