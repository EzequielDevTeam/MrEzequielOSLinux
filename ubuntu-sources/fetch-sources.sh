#!/bin/bash
# Baixa o código-fonte dos pacotes do Ubuntu para customização.
# Uso: ./fetch-sources.sh [pacote...]   (padrão: lê packages.txt)
# Roda no Ubuntu com acesso ao archive (GitHub runner 24.04 serve).
set -e
cd "$(dirname "$0")"
PKGS="$@"
[ -z "$PKGS" ] && PKGS=$(grep -vE '^[[:space:]]*(#|$)' packages.txt | tr '\n' ' ')

if ! grep -rq "^deb-src" /etc/apt/sources.list* 2>/dev/null; then
  echo "[fontes] Habilitando deb-src..."
  CODENAME=$(lsb_release -cs 2>/dev/null || echo noble)
  echo "deb-src http://archive.ubuntu.com/ubuntu $CODENAME main restricted universe multiverse" | sudo tee /etc/apt/sources.list.d/deb-src.list > /dev/null
  echo "deb-src http://archive.ubuntu.com/ubuntu $CODENAME-updates main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list.d/deb-src.list > /dev/null
  sudo apt update
fi

for p in $PKGS; do
  echo "[fontes] Baixando fonte de: $p"
  mkdir -p "$p" && ( cd "$p" && apt source "$p" )
  ( cd "$p" && dpkg-parsechangelog -S Version 2>/dev/null || echo "?" ) | xargs -I{} echo "$p {}" >> VERSIONS.txt
done
echo "[fontes] OK. Versões em ubuntu-sources/VERSIONS.txt"
