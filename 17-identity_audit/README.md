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
- **Host Discovery:** 10.99.0.0/24 (rede do laboratorio)
- **Demais modulos:** 10.99.0.10 (target container)
- **Servidores auxiliares:** LDAP=10.99.0.12, DNS=10.99.0.13, SNMP=10.99.0.14

### Evidencia de Execucao do Modulo

```
================================================
  Auditoria de Identidade e Politicas
  17-identity_audit
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
  PASSO 1: Definir alvo
================================================
IP ou hostname do alvo: 
Dominio AD (opcional, para SRV records): [+] Alvo definido: 10.99.0.12
[+] Dominio: lab.local
================================================
  PASSO 2: Varredura de servidores de identidade
================================================
  [+] LDAP (389/tcp) — ACESSIVEL
  [+] LDAPS (636/tcp) — ACESSIVEL
================================================
  PASSO 3: Enumeracao LDAP
================================================
  [+] Bind anonimo possivel (nmap ldap-rootdse)
      | ldap-rootdse: 
      | LDAP Results
      |   <ROOT>
      |       namingContexts: dc=lab,dc=local
      |       supportedControl: 2.16.840.1.113730.3.4.18
      |       supportedControl: 2.16.840.1.113730.3.4.2
      |       supportedControl: 1.3.6.1.4.1.4203.1.10.1
      |       supportedControl: 1.3.6.1.1.22
      |       supportedControl: 1.2.840.113556.1.4.319
      |       supportedControl: 1.2.826.0.1.3344810.2.3
      |       supportedControl: 1.3.6.1.1.13.2
      |       supportedControl: 1.3.6.1.1.13.1
      |       supportedControl: 1.3.6.1.1.12
      |       supportedExtension: 1.3.6.1.4.1.1466.20037
      |       supportedExtension: 1.3.6.1.4.1.4203.1.11.1
      |       supportedExtension: 1.3.6.1.4.1.4203.1.11.3
      |       supportedExtension: 1.3.6.1.1.8
      |       supportedLDAPVersion: 3
      |       supportedSASLMechanisms: GS2-IAKERB
      |       supportedSASLMechanisms: GS2-KRB5
```

> Output capturado em 2026-05-31 13:40:43 - execucao automatizada via `lab/run_tests.sh`
