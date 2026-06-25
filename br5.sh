#!/bin/bash
set -euo pipefail

# Назначение: SSH на BR-RTR для Ansible — net_admin, парольный вход, порт 22
# Билет / задание: Сконфигурируйте ansible на BR-SRV (часть BR-RTR)
# ОС: Debian 13
# Основано на: инвентарь (ansible_user=net_admin, P@ssw0rd)

if [ "$EUID" -ne 0 ]; then
  echo "Запусти от root"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt install -y openssh-server

# --- ОЧИСТКА ПРОШЛЫХ ПРАВОК ---
rm -f /etc/ssh/sshd_config.d/99-pwauth.conf /etc/ssh/sshd_config.d/00-exam-ssh.conf
sed -ri 's/^([[:space:]]*Port[[:space:]].*)$/#\1/' /etc/ssh/sshd_config

# --- ПОЛЬЗОВАТЕЛЬ ---
id net_admin &>/dev/null || { useradd -m -s /bin/bash net_admin -U; usermod -aG sudo net_admin; }
echo 'net_admin:P@ssw0rd' | chpasswd

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
# id net_admin
# с BR-SRV: sshpass -p 'P@ssw0rd' ssh net_admin@192.168.200.1 'echo ok'

# ==============================
# РУЧНОЕ ВЫПОЛНЕНИЕ ЗАДАНИЯ
# ==============================
# 1. apt install -y openssh-server
# 2. echo 'net_admin:P@ssw0rd' | chpasswd
# 3. nano /etc/ssh/sshd_config  -> PasswordAuthentication yes
# 4. sshd -t ; systemctl restart ssh

# ==============================
# ИЗМЕНЁННЫЕ ФАЙЛЫ
# ==============================
# /etc/ssh/sshd_config
# /etc/ssh/sshd_config.d/00-exam-ssh.conf
# /etc/shadow (пароль net_admin)