#!/bin/bash
set -euo pipefail

# Назначение: Веб-приложение на HQ-SRV (Apache + MariaDB + PHP), БД webdb, импорт dump.sql
# Билет / задание: Задание 7 — разверните веб-приложение на HQ-SRV
# ОС: Debian 13
# Основано на: методичка + скрин index.php

if [ "$EUID" -ne 0 ]; then
  echo "Запусти от root"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

WEB_SRC="/root/Additional/web"
DB_NAME="webdb"
DB_USER="web"
DB_PASS="P@ssw0rd"
WEBROOT="/var/www/html"

apt update
apt install -y apache2 mariadb-server mariadb-client php8.4 php8.4-mysqli

# Проверка наличия файлов веб-приложения (папка Additional должна быть в /root)
[ -f "${WEB_SRC}/dump.sql" ]  || { echo "Нет ${WEB_SRC}/dump.sql"; exit 1; }
[ -f "${WEB_SRC}/index.php" ] || { echo "Нет ${WEB_SRC}/index.php"; exit 1; }

# Копируем дамп
cp "${WEB_SRC}/dump.sql" /tmp/dump.sql

# Создаём БД и пользователя (идемпотентно)
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

# Импорт дампа
mysql -u root "${DB_NAME}" < /tmp/dump.sql

# Каталог веб-сервера и файлы сайта
mkdir -p "${WEBROOT}"
cp "${WEB_SRC}/index.php" "${WEBROOT}/"
[ -d "${WEB_SRC}/images" ] && cp -r "${WEB_SRC}/images" "${WEBROOT}/"

# Учётные данные подключения в index.php (по скрину)
sed -ri 's/(\$servername[[:space:]]*=[[:space:]]*).*/\1"localhost";/' "${WEBROOT}/index.php"
sed -ri "s/(\\\$username[[:space:]]*=[[:space:]]*).*/\\1\"${DB_USER}\";/"   "${WEBROOT}/index.php"
sed -ri "s/(\\\$password[[:space:]]*=[[:space:]]*).*/\\1\"${DB_PASS}\";/"   "${WEBROOT}/index.php"
sed -ri "s/(\\\$dbname[[:space:]]*=[[:space:]]*).*/\\1\"${DB_NAME}\";/"     "${WEBROOT}/index.php"

# Права
chown -R www-data:www-data "${WEBROOT}"
chmod -R 755 "${WEBROOT}"

# Убираем дефолтную страницу, чтобы открывался index.php
rm -f "${WEBROOT}/index.html"

systemctl enable --now apache2 mariadb
systemctl restart apache2

echo "OK"

# ==============================
# РУЧНОЙ ШАГ (НЕ СКРИПТУЕТСЯ — ГРАФИЧЕСКИЙ ПРОВОДНИК)
# ==============================
# 1. Скачать Additional.iso, извлечь через Xarchiver.
# 2. Папку Additional перетащить в /root. Должны существовать:
#      /root/Additional/web/dump.sql
#      /root/Additional/web/index.php
#      /root/Additional/web/images/   (если есть)
# Только потом запускать скрипт.

# ==============================
# ПРОВЕРКА РЕЗУЛЬТАТА
# ==============================
# systemctl status apache2 --no-pager
# systemctl status mariadb --no-pager
# mysql -u root -e "SHOW DATABASES;"
# mysql -u root -e "SHOW TABLES IN webdb;"
# mysql -u web -p'P@ssw0rd' webdb -e "SHOW TABLES;"
# cat /var/www/html/index.php
# curl http://localhost
# с HQ-CLI в браузере: http://192.168.100.2/

# ==============================
# РУЧНОЕ ВЫПОЛНЕНИЕ ЗАДАНИЯ
# ==============================
# 1. apt install apache2 mariadb-server mariadb-client php8.4 php8.4-mysqli -y
# 2. (Xarchiver) извлечь Additional.iso, папку Additional перетащить в /root
# 3. cp /root/Additional/web/dump.sql /tmp
# 4. mysql -u root
#    CREATE DATABASE webdb;
#    CREATE USER 'web'@'localhost' IDENTIFIED BY 'P@ssw0rd';
#    GRANT ALL PRIVILEGES ON webdb.* TO 'web'@'localhost';
#    FLUSH PRIVILEGES;
#    EXIT;
# 5. mysql -u root webdb < /tmp/dump.sql
# 6. mkdir -p /var/www/html
# 7. cp /root/Additional/web/index.php /var/www/html
#    (и cp -r /root/Additional/web/images /var/www/html при наличии)
# 8. chown -R www-data:www-data /var/www/html ; chmod -R 755 /var/www/html
# 9. nano /var/www/html/index.php
#    $servername="localhost"; $username="web"; $password="P@ssw0rd"; $dbname="webdb";
# 10. rm -f /var/www/html/index.html
# 11. systemctl restart apache2

# ==============================
# ИЗМЕНЁННЫЕ ФАЙЛЫ
# ==============================
# /var/www/html/index.php
# /var/www/html/images/ (если есть)
# /tmp/dump.sql
# база данных webdb (создана + импортирована)
# пользователь MariaDB web@localhost