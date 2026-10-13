import sys

with open('.github/workflows/build-iso.yml', 'r') as f:
    content = f.read()

lines = content.split('\n')

# Find the start and end of the block to replace
start_idx = None
end_idx = None
for i, line in enumerate(lines):
    if 'Validar nmwidgets' in line:
        start_idx = i
    if start_idx is not None and end_idx is None:
        if line.strip() == '' and i > start_idx + 8:
            end_idx = i
            break

print('start_idx:', start_idx, 'end_idx:', end_idx)

if start_idx is not None and end_idx is not None:
    # Replace lines[start_idx:end_idx] with new block - write script to file then run
    new_lines = [
        '      - name: Validar nmwidgets.py (sem IndentationError)',
        '        run: |',
        '          sudo chroot chroot bash -c \'',
        '            cat > /tmp/check_nmwidgets.py << "PYEOF"',
        'import sys',
        "sys.path.insert(0, '/usr/lib/ubiquity')",
        "from ubiquity.frontend.gtk_components import nmwidgets",
        "print('nmwidgets.py OK - sem erro de sintaxe')",
        'PYEOF',
        '            python3 /tmp/check_nmwidgets.py',
        "          '"
    ]
    # Replace
    lines[start_idx:end_idx] = new_lines
    content = '\n'.join(lines)
    with open('.github/workflows/build-iso.yml', 'w') as f:
        f.write(content)
    print('REPLACED lines', start_idx, 'to', end_idx)
else:
    print('Could not find block')