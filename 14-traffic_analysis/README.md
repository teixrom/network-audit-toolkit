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
- Interface: any, filtro: icmp

### Recursos Utilizados
- Ferramentas: tcpdump, wireshark/tshark

### Procedimento e Resultados
```
tcpdump -i any icmp
```
3 pacotes ICMP capturados com sucesso

### Observacao
Ambiente Docker limita visibilidade; em rede real analise e mais rica
