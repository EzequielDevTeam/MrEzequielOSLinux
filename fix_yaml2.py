import sys

with open('.github/workflows/build-iso.yml', 'r') as f:
    content = f.read()

old = """      - name: Validar nmwidgets.py (sem IndentationError)
        run: |
          sudo chroot chroot bash -c '
            python3 -c "
import sys
sys.path.insert(0, \"\"/usr/lib/ubiquity\"\")
from ubiquity.frontend.gtk_components import nmwidgets
print(\"\"nmwidgets.py OK - sem erro de sintaxe\"\"")
"
          ' 2>&1"""

new = """      - name: Validar nmwidgets.py (sem IndentationError)
        run: |
          sudo chroot chroot bash <<'EOF'
python3 -c "
import sys
sys.path.insert(0, '/usr/lib/ubiquity')
from ubiquity.frontend.gtk_components import nmwidgets
print('nmwidgets.py OK - sem erro de sintaxe')
"
EOF"""

if old in content:
    content = content.replace(old, new)
    with open('.github/workflows/build-iso.yml', 'w') as f:
        f.write(content)
    print('REPLACED')
else:
    print('NOT FOUND')
    # Find exact match
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if 'Validar nmwidgets' in line:
            print('Found at line', i)
            # Print next 10 lines
            for j in range(i, min(i+12, len(lines))):
                print(repr(lines[j]))

# Also try without the 2>&1 at the end
old2 = """      - name: Validar nmwidgets.py (sem IndentationError)
        run: |
          sudo chroot chroot bash -c '
            python3 -c "
import sys
sys.path.insert(0, \"\"/usr/lib/ubiquity\"\")
from ubiquity.frontend.gtk_components import nmwidgets
print(\"\"nmwidgets.py OK - sem erro de sintaxe\"\"")
"
          '"""

if old2 in content:
    content = content.replace(old2, new)
    with open('.github/workflows/build-iso.yml', 'w') as f:
        f.write(content)
    print('REPLACED with old2')