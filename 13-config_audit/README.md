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
