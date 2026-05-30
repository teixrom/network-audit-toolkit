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
