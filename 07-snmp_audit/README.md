# 07 - Auditoria SNMP

Ferramenta interativa para auditoria de segurança do protocolo SNMP (Simple Network Management Protocol).

## Funcionalidades

- **Verificação da porta UDP 161**: Verifica disponibilidade do serviço SNMP
- **Força bruta de community strings**: Testa strings de comunidade padrão comuns
- **Detecção de versão**: Identifica suporte a SNMP v1, v2c, v3
- **MIB walk**: Extrai informações detalhadas do sistema via consultas SNMP
- **Avaliação de exposição de informações**: Identifica dados sensíveis expostos

## Community Strings

Strings de comunidade SNMP atuam como senhas para v1 e v2c. Strings padrão como "public" (somente leitura) e "private" (leitura/escrita) são comumente deixadas inalteradas.

**Risco**: Valores padrão inalterados permitem que invasores leiam (ou escrevam) a configuração do dispositivo.

### Strings de Comunidade Comuns Testadas

public, private, community, manager, admin, snmp, c0mrade, all, read, write, test, security, monitor, netman, server, root, user

## MIB Walks

MIB (Management Information Base) walks recuperam dados hierárquicos de dispositivos habilitados para SNMP. As seguintes informações podem ser expostas:

| Ramo MIB                    | Informação                           | Risco  |
|-----------------------------|--------------------------------------|--------|
| 1.3.6.1.2.1.1.x            | Descrição do sistema, nome, localização | Alto |
| 1.3.6.1.2.1.2.x            | Interfaces de rede e IPs             | Alto   |
| 1.3.6.1.2.1.25.4.2.1.2     | Processos em execução                | Médio  |
| 1.3.6.1.2.1.25.6.3.1.2     | Software instalado                   | Médio  |
| 1.3.6.1.2.1.6.13.1.1       | Portas TCP abertas                   | Alto   |
| 1.3.6.1.2.1.7.5.1.1        | Portas UDP abertas                   | Alto   |
| 1.3.6.1.4.1.77.1.2.25      | Contas de usuário (SAM Windows)      | Alto   |

## Riscos de Segurança

- **Vazamento de informações**: Topologia de rede, versões de software, contas de usuário
- **Comunidades padrão**: Adivinhação fácil de credenciais
- **Má configuração do SNMPv3**: Autenticação ou criptografia fracas

## Dependências

- `snmpwalk`
- `snmpget`
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
  SNMP Auditor
  07-snmp_audit
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
Alvo (IP ou hostname): [+] Alvo: 10.99.0.14
================================================
  PASSO 2: Verificação da porta UDP 161
================================================
[*] Verificando porta UDP 161 (SNMP)...
  [+] Porta UDP 161 está ABERTA
================================================
  PASSO 3: Descoberta de string de comunidade
================================================
[*] Testando strings de comunidade SNMP comuns...
  [+] String de comunidade encontrada: public
================================================
  PASSO 4: Detecção de versão SNMP
================================================
[*] Detectando suporte a versão SNMP...
  [+] Versões SNMP suportadas: v1 v2c 
================================================
  PASSO 5: MIB walk e coleta de dados
================================================
================================================
  Informações Descobertas via SNMP
================================================
[*] MIB Walk - Informações do Sistema
----------------------------------------
  [+] Descrição do Sistema: "Linux snmp.lab.local 6.17.0-1023-oem #23-Ubuntu SMP PREEMPT_DYNAMIC Fri May  8 06:02:38 UTC 2026 x86_64"
  [+] Nome do Sistema: "snmp.lab.local"
  [+] Localização do Sistema: "Unknown (edit /etc/snmp/snmpd.conf)"
  [+] Contato do Sistema: "Root <root@localhost> (configure /etc/snmp/snmp.local.conf)"
  [+] Tempo de Atividade do Sistema: 0:1:21:27.62
  [+] Serviços do Sistema: No Such Instance currently exists at this OID
[*] MIB Walk - Interfaces de Rede
----------------------------------------
```

> Output capturado em 2026-05-31 13:40:43 - execucao automatizada via `lab/run_tests.sh`
