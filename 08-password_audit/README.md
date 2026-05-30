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
