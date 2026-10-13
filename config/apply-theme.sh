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

echo "[visual] Navegador Brave (oficial, sem snap)..."
( curl -fsSL https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg -o /usr/share/keyrings/brave-browser-archive-keyring.gpg 2>/dev/null || true
  echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" > /etc/apt/sources.list.d/brave-browser-release.list
  apt update || true
  apt install -y brave-browser 2>/dev/null || true ) || echo "AVISO Brave falhou"

echo "[visual] Wallpaper + logo..."
mkdir -p /usr/share/backgrounds /usr/share/pixmaps /usr/local/bin /usr/share/applications
cp "$BASE/branding/wallpaper.svg" /usr/share/backgrounds/mrezequielos-wallpaper.svg 2>/dev/null || true
cp "$BASE/branding/logo.svg" /usr/share/pixmaps/mrezequielos-logo.svg 2>/dev/null || true
cp "$BASE/branding/logo.svg" /usr/share/pixmaps/mrezequielos.svg 2>/dev/null || true
cp "$BASE/branding/start-button.svg" /usr/share/pixmaps/mrezequielos-start.svg 2>/dev/null || true

echo "[visual] Extensões gerenciadas só pelo nosso Appearance (esconde apps soltos)..."
for d in /usr/share/applications/com.mattjakeman.ExtensionManager.desktop /usr/share/applications/org.gnome.Extensions.desktop; do
  if [ -f "$d" ] && ! grep -q "^NoDisplay=true" "$d"; then
    echo "NoDisplay=true" >> "$d"
  fi
done

echo "[visual] Temas OFICIAIS Zorin (com créditos)..."
chmod +x "$BASE/gnome/install-zorin-themes.sh" 2>/dev/null || true
"$BASE/gnome/install-zorin-themes.sh" || echo "AVISO temas zorin falharam, seguindo com Yaru/Papirus"

echo "[visual] Extensões estilo Zorin..."
chmod +x "$BASE/gnome/install-extensions.sh" "$BASE/gnome/mrezequielos-appearance" 2>/dev/null || true
"$BASE/gnome/install-extensions.sh" || echo "AVISO extensões falharam, seguindo"

echo "[visual] Padrões do desktop (layout Windows travado)..."
mkdir -p /etc/dconf/db/local.d /etc/dconf/db/gdm.d /etc/dconf/db/site.d /etc/dconf/db/distro.d /etc/dconf/profile
cp "$BASE/gnome/95-mrezequielos" /etc/dconf/db/local.d/95-mrezequielos
cp "$BASE/gnome/95-mrezequielos" /etc/dconf/db/gdm.d/95-mrezequielos
echo "[visual] Icones redondos modernos (Tela roxo, senão Papirus)..."
apt install -y tela-icon-theme 2>/dev/null || true
ICON="Papirus-Dark"
if [ -d /usr/share/icons/ZorinPurple-Dark ]; then ICON="ZorinPurple-Dark";
elif [ -d /usr/share/icons/Tela-purple-dark ]; then ICON="Tela-purple-dark";
elif [ -d /usr/share/icons/Tela-dark ]; then ICON="Tela-dark"; fi
echo "[visual] icon-theme=$ICON"
sed -i "s/icon-theme='[^']*'/icon-theme='$ICON'/" /etc/dconf/db/local.d/95-mrezequielos /etc/dconf/db/gdm.d/95-mrezequielos
echo "[visual] GTK Zorin roxo (senão Yaru roxo, senão Yaru escuro)..."
if [ -d /usr/share/themes/ZorinPurple-Dark ]; then GTK="ZorinPurple-Dark";
elif [ -d /usr/share/themes/Yaru-purple-dark ]; then GTK="Yaru-purple-dark";
else GTK="Yaru-dark"; fi
echo "[visual] gtk-theme=$GTK"
sed -i "s/gtk-theme='[^']*'/gtk-theme='$GTK'/; s/^theme='[^']*'/theme='$GTK'/" /etc/dconf/db/local.d/95-mrezequielos /etc/dconf/db/gdm.d/95-mrezequielos
if [ -d /usr/share/themes/Yaru-purple-dark/gnome-shell ]; then
  mkdir -p /etc/dconf/db/local.d
  printf "[org/gnome/shell/extensions/user-theme]\nname='$GTK'\n" >> /etc/dconf/db/local.d/95-mrezequielos
  echo "[visual] shell-theme=$GTK"
fi
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
chmod +x /usr/local/bin/mrezequielos-update /usr/local/bin/mrezequielos-security /usr/local/bin/mrezequielos-diagnostico
cp "$BASE/tools/mrezequielos-update.desktop" /usr/share/applications/ 2>/dev/null || true
cp "$BASE/tools/mrezequielos-security.desktop" /usr/share/applications/ 2>/dev/null || true
cp "$BASE/tools/mrezequielos-diagnostico.desktop" /usr/share/applications/ 2>/dev/null || true
rm -f /usr/local/bin/mrezequielos-test-installer /usr/share/applications/mrezequielos-test-installer.desktop 2>/dev/null || true
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
echo "1.1.3" > /etc/mrezequielos-version

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
cp "$BASE/tools/mrezequielos-appearance-gtk.py" /usr/local/bin/mrezequielos-appearance-gtk
chmod +x /usr/local/bin/mrezequielos-appearance-gtk

echo "[visual] Zorin Connect (GSConnect) ativado por padrão."
echo "[visual] Base MrEzequielOS (nome nosso, numero valido)..."
cat > /etc/lsb-release <<'EOF'
DISTRIB_ID=MrEzequielOS
DISTRIB_RELEASE=24.04
DISTRIB_CODENAME=noble
DISTRIB_DESCRIPTION="MrEzequielOS 1.1.3"
EOF
cat /etc/lsb-release
if [ -f /usr/share/applications/update-manager.desktop ]; then
  sed -i 's/^Icon=.*/Icon=mrezequielos/' /usr/share/applications/update-manager.desktop
fi
chmod 644 /usr/share/applications/mrezequielos-*.desktop /etc/xdg/autostart/mrezequielos-*.desktop 2>/dev/null || true

echo "[visual] GRUB + hostname..."
sed -i 's/^GRUB_DISTRIBUTOR=.*/GRUB_DISTRIBUTOR="MrEzequielOS"/' /etc/default/grub 2>/dev/null || echo 'GRUB_DISTRIBUTOR="MrEzequielOS"' >> /etc/default/grub
echo "MrEzequielOS" > /etc/hostname 2>/dev/null || true
update-grub 2>/dev/null || true

echo "[visual] Bloqueia upgrade de base (igual Zorin: sem oferta de nova versao Ubuntu)..."
if [ -f /etc/update-manager/release-upgrades ]; then
  sed -i 's/^Prompt=.*/Prompt=never/' /etc/update-manager/release-upgrades
  grep -E "^Prompt=" /etc/update-manager/release-upgrades || true
else
  echo "AVISO release-upgrades ausente"
fi
echo "OK - MrEzequielOS 1.1.3 estilo Zorin aplicado. Layout padrão: Windows (taskbar embaixo + menu iniciar)."
