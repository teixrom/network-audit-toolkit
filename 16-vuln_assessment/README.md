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

---

## Testes com Laboratorio Virtual

### Alvo
- IP: 10.99.0.10 (target)

### Recursos Utilizados
- Ferramentas: searchsploit, curl, python3

### Procedimento e Resultados
Services analyzed:
- 22/tcp OpenSSH 8.4p1
- 80/tcp Apache httpd 2.4.41
- 443/tcp Apache httpd 2.4.41
- 21/tcp vsftpd 3.0.3

searchsploit: not installed in test environment (optional dependency)

CIRCL API: tested but endpoint may be unavailable in isolated networks
```
