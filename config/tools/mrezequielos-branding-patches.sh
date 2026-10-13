#!/bin/bash
# Patches para corrigir branding no update-manager e crash no ubiquity
# Executado durante o build da ISO e nas atualizações

set -euo pipefail

echo "[patch] Aplicando patches de branding..."

# 1. Patch update-manager utils.py - retorna MrEzequielOS em vez de Ubuntu
UTILS_PY="/usr/lib/python3/dist-packages/UpdateManager/Core/utils.py"
if [ -f "$UTILS_PY" ]; then
    # Backup
    cp "$UTILS_PY" "$UTILS_PY.bak"
    
    # Usar Python para fazer a substituição de forma robusta
    python3 << 'PYEOF'
import re

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

content = content.replace(old_flavor_name, new_flavor_name)

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

content = content.replace(old_flavor, new_flavor)

with open("/usr/lib/python3/dist-packages/UpdateManager/Core/utils.py", "w") as f:
    f.write(content)

print("update-manager utils.py patchado")
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

content = content.replace(old, new)

with open("/usr/lib/ubiquity/plugins/ubi-wireless.py", "w") as f:
    f.write(content)

print("ubiquity ubi-wireless.py patchado")
PYEOF

else
    echo "[patch] AVISO: $UBI_WIRELESS não encontrado"
fi

# 3. Patch nmwidgets.py - get_state mais defensivo
NMWIDGETS="/usr/lib/ubiquity/ubiquity/frontend/gtk_components/nmwidgets.py"
if [ -f "$NMWIDGETS" ]; then
    cp "$NMWIDGETS" "$NMWIDGETS.bak"
    
    python3 << 'PYEOF'
with open("/usr/lib/ubiquity/ubiquity/frontend/gtk_components/nmwidgets.py", "r") as f:
    content = f.read()

old = """    def get_state(self):
        return self.view.get_state()"""

new = """    def get_state(self):
        if hasattr(self, "view") and self.view:
            return self.view.get_state()
        return 0"""

content = content.replace(old, new)

with open("/usr/lib/ubiquity/ubiquity/frontend/gtk_components/nmwidgets.py", "w") as f:
    f.write(content)

print("nmwidgets.py patchado")
PYEOF

else
    echo "[patch] AVISO: $NMWIDGETS não encontrado"
fi

echo "[patch] Todos os patches aplicados"