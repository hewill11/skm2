#!/bin/bash
set -euo pipefail

# Назначение: Конфигурация Ansible на BR-SRV (inventory + ansible.cfg, рабочий каталог /etc/ansible)
# Билет / задание: Сконфигурируйте ansible на сервере BR-SRV
# ОС: Debian 13
# Основано на: методичка + скрин /etc/ansible/hosts

if [ "$EUID" -ne 0 ]; then
  echo "Запусти от root"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

apt install -y ansible sshpass

mkdir -p /etc/ansible

cat > /etc/ansible/ansible.cfg <<'EOF'
[defaults]
host_key_checking=False
EOF

cat > /etc/ansible/hosts <<'EOF'
[hq]
192.168.100.1	ansible_user=net_admin	ansible_password=P@ssw0rd
192.168.100.2	ansible_user=sshuser	ansible_password=P@ssw0rd	ansible_port=2026
192.168.100.35	ansible_user=sshuser	ansible_password=P@ssw0rd

[br]
192.168.200.1	ansible_user=net_admin	ansible_password=P@ssw0rd

[all:vars]
ansible_python_interpreter=/usr/bin/python3.13
EOF

echo "OK"

# ==============================
# ПРЕДУСЛОВИЯ НА ДРУГИХ МАШИНАХ (НЕ СКРИПТУЕТСЯ ЗДЕСЬ)
# ==============================
# HQ-RTR: apt install openssh-server -y
# BR-RTR: apt install openssh-server -y
# HQ-CLI: см. отдельный скрипт hq-cli_sshuser.sh (openssh-server + пользователь sshuser)
# HQ-SRV: ssh должен слушать порт 2026 (ansible_port=2026 из инвентаря)

# ==============================
# ПРОВЕРКА РЕЗУЛЬТАТА
# ==============================
# cd /etc/ansible && ansible all -m ping
# cat /etc/ansible/ansible.cfg
# cat /etc/ansible/hosts
# ansible --version

# ==============================
# РУЧНОЕ ВЫПОЛНЕНИЕ ЗАДАНИЯ
# ==============================
# 1. apt install ansible sshpass -y
# 2. mkdir -p /etc/ansible
# 3. nano /etc/ansible/ansible.cfg
#    [defaults]
#    host_key_checking=False
# 4. nano /etc/ansible/hosts   (содержимое по скрину)
# 5. cd /etc/ansible
# 6. ansible all -m ping

# ==============================
# ИЗМЕНЁННЫЕ ФАЙЛЫ
# ==============================
# /etc/ansible/ansible.cfg
# /etc/ansible/hosts