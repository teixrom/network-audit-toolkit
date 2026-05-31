# 03 - Service Enumeration

Enumeração de serviços rodando em portas abertas.

## Conceitos

### Banner Grabbing
Técnica que consiste em conectar a um serviço e capturar sua mensagem de boas-vindas (banner), que geralmente contém informações sobre o software e sua versão.

- **FTP:** Banner exibe servidor FTP e versão
- **SSH:** Banner exibe versão do protocolo SSH e software
- **HTTP:** Headers HTTP revelam servidor web, versão, tecnologia
- **SMTP:** Banner exibe servidor de email e versão

### Version Detection
Utiliza o nmap com a flag `-sV` para identificar versões de serviços através de fingerprinting (assinaturas de resposta).

### Automated Service Checks
O script detecta automaticamente serviços comuns por porta e executa verificações específicas:

| Porta | Serviço | Verificação |
|-------|---------|-------------|
| 21 | FTP | Login anônimo |
| 22 | SSH | Versão SSH |
| 25 | SMTP | EHLO/HELO |
| 80/443 | HTTP/HTTPS | Headers, título |
| 3306 | MySQL | Banner, versão |
| 5432 | PostgreSQL | Banner |
| 6379 | Redis | Banner |

## Uso

```bash
bash service_enum.sh
```

Não requer root para banner grabbing básico.

## Dependências

- `nmap` - Version detection detalhada
- `netcat-openbsd` - Banner grabbing TCP/UDP
- `curl` - Banner grabbing HTTP/HTTPS

### Instalação

```bash
sudo apt update
sudo apt install -y nmap netcat-openbsd curl
```

## Saída

Tabela com porta, serviço detectado e informações do banner. Resultados podem ser salvos em arquivo para análise posterior.

---



## Testes com Laboratorio Virtual

### Alvo
- **Host Discovery:** 10.99.0.0/24 (rede do laboratorio)
- **Demais modulos:** 10.99.0.10 (target container)
- **Servidores auxiliares:** LDAP=10.99.0.12, DNS=10.99.0.13, SNMP=10.99.0.14

### Evidencia de Execucao do Modulo

```
================================================
  Enumeração de Serviços
  03-service_enum
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
[*] Selecione a origem do alvo
  1) Digitar alvo manualmente
Selecione (1-1): IP/hostname alvo: [+] Alvo: 10.99.0.10
================================================
  PASSO 2: Digite as portas para enumerar
================================================
Portas (ex: 21,22,80,443 ou 1-1024): [+] Portas: 22,80,443,21
================================================
  PASSO 3: Executando enumeração
================================================
[*] Iniciando enumeração de serviços...
================================================
  PASSO 4: Exibir resultados
================================================
================================================
  Resultados da Enumeração de Serviços para 10.99.0.10
================================================
PORTA    SERVIÇO       DETALHES                      
------------------------------------------------------------------------
22       SSH            SSH version: SSH-2.0-OpenSSH_8.4p1
80       HTTP           Server: Apache | Title: Apache2 Debian Default Page: It works
443      HTTPS          Server: Apache               
21       FTP            FTP service detected | Anonymous login: disabled
================================================
  PASSO 5: Detecção de versão com nmap
================================================
[*] Executar nmap -sV para detecção detalhada de versão?
  1) Sim
  2) Não
Selecione (1-2): [!] Pulando varredura de versão do nmap
================================================
  PASSO 6: Salvar resultados
```

> Output capturado em 2026-05-31 13:40:43 - execucao automatizada via `lab/run_tests.sh`
