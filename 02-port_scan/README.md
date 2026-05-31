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
- **Host Discovery:** 10.99.0.0/24 (rede do laboratorio)
- **Demais modulos:** 10.99.0.10 (target container)
- **Servidores auxiliares:** LDAP=10.99.0.12, DNS=10.99.0.13, SNMP=10.99.0.14

### Evidencia de Execucao do Modulo

```
================================================
  Scanner de Portas
  02-port_scan
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
  PASSO 1: Digite o alvo
================================================
IP/hostname alvo: [+] Alvo: 2
================================================
  PASSO 2: Selecione o tipo de varredura
================================================
[*] Selecione o tipo de varredura
  1) Varredura rápida (top 100 portas)
  2) Varredura padrão (top 1000 portas)
  3) Varredura completa (portas 1-65535)
  4) Intervalo de portas personalizado
Selecione (1-4): Opção inválida
Selecione (1-4): [+] Tipo de varredura: quick
================================================
  PASSO 3: Selecione a técnica de varredura
================================================
[*] Selecione a técnica de varredura
  1) TCP Connect (-sT) - Handshake completo, sem root
  2) SYN Stealth (-sS) - Meia abertura, rápida, precisa de root
  3) UDP Scan (-sU) - Portas UDP, mais lenta
Selecione (1-3): [+] Técnica: -sS
================================================
  PASSO 4: Executando varredura
================================================
[*] Executando varredura nmap...
Nmap done: 1 IP address (0 hosts up) scanned in 2.05 seconds
================================================
  PASSO 5: Exibir resultados
================================================
================================================
  Portas Abertas em 2
================================================
[!] Nenhuma porta aberta encontrada.
================================================
```

> Output capturado em 2026-05-31 13:40:43 - execucao automatizada via `lab/run_tests.sh`
