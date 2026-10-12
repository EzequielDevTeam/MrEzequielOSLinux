#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# MrEzequielOS - biblioteca da camada de atualização (usada pelo updater e pelos testes).
# Raízes sobrescrevíveis para teste seguro: MRE_EXT_SYS, MRE_HOMES, MRE_DCONF_PROFILE_DIR.
MRE_EXT_SYS="${MRE_EXT_SYS:-/usr/share/gnome-shell/extensions}"
MRE_HOMES="${MRE_HOMES:-/home}"

# Lista usuários com home real (um por linha).
mre_users() {
  for h in $MRE_HOMES/*; do
    [ -d "$h" ] || continue
    U=$(basename "$h")
    id "$U" >/dev/null 2>&1 || continue
    echo "$U"
  done
}

# Endereço do bus de um usuário (vazio se sem sessão).
mre_user_bus() {
  local UIDU
  UIDU=$(id -u "$1" 2>/dev/null) || return 1
  [ -S "/run/user/$UIDU/bus" ] || return 1
  echo "unix:path=/run/user/$UIDU/bus"
}

# Roda dconf como o usuário (usa bus da sessão ou DCONF_PROFILE de teste).
mre_user_dconf() {
  local U="$1"; shift
  local BUS
  if BUS=$(mre_user_bus "$U"); then
    sudo -u "$U" env DBUS_SESSION_BUS_ADDRESS="$BUS" dconf "$@" 2>/dev/null
  else
    sudo -u "$U" dconf "$@" 2>/dev/null
  fi
}

# Backup do dconf de cada usuário em $1/<user>.dconf. Imprime dir.
mre_backup_users() {
  local DEST="$1"
  mkdir -p "$DEST"
  for U in $(mre_users); do
    if BUS=$(mre_user_bus "$U"); then
      sudo -u "$U" env DBUS_SESSION_BUS_ADDRESS="$BUS" dconf dump / > "$DEST/$U.dconf" 2>/dev/null || true
    else
      sudo -u "$U" dconf dump / > "$DEST/$U.dconf" 2>/dev/null || true
    fi
    echo "backup: $U"
  done
}

# Restaura backups de $1.
mre_restore_users() {
  local DEST="$1"
  [ -d "$DEST" ] || return 0
  for f in "$DEST"/*.dconf; do
    [ -f "$f" ] || continue
    U=$(basename "$f" .dconf)
    if BUS=$(mre_user_bus "$U"); then
      sudo -u "$U" env DBUS_SESSION_BUS_ADDRESS="$BUS" dconf load / < "$f" 2>/dev/null || true
    else
      sudo -u "$U" dconf load / < "$f" 2>/dev/null || true
    fi
    echo "restore: $U"
  done
}

# Remove extensões obsoletas (lista em $1). Nunca toca no resto.
mre_purge_obsolete() {
  local LIST="$1" n=0
  [ -f "$LIST" ] || { echo "purge: lista ausente $LIST"; return 1; }
  while IFS= read -r uuid || [ -n "$uuid" ]; do
    case "$uuid" in ''|\#*) continue ;; esac
    case "$uuid" in *..*|*/*) echo "purge: ignora nome suspeito $uuid"; continue ;; esac
    rm -rf "$MRE_EXT_SYS/$uuid"
    for h in $MRE_HOMES/*; do
      [ -d "$h" ] || continue
      rm -rf "$h/.local/share/gnome-shell/extensions/$uuid"
    done
    echo "purge: removido $uuid"
    n=$((n + 1))
  done < "$LIST"
  echo "purge: total $n"
}

# Reseta chaves do usuário (lista em $1) para o padrão do sistema.
mre_reset_users() {
  local LIST="$1"
  [ -f "$LIST" ] || { echo "reset: lista ausente $LIST"; return 1; }
  for U in $(mre_users); do
    while IFS= read -r path || [ -n "$path" ]; do
      case "$path" in ''|\#*) continue ;; esac
      case "$path" in /*) ;; *) echo "reset: ignora caminho suspeito $path"; continue ;; esac
      if BUS=$(mre_user_bus "$U"); then
        sudo -u "$U" env DBUS_SESSION_BUS_ADDRESS="$BUS" dconf reset -f "$path" 2>/dev/null || true
      else
        sudo -u "$U" dconf reset -f "$path" 2>/dev/null || true
      fi
    done < "$LIST"
    echo "reset: $U ok"
  done
}

# Verifica se todos os UUIDs de $1 existem instalados. Retorna 0/1.
mre_verify_required() {
  local LIST="$1" falta=0
  [ -f "$LIST" ] || { echo "verify: lista ausente $LIST"; return 1; }
  while IFS= read -r uuid || [ -n "$uuid" ]; do
    case "$uuid" in ''|\#*) continue ;; esac
    if [ -f "$MRE_EXT_SYS/$uuid/metadata.json" ]; then
      echo "verify: OK $uuid"
    else
      echo "verify: FALTA $uuid"
      falta=1
    fi
  done < "$LIST"
  return $falta
}
