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
