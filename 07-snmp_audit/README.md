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
