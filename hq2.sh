#!/bin/bash
set -euo pipefail

# Назначение: SSH на HQ-SRV для Ansible — порт 2026, sshuser, парольный вход
# Билет / задание: Сконфигурируйте ansible на BR-SRV (часть HQ-SRV)
# ОС: Debian 13
# Основано на: инвентарь (ansible_user=sshuser, ansible_port=2026, P@ssw0rd)

if [ "$EUID" -ne 0 ]; then
  echo "Запусти от root"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt install -y openssh-server

# --- ОЧИСТКА ПРОШЛЫХ ПРАВОК ---
rm -f /etc/ssh/sshd_config.d/99-pwauth.conf /etc/ssh/sshd_config.d/00-exam-ssh.conf
# снимаем ручной Port из основного конфига, чтобы им управлял drop-in
sed -ri 's/^([[:space:]]*Port[[:space:]].*)$/#\1/' /etc/ssh/sshd_config

# --- ПОЛЬЗОВАТЕЛЬ ---
id sshuser &>/dev/null || useradd -m -s /bin/bash sshuser -U
echo 'sshuser:P@ssw0rd' | chpasswd

# --- SSH (порт 2026, парольный вход; имя 00- читается раньше cloud-init) ---
cat > /etc/ssh/sshd_config.d/00-exam-ssh.conf <<'EOF'
Port 2026
PasswordAuthentication yes
KbdInteractiveAuthentication yes
EOF

# чтобы Port применился — sshd как служба, без socket-активации
systemctl disable --now ssh.socket 2>/dev/null || true
sshd -t
systemctl enable --now ssh
systemctl restart ssh

echo "OK"

# ==============================
# ПРОВЕРКА РЕЗУЛЬТАТА
# ==============================
# ss -tlnp | grep 2026
# id sshuser
# grep -RiE 'Port|PasswordAuthentication' /etc/ssh/sshd_config.d/00-exam-ssh.conf
# с BR-SRV: sshpass -p 'P@ssw0rd' ssh -p 2026 sshuser@192.168.100.2 'echo ok'

# ==============================
# РУЧНОЕ ВЫПОЛНЕНИЕ ЗАДАНИЯ
# ==============================
# 1. apt install -y openssh-server
# 2. useradd -m -s /bin/bash sshuser -U ; echo 'sshuser:P@ssw0rd' | chpasswd
# 3. nano /etc/ssh/sshd_config  -> Port 2026 ; PasswordAuthentication yes
# 4. systemctl disable --now ssh.socket
# 5. sshd -t ; systemctl restart ssh
# 6. ss -tlnp | grep 2026

# ==============================
# ИЗМЕНЁННЫЕ ФАЙЛЫ
# ==============================
# /etc/ssh/sshd_config            (закомментирован Port)
# /etc/ssh/sshd_config.d/00-exam-ssh.conf
# /etc/passwd /etc/shadow /etc/group