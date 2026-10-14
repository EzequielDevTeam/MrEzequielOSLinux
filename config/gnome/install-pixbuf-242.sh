#!/bin/bash
# MrEzequielOS - usa gdk-pixbuf 2.42 (loaders legados, SEM glycin/sandbox).
# Igual ao Zorin OS 18.1: o glycin do 2.44 quebra o instalador (bwrap aborta
# sob o UID do Ubiquity e derruba qualquer app GTK). Nada no 26.04 exige
# pixbuf >= 2.41 (o maior pin geral e >= 2.40.0), entao o downgrade e seguro.
# Idempotente: pode rodar no build e no OTA.
set -u
VER="2.42.10+dfsg-3ubuntu3"
URL="http://archive.ubuntu.com/ubuntu/pool/main/g/gdk-pixbuf"
PKGS="libgdk-pixbuf-2.0-0 libgdk-pixbuf2.0-bin libgdk-pixbuf2.0-common"

cur=$(dpkg-query -W -f='${Version}' libgdk-pixbuf-2.0-0 2>/dev/null || echo "ausente")
case "$cur" in
  2.42*)
    echo "[pixbuf] ja esta em $cur, garantindo hold + cache..."
    ;;
  *)
    echo "[pixbuf] atual: $cur -> baixando $VER (noble, amd64)..."
    TMPD=$(mktemp -d)
    ok=1
    for p in $PKGS; do
      case "$p" in
        libgdk-pixbuf2.0-common) arch="all" ;;
        *) arch="amd64" ;;
      esac
      f="${p}_${VER}_${arch}.deb"
      curl -fsSL --retry 2 --max-time 120 -o "$TMPD/$f" "$URL/$f" || { echo "[pixbuf] FALHOU download $f"; ok=0; }
    done
    if [ "$ok" = "1" ]; then
      echo "[pixbuf] instalando (downgrade)..."
      dpkg --force-downgrade -i "$TMPD"/*.deb || { echo "[pixbuf] FALHOU dpkg"; rm -rf "$TMPD"; exit 1; }
    else
      echo "[pixbuf] AVISO: download incompleto, mantendo $cur"
    fi
    rm -rf "$TMPD"
    ;;
esac

echo "[pixbuf] segurando pacotes (hold)..."
apt-mark hold $PKGS 2>/dev/null || true

echo "[pixbuf] regenerando loaders.cache (legados)..."
if command -v gdk-pixbuf-query-loaders >/dev/null; then
  gdk-pixbuf-query-loaders --update-cache 2>/dev/null || true
  ls -l /usr/lib/x86_64-linux-gnu/gdk-pixbuf-2.0/2.10.0/loaders.cache 2>/dev/null || true
else
  echo "[pixbuf] AVISO: gdk-pixbuf-query-loaders ausente"
fi

echo "[pixbuf] versao final: $(dpkg-query -W -f='${Version}' libgdk-pixbuf-2.0-0 2>/dev/null)"
echo "[pixbuf] pronto (sem glycin no caminho dos icones GTK)."
