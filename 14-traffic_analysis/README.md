# Traffic Analyzer

Captura e analisa tráfego de rede em tempo real usando tcpdump.

## Como usar

```bash
cd 14-traffic_analysis
sudo bash traffic_analysis.sh
```

## O que faz

- Lista interfaces de rede disponíveis
- Captura tráfego por duração configurável (padrão: 30s)
- Analisa protocolos detectados (TCP, UDP, ICMP, DNS, HTTP, etc.)
- Identifica top talkers (IPs com mais tráfego)
- Gera estatísticas básicas de tráfego

## Dependências

- `tcpdump`
- `root` (para captura de pacotes)

---



## Testes com Laboratorio Virtual

### Alvo
- **Host Discovery:** 10.99.0.0/24 (rede do laboratorio)
- **Demais modulos:** 10.99.0.10 (target container)
- **Servidores auxiliares:** LDAP=10.99.0.12, DNS=10.99.0.13, SNMP=10.99.0.14

### Evidencia de Execucao do Modulo

```
================================================
  Análise de Tráfego
  14-traffic_analysis
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
  Pressione ENTER para confirmar e continuar...[LOG] Root OK
================================================
  PASSO 1: Listar interfaces de rede disponíveis
================================================
[*] Interfaces de rede disponíveis:
  1) lo  [UNKNOWN]  IP: 127.0.0.1/8
  2) enp5s0  [DOWN]  IP: N/A
  3) wlp4s0  [UP]  IP: 192.168.31.89/24
  4) podman0  [UP]  IP: 10.88.0.1/16
  5) veth0  [podman0]  IP: N/A
  6) podman1  [UP]  IP: 10.99.0.1/24
  7) veth1  [podman1]  IP: N/A
  8) veth3  [podman1]  IP: N/A
  9) veth4  [podman1]  IP: N/A
  10) veth5  [podman1]  IP: N/A
Selecione a interface (1-10): [+] Interface selecionada: podman1
[*] Duração da captura (10-120 segundos, padrão 30):
Duração em segundos [30]: [+] Duração da captura: 10 segundos
================================================
  PASSO 2: Capturar tráfego de rede
================================================
[*] Iniciando captura em podman1 por 10 segundos...
[+] Captura concluída: 0 pacotes capturados
================================================
  PASSO 3: Analisar tráfego capturado
================================================
================================================
  Análise de Tráfego
================================================
  Total de pacotes: 0
--- Top 10 IPs Origem ---
  Não foi possível extrair IPs de origem
--- Tráfego Broadcast/Multicast ---
  Pacotes broadcast:  0
  Pacotes multicast:  0
--- Distribuição de Protocolos ---
```

> Output capturado em 2026-05-31 13:40:43 - execucao automatizada via `lab/run_tests.sh`
