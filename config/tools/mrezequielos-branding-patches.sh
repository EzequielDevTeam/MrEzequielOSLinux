#!/bin/bash
# Patches para corrigir branding no update-manager e crash no ubiquity
# Executado durante o build da ISO e nas atualizações

set -euo pipefail

echo "[patch] Aplicando patches de branding..."

# 1. Patch update-manager utils.py - retorna MrEzequielOS em vez de Ubuntu
UTILS_PY="/usr/lib/python3/dist-packages/UpdateManager/Core/utils.py"
if [ -f "$UTILS_PY" ]; then
    cp "$UTILS_PY" "$UTILS_PY.bak"
    python3 << 'PYEOF'
with open("/usr/lib/python3/dist-packages/UpdateManager/Core/utils.py", "r") as f:
    content = f.read()

# Substituir get_ubuntu_flavor_name
old_flavor_name = '''def get_ubuntu_flavor_name(cache=None):
    """try to guess the flavor name based on the running desktop"""
    pkg = get_ubuntu_flavor_package(cache=cache)
    lookup = {"ubuntustudio-desktop": "Ubuntu Studio"}
    if pkg in lookup:
        return lookup[pkg]
    elif pkg.endswith("-desktop"):
        return capitalize_first_word(pkg.rsplit("-desktop", 1)[0])
    elif pkg.endswith("-netbook"):
        return capitalize_first_word(pkg.rsplit("-netbook", 1)[0])
    else:
        return "Ubuntu"'''

new_flavor_name = '''def get_ubuntu_flavor_name(cache=None):
    """Retorna nome do nosso flavor"""
    return "MrEzequielOS"'''

if old_flavor_name in content:
    content = content.replace(old_flavor_name, new_flavor_name)
    print("update-manager utils.py patchado (flavor_name)")
else:
    print("update-manager utils.py AVISO: padrao flavor_name nao casou, pulando")

# Substituir get_ubuntu_flavor
old_flavor = '''def get_ubuntu_flavor(cache=None):
    """try to guess the flavor based on the running desktop"""
    # this will (of course) not work in a server environment,
    # but the main use case for this is to show the right
    # release notes.
    pkg = get_ubuntu_flavor_package(cache=cache)
    return pkg.split("-", 1)[0]'''

new_flavor = '''def get_ubuntu_flavor(cache=None):
    """Retorna flavor do nosso distro"""
    return "mrezequielos"'''

if old_flavor in content:
    content = content.replace(old_flavor, new_flavor)
    print("update-manager utils.py patchado (flavor)")
else:
    print("update-manager utils.py AVISO: padrao flavor nao casou, pulando")

with open("/usr/lib/python3/dist-packages/UpdateManager/Core/utils.py", "w") as f:
    f.write(content)

PYEOF
else
    echo "[patch] AVISO: $UTILS_PY não encontrado"
fi

# 2. Patch ubiquity ubi-wireless.py - não crashar se nmwidget sem view
UBI_WIRELESS="/usr/lib/ubiquity/plugins/ubi-wireless.py"
if [ -f "$UBI_WIRELESS" ]; then
    cp "$UBI_WIRELESS" "$UBI_WIRELESS.bak"
    python3 << 'PYEOF'
with open("/usr/lib/ubiquity/plugins/ubi-wireless.py", "r") as f:
    content = f.read()

old = "        self.state = self.nmwidget.get_state()"
new = """        try:
            self.state = self.nmwidget.get_state()
        except AttributeError:
            self.state = 0
            self.skip = True"""

if old in content:
    content = content.replace(old, new)
    print("ubiquity ubi-wireless.py patchado")
else:
    print("ubiquity ubi-wireless.py AVISO: padrao nao casou, pulando")

with open("/usr/lib/ubiquity/plugins/ubi-wireless.py", "w") as f:
    f.write(content)

PYEOF
else
    echo "[patch] AVISO: $UBI_WIRELESS não encontrado"
fi

# 3. Patch nmwidgets.py - get_state defensivo + configure_icons SEM load_icon("image-missing")
NMWIDGETS="/usr/lib/ubiquity/ubiquity/frontend/gtk_components/nmwidgets.py"
if [ -f "$NMWIDGETS" ]; then
    cp "$NMWIDGETS" "$NMWIDGETS.bak"
    
    # Escrever script Python em arquivo temporário para evitar problemas de escaping
    cat > /tmp/patch_nmwidgets.py << 'PYEOF'
import re

with open("/usr/lib/ubiquity/ubiquity/frontend/gtk_components/nmwidgets.py", "r") as f:
    content = f.read()

# 3a. get_state defensivo
old_get_state = """    def get_state(self):
        return self.view.get_state()"""

new_get_state = """    def get_state(self):
        if hasattr(self, "view") and self.view:
            return self.view.get_state()
        return 0"""

content = content.replace(old_get_state, new_get_state)

# 3b. SUBSTITUIR configure_icons INTEIRO por versão robusta (SEM load_icon image-missing)
new_configure = '''    def configure_icons(self):
        # Usa o tema atual (ubuntu-mono-light nao existe no 26.04).
        # O pixbuf padrao e criado em memoria: nunca chama
        # load_icon("image-missing") para nao depender do sandbox bwrap/glycin.
        from gi.repository import GdkPixbuf
        default = GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, True, 8, 22, 22)
        default.fill(0x00000000)
        it = Gtk.IconTheme.get_default()
        self.icons = []
        for n in ['nm-signal-00',
                  'nm-signal-25',
                  'nm-signal-50',
                  'nm-signal-75',
                  'nm-signal-100',
                  'nm-signal-00-secure',
                  'nm-signal-25-secure',
                  'nm-signal-50-secure',
                  'nm-signal-75-secure',
                  'nm-signal-100-secure']:
            ico = it.lookup_icon(n, 22, 0)
            if ico:
                try:
                    ico = ico.load_icon()
                except Exception:
                    ico = default
            else:
                ico = default
            self.icons.append(ico)'''

# Tentar regex DOTALL
old_configure_pattern = r'    def configure_icons\(self\):.*?(?=\n    def |\nclass |\Z)'
new_content, count = re.subn(old_configure_pattern, new_configure, content, flags=re.DOTALL)

if count == 0:
    # Regex não casou - fazer replace mais agressivo linha a linha
    print("[patch] Regex não casou, tentando replace linha a linha...")
    lines = content.split('\n')
    new_lines = []
    in_configure = False
    for line in lines:
        stripped = line.lstrip()
        if stripped.startswith('def configure_icons'):
            in_configure = True
            new_lines.append(new_configure)
            continue
        if in_configure:
            # Próximo método ou classe
            if stripped.startswith('def ') or stripped.startswith('class '):
                in_configure = False
                new_lines.append(line)
            # Skip linhas do método antigo
            continue
        else:
            new_lines.append(line)
    content = '\n'.join(new_lines)
else:
    content = new_content
    print("[patch] Regex substituiu configure_icons (count={})".format(count))

# VERIFICAÇÃO: confirmar que não tem mais load_icon("image-missing")
if 'load_icon("image-missing")' in content or "load_icon('image-missing')" in content:
    print("[patch] AVISO: load_icon('image-missing') AINDA PRESENTE no código!")
    # Force replace qualquer ocorrência restante
    content = content.replace('default_theme.load_icon("image-missing", 22, 0)', '# REMOVIDO: load_icon image-missing')
    content = content.replace("default.load_icon('image-missing', 22, 0)", '# REMOVIDO: load_icon image-missing')
    content = content.replace('default.load_icon("image-missing", 22, 0)', '# REMOVIDO: load_icon image-missing')
    print("[patch] Forçado remoção de load_icon image-missing")
else:
    print("[patch] OK: load_icon('image-missing') removido completamente")

with open("/usr/lib/ubiquity/ubiquity/frontend/gtk_components/nmwidgets.py", "w") as f:
    f.write(content)

print("nmwidgets.py patchado (get_state + configure_icons robusto + verificação)")
PYEOF

    python3 /tmp/patch_nmwidgets.py
    rm /tmp/patch_nmwidgets.py
else
    echo "[patch] AVISO: $NMWIDGETS não encontrado"
fi

# 4. Ícone do Ubiquity = anaconda.png 512px do Zorin
echo "[patch] Definindo ícone do instalador (anaconda 512px)..."
ANACONDA_ICON="/usr/share/icons/Zorin/512x512@2x/apps/anaconda.png"
UBQUITY_ICON="/usr/share/pixmaps/ubiquity.png"

if [ -f "$ANACONDA_ICON" ]; then
    cp "$ANACONDA_ICON" "$UBQUITY_ICON"
    cp "$ANACONDA_ICON" /usr/share/pixmaps/mrezequielos-installer.png 2>/dev/null || true
    echo "[patch] Ícone anaconda.png copiado para ubiquity.png"
else
    echo "[patch] AVISO: $ANACONDA_ICON não encontrado, procurando alternativas..."
    for sz in 512x512@2x 512x512 256x256 128x128 64x64 48x48 32x32 24x24 22x22 16x16; do
        if [ -f "/usr/share/icons/Zorin/${sz}/apps/anaconda.png" ]; then
            cp "/usr/share/icons/Zorin/${sz}/apps/anaconda.png" "$UBQUITY_ICON"
            cp "/usr/share/icons/Zorin/${sz}/apps/anaconda.png" /usr/share/pixmaps/mrezequielos-installer.png 2>/dev/null || true
            echo "[patch] Ícone anaconda.png encontrado em ${sz}"
            break
        fi
    done
fi

# Atualizar .desktop do ubiquity
DESKTOP_FILE="/usr/share/applications/ubiquity.desktop"
if [ -f "$DESKTOP_FILE" ]; then
    sed -i 's|^Icon=.*|Icon=ubiquity|' "$DESKTOP_FILE"
    echo "[patch] ubiquity.desktop atualizado"
fi

# 5. Regenerar cache de ícones para todos os temas
echo "[patch] Regenerando cache de ícones..."
for theme in /usr/share/icons/*/; do
    if [ -f "$theme/index.theme" ]; then
        gtk-update-icon-cache -f "$theme" 2>/dev/null || true
    fi
done

# 6. Resolver symlinks do image-missing.png no tema Zorin (evita bwrap crash)
echo "[patch] Criando image-missing.png transparente nos tamanhos necessários (evita bwrap crash)..."
python3 << 'PYEOF'
import os
from gi.repository import GdkPixbuf

sizes = [(16, 16), (22, 22), (24, 24), (32, 32), (48, 48)]
for w, h in sizes:
    dir_path = f"/usr/share/icons/Zorin/{w}x{h}/status"
    icon_path = f"{dir_path}/image-missing.png"
    os.makedirs(dir_path, exist_ok=True)
    # lexists: symlink quebrado tambem conta (exists retorna False nele).
    if os.path.islink(icon_path):
        os.unlink(icon_path)
    if not os.path.exists(icon_path):
        pb = GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, True, 8, w, h)
        pb.fill(0x00000000)
        pb.savev(icon_path, 'png', [], [])
        print(f"[patch] Criado: {icon_path}")

print("[patch] image-missing.png criado em todos os tamanhos")
PYEOF

# 7. Regenerar cache após criar ícones
for theme in /usr/share/icons/*/; do
    if [ -f "$theme/index.theme" ]; then
        gtk-update-icon-cache -f "$theme" 2>/dev/null || true
    fi
done

# 8. Wrapper bwrap para o Ubiquity (causa raiz do "Bail out! Gtk" no instalador).
# O Ubiquity baixa o UID efetivo da interface para 1000 (seteuid) mantendo o
# UID real 0. O glycin chama o bwrap nesse estado e o bwrap aborta com
# "Unexpected setuid user 1000, should be 0" (provado no live).
# O wrapper do compat/ cobre chamada via PATH; o teste no live mostrou que o
# glycin pode chamar /usr/bin/bwrap por caminho absoluto, entao o wrapper
# tambem assume /usr/bin/bwrap via dpkg-divert (idempotente, reversivel).
echo "[patch] Instalando wrappers bwrap do Ubiquity..."
WRAP_PY='#!/usr/bin/python3
"""Wrapper bwrap: restaura uid 0 quando possivel, senao repassa intacto."""
import os
import sys

REAL_BWRAP = "__REAL__"

for _fn in ("seteuid", "setuid"):
    try:
        getattr(os, _fn)(0)
    except Exception:
        pass

if not os.path.exists(REAL_BWRAP):
    sys.stderr.write("mre-bwrap: binario real ausente: %s\n" % REAL_BWRAP)
    sys.exit(127)

os.execv(REAL_BWRAP, [REAL_BWRAP] + sys.argv[1:])
'
# 8a. Compat (cobre chamada via PATH; Ubiquity poe compat no inicio do PATH).
mkdir -p /usr/lib/ubiquity/compat
printf '%s' "$WRAP_PY" | sed 's|__REAL__|/usr/bin/bwrap|' > /usr/lib/ubiquity/compat/bwrap
chmod +x /usr/lib/ubiquity/compat/bwrap
echo "[patch] Wrapper bwrap instalado em /usr/lib/ubiquity/compat/bwrap"
# 8b. Caminho absoluto (cobre chamada direta a /usr/bin/bwrap).
if [ -f /usr/bin/bwrap ] && [ ! -f /usr/bin/bwrap.real ]; then
  dpkg-divert --add --rename --divert /usr/bin/bwrap.real /usr/bin/bwrap 2>/dev/null || {
    mv /usr/bin/bwrap /usr/bin/bwrap.real
  }
fi
if [ -f /usr/bin/bwrap.real ]; then
  printf '%s' "$WRAP_PY" | sed 's|__REAL__|/usr/bin/bwrap.real|' > /usr/bin/bwrap
  chmod +x /usr/bin/bwrap
  echo "[patch] Wrapper bwrap instalado em /usr/bin/bwrap (real em bwrap.real)"
  /usr/bin/bwrap --version 2>/dev/null || echo "[patch] AVISO: wrapper /usr/bin/bwrap nao responde"
  # Configuracao original do bwrap: setuid root. Cobre o caso em que o
  # Ubiquity derrubou o UID por completo (saved=1000), onde nem o wrapper
  # consegue restaurar via seteuid: no exec, o kernel eleva o euid a 0.
  chmod 4755 /usr/bin/bwrap.real
  stat -c "[patch] bwrap.real modo: %a" /usr/bin/bwrap.real
  # Upgrades do pacote bubblewrap reinstalam o binario sem setuid; o hook
  # reaplica a permissao apos cada operacao do apt (o updater tambem
  # re-executa este script, redundancia proposital).
  printf '%s\n' 'DPkg::Post-Invoke { "chmod 4755 /usr/bin/bwrap.real 2>/dev/null || true"; };' > /etc/apt/apt.conf.d/99-mre-bwrap-setuid
  echo "[patch] Hook apt para manter setuid do bwrap.real instalado"
else
  echo "[patch] AVISO: sem /usr/bin/bwrap.real, mantido so o wrapper do compat/"
fi

echo "[patch] Todos os patches aplicados"