#!/bin/bash
set -euo pipefail

# Назначение: SSH на HQ-CLI для Ansible — порт 22 (откат с 2026), sshuser, парольный вход
# Билет / задание: Сконфигурируйте ansible на BR-SRV (часть HQ-CLI)
# ОС: Debian 13
# Основано на: инвентарь (ansible_user=sshuser, без ansible_port -> 22, P@ssw0rd)

if [ "$EUID" -ne 0 ]; then
  echo "Запусти от root"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt install -y openssh-server

# --- ОЧИСТКА ПРОШЛЫХ ПРАВОК (в т.ч. ошибочный Port 2026) ---
rm -f /etc/ssh/sshd_config.d/99-pwauth.conf /etc/ssh/sshd_config.d/00-exam-ssh.conf
sed -ri 's/^([[:space:]]*Port[[:space:]].*)$/#\1/' /etc/ssh/sshd_config

# --- ПОЛЬЗОВАТЕЛЬ ---
id sshuser &>/dev/null || useradd -m -s /bin/bash sshuser -U
echo 'sshuser:P@ssw0rd' | chpasswd

# --- SSH (порт 22, парольный вход) ---
cat > /etc/ssh/sshd_config.d/00-exam-ssh.conf <<'EOF'
Port 22
PasswordAuthentication yes
KbdInteractiveAuthentication yes
EOF

systemctl disable --now ssh.socket 2>/dev/null || true
sshd -t
systemctl enable --now ssh
systemctl restart ssh

echo "OK"

# ==============================
# ПРОВЕРКА РЕЗУЛЬТАТА
# ==============================
# ss -tlnp | grep ':22'
# id sshuser
# с BR-SRV: sshpass -p 'P@ssw0rd' ssh sshuser@192.168.100.35 'echo ok'

# ==============================
# РУЧНОЕ ВЫПОЛНЕНИЕ ЗАДАНИЯ
# ==============================
# 1. apt install -y openssh-server
# 2. useradd -m -s /bin/bash sshuser -U ; echo 'sshuser:P@ssw0rd' | chpasswd
# 3. nano /etc/ssh/sshd_config  -> Port 22 ; PasswordAuthentication yes
# 4. sshd -t ; systemctl restart ssh

# ==============================
# ИЗМЕНЁННЫЕ ФАЙЛЫ
# ==============================
# /etc/ssh/sshd_config
# /etc/ssh/sshd_config.d/00-exam-ssh.conf
# /etc/passwd /etc/shadow /etc/group