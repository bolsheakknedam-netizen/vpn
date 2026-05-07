#!/bin/bash

# IP вашего VPS
SERVER_IP="176.12.75.12"
VPN_NETWORK="10.66.66.0/24"
VPN_PORT="51820"
CLIENT_NAME="client1"

# Установка необходимых пакетов
apt-get update && apt-get install -y wireguard iproute2 qrencode curl ufw

# Генерация ключей
SERVER_PRIV_KEY=$(wg genkey)
SERVER_PUB_KEY=$(echo $SERVER_PRIV_KEY | wg pubkey)
CLIENT_PRIV_KEY=$(wg genkey)
CLIENT_PUB_KEY=$(echo $CLIENT_PRIV_KEY | wg pubkey)

# Конфигурация сервера WireGuard
cat > /etc/wireguard/wg0.conf <<EOL
[Interface]
PrivateKey = $SERVER_PRIV_KEY
Address = 10.66.66.1/24
ListenPort = $VPN_PORT
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = $CLIENT_PUB_KEY
AllowedIPs = 10.66.66.2/32
EOL

# Конфигурация клиента
cat > /etc/wireguard/${CLIENT_NAME}.conf <<EOL
[Interface]
PrivateKey = $CLIENT_PRIV_KEY
Address = 10.66.66.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUB_KEY
Endpoint = $SERVER_IP:$VPN_PORT
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOL

# QR-код для подключения клиента
qrencode -t ansiutf8 -l L < /etc/wireguard/${CLIENT_NAME}.conf

# Запуск WireGuard и автозапуск
wg-quick up wg0
systemctl enable wg-quick@wg0

echo "VPN настроен. Конфиг клиента /etc/wireguard/${CLIENT_NAME}.conf"