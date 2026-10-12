#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# MrEzequielOS - (c) EzequielDevTeam. Veja LICENSE e TRADEMARK.md.
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
UUIDS="zorin-taskbar@zorinos.com arcmenu@arcmenu.com blur-my-shell@aunetx ding@rastersoft.com appindicatorsupport@rgcjonas.gmail.com burn-my-windows@schneegans.github.com desktop-cube@schneegans.github.com dash-to-dock@micxgx.gmail.com"
declare -A MINVER=(
  [zorin-taskbar@zorinos.com]=70
  [arcmenu@arcmenu.com]=74
  [blur-my-shell@aunetx]=74
  [ding@rastersoft.com]=85
  [appindicatorsupport@rgcjonas.gmail.com]=66
  [burn-my-windows@schneegans.github.com]=49
  [desktop-cube@schneegans.github.com]=35
  [dash-to-dock@micxgx.gmail.com]=110
)

install_ego() {
  uuid="$1"
  echo "[ext] EGO: $uuid (shell $SHELL_VER)"
  rm -f "$uuid.zip"
  curl -sL --retry 3 --max-time 120 -o "$uuid.zip" "$EGO/$uuid.shell-extension.zip?shell_version=$SHELL_VER" || return 1
  python3 - "$uuid.zip" "$uuid" "${MINVER[$uuid]:-0}" <<'PYEOF' || return 1
import sys, zipfile, json
z = zipfile.ZipFile(sys.argv[1])
meta = [n for n in z.namelist() if n.endswith('metadata.json')]
assert meta, "zip sem metadata.json"
m = json.load(z.open(meta[0]))
assert m.get('uuid') == sys.argv[2], "uuid errado: %s" % m.get('uuid')
ver = int(str(m.get('version', 0)).split('.')[0])
floor = int(sys.argv[3])
assert ver >= floor, "versao antiga: v%s (min v%s)" % (ver, floor)
print("zip OK:", m.get('uuid'), "v" + str(m.get('version', '?')))
PYEOF
  rm -rf "$EXT_DIR/$uuid"
  mkdir -p "$EXT_DIR/$uuid"
  unzip -q -o "$uuid.zip" -d "$EXT_DIR/$uuid" || return 1
  chmod -R a+rX "$EXT_DIR/$uuid"
  [ -d "$EXT_DIR/$uuid/schemas" ] && glib-compile-schemas "$EXT_DIR/$uuid/schemas" || true
  return 0
}

git_zorintaskbar() {
  local UUID="zorin-taskbar@zorinos.com" D="$EXT_DIR/zorin-taskbar@zorinos.com"
  rm -rf zorin-taskbar
  git clone --depth 1 https://github.com/ZorinOS/zorin-taskbar.git || return 1
  [ -f zorin-taskbar/metadata.json ] || return 1
  python3 - zorin-taskbar/metadata.json <<'PYEOF' || return 1
import json, sys
m = json.load(open(sys.argv[1]))
assert m.get('uuid') == 'zorin-taskbar@zorinos.com', 'uuid errado'
assert '46' in [str(x) for x in m.get('shell-version', [])], 'sem GNOME 46'
print('zorin-taskbar v' + str(m.get('version')))
PYEOF
  rm -rf "$D"
  mkdir -p "$D/ui" "$D/img" "$D/schemas" "$D/locale"
  cp zorin-taskbar/src/*.js zorin-taskbar/src/stylesheet.css zorin-taskbar/metadata.json "$D/" || return 1
  cp zorin-taskbar/ui/*.ui "$D/ui/" 2>/dev/null || true
  cp -r zorin-taskbar/img/* "$D/img/" 2>/dev/null || true
  cp zorin-taskbar/schemas/*.xml "$D/schemas/" || return 1
  glib-compile-schemas "$D/schemas/" || return 1
  for po in zorin-taskbar/po/*.po; do
    lang=$(basename "$po" .po)
    mkdir -p "$D/locale/$lang/LC_MESSAGES"
    msgfmt -c "$po" -o "$D/locale/$lang/LC_MESSAGES/zorin-taskbar.mo" 2>/dev/null || true
  done
  chmod -R a+rX "$D"
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
  chmod -R a+rX "$EXT_DIR/$UUID"
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
    zorin-taskbar*) git_zorintaskbar ;;
    arcmenu*) git_arcmenu ;;
    blur-my-shell*) git_blur ;;
    ding*) git_ding ;;
    appindicator*) git_appindicator ;;
    *) echo "[ext] sem fallback git para $uuid"; return 1 ;;
  esac && echo "[ext] OK(git): $uuid" || echo "[ext] FALHOU: $uuid"
done

echo "[ext] Rebrand ArcMenu -> Menu MrEzequielOS (creditos mantidos)..."
python3 - "$EXT_DIR/arcmenu@arcmenu.com/metadata.json" <<'PYEOF' || echo "[ext] AVISO rebrand"
import json, sys
p = sys.argv[1]
m = json.load(open(p))
m['name'] = 'Menu MrEzequielOS'
desc = m.get('description', '')
m['description'] = (desc + ' [Baseado no ArcMenu (GPLv2+) por Andrew Zaech. Adaptado pelo MrEzequielOS.]').strip()
m['url'] = 'https://github.com/EzequielDevTeam/MrEzequielOSLinux'
json.dump(m, open(p, 'w'), indent=2, ensure_ascii=False)
print('rebrand OK:', m['name'])
PYEOF
echo "[ext] Rebrand Zorin Taskbar (creditos mantidos)..."
python3 - "$EXT_DIR/zorin-taskbar@zorinos.com/metadata.json" <<'PYEOF' || echo "[ext] AVISO rebrand taskbar"
import json, sys
p = sys.argv[1]
m = json.load(open(p))
m['name'] = 'Barra de Tarefas MrEzequielOS'
desc = m.get('description', '')
m['description'] = (desc + ' [Baseada na Zorin Taskbar (GPL-2.0) do Zorin Group. Adaptada pelo MrEzequielOS.]').strip()
m['url'] = 'https://github.com/EzequielDevTeam/MrEzequielOSLinux'
json.dump(m, open(p, 'w'), indent=2, ensure_ascii=False)
print('rebrand OK:', m['name'])
PYEOF

echo "[ext] instaladas:"
ls -1 "$EXT_DIR"
echo "[ext] pronto."
