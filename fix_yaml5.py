import sys

with open('.github/workflows/build-iso.yml', 'r') as f:
    content = f.read()

lines = content.split('\n')

# Find the start and end of the validation block
start_idx = None
end_idx = None
for i, line in enumerate(lines):
    if 'Validar nmwidgets' in line:
        start_idx = i
    if start_idx is not None and end_idx is None:
        if line.strip() == '' and i > start_idx + 5:
            end_idx = i
            break

print('start_idx:', start_idx, 'end_idx:', end_idx)

if start_idx is not None and end_idx is not None:
    # Just remove the validation step entirely - we'll add it to build-inside.sh instead
    del lines[start_idx:end_idx]
    content = '\n'.join(lines)
    with open('.github/workflows/build-iso.yml', 'w') as f:
        f.write(content)
    print('REMOVED validation step from workflow')
else:
    print('Could not find block')