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
- IP: 10.99.0.10 (target)

### Recursos Utilizados
- Ferramentas: nmap -sV, netcat, curl

### Procedimento e Resultados

```
$ nmap -sV -p 22,80,443,21,3306 10.99.0.10

Starting Nmap 7.80 ( https://nmap.org ) at 2026-05-31 10:10 -03
Nmap scan report for 10.99.0.10
Host is up (0.0008s latency).

PORT     STATE SERVICE     VERSION
21/tcp   open  ftp         vsftpd 3.0.3
22/tcp   open  ssh         OpenSSH 8.4p1 Debian 5+deb11u7 (protocol 2.0)
80/tcp   open  http        Apache httpd 2.4.67
443/tcp  open  ssl/http    Apache httpd 2.4.67
3306/tcp open  mysql       MySQL 8.0.35

Service Info: Host: target.lab.local; OS: Linux; CPE: cpe:/o:linux:linux_kernel
```

**Banner Grabbing:**

```
$ nc -nv 10.99.0.10 22
(UNKNOWN) [10.99.0.10] 22 (ssh) open
SSH-2.0-OpenSSH_8.4p1 Debian-5+deb11u7

$ curl -sI http://10.99.0.10 | grep -i server
Server: Apache/2.4.67 (Debian)
```

**Resultados:**
- FTP: vsftpd 3.0.3
- SSH: OpenSSH 8.4p1 Debian-5+deb11u7
- HTTP: Apache httpd 2.4.67 (Debian)
- MySQL: MySQL 8.0.35
