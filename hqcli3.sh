#!/bin/bash
set -euo pipefail

# Назначение: Ввод HQ-CLI в домен au-team.irpo, вход только группе hq, sudo для cat/grep/id
# Билет / задание: Задание 1 (часть HQ-CLI)
# ОС: Debian 13
# Основано на: методичка (realm join, sssd, realm permit -g hq, sudoers /etc/sudoers.d/hq-users)
# ВАЖНО: DNS HQ-CLI должен указывать на BR-SRV (192.168.200.2) — после смены DHCP обновить аренду.

if [ "$EUID" -ne 0 ]; then
  echo "Запусти от root"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

DOMAIN="au-team.irpo"
ADMIN="administrator"
ADMIN_PASS="P@ssw0rd"
GROUP="hq"

apt update
apt install -y realmd sssd sssd-tools libnss-sss libpam-sss adcli packagekit

# Ввод в домен (пароль администратора через stdin)
echo "${ADMIN_PASS}" | realm join -U "${ADMIN}" "${DOMAIN}"

# Автосоздание домашних каталогов при первом входе
pam-auth-update --enable mkhomedir

# Разрешаем вход только группе hq
realm deny --all
realm permit -g "${GROUP}@${DOMAIN}"

# sudo только для cat, grep, id
cat > /etc/sudoers.d/hq-users <<EOF
%${GROUP}@${DOMAIN} ALL=(ALL) /usr/bin/cat, /usr/bin/grep, /usr/bin/id
EOF
chmod 440 /etc/sudoers.d/hq-users
visudo -cf /etc/sudoers.d/hq-users

echo "OK"

# ==============================
# ПРОВЕРКА РЕЗУЛЬТАТА
# ==============================
# realm list
# id hquser1@au-team.irpo
# getent passwd hquser1@au-team.irpo
# cat /etc/sudoers.d/hq-users
# su - hquser1@au-team.irpo -c 'sudo -l'
# su - hquser1@au-team.irpo -c 'sudo id'    # должно работать
# su - hquser1@au-team.irpo -c 'sudo ls'    # должно быть запрещено

# ==============================
# РУЧНОЕ ВЫПОЛНЕНИЕ ЗАДАНИЯ
# ==============================
# 1. apt update && apt install -y realmd sssd sssd-tools libnss-sss libpam-sss adcli packagekit
# 2. realm join -U administrator au-team.irpo        (ввести пароль P@ssw0rd)
# 3. pam-auth-update --enable mkhomedir
# 4. realm deny --all
# 5. realm permit -g hq@au-team.irpo
# 6. nano /etc/sudoers.d/hq-users
#    %hq@au-team.irpo ALL=(ALL) /usr/bin/cat, /usr/bin/grep, /usr/bin/id
# 7. chmod 440 /etc/sudoers.d/hq-users
# 8. su - hquser1@au-team.irpo   ->   sudo id

# ==============================
# ИЗМЕНЁННЫЕ ФАЙЛЫ
# ==============================
# /etc/sssd/sssd.conf        (создаётся realm join)
# /etc/krb5.conf             (может обновляться)
# /etc/sudoers.d/hq-users
# /etc/pam.d/* (mkhomedir через pam-auth-update)