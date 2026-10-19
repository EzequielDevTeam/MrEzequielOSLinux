#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-or-later
# MrEzequielOS - boot direto no sistema, sem menu do GRUB.
#
# Por que o menu aparece: quando o instalador do Ubuntu encontra outro
# sistema (macOS, Windows, outra distro), ele grava GRUB_TIMEOUT=10 em
# /etc/default/grub e regenera o grub.cfg. Este script fixa o padrao e
# instala um override em /etc/grub.d/99_mrezequielos, que roda por ultimo
# no grub-mkconfig e vence o ajuste do instalador. Tambem sobrevive a
# atualizacoes de kernel, porque o override e um arquivo persistente.
#
# Uso:
#   mrezequielos-boot          -> boot direto (padrao)
#   mrezequielos-boot --menu   -> volta a mostrar o menu por 5 segundos
set -u
GRUBCFG=/etc/default/grub
MODE="${1:-direct}"

if grep -q "boot=casper" /proc/cmdline 2>/dev/null; then
  echo "[boot] modo live: nada a fazer."
  exit 0
fi

set_kv() {
  local k="$1" v="$2"
  [ -f "$GRUBCFG" ] || : > "$GRUBCFG"
  sed -i "/^${k}=/d" "$GRUBCFG"
  printf '%s=%s\n' "$k" "$v" >> "$GRUBCFG"
}

if [ "$MODE" = "--menu" ] || [ "$MODE" = "menu" ]; then
  set_kv GRUB_DEFAULT 0
  set_kv GRUB_TIMEOUT 5
  set_kv GRUB_TIMEOUT_STYLE menu
  rm -f /etc/grub.d/99_mrezequielos
  if update-grub >/tmp/mre-grub.log 2>&1; then
    tail -3 /tmp/mre-grub.log
  else
    tail -5 /tmp/mre-grub.log 2>/dev/null || true
    echo "[boot] AVISO: update-grub falhou"
  fi
  echo "[boot] menu do GRUB visivel por 5s. Para voltar ao boot direto: mrezequielos-boot"
  exit 0
fi

set_kv GRUB_DEFAULT 0
set_kv GRUB_TIMEOUT 0
set_kv GRUB_TIMEOUT_STYLE hidden
set_kv GRUB_DISABLE_OS_PROBER true
set_kv GRUB_DISTRIBUTOR '"MrEzequielOS"'
# Mesmo num boot que falhou, nada de menu.
set_kv GRUB_RECORDFAIL_TIMEOUT 0
# GRUB_SAVEDEFAULT faria o GRUB lembrar a ultima opcao escolhida (inclusive
# macOS/Windows) e voltar nela no proximo boot. Nao queremos isso.
sed -i '/^GRUB_SAVEDEFAULT=/d' "$GRUBCFG" 2>/dev/null || true

# recordfail=1 (de um boot que falhou) faz o GRUB abrir o menu por 30s,
# mesmo com timeout oculto. Limpa a flag presa.
ENVF=/boot/grub/grubenv
if [ ! -f "$ENVF" ]; then
  ENVF="$(find /boot -maxdepth 3 -name grubenv 2>/dev/null | head -1)"
fi
if command -v grub-editenv >/dev/null 2>&1 && [ -n "$ENVF" ] && [ -f "$ENVF" ]; then
  grub-editenv "$ENVF" unset recordfail 2>/dev/null || true
  grub-editenv "$ENVF" unset initrdfail 2>/dev/null || true
fi

mkdir -p /etc/grub.d
cat > /etc/grub.d/99_mrezequielos <<'GRUBSCRIPT'
#!/bin/sh
# MrEzequielOS: boot direto. Roda por ultimo no grub-mkconfig para vencer
# o GRUB_TIMEOUT=10 que o instalador grava ao detectar outro sistema.
cat <<'GRUBEOF'
set timeout=0
set timeout_style=hidden
set default=0
GRUBEOF
GRUBSCRIPT
chmod 755 /etc/grub.d/99_mrezequielos

echo "[boot] /etc/default/grub:"
grep -E "^(GRUB_DEFAULT|GRUB_TIMEOUT|GRUB_TIMEOUT_STYLE|GRUB_DISABLE_OS_PROBER|GRUB_RECORDFAIL_TIMEOUT|GRUB_DISTRIBUTOR)=" "$GRUBCFG" || true
if update-grub >/tmp/mre-grub.log 2>&1; then
  tail -5 /tmp/mre-grub.log
else
  tail -10 /tmp/mre-grub.log 2>/dev/null || true
  echo "[boot] AVISO: update-grub falhou (no chroot e normal; o instalador regenera)"
fi
echo "[boot] pronto: inicia direto no MrEzequielOS (segure Esc para ver o menu)."
