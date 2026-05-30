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
