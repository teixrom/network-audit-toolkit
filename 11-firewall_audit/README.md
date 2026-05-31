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
- **Host Discovery:** 10.99.0.0/24 (rede do laboratorio)
- **Demais modulos:** 10.99.0.10 (target container)
- **Servidores auxiliares:** LDAP=10.99.0.12, DNS=10.99.0.13, SNMP=10.99.0.14

### Evidencia de Execucao do Modulo

```
================================================
  Firewall Auditor
  11-firewall_audit
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
  PASSO 1: Selecionar alvo
================================================
IP do alvo: [+] Alvo: 1
================================================
  PASSO 2: Escolha o tipo de auditoria
================================================
[*] Selecione o tipo de auditoria:
  1) Análise local de regras de firewall (iptables)
  2) Detecção remota de firewall (nmap)
Selecione (1-2): Opção inválida
Selecione (1-2): [+] Tipo de auditoria: 2
================================================
  PASSO 3: Detecção remota de firewall
================================================
[*] Executando varreduras de detecção de firewall em 1...
--- Varredura TCP ACK (detecta filtragem stateful) ---
Starting Nmap 7.94SVN ( https://nmap.org ) at 2026-05-31 13:39 -03
Note: Host seems down. If it is really up, but blocking our ping probes, try -Pn
Nmap done: 1 IP address (0 hosts up) scanned in 2.06 seconds
  [+] Todas as portas filtradas - firewall stateful detectado
--- Varredura TCP FIN ---
Starting Nmap 7.94SVN ( https://nmap.org ) at 2026-05-31 13:39 -03
Note: Host seems down. If it is really up, but blocking our ping probes, try -Pn
Nmap done: 1 IP address (0 hosts up) scanned in 2.06 seconds
--- Varredura TCP NULL ---
Starting Nmap 7.94SVN ( https://nmap.org ) at 2026-05-31 13:39 -03
Note: Host seems down. If it is really up, but blocking our ping probes, try -Pn
Nmap done: 1 IP address (0 hosts up) scanned in 2.06 seconds
--- Varredura TCP XMAS ---
Starting Nmap 7.94SVN ( https://nmap.org ) at 2026-05-31 13:39 -03
Note: Host seems down. If it is really up, but blocking our ping probes, try -Pn
Nmap done: 1 IP address (0 hosts up) scanned in 2.06 seconds
--- Varredura UDP (top 50 portas) ---
Starting Nmap 7.94SVN ( https://nmap.org ) at 2026-05-31 13:39 -03
```

> Output capturado em 2026-05-31 13:40:43 - execucao automatizada via `lab/run_tests.sh`
