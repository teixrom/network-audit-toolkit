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
- **Host Discovery:** 10.99.0.0/24 (rede do laboratorio)
- **Demais modulos:** 10.99.0.10 (target container)
- **Servidores auxiliares:** LDAP=10.99.0.12, DNS=10.99.0.13, SNMP=10.99.0.14

### Evidencia de Execucao do Modulo

```
================================================
  Avaliacao de Vulnerabilidades
  16-vuln_assessment
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
  PASSO 1: Arquivo de servicos
================================================
[*] Informe o caminho do arquivo com a lista de servicos
  Formato (uma por linha): porta protocolo servico versao
  Exemplo: 80 http Apache 2.4.41
Caminho do arquivo (ou 0 para criar um modelo): [+] Arquivo modelo criado em: /tmp/servicos_exemplo.txt
[+] Total de servicos a analisar: 6
================================================
  PASSO 2: Exportar relatorio
================================================
  1) Salvar relatorio
  2) Pular
Selecione (1-2): [+] Relatorio salvo em: /home/teixrom/projetos/network_audit/audits/vuln_assessment_20260531_134035.txt
================================================
  PASSO 3: Analise de vulnerabilidades
================================================
[!] searchsploit nao encontrado - usando API Circl.lu
--- Analisando Apache 2.4.41 (80/http) ---
--- Analisando Apache 2.4.41 (443/https) ---
--- Analisando OpenSSH 8.0 (22/ssh) ---
--- Analisando MySQL 5.7.30 (3306/mysql) ---
--- Analisando Redis 6.0 (6379/redis) ---
--- Analisando PostgreSQL 12.3 (5432/postgresql) ---
=== Resumo de Vulnerabilidades ===
[-] Nenhuma vulnerabilidade encontrada ou todas as consultas falharam
================================================
  PASSO 4: Recomendacoes de remediacao
================================================
Boas praticas gerais:
  [*] Mantenha todos os servicos atualizados com as ultimas versoes estaveis
  [*] Aplique patches de seguranca assim que disponiveis
  [*] Desative servicos e portas nao utilizados
  [*] Implemente firewalls de aplicacao (WAF) para servicos web
  [*] Utilize segmentacao de rede para isolar servicos criticos
```

> Output capturado em 2026-05-31 13:40:43 - execucao automatizada via `lab/run_tests.sh`
