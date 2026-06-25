#!/bin/bash
set -euo pipefail

# Назначение: Развёртывание стека testapp + db (MariaDB) в Docker на BR-SRV
# Билет / задание: Задание 6 — веб-приложение в docker на BR-SRV
# ОС: Debian 13
# Основано на: методичка + скрин docker-compose.yaml

if [ "$EUID" -ne 0 ]; then
  echo "Запусти от root"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# Единый пароль БД (как на скрине — Passw0rd; для P@ssw0rd поменять только здесь)
DB_PASS="Passw0rd"

IMG_DIR="/root/Additional/docker"
APP_DIR="/root/testapp"

apt install -y docker.io docker-compose

# Загрузка образов из tar (папка Additional уже должна быть в /root)
[ -f "${IMG_DIR}/site_latest.tar" ]    || { echo "Нет ${IMG_DIR}/site_latest.tar"; exit 1; }
[ -f "${IMG_DIR}/mariadb_latest.tar" ] || { echo "Нет ${IMG_DIR}/mariadb_latest.tar"; exit 1; }
docker image load -i "${IMG_DIR}/site_latest.tar"
docker image load -i "${IMG_DIR}/mariadb_latest.tar"

mkdir -p "${APP_DIR}"

cat > "${APP_DIR}/docker-compose.yaml" <<EOF
version: '3.8'

services:
  testapp:
    image: site:latest
    container_name: testapp
    restart: always
    depends_on:
      - db
    ports:
      - "8080:8000"
    environment:
      DB_TYPE: maria
      DB_HOST: db
      DB_NAME: testdb
      DB_PORT: "3306"
      DB_USER: test
      DB_PASS: ${DB_PASS}

  db:
    image: mariadb:10.11
    container_name: db
    restart: always
    environment:
      MARIADB_DATABASE: testdb
      MARIADB_USER: test
      MARIADB_PASSWORD: ${DB_PASS}
      MARIADB_ROOT_PASSWORD: ${DB_PASS}
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
EOF

cd "${APP_DIR}"
docker-compose -f docker-compose.yaml up -d

echo "OK"

# ==============================
# РУЧНОЙ ШАГ (НЕ СКРИПТУЕТСЯ — ГРАФИЧЕСКИЙ ПРОВОДНИК)
# ==============================
# 1. Скачать Additional.iso, извлечь через Xarchiver.
# 2. В проводнике перетащить папку Additional в /root.
#    После этого должны существовать:
#      /root/Additional/docker/site_latest.tar
#      /root/Additional/docker/mariadb_latest.tar
# Только потом запускать этот скрипт.

# ==============================
# ПРОВЕРКА РЕЗУЛЬТАТА
# ==============================
# docker images
# docker ps
# docker-compose -f /root/testapp/docker-compose.yaml ps
# curl http://localhost:8080
# с HQ-CLI в браузере: http://192.168.200.2:8080
# docker logs testapp --tail 30
# docker logs db --tail 30

# ==============================
# РУЧНОЕ ВЫПОЛНЕНИЕ ЗАДАНИЯ
# ==============================
# 1. apt install docker.io docker-compose -y
# 2. (Xarchiver) извлечь Additional.iso, папку Additional перетащить в /root
# 3. docker image load -i /root/Additional/docker/site_latest.tar
# 4. docker image load -i /root/Additional/docker/mariadb_latest.tar
# 5. docker images
# 6. mkdir testapp && cd testapp/
# 7. nano docker-compose.yaml   (содержимое по скрину)
# 8. docker-compose -f docker-compose.yaml up -d
# 9. docker ps
# 10. HQ-CLI -> http://192.168.200.2:8080

# ==============================
# ИЗМЕНЁННЫЕ ФАЙЛЫ
# ==============================
# /root/testapp/docker-compose.yaml
# (загружены docker-образы: site:latest, mariadb:10.11; создан volume db_data)