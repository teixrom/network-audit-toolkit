# WiFi Auditor

Escaneia e audita redes Wi-Fi em busca de pontos de acesso e configurações inseguras.

## Como usar

```bash
cd 15-wifi_audit
sudo bash wifi_audit.sh
```

## O que faz

- Detecta interfaces Wi-Fi disponíveis
- Escaneia pontos de acesso próximos
- Identifica redes com criptografia fraca (WEP, WPA fraco)
- Detecta redes abertas (sem autenticação)
- Lista SSIDs e fabricantes dos APs

## Dependências

- `iw`
- `iwlist` ou `nmcli`
- `root` (para modo monitor/scan)

---



## Testes com Laboratorio Virtual

### Alvo
- **Host Discovery:** 10.99.0.0/24 (rede do laboratorio)
- **Demais modulos:** 10.99.0.10 (target container)
- **Servidores auxiliares:** LDAP=10.99.0.12, DNS=10.99.0.13, SNMP=10.99.0.14

### Evidencia de Execucao do Modulo

```
================================================
  Auditoria Wi-Fi
  15-wifi_audit
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
  PASSO 1: Listar interfaces Wi-Fi disponíveis
================================================
[*] Interfaces Wi-Fi detectadas:
  1) [*] Detectando interfaces Wi-Fi...  []
  2) wlp4s0  [UP]
Selecione a interface (1-2): [+] Interface selecionada: wlp4s0
[*] Deseja informar SSIDs conhecidos para detectar Rogue APs?
    (Redes legítimas da sua organização)
Informe os SSIDs conhecidos separados por vírgula (ou Enter para pular): 
================================================
  PASSO 2: Escaneando redes Wi-Fi
================================================
[*] Iniciando varredura em wlp4s0...
[*] Isso pode levar alguns segundos...
[+] Varredura concluída: 12 AP(s) encontrado(s)
================================================
  PASSO 3: Analisar pontos de acesso encontrados
================================================
================================================
  Pontos de Acesso Encontrados
================================================
--- AP #1 ---
  SSID:       Mix
  Canal:      1
  Sinal:      Signal level=-59
  Criptografia: WPA2
--- AP #2 ---
  SSID:       teixrom 2.4
  Canal:      5
  Sinal:      Signal level=-50
  Criptografia: WPA2
--- AP #3 ---
  SSID:       Teicel
  Canal:      6
```

> Output capturado em 2026-05-31 13:40:43 - execucao automatizada via `lab/run_tests.sh`
