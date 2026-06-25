#!/bin/bash
set -euo pipefail

# Назначение: Установка SSH-сервера и создание пользователя sshuser на HQ-CLI
# Билет / задание: Сконфигурируйте ansible на BR-SRV (часть HQ-CLI)
# ОС: Debian 13
# Основано на: методичка (useradd sshuser -U, usermod -aG sudo, пароль P@ssw0rd)

if [ "$EUID" -ne 0 ]; then
  echo "Запусти от root"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt install -y openssh-server

id sshuser &>/dev/null || useradd -m -s /bin/bash sshuser -U
usermod -aG sudo sshuser
echo 'sshuser:P@ssw0rd' | chpasswd

systemctl enable --now ssh

echo "OK"

# ==============================
# ПРОВЕРКА РЕЗУЛЬТАТА
# ==============================
# id sshuser
# groups sshuser
# getent passwd sshuser
# systemctl status ssh --no-pager

# ==============================
# РУЧНОЕ ВЫПОЛНЕНИЕ ЗАДАНИЯ
# ==============================
# 1. apt install openssh-server
# 2. useradd -m -s /bin/bash sshuser -U
# 3. usermod -aG sudo sshuser
# 4. passwd sshuser
#    P@ssw0rd

# ==============================
# ИЗМЕНЁННЫЕ ФАЙЛЫ
# ==============================
# /etc/passwd
# /etc/shadow
# /etc/group