#!/bin/bash
set -euo pipefail

# Назначение: Ansible-контроллер на BR-SRV (чистая переустановка inventory + cfg)
# Билет / задание: Сконфигурируйте ansible на BR-SRV
# ОС: Debian 13
# Основано на: методичка + скрин /etc/ansible/hosts

if [ "$EUID" -ne 0 ]; then
  echo "Запусти от root"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

# --- ОЧИСТКА ПРОШЛЫХ ПРАВОК ЭТОГО ЗАДАНИЯ ---
rm -f /etc/ansible/ansible.cfg /etc/ansible/hosts
# чистим устаревшие host-ключи (HQ-SRV менял порт 22 -> 2026)
for h in 192.168.100.1 192.168.100.2 192.168.100.35 192.168.200.1; do
  ssh-keygen -R "$h" 2>/dev/null || true
done
ssh-keygen -R '[192.168.100.2]:2026' 2>/dev/null || true

# --- ПРИМЕНЕНИЕ ---
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
# ПОШАГОВАЯ ИНСТРУКЦИЯ / РУЧНОЕ ВМЕШАТЕЛЬСТВО
# ==============================
# Порядок: сначала целевые машины, потом этот скрипт.
# 1. HQ-SRV  (192.168.100.2):  запустить hq-srv_ssh.sh   -> sshuser, порт 2026, парольный вход
# 2. HQ-CLI  (192.168.100.35): запустить hq-cli_ssh.sh   -> sshuser, порт 22,  парольный вход
# 3. HQ-RTR  (192.168.100.1):  запустить hq-rtr_ssh.sh   -> net_admin, openssh, парольный вход
# 4. BR-RTR  (192.168.200.1):  запустить br-rtr_ssh.sh   -> net_admin, openssh, парольный вход
# 5. BR-SRV: запустить этот скрипт, затем:  cd /etc/ansible && ansible all -m ping
#
# Если какой-то узел всё ещё UNREACHABLE / Permission denied — проверить вручную НА УЗЛЕ:
#   а) grep -RiE '^\s*PasswordAuthentication' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/
#      -> если где-то 'no' и файл сортируется РАНЬШЕ 00-exam-ssh.conf, удалить/исправить ту строку:
#         nano /etc/ssh/sshd_config.d/<файл>.conf   (PasswordAuthentication yes)
#   б) пароль пользователя:  echo 'ПОЛЬЗОВАТЕЛЬ:P@ssw0rd' | chpasswd
#   в) порт слушается:        ss -tlnp | grep ssh
#   г) синтаксис:             sshd -t   (должен молчать)
#   д) перезапуск:            systemctl restart ssh

# ==============================
# ПРОВЕРКА РЕЗУЛЬТАТА
# ==============================
# cd /etc/ansible && ansible all -m ping
# cat /etc/ansible/ansible.cfg
# cat /etc/ansible/hosts

# ==============================
# РУЧНОЕ ВЫПОЛНЕНИЕ ЗАДАНИЯ
# ==============================
# 1. apt install ansible sshpass -y
# 2. mkdir -p /etc/ansible
# 3. nano /etc/ansible/ansible.cfg  ([defaults] / host_key_checking=False)
# 4. nano /etc/ansible/hosts        (по скрину)
# 5. cd /etc/ansible && ansible all -m ping

# ==============================
# ИЗМЕНЁННЫЕ ФАЙЛЫ
# ==============================
# /etc/ansible/ansible.cfg
# /etc/ansible/hosts
# /root/.ssh/known_hosts (очистка устаревших ключей)