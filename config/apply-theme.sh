#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# MrEzequielOS - (c) EzequielDevTeam. Veja LICENSE e TRADEMARK.md.
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
cp "$BASE/branding/start-button.svg" /usr/share/pixmaps/mrezequielos-start.svg 2>/dev/null || true

echo "[visual] Extensões estilo Zorin..."
chmod +x "$BASE/gnome/install-extensions.sh" "$BASE/gnome/mrezequielos-appearance" 2>/dev/null || true
"$BASE/gnome/install-extensions.sh" || echo "AVISO extensões falharam, seguindo"

echo "[visual] Padrões do desktop (layout Windows travado)..."
mkdir -p /etc/dconf/db/local.d /etc/dconf/db/gdm.d /etc/dconf/db/site.d /etc/dconf/db/distro.d /etc/dconf/profile
cp "$BASE/gnome/95-mrezequielos" /etc/dconf/db/local.d/95-mrezequielos
cp "$BASE/gnome/95-mrezequielos" /etc/dconf/db/gdm.d/95-mrezequielos
cat > /etc/dconf/profile/user <<'EOF'
user-db:user
system-db:local
system-db:site
system-db:distro
system-db:gdm
EOF
cat /etc/dconf/profile/user
dconf update || echo "AVISO dconf"
which dconf && dconf update && echo DCONF-OK || true
ls -l /etc/dconf/db/local /etc/dconf/db/gdm 2>/dev/null || echo "AVISO db nao compilado"

echo "[visual] Plymouth MrEzequielOS (nossa tela de loading)..."
mkdir -p /usr/share/plymouth/themes/mrezequielos
cp "$BASE/plymouth/mrezequielos/mrezequielos.plymouth" /usr/share/plymouth/themes/mrezequielos/ 2>/dev/null || true
cp "$BASE/branding/plymouth-watermark.png" /usr/share/plymouth/themes/mrezequielos/watermark.png 2>/dev/null || true
SPIN="/usr/share/plymouth/themes/spinner"
if [ -d "$SPIN" ]; then
  cp "$SPIN"/animation-*.png "$SPIN"/throbber-*.png /usr/share/plymouth/themes/mrezequielos/ 2>/dev/null || true
  cp "$SPIN"/entry.png "$SPIN"/lock.png "$SPIN"/bullet.png "$SPIN"/keyboard.png "$SPIN"/keymap-render.png "$SPIN"/capslock.png /usr/share/plymouth/themes/mrezequielos/ 2>/dev/null || true
fi
ls /usr/share/plymouth/themes/mrezequielos/ || true
update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth /usr/share/plymouth/themes/mrezequielos/mrezequielos.plymouth 100 2>/dev/null || true
update-alternatives --set default.plymouth /usr/share/plymouth/themes/mrezequielos/mrezequielos.plymouth 2>/dev/null || echo "AVISO plymouth falhou"

echo "[visual] Licença GPLv3 + marca..."
mkdir -p /usr/share/doc/mrezequielos
for L in "$BASE/../LICENSE" /tmp/LICENSE; do
  if [ -f "$L" ]; then cp "$L" /usr/share/doc/mrezequielos/LICENSE; break; fi
done
for T in "$BASE/../TRADEMARK.md" /tmp/TRADEMARK.md; do
  if [ -f "$T" ]; then cp "$T" /usr/share/doc/mrezequielos/TRADEMARK.md; break; fi
done
ls /usr/share/doc/mrezequielos/ || true

echo "[visual] Ferramentas MrEzequielOS (atualizador + segurança)..."
chmod +x "$BASE/tools/"* 2>/dev/null || true
cp "$BASE/tools/mrezequielos-update" /usr/local/bin/mrezequielos-update
cp "$BASE/tools/mrezequielos-security" /usr/local/bin/mrezequielos-security
cp "$BASE/tools/mrezequielos-diagnostico" /usr/local/bin/mrezequielos-diagnostico
cp "$BASE/tools/mrezequielos-test-installer" /usr/local/bin/mrezequielos-test-installer
chmod +x /usr/local/bin/mrezequielos-update /usr/local/bin/mrezequielos-security /usr/local/bin/mrezequielos-diagnostico /usr/local/bin/mrezequielos-test-installer
cp "$BASE/tools/mrezequielos-update.desktop" /usr/share/applications/ 2>/dev/null || true
cp "$BASE/tools/mrezequielos-security.desktop" /usr/share/applications/ 2>/dev/null || true
cp "$BASE/tools/mrezequielos-diagnostico.desktop" /usr/share/applications/ 2>/dev/null || true
cp "$BASE/tools/mrezequielos-test-installer.desktop" /usr/share/applications/ 2>/dev/null || true
cp "$BASE/tools/mrezequielos-appearance.desktop" /usr/share/applications/ 2>/dev/null || true
mkdir -p /etc/xdg/autostart
cp "$BASE/tools/mrezequielos-update-notify.desktop" /etc/xdg/autostart/ 2>/dev/null || true
cp "$BASE/tools/mrezequielos-try-install" /usr/local/bin/mrezequielos-try-install
chmod +x /usr/local/bin/mrezequielos-try-install
cp "$BASE/tools/mrezequielos-try-install.desktop" /etc/xdg/autostart/ 2>/dev/null || true
cp "$BASE/tools/mrezequielos-live-keyring" /usr/local/bin/mrezequielos-live-keyring
chmod +x /usr/local/bin/mrezequielos-live-keyring
cp "$BASE/tools/mrezequielos-live-keyring.desktop" /etc/xdg/autostart/ 2>/dev/null || true
mkdir -p /etc/systemd/system /var/lib/mrezequielos
cp "$BASE/tools/mrezequielos-update-check.service" /etc/systemd/system/ 2>/dev/null || true
cp "$BASE/tools/mrezequielos-update-check.timer" /etc/systemd/system/ 2>/dev/null || true
systemctl enable mrezequielos-update-check.timer 2>/dev/null || true
echo "1.1" > /etc/mrezequielos-version

echo "[visual] App de Ajuda próprio (tudo nosso, com créditos)..."
mkdir -p /usr/share/help/C/mrezequielos-help
cp "$BASE/help/C/mrezequielos-help/"*.page /usr/share/help/C/mrezequielos-help/ 2>/dev/null || true
cp "$BASE/tools/mrezequielos-help.desktop" /usr/share/applications/ 2>/dev/null || true

echo "[visual] Slideshow do instalador em pt-BR (nossa cara + nosso wallpaper)..."
SS="/usr/share/ubiquity-slideshow/slides"
if [ -d "$SS" ]; then
  for f in welcome usc browse office music photos accessibility gethelp; do
    cp "$BASE/slideshow/$f.html" "$SS/$f.html" 2>/dev/null || true
    for loc in l10n/pt_BR l10n/pt; do
      [ -f "$SS/$loc/$f.html" ] && cp "$BASE/slideshow/$f.html" "$SS/$loc/$f.html" 2>/dev/null || true
    done
  done
  for s in welcome browse office music photos gs customize; do
    cp "$BASE/branding/grub-bg.png" "$SS/screenshots/$s.png" 2>/dev/null || true
  done
  ls "$SS"/welcome.html "$SS"/l10n/pt_BR/welcome.html 2>/dev/null || true
else
  echo "AVISO slideshow ausente"
fi

echo "[visual] App Appearance (trocar layout Windows/macOS)..."
cp "$BASE/gnome/mrezequielos-appearance" /usr/local/bin/mrezequielos-appearance
chmod +x /usr/local/bin/mrezequielos-appearance

echo "[visual] Zorin Connect (GSConnect) ativado por padrão."
echo "[visual] GRUB + hostname..."
sed -i 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="MrEzequielOS"/' /etc/default/grub 2>/dev/null || echo 'GRUB_DISTRIBUTOR="MrEzequielOS"' >> /etc/default/grub
echo "MrEzequielOS" > /etc/hostname 2>/dev/null || true
update-grub 2>/dev/null || true
echo "OK - MrEzequielOS 1.1 estilo Zorin aplicado. Layout padrão: Windows (taskbar embaixo + menu iniciar)."
