#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# MrEzequielOS - ajustes de desempenho, boot e manutencao.
# Idempotente: roda no build (chroot), no OTA (sistema real) e a mao.
set -u
BASE="$(dirname "$0")"

# Boot direto no MrEzequielOS (sem menu do GRUB).
BOOT=""
for c in "$BASE/mrezequielos-boot.sh" "$BASE/mrezequielos-boot" /usr/local/bin/mrezequielos-boot; do
  if [ -x "$c" ]; then BOOT="$c"; break; fi
done
if [ -n "$BOOT" ]; then
  echo "[tweaks] boot direto no MrEzequielOS..."
  "$BOOT" || echo "[tweaks] AVISO: GRUB nao ajustado"
else
  echo "[tweaks] AVISO: mrezequielos-boot nao encontrado"
fi

echo "[tweaks] boot sem esperar a rede ficar online..."
systemctl disable NetworkManager-wait-online.service 2>/dev/null || true
systemctl mask NetworkManager-wait-online.service 2>/dev/null || true

echo "[tweaks] journald limitado a 200 MB (menos escrita no SSD)..."
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/99-mrezequielos.conf <<'EOF'
[Journal]
SystemMaxUse=200M
SystemMaxFileSize=50M
RuntimeMaxUse=50M
EOF

echo "[tweaks] TRIM semanal no SSD..."
systemctl enable fstrim.timer 2>/dev/null || true

echo "[tweaks] sem motd-news (nada de download no boot)..."
systemctl disable motd-news.timer motd-news.service 2>/dev/null || true
if [ -f /etc/default/motd-news ]; then
  sed -i 's/^ENABLED=.*/ENABLED=0/' /etc/default/motd-news
else
  printf 'ENABLED=0\n' > /etc/default/motd-news
fi

echo "[tweaks] zram (swap comprimido na RAM)..."
systemctl enable zramswap.service 2>/dev/null || true
if [ -f /etc/default/zramswap ]; then
  sed -i 's/^ALGO=.*/ALGO=lz4/' /etc/default/zramswap
  sed -i 's/^PERCENT=.*/PERCENT=50/' /etc/default/zramswap
  sed -i 's/^PRIORITY=.*/PRIORITY=100/' /etc/default/zramswap
  cat > /etc/sysctl.d/99-mrezequielos-zram.conf <<'EOF'
vm.swappiness=100
vm.page-cluster=0
EOF
fi

echo "[tweaks] rede: BBR + fq (se o kernel suportar)..."
if grep -qw bbr /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null || \
   find /lib/modules -name 'tcp_bbr.ko*' -print -quit 2>/dev/null | grep -q .; then
  cat > /etc/sysctl.d/99-mrezequielos-net.conf <<'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
  printf 'tcp_bbr\n' > /etc/modules-load.d/mrezequielos-bbr.conf
fi

echo "[tweaks] atualizacoes de seguranca automaticas..."
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF
# Evita o atualizador falhar se o unattended-upgrades estiver com o lock.
cat > /etc/apt/apt.conf.d/99-mrezequielos-lock <<'EOF'
DPkg::Lock::Timeout "300";
EOF
# Nosso lsb-release diz "MrEzequielOS", entao as origens padrao do
# unattended-upgrades nao casam com os repos da Ubuntu e nada seria
# instalado. Aqui apontamos a seguranca da base certa.
cat > /etc/apt/apt.conf.d/51mrezequielos-auto-upgrades <<'EOF'
Unattended-Upgrade::Origins-Pattern {
    "origin=Ubuntu,codename=${distro_codename}-security";
};
EOF
# No modo live nada de apt automatico enchendo o /cow (RAM). Vale so no
# sistema instalado, onde nao existe boot=casper.
mkdir -p /etc/systemd/system/apt-daily.service.d /etc/systemd/system/apt-daily-upgrade.service.d /etc/systemd/system/unattended-upgrades.service.d
for u in apt-daily apt-daily-upgrade unattended-upgrades; do
  cat > "/etc/systemd/system/$u.service.d/99-mrezequielos-live.conf" <<'EOF'
[Unit]
ConditionKernelCommandLine=!boot=casper
EOF
done
systemctl enable apt-daily.timer apt-daily-upgrade.timer 2>/dev/null || true

# Em chroot nao existe systemd rodando; so aplica em sistema real.
if [ -d /run/systemd/system ]; then
  sysctl --system >/dev/null 2>&1 || true
  systemctl restart systemd-journald 2>/dev/null || true
fi

echo "[tweaks] pronto."
