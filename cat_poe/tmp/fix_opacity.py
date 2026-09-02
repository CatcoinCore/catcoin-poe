import os
import re

# Directory to search
lib_dir = "lib"

# Pattern to find withOpacity(0.X) or withOpacity(any_variable)
# Matches: .withOpacity(anything_inside)
pattern = re.compile(r'\.withOpacity\((.*?)\)')

def migrate_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace .withOpacity(x) with .withValues(alpha: x)
    new_content = pattern.sub(r'.withValues(alpha: \1)', content)
    
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Migrated: {filepath}")

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart"):
            migrate_file(os.path.join(root, file))
