#!/bin/bash
# Aplica visual + ferramentas MrEzequielOS estilo Zorin no chroot / sistema instalado
set -e
BASE="$(dirname "$0")"
echo "[visual] Temas..."
apt update
apt install -y yaru-theme-gtk yaru-theme-icon yaru-theme-gnome-shell papirus-icon-theme gnome-tweaks gnome-shell-extension-manager zenity dconf-editor fonts-inter 2>/dev/null || true
apt install -y gnome-shell-extension-gsconnect gnome-shell-extension-user-theme 2>/dev/null || true

echo "[visual] Firefox deb real (via Mozilla Team PPA, sem snap)..."
( add-apt-repository -y ppa:mozillateam/ppa 2>/dev/null || true
  cat > /etc/apt/preferences.d/mozilla-firefox <<'EOF'
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
EOF
  apt update || true
  apt install -y firefox 2>/dev/null || true
  apt install -y firefox-locale-pt 2>/dev/null || true ) || echo "AVISO Firefox PPA falhou, usando Epiphany"

echo "[visual] Wallpaper + logo..."
mkdir -p /usr/share/backgrounds /usr/share/pixmaps /usr/local/bin /usr/share/applications
cp "$BASE/branding/wallpaper.svg" /usr/share/backgrounds/mrezequielos-wallpaper.svg 2>/dev/null || true
cp "$BASE/branding/logo.svg" /usr/share/pixmaps/mrezequielos-logo.svg 2>/dev/null || true
cp "$BASE/branding/logo.svg" /usr/share/pixmaps/mrezequielos.svg 2>/dev/null || true

echo "[visual] Extensões estilo Zorin..."
chmod +x "$BASE/gnome/install-extensions.sh" "$BASE/gnome/mrezequielos-appearance" 2>/dev/null || true
"$BASE/gnome/install-extensions.sh" || echo "AVISO extensões falharam, seguindo"

echo "[visual] Padrões do desktop (layout Windows travado)..."
mkdir -p /etc/dconf/db/gdm.d
cp "$BASE/gnome/95-mrezequielos" /etc/dconf/db/gdm.d/95-mrezequielos
dconf update || true

echo "[visual] Plymouth sem logo Ubuntu (spinner neutro)..."
plymouth-set-default-theme -R spinner 2>/dev/null || echo "AVISO plymouth falhou"

echo "[visual] Ferramentas MrEzequielOS (atualizador + segurança)..."
chmod +x "$BASE/tools/"* 2>/dev/null || true
cp "$BASE/tools/mrezequielos-update" /usr/local/bin/mrezequielos-update
cp "$BASE/tools/mrezequielos-security" /usr/local/bin/mrezequielos-security
cp "$BASE/tools/mrezequielos-dev" /usr/local/bin/mrezequielos-dev
chmod +x /usr/local/bin/mrezequielos-update /usr/local/bin/mrezequielos-security /usr/local/bin/mrezequielos-dev
cp "$BASE/tools/mrezequielos-update.desktop" /usr/share/applications/ 2>/dev/null || true
cp "$BASE/tools/mrezequielos-security.desktop" /usr/share/applications/ 2>/dev/null || true
cp "$BASE/tools/mrezequielos-dev.desktop" /usr/share/applications/ 2>/dev/null || true
cp "$BASE/tools/mrezequielos-appearance.desktop" /usr/share/applications/ 2>/dev/null || true
mkdir -p /etc/xdg/autostart
cp "$BASE/tools/mrezequielos-update-notify.desktop" /etc/xdg/autostart/ 2>/dev/null || true
mkdir -p /etc/systemd/system /var/lib/mrezequielos
cp "$BASE/tools/mrezequielos-update-check.service" /etc/systemd/system/ 2>/dev/null || true
cp "$BASE/tools/mrezequielos-update-check.timer" /etc/systemd/system/ 2>/dev/null || true
systemctl enable mrezequielos-update-check.timer 2>/dev/null || true
echo "1.1" > /etc/mrezequielos-version

echo "[visual] App Appearance (trocar layout Windows/macOS)..."
cp "$BASE/gnome/mrezequielos-appearance" /usr/local/bin/mrezequielos-appearance
chmod +x /usr/local/bin/mrezequielos-appearance

echo "[visual] Zorin Connect (GSConnect) ativado por padrão."
echo "[visual] GRUB + hostname..."
sed -i 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="MrEzequielOS"/' /etc/default/grub 2>/dev/null || echo 'GRUB_DISTRIBUTOR="MrEzequielOS"' >> /etc/default/grub
echo "MrEzequielOS" > /etc/hostname 2>/dev/null || true
update-grub 2>/dev/null || true
echo "OK - MrEzequielOS 1.1 estilo Zorin aplicado. Layout padrão: Windows (taskbar embaixo + menu iniciar)."
