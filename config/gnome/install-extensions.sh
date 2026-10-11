#!/bin/bash
# MrEzequielOS - Instala extensões estilo Zorin OS (GNOME 46 / Ubuntu 24.04)
# Método 1: zips oficiais do extensions.gnome.org (rápido, sem compilar)
# Método 2 (fallback): git + make/meson
# Roda no chroot durante o build. Falha isolada não quebra o build.
set -u
SHELL_VER="${GNOME_SHELL_VERSION:-46}"
EGO="https://extensions.gnome.org/download-extension"
EXT_DIR="/usr/share/gnome-shell/extensions"
TMP="/tmp/mre-ext"
mkdir -p "$EXT_DIR" "$TMP"
cd "$TMP"
UUIDS="dash-to-panel@jderose9.github.com arcmenu@arcmenu.com blur-my-shell@aunetx ding@rastersoft.com appindicatorsupport@rgcjonas.gmail.com burn-my-windows@schneegans.github.com desktop-cube@schneegans.github.com dash-to-dock@micxgx.gmail.com"

install_ego() {
  uuid="$1"
  echo "[ext] EGO: $uuid (shell $SHELL_VER)"
  rm -f "$uuid.zip"
  curl -sL --retry 3 --max-time 120 -o "$uuid.zip" "$EGO/$uuid.shell-extension.zip?shell_version=$SHELL_VER" || return 1
  python3 - "$uuid.zip" "$uuid" <<'PYEOF' || return 1
import sys, zipfile, json
z = zipfile.ZipFile(sys.argv[1])
meta = [n for n in z.namelist() if n.endswith('metadata.json')]
assert meta, "zip sem metadata.json"
m = json.load(z.open(meta[0]))
assert m.get('uuid') == sys.argv[2], "uuid errado: %s" % m.get('uuid')
print("zip OK:", m.get('uuid'), "v" + str(m.get('version', '?')))
PYEOF
  rm -rf "$EXT_DIR/$uuid"
  mkdir -p "$EXT_DIR/$uuid"
  unzip -q -o "$uuid.zip" -d "$EXT_DIR/$uuid" || return 1
  [ -d "$EXT_DIR/$uuid/schemas" ] && glib-compile-schemas "$EXT_DIR/$uuid/schemas" || true
  return 0
}

git_dashtopanel() {
  rm -rf dash-to-panel
  git clone --depth 1 https://github.com/home-sweet-gnome/dash-to-panel.git dash-to-panel \
    || git clone --depth 1 https://github.com/jderose9/dash-to-panel.git dash-to-panel || return 1
  cd dash-to-panel && make install || { cd ..; return 1; }
  cd ..
}
git_arcmenu() {
  rm -rf ArcMenu && git clone --depth 1 https://github.com/arcmenu/ArcMenu.git || return 1
  cd ArcMenu && (make install || (meson setup build --prefix=/usr && ninja -C build install)) || { cd ..; return 1; }
  cd ..
}
git_blur() {
  rm -rf blur-my-shell && git clone --depth 1 https://github.com/aunetx/blur-my-shell.git || return 1
  cd blur-my-shell && meson setup build --prefix=/usr && ninja -C build install || { cd ..; return 1; }
  cd ..
}
git_ding() {
  rm -rf ding && git clone --depth 1 https://gitlab.com/rastersoft/desktop-icons-ng.git ding || return 1
  UUID="ding@rastersoft.com"
  mkdir -p "$EXT_DIR/$UUID"
  cp ding/*.js ding/metadata.json "$EXT_DIR/$UUID/" || return 1
  [ -d ding/schemas ] && { mkdir -p "$EXT_DIR/$UUID/schemas"; cp -r ding/schemas/* "$EXT_DIR/$UUID/schemas/"; }
  [ -d ding/locale ] && cp -r ding/locale "$EXT_DIR/$UUID/"
  [ -f ding/stylesheet.css ] && cp ding/stylesheet.css "$EXT_DIR/$UUID/"
  glib-compile-schemas "$EXT_DIR/$UUID/schemas" 2>/dev/null || true
}
git_appindicator() {
  rm -rf gnome-shell-extension-appindicator && git clone --depth 1 https://github.com/ubuntu/gnome-shell-extension-appindicator.git || return 1
  cd gnome-shell-extension-appindicator && meson setup build --prefix=/usr && ninja -C build install || { cd ..; return 1; }
  cd ..
}

for uuid in $UUIDS; do
  if install_ego "$uuid"; then
    echo "[ext] OK(EGO): $uuid"
    continue
  fi
  echo "[ext] EGO falhou, tentando git: $uuid"
  case "$uuid" in
    dash-to-panel*) git_dashtopanel ;;
    arcmenu*) git_arcmenu ;;
    blur-my-shell*) git_blur ;;
    ding*) git_ding ;;
    appindicator*) git_appindicator ;;
    *) echo "[ext] sem fallback git para $uuid"; return 1 ;;
  esac && echo "[ext] OK(git): $uuid" || echo "[ext] FALHOU: $uuid"
done

echo "[ext] instaladas:"
ls -1 "$EXT_DIR"
echo "[ext] pronto."
