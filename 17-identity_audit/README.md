# Identity Auditor

Audita serviços de identidade e gerenciamento de acesso em hosts alvo.

## Como usar

```bash
cd 17-identity_audit
sudo bash identity_audit.sh
```

## O que faz

- Verifica portas comuns de serviços de identidade:
  - 389 (LDAP)
  - 636 (LDAPS)
  - 445 (Active Directory/NetBIOS)
  - 1812 (RADIUS Authentication)
  - 1813 (RADIUS Accounting)
- Detecta versões de serviços
- Verifica conectividade e banners

## Dependências

- `nmap`

---

## Testes com Laboratorio Virtual

### Alvo
- IP: 10.99.0.12 (LDAP), 10.99.0.13 (DNS)

### Recursos Utilizados
- Ferramentas: nmap, ldapsearch, dig, openssl

### Procedimento e Resultados
```
nmap -p389,636,88,445 10.99.0.12
```
389/ldap OPEN, 636/ldaps OPEN, 88/kerberos CLOSED, 445/smb CLOSED

```
ldapsearch -x -H ldap://10.99.0.12 -b "" -s base
```
LDAP anonymous bind: Permitido - root DSE query retornou informacoes do diretorio

```
dig _ldap._tcp.lab.local SRV
```
_ldap._tcp.lab.local → 0 100 389 ldap.lab.local

```
dig _kerberos._tcp.lab.local SRV
```
_kerberos._tcp.lab.local → 0 100 88 target.lab.local
