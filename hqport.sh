#!/bin/bash
set -euo pipefail

# Назначение: Сменить порт Apache на HQ-SRV с 80 на 8080
# Билет / задание: Задание 8 (часть HQ-SRV)
# ОС: Debian 13
# Основано на: методичка (000-default.conf <VirtualHost *:8080>, ports.conf Listen 8080)

if [ "$EUID" -ne 0 ]; then
  echo "Запусти от root"
  exit 1
fi

PORTS="/etc/apache2/ports.conf"
VHOST="/etc/apache2/sites-available/000-default.conf"

# Listen 80 -> Listen 8080
sed -ri 's/^([[:space:]]*Listen[[:space:]]+)80([[:space:]]*)$/\18080\2/' "$PORTS"
grep -qE '^[[:space:]]*Listen[[:space:]]+8080' "$PORTS" || echo "Listen 8080" >> "$PORTS"

# <VirtualHost *:80> -> <VirtualHost *:8080>
sed -ri 's/(<VirtualHost[[:space:]]+\*:)80(>)/\18080\2/' "$VHOST"

apache2ctl configtest
systemctl restart apache2

echo "OK"

# ==============================
# ПРОВЕРКА РЕЗУЛЬТАТА
# ==============================
# grep -R Listen /etc/apache2/ports.conf
# grep VirtualHost /etc/apache2/sites-available/000-default.conf
# ss -tlnp | grep 8080
# curl -I http://localhost:8080

# ==============================
# РУЧНОЕ ВЫПОЛНЕНИЕ ЗАДАНИЯ
# ==============================
# 1. nano /etc/apache2/sites-available/000-default.conf -> <VirtualHost *:8080>
# 2. nano /etc/apache2/ports.conf -> Listen 8080
# 3. systemctl restart apache2

# ==============================
# ИЗМЕНЁННЫЕ ФАЙЛЫ
# ==============================
# /etc/apache2/ports.conf
# /etc/apache2/sites-available/000-default.conf