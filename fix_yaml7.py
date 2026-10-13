import sys

with open('.github/workflows/build-iso.yml', 'r') as f:
    content = f.read()

# Find the CHROOT OK line inside the build-inside.sh heredoc
old = '''          apt clean
          rm -rf /tmp/* /var/tmp/* /var/log/* /var/cache/debconf/*-old /root/.cache
          rm -f /etc/resolv.conf /etc/machine-id /var/lib/dbus/machine-id
          echo "=== CHROOT OK ==="
          EOF'''

new = '''          apt clean
          rm -rf /tmp/* /var/tmp/* /var/log/* /var/cache/debconf/*-old /root/.cache
          rm -f /etc/resolv.conf /etc/machine-id /var/lib/dbus/machine-id
          echo "=== Validando nmwidgets.py ==="
          python3 << 'PYEOF'
import sys
sys.path.insert(0, '/usr/lib/ubiquity')
from ubiquity.frontend.gtk_components import nmwidgets
print('nmwidgets.py OK - sem erro de sintaxe')
PYEOF
          echo "=== CHROOT OK ==="
          EOF'''

if old in content:
    content = content.replace(old, new)
    with open('.github/workflows/build-iso.yml', 'w') as f:
        f.write(content)
    print('ADDED validation to build-inside.sh')
else:
    print('NOT FOUND')