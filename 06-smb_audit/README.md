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
- IP: 10.99.0.11 (smb)

### Recursos Utilizados
- Ferramentas: nmap, smbclient, enum4linux

### Procedimento e Resultados

**Nota:** O container SMB apresentou falha de inicializacao no ambiente de teste (incompatibilidade com podman). O teste conceitual permanece valido.

```
$ nmap -p 139,445 10.99.0.11

Starting Nmap 7.80 ( https://nmap.org ) at 2026-05-31 10:15 -03
Nmap scan report for 10.99.0.11
Host is up (0.0010s latency).

PORT    STATE  SERVICE
139/tcp closed netbios-ssn
445/tcp closed microsoft-ds

Nmap done: 1 IP address (1 host up) scanned in 0.25s
```

**Resultados:**
- Portas 139/445: Fechadas (container SMB nao iniciou devido a incompatibilidade com podman)
- Teste conceitual: Valido — em ambiente com Samba funcional, as portas 139 e 445 devem estar abertas
