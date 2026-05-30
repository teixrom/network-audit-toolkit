# Vulnerability Assessment

Consulta vulnerabilidades conhecidas (CVEs) para serviços enumerados, usando SearchSploit.

## Como usar

```bash
cd 16-vuln_assessment
bash vuln_assessment.sh
```

## O que faz

- Aceita lista de serviços (porta, nome, versão) manual ou de arquivo
- Exemplo embutido para teste
- Consulta SearchSploit para cada serviço
- Exibe exploits públicos disponíveis

## Dependências

- `searchsploit` (exploitdb)

### Instalação do SearchSploit

```bash
sudo apt install exploitdb
```
