# Используем Ubuntu 22.04
FROM ubuntu:22.04

# Обновление и установка WireGuard и утилит
RUN apt-get update && apt-get install -y wireguard iproute2 qrencode curl ufw && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Копируем скрипт настройки VPN внутрь контейнера
COPY setup_vpn.sh /setup_vpn.sh
RUN chmod +x /setup_vpn.sh

# Проброс порта WireGuard
EXPOSE 51820/udp

# Запуск скрипта при старте контейнера
ENTRYPOINT ["/setup_vpn.sh"]