#!/bin/bash
# MrEzequielOS - Instala temas e ícones OFICIAIS do Zorin OS.
# Fontes: github.com/ZorinOS/zorin-desktop-themes (GPL-2.0)
#         github.com/ZorinOS/zorin-icon-themes (CC-BY-SA-4.0)
# Uso permitido com créditos (veja Ajuda > Créditos). Arquivos originais,
# sem modificação. Falha isolada não quebra o build.
set -u
TMP="/tmp/mre-zorin"
rm -rf "$TMP"
mkdir -p "$TMP"
cd "$TMP" || exit 1

echo "[zorin] baixando temas oficiais..."
git clone --depth 1 https://github.com/ZorinOS/zorin-desktop-themes.git dt || { echo "[zorin] AVISO clone temas falhou"; exit 1; }
git clone --depth 1 https://github.com/ZorinOS/zorin-icon-themes.git it || { echo "[zorin] AVISO clone icones falhou"; exit 1; }

echo "[zorin] instalando temas GTK..."
for t in ZorinPurple-Dark ZorinGrey-Dark ZorinPurple-Light ZorinGrey-Light; do
  if [ -d "dt/$t" ]; then
    rm -rf "/usr/share/themes/$t"
    cp -r "dt/$t" /usr/share/themes/
    chmod -R a+rX "/usr/share/themes/$t"
    echo "[zorin] tema $t OK"
  fi
done

echo "[zorin] instalando icones..."
for i in Zorin ZorinPurple-Dark ZorinGrey-Dark; do
  if [ -d "it/$i" ]; then
    rm -rf "/usr/share/icons/$i"
    cp -r "it/$i" /usr/share/icons/
    chmod -R a+rX "/usr/share/icons/$i"
    gtk-update-icon-cache -f "/usr/share/icons/$i" 2>/dev/null || true
    echo "[zorin] icones $i OK"
  fi
done

echo "[zorin] licenças (créditos)..."
mkdir -p /usr/share/doc/mrezequielos
cp dt/LICENSE /usr/share/doc/mrezequielos/LICENSE.zorin-desktop-themes 2>/dev/null || true
cp it/LICENSE /usr/share/doc/mrezequielos/LICENSE.zorin-icon-themes 2>/dev/null || true

echo "[zorin] instalado:"
ls -d /usr/share/themes/Zorin* /usr/share/icons/Zorin* 2>/dev/null || echo "[zorin] AVISO nada instalado"
cd / && rm -rf "$TMP"
echo "[zorin] pronto."
