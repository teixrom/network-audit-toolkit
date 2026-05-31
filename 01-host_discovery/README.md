# 01 - Host Discovery

Descoberta de hosts ativos em uma rede local ou remota.

## Conceitos

### ARP Scan
Utiliza o protocolo ARP para descobrir dispositivos na **mesma rede local** (Layer 2). É o método mais rápido e confiável para redes locais, pois todos os dispositivos respondem a requisições ARP.

- **Vantagens:** Muito rápido, descobre MAC address e fabricante
- **Desvantagens:** Não funciona fora do broadcast domain
- **Ferramentas:** `arp-scan`, `nmap -PR`

### ICMP Ping Sweep
Envia pacotes ICMP Echo Request (ping) para cada endereço IP do range alvo. Hosts ativos respondem com Echo Reply.

- **Vantagens:** Simples, funciona em redes roteadas
- **Desvantagens:** Firewalls podem bloquear ICMP, mais lento que ARP
- **Ferramentas:** `nmap -sn -PE`, `fping`, `ping`

### TCP SYN Ping
Envia pacotes TCP SYN para portas específicas (80, 443, 22). Se a porta estiver aberta, o host responde com SYN/ACK; se fechada, responde com RST.

- **Vantagens:** Bypassa firewalls que bloqueiam ICMP
- **Desvantagens:** Requer privilégios root, pode ser detectado como scan
- **Ferramentas:** `nmap -sn -PS80,443,22`

## Uso

```bash
sudo bash host_discovery.sh
```

Requer privilégios **root** para criar sockets raw.

## Dependências

- `nmap` - Scanner de rede
- `arp-scan` (opcional) - Para ARP scan mais rápido

### Instalação

```bash
sudo apt update
sudo apt install -y nmap arp-scan
```

## Saída

O script exibe uma tabela com:
- Endereço IP
- Endereço MAC
- Fabricante (se disponível)

Os resultados podem ser exportados para um arquivo de texto.

---



## Testes com Laboratorio Virtual

### Alvo
- **Host Discovery:** 10.99.0.0/24 (rede do laboratorio)
- **Demais modulos:** 10.99.0.10 (target container)
- **Servidores auxiliares:** LDAP=10.99.0.12, DNS=10.99.0.13, SNMP=10.99.0.14

### Evidencia de Execucao do Modulo

```
================================================
  Descoberta de Hosts
  01-host_discovery
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
  PASSO 1: Selecione a interface de rede
================================================
[*] Selecione a interface de rede
  1) enp5s0
  2) wlp4s0
  3) podman0
  4) veth0@if2
  5) podman1
  6) veth1@if2
  7) veth3@if2
  8) veth4@if2
  9) veth5@if2
Selecione (1-9): [+] Interface selecionada: podman1
================================================
  PASSO 2: Selecione o tipo de varredura
================================================
[*] Selecione o tipo de varredura
  1) Varredura ARP (rede local) - Rápida, endereços MAC
  2) Varredura ICMP - Ping sweep tradicional
  3) TCP SYN Ping - Ignora firewalls (porta 80/443)
Selecione (1-3): [+] Tipo de varredura: tcp
================================================
  PASSO 3: Digite a rede alvo
================================================
Rede alvo: [+] Alvo: 10.99.0.10
================================================
  PASSO 4: Executando varredura
================================================
[*] Executando ping TCP SYN em 10.99.0.10...
[*] Escaneando com nmap -sn -PS
Starting Nmap 7.94SVN ( https://nmap.org ) at 2026-05-31 13:38 -03
Nmap scan report for 10.99.0.10
Host is up (0.000041s latency).
MAC Address: CA:F4:61:D2:A2:15 (Unknown)
```

> Output capturado em 2026-05-31 13:40:43 - execucao automatizada via `lab/run_tests.sh`
