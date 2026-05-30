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
