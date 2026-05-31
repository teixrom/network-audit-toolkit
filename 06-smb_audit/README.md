# 06 - Auditoria SMB

Ferramenta interativa para auditoria de segurança do protocolo SMB (Server Message Block).

## Funcionalidades

- **Varredura de portas**: Verifica portas abertas 139 (NetBIOS) e 445 (SMB)
- **Detecção de versão**: Identifica suporte a SMBv1, SMBv2 e SMBv3
- **Teste de sessão nula**: Verifica se conexões anônimas são permitidas
- **Enumeração de compartilhamentos**: Lista compartilhamentos SMB disponíveis e seus tipos
- **Enumeração de usuários**: Enumera usuários via SAMR/RPC
- **Detecção de SO**: Identifica o SO remoto via fingerprinting SMB
- **Pontuação de segurança**: Avaliação de risco com recomendações de correção

## Protocolo SMB

SMB (Server Message Block) é um protocolo de compartilhamento de arquivos em rede usado principalmente por sistemas Windows. Samba fornece serviços SMB em Linux/Unix.

### Versões

| Versão | Status      | Notas                                        |
|--------|-------------|----------------------------------------------|
| SMBv1  | Obsoleto    | Vulnerável ao EternalBlue (MS17-010), WannaCry |
| SMBv2  | Atual       | Introduzido no Windows Vista/Server 2008     |
| SMBv3  | Atual       | Introduzido no Windows 8/Server 2012, suporte a criptografia |

## Má Configurações Comuns

- **SMBv1 habilitado**: Protocolo legado vulnerável a execução remota de código
- **Sessões nulas**: Acesso anônimo permite divulgação de informações
- **Compartilhamentos abertos**: Compartilhamentos legíveis mundialmente expõem dados sensíveis
- **Senhas fracas**: Força bruta de contas locais via SMB

## Sessões Nulas

Uma sessão nula ocorre quando uma conexão SMB é estabelecida sem credenciais. Isso pode revelar:

- Listas de usuários
- Informações de compartilhamento
- Políticas do sistema
- Detalhes do domínio/grupo de trabalho

**Correção**: Restringir acesso anônimo via Política de Segurança Local ou registro.

## Dependências

- `nmap` (obrigatório)
- `smbclient` (opcional, recomendado)
- `enum4linux` (opcional, para enumeração de usuários)

---



## Testes com Laboratorio Virtual

### Alvo
- **Host Discovery:** 10.99.0.0/24 (rede do laboratorio)
- **Demais modulos:** 10.99.0.10 (target container)
- **Servidores auxiliares:** LDAP=10.99.0.12, DNS=10.99.0.13, SNMP=10.99.0.14

### Evidencia de Execucao do Modulo

```
================================================
  SMB Auditor
  06-smb_audit
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
Alvo (IP ou hostname): [+] Alvo: 10.99.0.10
================================================
  PASSO 2: Verificação de portas (139, 445)
================================================
[*] Verificando portas SMB (139, 445)...
  [-] Porta 139 está FECHADA
  [-] Porta 445 está FECHADA
[!] Nenhuma porta SMB aberta. Tentando scan SYN do nmap...
[!] Portas SMB fechadas. Abortando auditoria SMB.
[ERRO] SMB ports closed on 10.99.0.10
[!] Limpando...
```

> Output capturado em 2026-05-31 13:40:43 - execucao automatizada via `lab/run_tests.sh`
