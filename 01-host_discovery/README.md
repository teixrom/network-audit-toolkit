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
- IP: 10.99.0.0/24

### Recursos Utilizados
- Ferramentas: nmap (ICMP Ping Sweep), arp-scan

### Procedimento e Resultados

```
$ nmap -sn 10.99.0.0/24

Starting Nmap 7.80 ( https://nmap.org ) at 2026-05-31 10:00 -03
Nmap scan report for 10.99.0.1
Host is up (0.0012s latency).
Nmap scan report for 10.99.0.10 (target)
Host is up (0.0008s latency).
Nmap scan report for 10.99.0.11 (smb)
Host is up (0.0011s latency).
Nmap scan report for 10.99.0.12 (ldap)
Host is up (0.0009s latency).
Nmap scan report for 10.99.0.13 (dns)
Host is up (0.0010s latency).
Nmap scan report for 10.99.0.14 (snmp)
Host is up (0.0013s latency).
Nmap done: 256 IP addresses (6 hosts up) scanned in 2.45s
```

**Resultados:**
- Total de hosts ativos: 6
- Gateway: 10.99.0.1
- Containers alvo: 10.99.0.10 (target), 10.99.0.11 (smb), 10.99.0.12 (ldap), 10.99.0.13 (dns), 10.99.0.14 (snmp)
- Todos os 5 containers + gateway responderam ao ICMP
