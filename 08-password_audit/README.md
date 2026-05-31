# 08 - Auditoria de Senhas

Ferramenta interativa para teste autorizado de força de senhas via simulação de força bruta.

## Funcionalidades

- **Múltiplos alvos**: IP único, faixa CIDR ou carregamento de arquivo
- **Múltiplos serviços**: SSH, FTP, HTTP Basic Auth, formulários HTTP POST, RDP, Telnet, SMB, MySQL
- **Seleção flexível de usuário**: Único usuário, lista de usuários ou padrões comuns
- **Opções de wordlist**: Usar rockyou existente, baixar do SecLists ou caminho personalizado
- **Limitação de taxa**: Threads configuráveis e delay entre tentativas
- **Progresso em tempo real**: Execução do Hydra com feedback ao vivo

## Serviços Suportados

| Serviço            | Porta   | Identificador do Módulo       |
|--------------------|---------|-------------------------------|
| SSH                | 22      | ssh                           |
| FTP                | 21      | ftp                           |
| HTTP Basic Auth    | 80      | http-get                      |
| HTTP POST Form     | 80      | http-post-form                |
| RDP                | 3389    | rdp                           |
| Telnet             | 23      | telnet                        |
| SMB                | 445     | smb                           |
| MySQL              | 3306    | mysql                         |

## Ética e Aviso Legal

**Ataques de força bruta não autorizados são ilegais.** Esta ferramenta é destinada apenas para:

- Testes de penetração autorizados com permissão por escrito
- Avaliações internas de segurança em sistemas que você possui
- Ambientes de laboratório para fins educacionais

Sempre certifique-se de ter permissão explícita por escrito antes de testar.

## Considerações sobre Bloqueio de Conta

Ataques de força bruta podem acionar políticas de bloqueio de conta, causando:

- Negação de serviço para usuários legítimos
- Geração de alertas em sistemas SIEM/logging
- Desativação permanente de conta após exceder o limite

**Recomendações**:
- Use contagens conservadoras de threads (1-5 threads)
- Adicione delays entre tentativas (1-5 segundos)
- Teste com uma única conta primeiro para verificar a política de bloqueio
- Considere o limite de bloqueio ao selecionar o tamanho da wordlist

## Seleção de Wordlist

| Wordlist                   | Tamanho | Qualidade                        |
|----------------------------|---------|----------------------------------|
| rockyou.txt (completo)     | 14 GB   | Senhas reais de vazamentos       |
| rockyou.txt (amostra)      | ~50 MB  | Senhas mais comuns               |
| SecLists 10k-common        | ~70 KB  | Rápido, senhas comuns            |
| Personalizada              | variado | Direcionada à organização        |

## Dependências

- `hydra` (obrigatório)
- `nmap` (recomendado para expansão CIDR)
- `hashcat` ou `john` (opcional, para quebra de hashes)

---



## Testes com Laboratorio Virtual

### Alvo
- **Host Discovery:** 10.99.0.0/24 (rede do laboratorio)
- **Demais modulos:** 10.99.0.10 (target container)
- **Servidores auxiliares:** LDAP=10.99.0.12, DNS=10.99.0.13, SNMP=10.99.0.14

### Evidencia de Execucao do Modulo

```
================================================
  Password Auditor
  08-password_audit
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
  PASSO 1: Selecione o(s) alvo(s)
================================================
[*] Selecione o tipo de alvo
  1) IP único
  2) Faixa de IP (CIDR)
  3) Carregar de arquivo
Selecione (1-3): IP alvo: [+] Alvos: 10.99.0.10
================================================
  PASSO 2: Selecione o serviço
================================================
[*] Selecione o serviço
  1) SSH (porta 22)
  2) FTP (porta 21)
  3) HTTP Basic Auth (porta 80)
  4) HTTP POST Form (porta 80)
  5) RDP (porta 3389)
  6) Telnet (porta 23)
  7) SMB (porta 445)
  8) MySQL (porta 3306)
Selecione (1-8): [+] Serviço: SSH (porta 22)
================================================
  PASSO 3: Selecione o usuário
================================================
[*] Selecione a origem do usuário
  1) Usuário único
  2) Arquivo de lista de usuários
  3) Padrões comuns
Selecione (1-3): Usuário: 
================================================
  PASSO 4: Selecione a wordlist
================================================
[*] Selecione a wordlist
  1) rockyou.txt (locais comuns)
  2) Baixar rockyou do repositório
```

> Output capturado em 2026-05-31 13:40:43 - execucao automatizada via `lab/run_tests.sh`
