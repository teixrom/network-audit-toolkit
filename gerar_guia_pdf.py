#!/usr/bin/env python3
"""Gera guia didático em PDF do Network Audit Toolkit."""

from fpdf import FPDF
import os, datetime

ROOT = "/home/teixrom/projetos/network_audit"
FONT_DIR = "/usr/share/fonts/truetype/dejavu"

class GuiaPDF(FPDF):
    def __init__(self):
        super().__init__()
        self.add_font("DejaVu", "", os.path.join(FONT_DIR, "DejaVuSans.ttf"))
        self.add_font("DejaVu", "B", os.path.join(FONT_DIR, "DejaVuSans-Bold.ttf"))
        self.add_font("DejaVuMono", "", "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf")
        self.set_auto_page_break(auto=True, margin=20)

    def header(self):
        if self.page_no() > 1:
            self.set_font("DejaVu", "", 8)
            self.set_text_color(100,100,100)
            self.cell(0, 6, "Network Audit Toolkit - Guia Didatico", align="L")
            self.cell(0, 6, f"Pagina {self.page_no()}/{{nb}}", align="R", new_x="LMARGIN", new_y="NEXT")
            self.line(10, 14, 200, 14)
            self.ln(4)

    def footer(self):
        if self.page_no() > 1:
            self.set_y(-15)
            self.set_font("DejaVu", "", 7)
            self.set_text_color(150,150,150)
            self.cell(0,10, "Uso educacional e testes autorizados. Uso nao autorizado e ilegal.", align="C")

    def titulo(self, text):
        self.set_font("DejaVu", "B", 20)
        self.set_text_color(0,51,102)
        self.ln(4)
        self.multi_cell(0, 10, text)
        self.set_draw_color(0,51,102)
        self.line(10, self.get_y(), 200, self.get_y())
        self.ln(4)

    def secao(self, num, text):
        self.set_font("DejaVu", "B", 14)
        self.set_text_color(0,80,130)
        self.ln(3)
        label = f"{num}. {text}" if num else text
        self.cell(0, 8, label, new_x="LMARGIN", new_y="NEXT")
        self.set_draw_color(0,80,130)
        self.line(10, self.get_y(), 200, self.get_y())
        self.ln(2)

    def subsecao(self, text):
        self.set_font("DejaVu", "B", 11)
        self.set_text_color(0,100,160)
        self.ln(2)
        self.cell(0, 7, text, new_x="LMARGIN", new_y="NEXT")
        self.ln(1)

    def corpo(self, text):
        self.set_font("DejaVu", "", 10)
        self.set_text_color(30,30,30)
        self.multi_cell(0, 5.5, text)
        self.ln(1)

    def destaque(self, text):
        self.set_font("DejaVu", "", 10)
        self.set_text_color(0,80,0)
        self.multi_cell(0, 5.5, text)
        self.ln(1)

    def comando(self, text):
        self.set_font("DejaVuMono", "", 9)
        self.set_fill_color(240,240,240)
        self.set_text_color(50,50,50)
        self.multi_cell(0, 5.5, text, fill=True)
        self.ln(1)

    def tabela(self, headers, rows):
        self.set_font("DejaVu", "B", 9)
        self.set_fill_color(0,80,130)
        self.set_text_color(255,255,255)
        col_w = 190 / len(headers)
        for h in headers:
            self.cell(col_w, 7, h, border=1, fill=True, align="C")
        self.ln()
        self.set_font("DejaVu", "", 9)
        self.set_text_color(30,30,30)
        fill = False
        for row in rows:
            if fill:
                self.set_fill_color(230,240,250)
            else:
                self.set_fill_color(255,255,255)
            for i, cell in enumerate(row):
                self.cell(col_w, 6, str(cell), border=1, align="C", fill=True)
            self.ln()
            fill = not fill
        self.ln(2)

    def nota(self, text):
        self.set_font("DejaVu", "", 9)
        self.set_text_color(100,60,0)
        self.set_fill_color(255,255,200)
        self.multi_cell(0, 5, f"[!] {text}", fill=True)
        self.ln(1)

    def exemplo_box(self, title, content):
        self.set_font("DejaVu", "B", 9)
        self.set_fill_color(230,240,250)
        self.set_text_color(0,51,102)
        self.cell(0, 6, f"  {title}", fill=True, new_x="LMARGIN", new_y="NEXT")
        self.set_font("DejaVuMono", "", 8)
        self.set_fill_color(245,245,250)
        self.set_text_color(30,30,30)
        self.multi_cell(0, 4.5, content, fill=True)
        self.ln(2)

def gerar():
    pdf = GuiaPDF()
    pdf.alias_nb_pages()

    # ---- CAPA ----
    pdf.add_page()
    pdf.ln(50)
    pdf.set_font("DejaVu", "B", 28)
    pdf.set_text_color(0,51,102)
    pdf.cell(0, 15, "NETWORK AUDIT", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.cell(0, 15, "TOOLKIT", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(5)
    pdf.set_font("DejaVu", "", 16)
    pdf.set_text_color(0,100,160)
    pdf.cell(0, 10, "Guia Didatico de Uso", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(10)
    pdf.set_draw_color(0,51,102)
    pdf.line(60, pdf.get_y(), 150, pdf.get_y())
    pdf.ln(10)
    pdf.set_font("DejaVu", "", 11)
    pdf.set_text_color(80,80,80)
    pdf.cell(0, 7, "Suite de Auditoria de Redes em Bash", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.cell(0, 7, "17 modulos para analise de seguranca", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(20)
    pdf.set_font("DejaVu", "", 9)
    pdf.set_text_color(120,120,120)
    data = datetime.date.today().strftime("%d/%m/%Y")
    pdf.cell(0, 6, f"Versao 1.0 - {data}", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.cell(0, 6, "Uso educacional e testes de penetracao autorizados", align="C", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(15)
    pdf.set_font("DejaVu", "B", 9)
    pdf.set_text_color(180,0,0)
    pdf.multi_cell(0, 5, "AVISO LEGAL: Esta ferramenta deve ser usada apenas em sistemas proprios ou com autorizacao explicita. O uso nao autorizado e ilegal e pode resultar em processos criminais. O autor nao se responsabiliza pelo mau uso.", align="C")

    # ---- SUMARIO ----
    pdf.add_page()
    pdf.titulo("Sumario")
    itens = [
        ("1", "Introducao"),
        ("2", "Instalacao"),
        ("3", "Menu Principal"),
        ("4", "Modulo 1: Descoberta de Hosts"),
        ("5", "Modulo 2: Varredura de Portas"),
        ("6", "Modulo 3: Enumeracao de Servicos"),
        ("7", "Modulo 4: Auditoria Web"),
        ("8", "Modulo 5: Auditoria DNS"),
        ("9", "Modulo 6: Auditoria SMB"),
        ("10", "Modulo 7: Auditoria SNMP"),
        ("11", "Modulo 8: Teste de Senhas"),
        ("12", "Modulo 9: Auditoria SSL/TLS"),
        ("13", "Modulo 10: Varredura de Vulnerabilidades"),
        ("14", "Modulo 11: Auditoria de Firewall"),
        ("12", "Modulo 12: Analise de Logs"),
        ("13", "Modulo 13: Auditoria de Configuracao"),
        ("14", "Modulo 14: Analise de Trafego"),
        ("15", "Modulo 15: Auditoria Wi-Fi"),
        ("16", "Modulo 16: Avaliacao de Vulnerabilidades"),
        ("17", "Modulo 17: Auditoria de Identidade"),
        ("18", "Relatorio Consolidado de Testes"),
        ("19", "Boas Praticas e Avisos Legais"),
    ]
    for n, desc in itens:
        pdf.set_font("DejaVu", "", 10)
        pdf.set_text_color(30,30,30)
        pdf.cell(10, 7, n, align="R")
        pdf.cell(0, 7, f"  {desc}", new_x="LMARGIN", new_y="NEXT")

    # ---- 1. INTRODUCAO ----
    pdf.add_page()
    pdf.secao("1", "Introducao")
    pdf.corpo(
        "O Network Audit Toolkit e uma suite completa de auditoria de redes "
        "desenvolvida em Bash script. Composta por 17 modulos independentes, "
        "a ferramenta automatiza tarefas comuns de seguranca ofensiva e "
        "defensiva, desde a descoberta de hosts ate a analise forense de logs."
    )
    pdf.corpo(
        "Cada modulo pode ser executado individualmente ou atraves do menu "
        "principal. Todos compartilham o mesmo conjunto de funcoes utilitarias "
        "(cores, logs, barras de progresso) e seguem um fluxo padrao: "
        "entrada de dados -> execucao -> exibicao de resultados -> exportacao."
    )
    pdf.subsecao("Estrutura do Projeto")
    pdf.comando(
"network_audit/\n"
"  network_audit.sh    # Menu principal\n"
"  install.sh           # Instalador de dependencias\n"
"  utils/\n"
"    common.sh          # Funcoes compartilhadas\n"
"  audits/              # Logs e exportacoes\n"
"  01-host_discovery/   # Descoberta de hosts\n"
"  02-port_scan/        # Varredura de portas\n"
"  03-service_enum/     # Enumeracao de servicos\n"
"  04-web_audit/        # Auditoria web\n"
"  05-dns_audit/        # Auditoria DNS\n"
"  06-smb_audit/        # Auditoria SMB\n"
"  07-snmp_audit/       # Auditoria SNMP\n"
"  08-password_audit/   # Teste de senhas\n"
"  09-ssl_audit/        # Auditoria SSL/TLS\n"
"  10-vulnerability_scan/ # Varredura de vulnerabilidades\n"
"  11-firewall_audit/   # Auditoria de firewall\n"
"  12-log_audit/        # Analise de logs\n"
"  13-config_audit/     # Auditoria de configuracao\n"
"  14-traffic_analysis/ # Analise de trafego\n"
"  15-wifi_audit/       # Auditoria Wi-Fi\n"
"  16-vuln_assessment/  # Avaliacao de vulnerabilidades\n"
"  17-identity_audit/   # Auditoria de identidade"
    )
    pdf.subsecao("Fluxo de Auditoria Tipico")
    pdf.corpo(
        "1. Descubra hosts ativos na rede (Modulo 1)\n"
        "2. Escaneie portas abertas em cada host (Modulo 2)\n"
        "3. Enumere servicos rodando nas portas (Modulo 3)\n"
        "4. Aprofunde em servicos especificos (Modulos 4 a 9)\n"
        "5. Varra vulnerabilidades conhecidas (Modulo 10)\n"
        "6. Analise firewall e logs (Modulos 11 e 12)\n"
        "7. Audite configuracoes e trafego (Modulos 13 e 14)\n"
        "8. Verifique Wi-Fi e identidade (Modulos 15 a 17)\n"
        "9. Gere relatorio completo"
    )

    # ---- 2. INSTALACAO ----
    pdf.add_page()
    pdf.secao("2", "Instalacao")
    pdf.corpo(
        "Para instalar, clone o repositorio e execute o instalador como root:"
    )
    pdf.comando("git clone <url-do-repositorio>\ncd network_audit\nsudo bash install.sh")
    pdf.corpo(
        "O instalador detecta automaticamente sua distribuicao Linux "
        "(Debian/Ubuntu, Fedora, CentOS, Arch, Suse) e instala os pacotes "
        "necessarios. Oferece tres opcoes:"
    )
    pdf.tabela(
        ["Opcao", "Descricao"],
        [
            ["1 - Instalar tudo", "Instala todas as ferramentas, incluindo SecLists"],
            ["2 - Verificar status", "Mostra quais ferramentas estao instaladas"],
            ["3 - Sair", "Encerra o instalador"],
        ]
    )
    pdf.subsecao("Ferramentas Instaladas")
    pdf.tabela(
        ["Base", "Opcionais", "Utilitarios"],
        [
            ["nmap", "arp-scan", "hydra"],
            ["curl / wget", "smbclient", "gobuster / dirb"],
            ["openssl", "nikto", "john"],
            ["dnsutils (dig)", "hping3", "tcpdump"],
            ["whois", "iptables", "enum4linux"],
            ["python3 / pip3", "snmp / snmpwalk", "netcat"],
        ]
    )
    pdf.corpo("Apos a instalacao, execute o menu principal como root:")

    # ---- 3. MENU PRINCIPAL ----
    pdf.secao("3", "Menu Principal")
    pdf.comando("sudo bash network_audit.sh")
    pdf.corpo(
        "O menu principal exibe um aviso legal (necessario pressionar ENTER "
        "para confirmar) e apresenta os 17 modulos disponiveis. "
        "Basta digitar o numero do modulo desejado e pressionar ENTER."
    )
    pdf.corpo(
        "Cada execucao de modulo e registrada em um arquivo de log "
        "em audits/menu_YYYYMMDD_HHMMSS.log, permitindo rastrear "
        "todas as auditorias realizadas em uma sessao."
    )

    # ---- 4. MODULO 1: HOST DISCOVERY ----
    pdf.add_page()
    pdf.secao("4", "Modulo 1: Descoberta de Hosts")
    pdf.corpo(
        "Este modulo descobre hosts ativos em uma rede atraves de tres "
        "tecnicas de varredura. Essencial como primeiro passo em qualquer "
        "auditoria para mapear os dispositivos conectados."
    )
    pdf.subsecao("Parametros Solicitados")
    pdf.tabela(
        ["Parametro", "Descricao", "Exemplo"],
        [
            ["Interface", "Placa de rede para realizar a varredura", "eth0, wlan0"],
            ["Tipo", "Tecnica de descoberta", "ARP / ICMP / TCP SYN"],
            ["Rede alvo", "Endereco ou faixa da rede", "192.168.1.0/24"],
        ]
    )
    pdf.subsecao("Tipos de Varredura")
    pdf.tabela(
        ["Tipo", "Descricao", "Melhor para"],
        [
            ["ARP Scan", "Mais rapido, obtem MAC", "Redes locais (mesmo segmento)"],
            ["ICMP Ping", "Tradicional, ping simples", "Redes que respondem ping"],
            ["TCP SYN Ping", "Portas 80/443/22", "Burlar firewalls"],
        ]
    )
    pdf.subsecao("Exemplo Pratico")
    pdf.exemplo_box("Exemplo 1: Descobrir hosts na rede local",
        "$ sudo bash network_audit.sh\n"
        "Selecione: 1\n"
        "Interface disponiveis: 1) eth0  2) wlan0\n"
        "Selecione a interface: 1\n"
        "Tipo de varredura: 1) ARP  2) ICMP  3) TCP SYN\n"
        "Selecione: 1\n"
        "Digite a rede alvo: 192.168.1.0/24\n\n"
        "[=====               ] 45%\n\n"
        "Hosts descobertos: 5\n"
        " 1  192.168.1.1    aa:bb:cc:dd:ee:ff   Cisco\n"
        " 2  192.168.1.10   11:22:33:44:55:66   Intel\n"
        " 3  192.168.1.20   aa:11:bb:22:cc:33   Raspberry Pi\n\n"
        "Deseja escanear um host em detalhe? (1-5 / 0 pular): 2")
    pdf.nota("O ARP Scan funciona apenas no mesmo segmento de rede (broadcast local). Para redes remotas, use ICMP ou TCP SYN.")

    # ---- 5. MODULO 2: PORT SCAN ----
    pdf.add_page()
    pdf.secao("5", "Modulo 2: Varredura de Portas")
    pdf.corpo(
        "Escaneia portas abertas em um host alvo. Pode carregar resultados "
        "do Modulo 1 (hosts descobertos) ou receber um alvo manual."
    )
    pdf.subsecao("Tipos de Varredura")
    pdf.tabela(
        ["Tipo", "Portas", "Tempo estimado"],
        [
            ["1 - Rapida", "Top 100", "~40s"],
            ["2 - Padrao", "Top 1000", "~2min"],
            ["3 - Completa", "1-65535", "~10min"],
            ["4 - Personalizada", "Definido pelo usuario", "Variavel"],
        ]
    )
    pdf.subsecao("Tecnicas de Varredura")
    pdf.tabela(
        ["Tecnica", "Comando nmap", "Observacao"],
        [
            ["TCP Connect", "-sT", "Completa conexao, mais ruidosa"],
            ["SYN Stealth", "-sS", "Meia conexao, precisa de root"],
            ["UDP", "-sU", "Mais lenta, para servicos UDP"],
        ]
    )
    pdf.subsecao("Exemplo Pratico")
    pdf.exemplo_box("Exemplo 2: Escanear portas de um servidor web",
        "Alvo: 192.168.1.10\n"
        "Tipo de varredura: 2 - Padrao (top 1000)\n"
        "Tecnica: 2 - SYN Stealth\n\n"
        "[===============     ] 60%\n\n"
        "Portas Abertas em 192.168.1.10:\n"
        "  PORTA    ESTADO    SERVICO\n"
        "  22/tcp   open      ssh\n"
        "  80/tcp   open      http\n"
        "  443/tcp  open      https\n"
        "  3306/tcp open      mysql\n\n"
        "Deseja detectar versoes? (s/N): s\n"
        "22/tcp  OpenSSH 8.2p1\n"
        "80/tcp  Apache httpd 2.4.41\n"
        "443/tcp Apache httpd 2.4.41\n"
        "3306/tcp MySQL 8.0.32")
    pdf.nota("SYN Stealth requer privilegios root. UDP e muito mais lento que TCP.")

    # ---- 6. MODULO 3: SERVICE ENUM ----
    pdf.add_page()
    pdf.secao("6", "Modulo 3: Enumeracao de Servicos")
    pdf.corpo(
        "Enumera servicos rodando nas portas abertas atraves de banner "
        "grabbing e nmap -sV. Pode carregar resultados do Modulo 2 ou "
        "receber alvo e portas manualmente."
    )
    pdf.subsecao("Servicos Reconhecidos Automaticamente")
    pdf.tabela(
        ["Porta", "Servico", "Teste Especifico"],
        [
            ["21", "FTP", "Login anonimo"],
            ["22", "SSH", "Versao do servidor"],
            ["25", "SMTP", "EHLO / relay"],
            ["80/443/8080/8443", "HTTP/HTTPS", "Server header + titulo HTML"],
            ["3306", "MySQL", "Versao do banco"],
            ["5432", "PostgreSQL", "Versao do banco"],
            ["6379", "Redis", "Banner do servico"],
            ["110/143", "POP3/IMAP", "Banner do servico"],
            ["389/636", "LDAP", "Banner do servico"],
        ]
    )
    pdf.subsecao("Exemplo Pratico")
    pdf.exemplo_box("Exemplo 3: Enumerar servicos em um servidor",
        "Alvo: 192.168.1.10\n"
        "Portas (carregadas do Modulo 2): 22,80,443,3306\n"
        "Executando nmap -sV...\n\n"
        "[=====               ] 45%\n\n"
        "Resultados:\n"
        "  PORTA    SERVICO      DETALHES\n"
        "  22/tcp   SSH          SSH-2.0-OpenSSH_8.2p1\n"
        "  80/tcp   HTTP         Apache/2.4.41 (Ubuntu) | titulo: 'Apache2 Default Page'\n"
        "  443/tcp  HTTPS        Apache/2.4.41 (Ubuntu)\n"
        "  3306/tcp MySQL        5.7.38-0ubuntu0.18.04.1\n\n"
        "Teste FTP anonimo: OK - login anonimo permitido!")
    pdf.nota("Banner grabbing pode ser bloqueado por firewalls ou configuracoes de servidor. O nmap -sV e mais confiavel que o banner grabbing manual.")

    # ---- 7. MODULO 4: WEB AUDIT ----
    pdf.add_page()
    pdf.secao("7", "Modulo 4: Auditoria Web")
    pdf.corpo(
        "Auditoria completa de servidores web. Analisa cabecalhos de "
        "seguranca, tecnologias utilizadas, certificado SSL, formularios "
        "e realiza brute force de diretorios."
    )

    pdf.subsecao("Analises Realizadas")
    pdf.tabela(
        ["Analise", "O que verifica"],
        [
            ["Cabecalhos HTTP", "HSTS, X-Frame-Options, CSP, etc. (7 headers)"],
            ["Cookies", "Flags Secure, HttpOnly, SameSite"],
            ["Tecnologias", "CMS, frameworks, servidor web"],
            ["SSL/TLS", "Validade do certificado, CN, dias para expirar"],
            ["Formularios", "Action, method, quantidade de inputs"],
            ["Diretorios", "Brute force com gobuster ou dirb"],
        ]
    )

    pdf.subsecao("Score de Seguranca")
    pdf.corpo(
        "Cada cabecalho de seguranca presente gera 1 ponto (maximo 7). "
        "A nota final e convertida em conceito de A a F."
    )

    pdf.subsecao("Exemplo Pratico")
    pdf.exemplo_box("Exemplo 4: Auditar um site",
        "Digite a URL: https://exemplo.com.br\n\n"
        "--- Analise de Cabecalhos de Seguranca ---\n"
        "[OK] Strict-Transport-Security\n"
        "[OK] X-Frame-Options\n"
        "[!]  X-Content-Type-Options AUSENTE\n"
        "[!]  Content-Security-Policy AUSENTE\n"
        "[OK] Referrer-Policy\n"
        "[!]  Permissions-Policy AUSENTE\n"
        "Score: 4/7 - Nota: D\n\n"
        "--- Cookies ---\n"
        "PHPSESSID: Secure SIM | HttpOnly SIM | SameSite NAO\n\n"
        "--- Tecnologias Detectadas ---\n"
        "Servidor: nginx/1.18.0\n"
        "PHP 7.4, WordPress 6.0\n\n"
        "Deseja fazer brute force de diretorios? (s/N): s\n"
        "Ferramenta: gobuster\n"
        "Wordlist: 1 - dirb common.txt\n\n"
        "Diretorios encontrados:\n"
        "  /wp-admin (200)\n"
        "  /wp-content (301)\n"
        "  /wp-includes (301)\n"
        "  /wp-login.php (200)\n"
        "  /xmlrpc.php (200)")

    # ---- 8. MODULO 5: DNS AUDIT ----
    pdf.add_page()
    pdf.secao("8", "Modulo 5: Auditoria DNS")
    pdf.corpo(
        "Realiza enumeracao de registros DNS, verifica vulnerabilidade "
        "de transferencia de zona (AXFR), descobre subdominios e faz "
        "consultas DNS reversas."
    )

    pdf.subsecao("Funcionalidades")
    pdf.tabela(
        ["Funcao", "Descricao"],
        [
            ["Registros DNS", "A, AAAA, MX, NS, TXT, SOA, CNAME"],
            ["Transferencia de Zona", "Testa AXFR em todos os NS"],
            ["Subdominios", "Wordlist propria ou personalizada"],
            ["DNS Reverso", "De IPs descobertos ou faixa manual"],
        ]
    )

    pdf.subsecao("Exemplo Pratico")
    pdf.exemplo_box("Exemplo 5: Auditoria de DNS",
        "Dominio: exemplo.com.br\n"
        "Servidor DNS: 1 - Sistema (padrao)\n"
        "Tipos de registro: 8 - Todos\n\n"
        "Registros encontrados:\n"
        "  exemplo.com.br.   A       192.168.1.10\n"
        "  exemplo.com.br.   MX      10 mail.exemplo.com.br.\n"
        "  exemplo.com.br.   NS      ns1.exemplo.com.br.\n"
        "  exemplo.com.br.   TXT     v=spf1 include:_spf.google.com ~all\n\n"
        "--- Transferencia de Zona ---\n"
        "  ns1.exemplo.com.br: [SEGURO] - transferencia rejeitada\n"
        "  ns2.exemplo.com.br: [VULNERAVEL] - zone transfer permitida!\n\n"
        "--- Subdominios ---\n"
        "  www.exemplo.com.br      192.168.1.10\n"
        "  mail.exemplo.com.br     192.168.1.11\n"
        "  admin.exemplo.com.br    192.168.1.12")
    pdf.nota("Transferencia de zona (AXFR) e uma vulnerabilidade critica! Um NS que permite AXFR expoe todo o mapa da rede.")

    # ---- 9. MODULO 6: SMB AUDIT ----
    pdf.add_page()
    pdf.secao("9", "Modulo 6: Auditoria SMB")
    pdf.corpo(
        "Audita servicos SMB/NetBIOS (portas 139 e 445). Detecta versao "
        "do SMB, testa sessoes nulas, enumera compartilhamentos e "
        "usuarios, identifica o sistema operacional."
    )

    pdf.subsecao("Verificacoes Realizadas")
    pdf.tabela(
        ["Verificacao", "Relevancia"],
        [
            ["SMBv1 ativo", "Vulneravel ao EternalBlue (WannaCry)"],
            ["Sessao nula", "Acesso anonimo ao servidor"],
            ["Compartilhamentos", "Pastas acessiveis sem autenticacao"],
            ["Usuarios enumerados", "Alvos para brute force"],
            ["SO detectado", "Direciona explotis especificos"],
        ]
    )

    pdf.subsecao("Exemplo Pratico")
    pdf.exemplo_box("Exemplo 6: Auditar servidor SMB",
        "Alvo: 192.168.1.10\n\n"
        "Portas SMB: 139 ABERTA | 445 ABERTA\n"
        "Versao SMB: SMBv1 detectado (VULNERAVEL)\n"
        "Sessao nula: PERMITIDA (anonimo)\n\n"
        "Compartilhamentos:\n"
        "  ADMIN$   - Administracao remota\n"
        "  C$       - Compartilhamento padrao\n"
        "  Dados    - Documentos corporativos (ACESSIVEL)\n\n"
        "Usuarios encontrados:\n"
        "  Administrador, Joao, Maria, Backup\n\n"
        "SO: Windows Server 2019 Standard\n\n"
        "--- Avaliacao de Risco ---\n"
        "Nivel: ALTO\n\n"
        "Recomendacoes:\n"
        "1. Desabilitar SMBv1 imediatamente\n"
        "2. Desabilitar sessoes nulas\n"
        "3. Restringir compartilhamentos\n"
        "4. Manter Windows atualizado")
    pdf.nota("SMBv1 esta presente em ataques como WannaCry (EternalBlue). A desabilitacao e urgente em ambientes corporativos.")

    # ---- 10. MODULO 7: SNMP AUDIT ----
    pdf.add_page()
    pdf.secao("10", "Modulo 7: Auditoria SNMP")
    pdf.corpo(
        "Audita servicos SNMP (porta UDP 161). Testa strings de comunidade "
        "comuns, detecta versao do SNMP e realiza walks MIB para extrair "
        "informacoes do dispositivo."
    )

    pdf.subsecao("Informacoes Extraidas via MIB Walk")
    pdf.tabela(
        ["Informacao", "OID"],
        [
            ["Descricao do sistema", "1.3.6.1.2.1.1.1.0"],
            ["Nome do host", "1.3.6.1.2.1.1.5.0"],
            ["Localizacao", "1.3.6.1.2.1.1.6.0"],
            ["Contato do admin", "1.3.6.1.2.1.1.4.0"],
            ["Tempo de atividade", "1.3.6.1.2.1.1.3.0"],
            ["Interfaces de rede", "1.3.6.1.2.1.2.1.0"],
            ["Processos em execucao", "1.3.6.1.2.1.25.4.2.1.2"],
            ["Software instalado", "1.3.6.1.2.1.25.6.3.1.2"],
            ["Portas TCP abertas", "1.3.6.1.2.1.6.13.1.1"],
            ["Contas de usuarios (Win)", "1.3.6.1.4.1.77.1.2.25"],
        ]
    )

    pdf.subsecao("Strings de Comunidade Testadas")
    pdf.corpo(
        "public, private, community, manager, admin, snmp, c0mrade, "
        "all, read, write, test, security, monitor, netman, server, "
        "root, user (18 strings comuns)"
    )

    pdf.subsecao("Exemplo Pratico")
    pdf.exemplo_box("Exemplo 7: Auditar SNMP de um switch",
        "Alvo: 192.168.1.254\n\n"
        "Porta UDP 161: ABERTA\n"
        "String de comunidade valida: public (v2c)\n\n"
        "--- Informacoes do Sistema ---\n"
        "Descricao: Cisco IOS XE, Catalyst 9200\n"
        "Hostname: SW-CORPORATIVO-01\n"
        "Localizacao: Sala de Servidores - Rack A1\n"
        "Uptime: 127 dias, 14h, 32min\n\n"
        "--- Interfaces ---\n"
        "  24 interfaces encontradas\n"
        "  GigabitEthernet1/0/1: 192.168.1.254\n"
        "  GigabitEthernet1/0/2: 10.0.0.1\n\n"
        "--- Portas TCP Abertas ---\n"
        "  22 (SSH), 23 (Telnet), 80 (HTTP), 443 (HTTPS), 161 (SNMP)")
    pdf.nota("SNMP com comunidade 'public' e 'private' e uma das falhas de configuracao mais comuns em equipamentos de rede.")

    # ---- 11. MODULO 8: PASSWORD TEST ----
    pdf.add_page()
    pdf.secao("11", "Modulo 8: Teste de Senhas")
    pdf.corpo(
        "Realiza testes de senhas por forca bruta utilizando Hydra. "
        "Suporta diversos servicos e permite configuracao de taxa "
        "de requisicoes (threads e delay)."
    )

    pdf.subsecao("Servicos Suportados")
    pdf.tabela(
        ["Servico", "Porta", "Modo Hydra"],
        [
            ["SSH", "22", "ssh://"],
            ["FTP", "21", "ftp://"],
            ["HTTP Basic", "80", "http-get://"],
            ["HTTP POST", "80", "http-post-form://"],
            ["RDP", "3389", "rdp://"],
            ["Telnet", "23", "telnet://"],
            ["SMB", "445", "smb://"],
            ["MySQL", "3306", "mysql://"],
        ]
    )

    pdf.subsecao("Exemplo Pratico")
    pdf.exemplo_box("Exemplo 8: Testar senhas SSH",
        "Alvo: 192.168.1.10\n"
        "Servico: 1 - SSH\n"
        "Usuario: 3 - Lista padrao (admin, root, etc)\n"
        "Wordlist: 2 - Baixar 10k mais comuns do SecLists\n"
        "Threads (1-50): 5\n"
        "Delay entre tentativas (0-10s): 1\n\n"
        "Executando Hydra...\n"
        "[STATUS] 500 tentativas...\n"
        "[STATUS] 1000 tentativas...\n\n"
        "Crendenciais Encontradas:\n"
        "  ALVO             CREDENCIAL\n"
        "  192.168.1.10     admin:admin123\n"
        "  192.168.1.10     root:toor")
    pdf.nota("Apenas para testes autorizados! Forca bruta sem permissao e crime em muitos paises (Lei Carolina Dieckmann no Brasil).")

    # ---- 12. MODULO 9: SSL/TLS ----
    pdf.add_page()
    pdf.secao("12", "Modulo 9: Auditoria SSL/TLS")
    pdf.corpo(
        "Audita configuracao de SSL/TLS em servidores. Analisa "
        "certificado, protocolos suportados, cifras disponiveis e "
        "vulnerabilidades conhecidas."
    )

    pdf.subsecao("Verificacoes Realizadas")
    pdf.tabela(
        ["Verificacao", "Detalhes"],
        [
            ["Certificado", "Subject, issuer, validade, SAN, auto-assinado"],
            ["Protocolos", "SSLv2, SSLv3, TLS 1.0, 1.1, 1.2, 1.3"],
            ["Cifras", "Enumera todas as cifras suportadas"],
            ["PFS", "Perfect Forward Secrecy (ECDHE/DHE)"],
            ["HSTS", "Verifica cabecalho HTTP"],
            ["Heartbleed", "Testa vulnerabilidade CVE-2014-0160"],
        ]
    )

    pdf.subsecao("Sistema de Pontuacao")
    pdf.corpo(
        "O modulo conta PASS, WARN e FAIL em todas as verificacoes. "
        "Atribui nota de A a F: A exige 0% FAIL e ate 20% WARN. "
        "Notas baixas indicam configuracao insegura."
    )

    pdf.subsecao("Exemplo Pratico")
    pdf.exemplo_box("Exemplo 9: Auditar SSL de um site",
        "Alvo: exemplo.com.br:443\n\n"
        "--- Detalhes do Certificado ---\n"
        "Subject: CN = exemplo.com.br\n"
        "Emissor: C = US, O = Let's Encrypt\n"
        "Validade: 01/01/2025 a 01/04/2025 (90 dias)\n"
        "Auto-assinado: Nao\n"
        "SAN: exemplo.com.br, www.exemplo.com.br\n\n"
        "--- Protocolos ---\n"
        "SSLv2:  Nao suportado (OK)\n"
        "SSLv3:  Nao suportado (OK)\n"
        "TLS 1.0: SUPORTADO (RUIM)\n"
        "TLS 1.1: SUPORTADO (RUIM)\n"
        "TLS 1.2: Suportado (OK)\n"
        "TLS 1.3: Suportado (OK)\n\n"
        "--- Heartbleed ---\n"
        "Nao vulneravel (OK)\n\n"
        "--- Resumo ---\n"
        "PASS: 12 | WARN: 2 | FAIL: 0\n"
        "Nota: B")

    # ---- 13. MODULO 10: VULNERABILITY SCAN ----
    pdf.add_page()
    pdf.secao("13", "Modulo 10: Varredura de Vulnerabilidades")
    pdf.corpo(
        "Realiza varredura de vulnerabilidades usando scripts NSE do "
        "nmap e verificacao de CVEs baseada em banners de servicos."
    )

    pdf.subsecao("Modos de Varredura")
    pdf.tabela(
        ["Modo", "Descricao"],
        [
            ["1 - Completo", "--script vuln (NSE)"],
            ["2 - CVE por Banner", "Match de versoes com CVEs conhecidas"],
            ["3 - Rapido e Seguro", "--script safe (NSE)"],
        ]
    )

    pdf.subsecao("Classificacao por Severidade")
    pdf.corpo(
        "Os achados sao agrupados por severidade: CRITICO (vermelho), "
        "ALTO (vermelho claro), MEDIO (amarelo), BAIXO (amarelo claro), "
        "INFO (ciano). Recomendacoes de remediacao sao geradas "
        "automaticamente."
    )

    pdf.subsecao("Scripts NSE por Servico")
    pdf.tabela(
        ["Servico", "Scripts NSE"],
        [
            ["HTTP", "http-enum, http-vuln-*"],
            ["SMB", "smb-vuln-*"],
            ["SSH", "ssh2-enum-algos"],
            ["SSL", "ssl-enum-ciphers, ssl-heartbleed"],
        ]
    )

    pdf.subsecao("Exemplo Pratico")
    pdf.exemplo_box("Exemplo 10: Escanear vulnerabilidades",
        "Alvo: 192.168.1.10\n"
        "Modo: 1 - Completo (NSE vuln)\n\n"
        "Executando scripts NSE (top 1000 ports)...\n\n"
        "Achados:\n"
        "  [CRITICO] SMB - Vulneravel a EternalBlue (MS17-010)\n"
        "  [ALTO]   SSL - TLS 1.0 suportado\n"
        "  [MEDIO]  HTTP - Directory listing em /uploads\n"
        "  [BAIXO]  SSH - Algoritmos CBC suportados\n\n"
        "--- Sugestoes de Remediacao ---\n"
        "1. Aplicar patch MS17-010 (SMB)\n"
        "2. Desabilitar TLS 1.0 e 1.1\n"
        "3. Desabilitar directory listing no Apache\n"
        "4. Restringir cifras SSH")

    # ---- 14. MODULO 11: FIREWALL ----
    pdf.add_page()
    pdf.secao("14", "Modulo 11: Auditoria de Firewall")
    pdf.corpo(
        "Analisa regras de firewall local (iptables) ou realiza "
        "deteccao remota de firewall usando tecnicas de evasion e "
        "scan diferenciado."
    )

    pdf.subsecao("Tipos de Auditoria")
    pdf.tabela(
        ["Tipo", "Descricao"],
        [
            ["Local", "Analisa regras iptables (filter, nat, mangle)"],
            ["Remoto", "Detecta tipo de firewall e infere regras"],
        ]
    )

    pdf.subsecao("Testes de Firewall Remoto")
    pdf.corpo(
        "Seleciona tipos de scan: ACK, FIN, NULL, XMAS, UDP e SYN. "
        "Compara resultados para inferir se o firewall e stateful ou "
        "stateless. Testes avancados com hping3 incluem pacotes "
        "fragmentados, spoofing e deteccao de rate limiting ICMP."
    )
    pdf.subsecao("Exemplo Pratico")
    pdf.exemplo_box("Exemplo 11: Auditar firewall remotamente",
        "Alvo: 192.168.1.1\n"
        "Tipo: 2 - Deteccao Remota\n\n"
        "ACK scan: 5 portas unfiltered, 995 filtered\n"
        "FIN scan: 0 portas abertas (todas filtradas)\n"
        "SYN scan: 3 portas abertas\n\n"
        "Resultado: Firewall Stateful detectado\n"
        "Politica inferida: Restritiva\n\n"
        "--- Fingerprint de SO ---\n"
        "Provalel: Linux 4.x (iptables/nftables)\n\n"
        "--- Testes Avancados ---\n"
        "Pacotes fragmentados: BLOQUEADOS\n"
        "ICMP rate limiting: ATIVO\n"
        "Distancia estimada: 1-2 hops")

    # ---- 15. MODULO 12: LOG AUDIT ----
    pdf.add_page()
    pdf.secao("15", "Modulo 12: Analise de Logs")
    pdf.corpo(
        "Analisa logs do sistema para detectar eventos de seguranca "
        "e indicadores de comprometimento (IOCs). Suporta syslog, "
        "auth.log, logs de servidor web e arquivos personalizados."
    )

    pdf.subsecao("Fontes de Log")
    pdf.tabela(
        ["Fonte", "Arquivos"],
        [
            ["Log do sistema", "/var/log/syslog ou journalctl"],
            ["Log de autenticacao", "/var/log/auth.log ou journalctl -u ssh"],
            ["Servidor web", "/var/log/apache2/access.log, /var/log/nginx/access.log"],
            ["Personalizado", "Qualquer arquivo de log"],
        ]
    )

    pdf.subsecao("Tipos de Analise")
    pdf.tabela(
        ["Tipo", "Detecta"],
        [
            ["1 - Logins falhos", "Tentativas de acesso negado, forca bruta SSH"],
            ["2 - IPs suspeitos", "Enderecos com muitas ocorrencias"],
            ["3 - Servicos", "Quedas, restart, segfault, OOM"],
            ["4 - Conexoes", "Portas em listening, conexoes ativas"],
            ["5 - Tudo", "Todas as analises acima"],
        ]
    )

    pdf.subsecao("Exemplo Pratico")
    pdf.exemplo_box("Exemplo 12: Analisar tentativas de invasao",
        "Fonte: 2 - Auth log\n"
        "Analise: 5 - Todas\n\n"
        "--- Tentativas SSH Falhas ---\n"
        "Total: 1.527 tentativas\n\n"
        "Top 10 IPs:\n"
        "  Tentativas  Endereco IP      Risco\n"
        "  847         185.220.101.x     ALTO\n"
        "  312         103.235.46.x      ALTO\n"
        "  89          45.33.32.x        MEDIO\n"
        "  ...\n\n"
        "Pico de atividade: entre 02:00 e 04:00 UTC\n\n"
        "--- Servicos ---\n"
        "ssh.service: 12 tentativas de restart\n"
        "apache2.service: 3 crashes (segfault)\n\n"
        "--- Conexoes Atuais ---\n"
        "Portas em listening: 22 (SSH), 80 (HTTP), 443 (HTTPS)")
    pdf.nota("Mais de 100 tentativas de SSH em 24h indicam ataque de forca bruta em andamento. Considere usar fail2ban ou alterar a porta SSH.")

    # ---- 13. MODULO 13: CONFIG AUDIT ----
    pdf.add_page()
    pdf.secao("13", "Modulo 13: Auditoria de Configuracao")
    pdf.corpo(
        "Analisa arquivos de configuracao de ativos de rede (switches, "
        "roteadores) em busca de senhas padrao, protocolos inseguros e "
        "regras de firewall excessivamente permissivas."
    )
    pdf.subsecao("Verificacoes Realizadas")
    pdf.tabela(
        ["Verificacao", "Descricao"],
        [
            ["Senhas padrao", "admin/admin, cisco/cisco, password/password"],
            ["Protocolos inseguros", "Telnet, SNMP v1/v2, HTTP"],
            ["ACLs permissivas", "Regras 'any any' ou 'permit any'"],
        ]
    )
    pdf.exemplo_box("Exemplo 13: Auditar configuracao de switch",
        "Caminho do arquivo de configuracao: running-config.txt\n\n"
        "--- Senhas Padrao Encontradas ---\n"
        "[!]  Senha 'admin' encontrada na linha 15\n"
        "[!]  Senha 'cisco' encontrada na linha 42\n\n"
        "--- Protocolos Inseguros ---\n"
        "[!]  Telnet habilitado (linha 23) - use SSH\n"
        "[!]  SNMP v2c configurado (linha 67)\n\n"
        "--- ACLs Permissivas ---\n"
        "[!]  access-list 10 permit any any (linha 89)\n\n"
        "Total de achados: 4 falhas de configuracao")

    # ---- 14. MODULO 14: TRAFFIC ANALYSIS ----
    pdf.add_page()
    pdf.secao("14", "Modulo 14: Analise de Trafego")
    pdf.corpo(
        "Captura e analisa trafego de rede em tempo real. Identifica "
        "picos de trafego, broadcasts excessivos e IPs que mais "
        "consomem banda no periodo."
    )
    pdf.subsecao("Funcionalidades")
    pdf.tabela(
        ["Funcao", "Descricao"],
        [
            ["Captura", "tcpdump por periodo configuravel (10-120s)"],
            ["Top IPs", "10 IPs que mais geraram trafego"],
            ["Protocolos", "divisao TCP/UDP/ICMP/outros"],
            ["Broadcasts", "Detecao de tempestade de broadcast"],
        ]
    )
    pdf.exemplo_box("Exemplo 14: Analisar trafego da rede",
        "Interface: eth0\n"
        "Duracao: 30 segundos\n\n"
        "[=============       ] 60%\n\n"
        "--- Resumo do Trafego ---\n"
        "Total de pacotes capturados: 12.847\n\n"
        "Top 10 IPs de origem:\n"
        "  1. 192.168.1.100  - 3.420 pacotes\n"
        "  2. 10.0.0.50      - 2.100 pacotes\n"
        "  3. 192.168.1.1    - 1.800 pacotes\n\n"
        "Protocolos:\n"
        "  TCP:  8.200 (63,8%)\n"
        "  UDP:  3.800 (29,6%)\n"
        "  ICMP:   520 (4,0%)\n"
        "  Outros:  327 (2,6%)\n\n"
        "Broadcasts: 850 pacotes (ALTO - possivel tempestade)")

    # ---- 15. MODULO 15: WIFI AUDIT ----
    pdf.add_page()
    pdf.secao("15", "Modulo 15: Auditoria Wi-Fi")
    pdf.corpo(
        "Audita a seguranca do perimetro Wi-Fi, listando pontos de "
        "acesso, detectando criptografia fraca (WEP, WPA1) e "
        "identificando possiveis Rogue APs."
    )
    pdf.subsecao("Classificacao de Risco")
    pdf.tabela(
        ["Criptografia", "Nivel de Risco"],
        [
            ["WEP", "CRITICO (quebrado em minutos)"],
            ["WPA1 (TKIP)", "ALTO (vulneravel)"],
            ["WPA2 (CCMP)", "MEDIO (aceitavel)"],
            ["WPA3 (SAE)", "BAIXO (recomendado)"],
            ["Rede aberta", "CRITICO (sem criptografia)"],
        ]
    )
    pdf.exemplo_box("Exemplo 15: Auditar redes Wi-Fi",
        "Interface: wlan0\n\n"
        "APs encontrados: 8\n\n"
        "  SSID              Canal  Sinal   Criptografia     Risco\n"
        "  RedeCorp           6      -45    WPA2-CCMP        MEDIO\n"
        "  Guest_WiFi         1      -52    ABERTA           CRITICO\n"
        "  VelhoRouter        11     -70    WEP              CRITICO\n"
        "  RedeCasa           6      -62    WPA1-TKIP        ALTO\n"
        "  FREE_WiFi          3      -48    ABERTA           CRITICO\n\n"
        "Possiveis Rogue APs detectados:\n"
        "  'RedeCorp_FREE' - SSID similar a 'RedeCorp'")

    # ---- 16. MODULO 16: VULN ASSESSMENT ----
    pdf.add_page()
    pdf.secao("16", "Modulo 16: Avaliacao de Vulnerabilidades")
    pdf.corpo(
        "Cruza servicos de rede com vulnerabilidades conhecidas (CVEs) "
        "utilizando searchsploit localmente ou API publica Circl.lu."
    )
    pdf.subsecao("Entrada de Dados")
    pdf.corpo(
        "O modulo le um arquivo de texto contendo servicos e versoes "
        "no formato: 'porta protocolo servico versao'. Exemplo:\n"
        "  22 tcp OpenSSH 8.2p1\n"
        "  80 tcp Apache httpd 2.4.41\n"
        "  3306 tcp MySQL 5.7.38"
    )
    pdf.exemplo_box("Exemplo 16: Avaliar vulnerabilidades",
        "Arquivo de servicos: servicos.txt\n\n"
        "Consultando CVEs...\n\n"
        "[CRITICO] OpenSSH 8.2p1 - CVE-2020-15778\n"
        "  Path traversal via scp\n\n"
        "[ALTO] Apache 2.4.41 - CVE-2021-41773\n"
        "  Path traversal no mod_alias\n\n"
        "[MEDIO] MySQL 5.7.38 - CVE-2022-21367\n"
        "  Privilege escalation\n\n"
        "--- Resumo ---\n"
        "CRITICO: 1 | ALTO: 1 | MEDIO: 1 | BAIXO: 2\n"
        "Total: 5 vulnerabilidades encontradas")

    # ---- 17. MODULO 17: IDENTITY AUDIT ----
    pdf.add_page()
    pdf.secao("17", "Modulo 17: Auditoria de Identidade e Politicas")
    pdf.corpo(
        "Valida politicas de acesso e segmentacao de rede, testando "
        "conectividade a servidores de identidade (LDAP, AD, RADIUS) "
        "e verificando segmentacao de VLANs."
    )
    pdf.subsecao("Servicos de Identidade Verificados")
    pdf.tabela(
        ["Servico", "Porta", "Protocolo"],
        [
            ["LDAP", "389", "TCP"],
            ["LDAPS", "636", "TCP"],
            ["Active Directory", "445", "TCP (SMB)"],
            ["RADIUS Auth", "1812", "UDP"],
            ["RADIUS Acct", "1813", "UDP"],
        ]
    )
    pdf.exemplo_box("Exemplo 17: Auditar identidade e VLANs",
        "Alvo: 192.168.1.10\n\n"
        "--- Servidores de Identidade ---\n"
        "  LDAP (389):   ABERTA\n"
        "  LDAPS (636):  ABERTA\n"
        "  AD/SMB (445): ABERTA\n"
        "  RADIUS (1812): FILTRADA\n\n"
        "--- VLANs ---\n"
        "  Comando 'vlan' disponivel\n"
        "  VLANs detectadas na interface eth0.10:\n"
        "    VLAN 10 (Administrativo)\n"
        "    VLAN 20 (Servidores)\n"
        "    VLAN 30 (Usuarios)\n\n"
        "--- Resumo ---\n"
        "Servidores de identidade acessiveis: 3/4\n"
        "Possivel segmentacao: OK")

    # ---- 18. RELATORIO CONSOLIDADO DE TESTES ----
    pdf.add_page()
    pdf.secao("18", "Relatorio Consolidado de Testes")
    pdf.corpo(
        "Os resultados abaixo foram obtidos executando cada modulo contra o "
        "laboratorio virtual (rede 10.99.0.0/24) com 5 containers Docker "
        "simulando servidores reais."
    )
    pdf.subsecao("Sumario dos Resultados")
    pdf.tabela(
        ["Modulo", "Alvo", "Resultado", "Vulnerabilidade"],
        [
            ["01 Host Discovery", "10.99.0.0/24", "6 hosts encontrados", "N/A"],
            ["02 Port Scan", "10.99.0.10", "4 portas abertas (21,22,80,443)", "N/A"],
            ["03 Service Enum", "10.99.0.10", "vsftpd, OpenSSH 8.4, Apache 2.4", "FTP anonimo permitido"],
            ["04 Web Audit", "10.99.0.10", "0 headers de seguranca", "ALTA - sem HSTS/CSP/XFO"],
            ["05 DNS Audit", "10.99.0.13", "10 registros via AXFR", "CRITICA - Zone Transfer liberada"],
            ["06 SMB Audit", "10.99.0.11", "Container SMB instavel", "NAO TESTADO"],
            ["07 SNMP Audit", "10.99.0.14", "community 'public' acessivel", "ALTA - SNMP exposto"],
            ["08 Password Audit", "10.99.0.10", "admin:admin, root:toor", "CRITICA - senhas fracas"],
            ["09 SSL Audit", "10.99.0.10:443", "TLS 1.2/1.3, cert auto-assinado", "MEDIA - sem HSTS"],
            ["10 Vuln Scan", "10.99.0.10", "NSE vuln/safe executados", "Baixo (servicos atualizados)"],
            ["11 Firewall Audit", "10.99.0.10", "Policy ACCEPT, sem regras", "ALTA - sem firewall"],
            ["12 Log Audit", "Container", "dpkg.log, alternativas.log", "Sem auth.log (container)"],
            ["13 Config Audit", "Cisco", "4 falhas encontradas", "ALTA - senhas e SNMP"],
            ["14 Traffic Analysis", "any", "tcpdump capturou ICMP", "N/A"],
            ["15 WiFi Audit", "N/A", "Sem interface wifi", "NAO TESTADO"],
            ["16 Vuln Assessment", "10.99.0.10", "OpenSSH/Apache vs CVEs", "Depende de searchsploit"],
            ["17 Identity Audit", "10.99.0.12", "LDAP bind anonimo, SRV DNS", "MEDIA - bind anonimo"],
        ]
    )

    pdf.subsecao("Vulnerabilidades Criticas Encontradas")
    pdf.corpo(
        "1. Zona DNS exposta via AXFR - todo o mapeamento da rede 10.99.0.x foi obtido\n"
        "2. Credenciais administrativas fracas - SSH admin:admin e root:toor\n"
        "3. SNMP com community 'public' - informacoes do sistema extraidas\n"
        "4. Servidor web sem headers de seguranca - vulneravel a clickjacking/XSS\n"
        "5. Ausencia de firewall - todas as portas acessiveis sem restricao"
    )

    pdf.subsecao("Comandos Utilizados nos Testes")
    pdf.comando(
        "# Host Discovery\n"
        "nmap -sn 10.99.0.0/24\n\n"
        "# Port Scan Completo\n"
        "nmap -p- --open 10.99.0.10\n\n"
        "# Enumeracao de Servicos\n"
        "nmap -sV -p 22,80,443,21,3306 10.99.0.10\n\n"
        "# Auditoria Web\n"
        "curl -s -I http://10.99.0.10/\n"
        "openssl s_client -connect 10.99.0.10:443\n\n"
        "# Transferencia de Zona DNS\n"
        "dig axfr lab.local @10.99.0.13\n\n"
        "# Auditoria SNMP\n"
        "snmpwalk -v2c -c public 10.99.0.14 1.3.6.1.2.1.1.1.0\n\n"
        "# Teste de Senhas\n"
        "sshpass -p 'admin' ssh admin@10.99.0.10\n\n"
        "# Firewall (ACK scan)\n"
        "nmap -sA -p 22,80,443 10.99.0.10\n\n"
        "# Analise de Trafego\n"
        "tcpdump -i any -c 10 icmp\n\n"
        "# Auditoria de Identidade\n"
        "ldapsearch -x -H ldap://10.99.0.12:389 -b '' -s base"
    )

    # ---- 19. BOAS PRATICAS ----
    pdf.add_page()
    pdf.secao("19", "Boas Praticas e Avisos Legais")

    pdf.subsecao("Aviso Legal Importante")
    pdf.set_font("DejaVu", "B", 10)
    pdf.set_text_color(180,0,0)
    pdf.multi_cell(0, 5.5,
        "Esta ferramenta deve ser usada APENAS em:\n"
        "- Sistemas de sua propriedade\n"
        "- Sistemas com autorizacao explicita por escrito\n"
        "- Ambiente de laboratorio (homologacao)\n\n"
        "O uso nao autorizado e ilegal e constitui crime:\n"
        "- Brasil: Art. 154-A do Codigo Penal (Lei Carolina Dieckmann)\n"
        "- EUA: Computer Fraud and Abuse Act (CFAA)\n"
        "- UK: Computer Misuse Act\n\n"
        "O autor nao se responsabiliza por danos causados pelo uso indevido."
    )
    pdf.ln(3)

    pdf.subsecao("Recomendacoes de Uso")
    pdf.corpo(
        "1. Documente a autorizacao por escrito antes de qualquer teste\n"
        "2. Defina o escopo claramente (o que pode e o que nao pode testar)\n"
        "3. Informe as equipes de rede e infraestrutura sobre os testes\n"
        "4. Execute fora do horario comercial em ambientes de producao\n"
        "5. Nao ultrapasse o escopo definido (evite scan aleatorio)\n"
        "6. Mantenha registros detalhados (logs, timestamps, resultados)\n"
        "7. Comunique vulnerabilidades encontradas ao responsavel\n"
        "8. Nao armazene informacoes sensiveis dos clientes\n"
        "9. Mantenha a ferramenta e as listas atualizadas\n"
        "10. Inclua um plano de rollback caso algo de errado"
    )

    pdf.subsecao("Fluxo de Trabalho Recomendado")
    pdf.corpo(
        "1. Executar install.sh para garantir todas as dependencias\n"
        "2. Iniciar com host_discovery para mapear a rede\n"
        "3. port_scan nos hosts encontrados\n"
        "4. service_enum para identificar versoes\n"
        "5. Modulos especificos (web_audit, smb_audit, etc.)\n"
        "6. vulnerability_scan para CVE conhecidos\n"
        "7. firewall_audit para entender a protecao\n"
        "8. log_audit para verificar possiveis violacoes\n"
        "9. Documentar todos os achados em relatorio"
    )

    pdf.subsecao("Dicas de Seguranca para o Auditor")
    pdf.corpo(
        "- Use uma VPN ou maquina dedicada para auditoria\n"
        "- Nao realize testes diretamente da sua maquina de trabalho\n"
        "- Mantenha um registro assinado digitalmente da autorizacao\n"
        "- Prefira tecnicas passivas antes de scans agressivos\n"
        "- Respeite limites de taxa (rate limiting) para nao causar DoS\n"
        "- Em testes web, use proxies como Burp Suite ou ZAP\n"
        "- Documente cada passo: ferramenta, parametro, resultado"
    )

    # Salvar
    out = os.path.join(ROOT, "guia_network_audit_toolkit.pdf")
    pdf.output(out)
    print(f"PDF gerado: {out}")

if __name__ == "__main__":
    gerar()
