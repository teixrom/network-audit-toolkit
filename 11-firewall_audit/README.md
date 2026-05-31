# 11 - Firewall Auditor

Ferramenta de auditoria de firewall local e remoto.

## Conceitos

### Stateful vs Stateless Firewall

| Tipo | Característica | Detecção |
|------|----------------|----------|
| **Stateful** | Mantém tabela de conexões ativas | Portas filtradas retornam ICMP unreachable ou drop silencioso |
| **Stateless** | Filtra pacote a pacote sem estado | Portas unfiltered no ACK scan |

### Tipos de Scan nmap

| Scan | Flags TCP | Uso |
|------|-----------|-----|
| `-sS` (SYN) | SYN | Detecta portas abertas |
| `-sA` (ACK) | ACK | Testa se firewall é stateful |
| `-sF` (FIN) | FIN | Detecta firewalls stateless |
| `-sN` (NULL) | Nenhuma | Firewalls que não seguem RFC |
| `-sX` (XMAS) | FIN+PSH+URG | Firewalls que não seguem RFC |
| `-sU` (UDP) | - | Scan de portas UDP |

### Packet Filtering

- **Open**: Porta respondendo (SYN+ACK)
- **Filtered**: Sem resposta ou ICMP unreachable
- **Unfiltered**: Acessível mas sem serviço (ACK scan)
- **Closed**: Responde com RST

### Técnicas Avançadas (hping3)

| Técnica | Descrição |
|---------|-----------|
| Fragmentação | Pacotes fragmentados podem bypassar firewalls simples |
| Spoofing | Pacotes com IP falsificado testam validação de origem |
| Rate Limiting | ICMP rate limiting indica proteção contra flooding |
| TTL Manipulação | Determina distância de hops até o alvo |

## Uso

```bash
bash firewall_audit.sh
```

Para análise local de iptables, execute como root.

## Dependências

- `nmap` - Scans de firewall
- `hping3` (opcional) - Testes avançados
- `iptables` (para análise local)

### Instalação

```bash
sudo apt update
sudo apt install -y nmap hping3 iptables
```

## Saída

Relatório completo contendo:
- Tipo de firewall (stateful/stateless)
- Regras inferidas (portas abertas/bloqueadas)
- Resultados de scans TCP/UDP
- Testes avançados com fragmentação e spoofing
- Fingerprint de SO

---

## Testes com Laboratorio Virtual

### Alvo
- IP: 10.99.0.10 (target)

### Recursos Utilizados
- Ferramentas: nmap -sA, -sF, -sN, -sX; iptables; hping3

### Procedimento e Resultados
```
nmap -sA 10.99.0.10
```
22/unfiltered, 80/unfiltered, 443/unfiltered (stateless)

```
nmap -sF 10.99.0.10
```
open|filtered (inconsistent - suggests stateful inspection)

```
iptables -L -n
```
Policy ACCEPT on all chains (no firewall rules)
