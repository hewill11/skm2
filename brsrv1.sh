#!/bin/bash
set -euo pipefail

# Назначение: Развёртывание контроллера домена Samba AD DC (au-team.irpo) на BR-SRV
# Билет / задание: Задание 1 — Настройте контроллер домена Samba DC на сервере BR-SRV
# ОС: Debian 13
# Основано на: методичка (samba-tool domain provision --use-rfc2307, группа hq, hquser1..5)

if [ "$EUID" -ne 0 ]; then
  echo "Запусти от root"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive

REALM="AU-TEAM.IRPO"
DOMAIN="AU-TEAM"
HOST_FQDN="br-srv.au-team.irpo"
HOST_SHORT="br-srv"
SRV_IP="192.168.200.2"
ADMIN_PASS="P@ssw0rd"
USER_PASS="P@ssw0rd"

# Предзаполнение "синего окна" krb5-user
echo "krb5-config krb5-config/default_realm string ${REALM}" | debconf-set-selections
echo "krb5-config krb5-config/kerberos_servers string ${HOST_FQDN}" | debconf-set-selections
echo "krb5-config krb5-config/admin_server string ${HOST_FQDN}" | debconf-set-selections

apt update
apt install -y samba smbclient winbind libnss-winbind krb5-user net-tools

# Гарантируем разрешение FQDN контроллера
grep -q "${HOST_FQDN}" /etc/hosts || echo "${SRV_IP} ${HOST_FQDN} ${HOST_SHORT}" >> /etc/hosts

# Убираем дефолтный smb.conf (иначе provision не пройдёт)
[ -f /etc/samba/smb.conf ] && mv /etc/samba/smb.conf /etc/samba/smb.conf.bak

# Останавливаем классические службы перед провижном
systemctl stop smbd nmbd winbind 2>/dev/null || true
systemctl stop samba-ad-dc 2>/dev/null || true

# Развёртывание домена (неинтерактивный эквивалент --interactive: ENTER + пароль P@ssw0rd)
samba-tool domain provision \
  --use-rfc2307 \
  --realm="${REALM}" \
  --domain="${DOMAIN}" \
  --server-role=dc \
  --dns-backend=SAMBA_INTERNAL \
  --adminpass="${ADMIN_PASS}"

# Подключаем сгенерированный krb5.conf
cp -f /var/lib/samba/private/krb5.conf /etc/krb5.conf

# AD DC = единый демон samba-ad-dc; standalone-службы отключаем, samba-ad-dc размаскируем
systemctl disable --now smbd nmbd winbind 2>/dev/null || true
systemctl unmask samba-ad-dc
systemctl enable --now samba-ad-dc

# Группа hq, пользователи hquser1..5 и их членство в группе
samba-tool group add hq
for i in 1 2 3 4 5; do
  samba-tool user create "hquser${i}" "${USER_PASS}"
  samba-tool group addmembers hq "hquser${i}"
done

echo "OK"

# ==============================
# ПРОВЕРКА РЕЗУЛЬТАТА
# ==============================
# systemctl status samba-ad-dc --no-pager
# samba-tool domain level show
# samba-tool user list
# samba-tool group listmembers hq
# host -t SRV _ldap._tcp.au-team.irpo
# smbclient -L localhost -U administrator

# ==============================
# РУЧНОЕ ВЫПОЛНЕНИЕ ЗАДАНИЯ
# ==============================
# 1. apt update
# 2. apt install -y samba smbclient winbind libnss-winbind krb5-user net-tools
#    (синее окно: AU-TEAM.IRPO / br-srv.au-team.irpo / br-srv.au-team.irpo)
# 3. mv /etc/samba/smb.conf /etc/samba/smb.conf.bak
# 4. systemctl stop smbd nmbd winbind
# 5. systemctl stop samba-ad-dc
# 6. samba-tool domain provision --use-rfc2307 --interactive
#    (ENTER до Administrator, пароль P@ssw0rd дважды)
# 7. cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
# 8. systemctl unmask samba-ad-dc
# 9. systemctl disable --now smbd nmbd winbind
# 10. systemctl enable --now samba-ad-dc
# 11. samba-tool group add hq
# 12. samba-tool user create hquser1 P@ssw0rd   (и так до hquser5)
# 13. samba-tool group addmembers hq hquser1     (и так до hquser5)

# ==============================
# ИЗМЕНЁННЫЕ ФАЙЛЫ
# ==============================
# /etc/hosts
# /etc/samba/smb.conf -> /etc/samba/smb.conf.bak (переименован)
# /etc/samba/smb.conf  (создан заново provision'ом)
# /etc/krb5.conf
# /var/lib/samba/* (база каталога AD)