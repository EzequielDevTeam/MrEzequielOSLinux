import sys

with open('.github/workflows/build-iso.yml', 'r') as f:
    content = f.read()

# Find the problematic python3 -c block
old = '''          echo "=== Validando nmwidgets.py ==="
          python3 -c "
import sys
sys.path.insert(0, '/usr/lib/ubiquity')
from ubiquity.frontend.gtk_components import nmwidgets
print('nmwidgets.py OK - sem erro de sintaxe')
"
          echo "=== CHROOT OK ==="'''

new = '''          echo "=== Validando nmwidgets.py ==="
          python3 -c "import sys; sys.path.insert(0, '/usr/lib/ubiquity'); from ubiquity.frontend.gtk_components import nmwidgets; print('nmwidgets.py OK - sem erro de sintaxe')"
          echo "=== CHROOT OK ==="'''

if old in content:
    content = content.replace(old, new)
    with open('.github/workflows/build-iso.yml', 'w') as f:
        f.write(content)
    print('FIXED python3 -c to one-liner')
else:
    print('NOT FOUND - trying alternative')
    # Try with slightly different spacing
    for i, line in enumerate(content.split('\n')):
        if 'Validando nmwidgets' in line:
            print(f'Line {i}: {repr(line)}')
            for j in range(i, min(i+10, len(content.split('\n')))):
                print(f'Line {i+j}: {repr(content.split(chr(10))[i+j])}')