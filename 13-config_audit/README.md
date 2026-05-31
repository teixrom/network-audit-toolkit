# Config Auditor

Analisa arquivos de configuração de dispositivos de rede (switches/routers) em busca de problemas de segurança.

## Como usar

```bash
cd 13-config_audit
sudo bash config_audit.sh
```

## O que faz

- Analisa configuração de exemplo embutida ou fornecida pelo usuário
- Detecta senhas fracas/padrão (admin, cisco, password)
- Identifica protocolos inseguros (Telnet, HTTP)
- Verifica ACLs e regras de acesso
- Gera relatório com recomendações

## Dependências

Nenhuma — análise puramente textual de arquivos de configuração.

---



## Testes com Laboratorio Virtual

### Alvo
- **Host Discovery:** 10.99.0.0/24 (rede do laboratorio)
- **Demais modulos:** 10.99.0.10 (target container)
- **Servidores auxiliares:** LDAP=10.99.0.12, DNS=10.99.0.13, SNMP=10.99.0.14

### Evidencia de Execucao do Modulo

```
================================================
  Auditoria de Configuração
  13-config_audit
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
  Pressione ENTER para confirmar e continuar...
================================================
  PASSO 1: Carregar arquivo de configuração
================================================
[*] Selecione a fonte do arquivo de configuração:
  1) Usar configuração simulada padrão (embutida)
  2) Informar caminho de um arquivo de configuração
Selecione (1-2): [+] Usando configuração simulada padrão
================================================
  PASSO 2: Verificar senhas padrão
================================================
--- Buscando credenciais padrão/padrão ---
  [ALTO] Senha 'admin' detectada (configuração padrão)
  [ALTO] Senha 'cisco' detectada (configuração padrão)
  [ALTO] Senha 'password' detectada (configuração padrão)
  [MÉDIO] Senha enable configurada: enable password admin
  [MÉDIO] 2 comunidades SNMP encontradas (verificar se são padrão)
================================================
  PASSO 3: Identificar protocolos inseguros
================================================
--- Verificando protocolos inseguros ---
  [ALTO] Telnet habilitado (protocolo inseguro - substituir por SSH)
  [MÉDIO] Servidor HTTP habilitado (usar HTTPS se possível)
  [MÉDIO] SNMP v1/v2c detectado (usar SNMPv3 com criptografia)
  [ALTO] SSH versão 1 habilitado (versão insegura - usar SSH v2)
================================================
  PASSO 4: Alertar sobre regras de firewall permissivas
================================================
--- Verificando regras de acesso permissivas ---
  [ALTO] Regra 'permit any any' encontrada (extremamente permissiva):
    access-list 100 permit ip any any
  [MÉDIO] Regras 'permit any' detectadas (revisar necessidade):
    access-list 100 permit ip any any
    access-list 101 permit tcp any host 10.0.0.1 eq 22
    access-list 101 permit tcp any host 10.0.0.2 eq 443
  [MÉDIO] ACLs configuradas sem 'deny any any' explícito (depende de deny implícito)
```

> Output capturado em 2026-05-31 13:40:43 - execucao automatizada via `lab/run_tests.sh`
