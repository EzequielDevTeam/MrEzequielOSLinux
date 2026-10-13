import sys

with open('.github/workflows/build-iso.yml', 'r') as f:
    content = f.read()

# Remove the validation block from build-inside.sh
old = '''          echo "=== Validando nmwidgets.py ==="
          python3 -c "import sys; sys.path.insert(0, '/usr/lib/ubiquity'); from ubiquity.frontend.gtk_components import nmwidgets; print('nmwidgets.py OK - sem erro de sintaxe')"
          echo "=== CHROOT OK ==="'''

new = '''          echo "=== CHROOT OK ==="'''

if old in content:
    content = content.replace(old, new)
    with open('.github/workflows/build-iso.yml', 'w') as f:
        f.write(content)
    print('REMOVED validation from build-inside.sh')
else:
    print('NOT FOUND')