#!/bin/bash
set -euo pipefail

# Назначение: В DHCP раздать DNS-сервер 192.168.100.2 (HQ-SRV) на HQ-RTR
# Билет / задание: Задание 7 (часть HQ-RTR)
# ОС: Debian 13
# Основано на: методичка (option domain-name-server 192.168.100.2)

if [ "$EUID" -ne 0 ]; then
  echo "Запусти от root"
  exit 1
fi

DHCPD_CONF="/etc/dhcp/dhcpd.conf"
DNS_IP="192.168.100.2"

[ -f "$DHCPD_CONF" ] || { echo "Нет файла $DHCPD_CONF"; exit 1; }

if grep -qE 'option[[:space:]]+domain-name-servers' "$DHCPD_CONF"; then
  sed -ri "s/(option[[:space:]]+domain-name-servers[[:space:]]+)[^;]+;/\1${DNS_IP};/" "$DHCPD_CONF"
else
  echo "option domain-name-servers ${DNS_IP};" >> "$DHCPD_CONF"
fi

systemctl restart isc-dhcp-server

echo "OK"

# ==============================
# ПРОВЕРКА РЕЗУЛЬТАТА
# ==============================
# grep domain-name-servers /etc/dhcp/dhcpd.conf
# systemctl status isc-dhcp-server --no-pager
# journalctl -u isc-dhcp-server -n 30 --no-pager

# ==============================
# РУЧНОЕ ВЫПОЛНЕНИЕ ЗАДАНИЯ
# ==============================
# 1. nano /etc/dhcp/dhcpd.conf
#    -> option domain-name-servers 192.168.100.2;
# 2. systemctl restart isc-dhcp-server

# ==============================
# ИЗМЕНЁННЫЕ ФАЙЛЫ
# ==============================
# /etc/dhcp/dhcpd.conf