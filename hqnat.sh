#!/bin/bash
set -euo pipefail

# Назначение: Статическая трансляция портов (DNAT) на HQ-RTR -> HQ-SRV (8080, 2026) + masquerade
# Билет / задание: Задание 8 (часть HQ-RTR)
# ОС: Debian 13
# Основано на: методичка (скрин /etc/nftables.conf, iifname ens3, dnat to 192.168.100.2)

if [ "$EUID" -ne 0 ]; then
  echo "Запусти от root"
  exit 1
fi

CONF="/etc/nftables.conf"
WAN_IF="ens3"          # e0 = внешний интерфейс роутера
DST="192.168.100.2"    # HQ-SRV

# Бэкап текущего конфига
cp -f "$CONF" "${CONF}.bak.$(date +%s)" 2>/dev/null || true

# Сохраняем существующий filter-блок (если есть), чтобы не потерять firewall.
# Берём всё, начиная со строки 'table inet filter' до конца файла.
FILTER_PART=""
if grep -qE '^[[:space:]]*table[[:space:]]+inet[[:space:]]+filter' "$CONF" 2>/dev/null; then
  FILTER_PART="$(sed -n '/^[[:space:]]*table[[:space:]]\+inet[[:space:]]\+filter/,$p' "$CONF")"
fi

# Записываем nat-таблицу (как на скрине)
cat > "$CONF" <<EOF
#!/usr/sbin/nft -f

flush ruleset

table ip nat {
	chain prerouting {
		type nat hook prerouting priority 0;
		iifname "${WAN_IF}" tcp dport 8080 dnat to ${DST}:8080
		iifname "${WAN_IF}" tcp dport 2026 dnat to ${DST}:2026
	}

	chain postrouting {
		type nat hook postrouting priority 100; policy accept;
		meta l4proto { gre, ipip, ospf } counter return
		masquerade
	}
}
EOF

# Возвращаем сохранённый filter-блок (если был)
if [ -n "$FILTER_PART" ]; then
  printf '\n%s\n' "$FILTER_PART" >> "$CONF"
fi

nft -f "$CONF"
systemctl enable nftables
systemctl restart networking

echo "OK"

# ==============================
# ВАРИАНТ "ТОЛЬКО NAT" (как на скрине, без сохранения filter)
# ==============================
# Если нужно ровно содержимое скрина без своего firewall — заменить логику выше
# простой записью файла без блока FILTER_PART (table inet filter с экрана обрезан).

# ==============================
# ПРОВЕРКА РЕЗУЛЬТАТА
# ==============================
# nft list ruleset
# nft list table ip nat
# с ISP: ssh sshuser@172.16.1.2 -p 2026
# с ISP: curl -I http://172.16.1.2:8080
# cat /etc/nftables.conf

# ==============================
# РУЧНОЕ ВЫПОЛНЕНИЕ ЗАДАНИЯ
# ==============================
# 1. nano /etc/nftables.conf   (содержимое по скрину: table ip nat, prerouting/postrouting)
# 2. nft -f /etc/nftables.conf
# 3. systemctl enable nftables
# 4. systemctl restart networking

# ==============================
# ИЗМЕНЁННЫЕ ФАЙЛЫ
# ==============================
# /etc/nftables.conf
# /etc/nftables.conf.bak.* (бэкап)