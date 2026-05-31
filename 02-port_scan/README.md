# 02 - Port Scanner

Varredura de portas abertas em hosts alvo.

## Conceitos

### TCP Connect Scan (-sT)
Realiza o three-way handshake completo (SYN, SYN/ACK, ACK). É o método mais básico e não requer privilégios root.

- **Vantagens:** Não precisa de root, funciona em qualquer sistema
- **Desvantagens:** Mais lento, facilmente logado pelo alvo
- **Uso:** Scan de portas TCP comuns

### SYN Stealth Scan (-sS)
Envia apenas o pacote SYN. Se receber SYN/ACK, a porta está aberta; envia RST para não completar a conexão.

- **Vantagens:** Mais rápido, menos detectável
- **Desvantagens:** Requer privilégios root
- **Uso:** Scan stealth, auditoria de firewall

### UDP Scan (-sU)
Envia pacotes UDP vazios para portas específicas. Portas fechadas respondem com ICMP Port Unreachable.

- **Vantagens:** Detecta serviços UDP (DNS, SNMP, DHCP)
- **Desvantagens:** Muito mais lento, menos confiável
- **Uso:** Auditoria de serviços UDP

## Uso

```bash
sudo bash port_scan.sh
```

Requer privilégios **root** para SYN scan.

## Dependências

- `nmap` - Scanner de portas

### Instalação

```bash
sudo apt update
sudo apt install -y nmap
```

## Saída

O script exibe uma tabela com:
- Porta e protocolo (ex: 80/tcp)
- Estado (aberta, filtrada)
- Serviço associado (http, ssh, etc.)

Resultados podem ser exportados para arquivo de texto e carregados posteriormente pelo módulo de enumeração de serviços.

---

## Testes com Laboratorio Virtual

### Alvo
- IP: 10.99.0.10 (target)

### Recursos Utilizados
- Ferramentas: nmap (TCP Connect, SYN Stealth, UDP)

### Procedimento e Resultados

**TCP Connect Scan (-sT) e SYN Stealth Scan (-sS):**

```
$ nmap -p- --open 10.99.0.10

Starting Nmap 7.80 ( https://nmap.org ) at 2026-05-31 10:05 -03
Nmap scan report for 10.99.0.10
Host is up (0.0009s latency).
Not shown: 65531 closed ports
PORT    STATE SERVICE
21/tcp  open  ftp
22/tcp  open  ssh
80/tcp  open  http
443/tcp open  https

Nmap done: 1 IP address (1 host up) scanned in 65.23s
```

```
$ nmap -sS -T4 --top-ports 100 10.99.0.10

Starting Nmap 7.80 ( https://nmap.org ) at 2026-05-31 10:06 -03
Nmap scan report for 10.99.0.10
Host is up (0.0007s latency).
PORT    STATE SERVICE
21/tcp  open  ftp
22/tcp  open  ssh
80/tcp  open  http
443/tcp open  https

Nmap done: 1 IP address (1 host up) scanned in 4.52s
```

**UDP Scan:**

```
$ nmap -sU -T4 --top-ports 20 10.99.0.10

Starting Nmap 7.80 ( https://nmap.org ) at 2026-05-31 10:07 -03
Nmap scan report for 10.99.0.10
Host is up (0.0011s latency).
PORT      STATE         SERVICE
53/udp    open|filtered domain
135/udp   open|filtered msrpc
162/udp   open|filtered snmptrap
520/udp   open|filtered route
1900/udp  open|filtered upnp
49152/udp open|filtered unknown

Nmap done: 1 IP address (1 host up) scanned in 20.18s
```

**Resultados:**
- Portas TCP abertas: 21 (FTP), 22 (SSH), 80 (HTTP), 443 (HTTPS)
- Portas UDP filtradas: 53, 135, 162, 520, 1900, 49152
