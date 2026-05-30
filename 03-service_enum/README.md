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
