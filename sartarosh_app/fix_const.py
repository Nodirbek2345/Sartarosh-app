import re

with open('analyze.txt', 'r', encoding='utf-8') as f:
    lines = f.readlines()

files_and_lines = {}
for line in lines:
    if 'invalid_constant' in line:
        parts = line.split(' - ')
        if len(parts) >= 2:
            path_info = parts[-2].strip()
            # The path could look like: lib\app\modules\...\add_barber_view.dart:83:22
            subparts = path_info.split(':')
            if len(subparts) >= 2:
                file_path = subparts[0].strip()
                line_no = int(subparts[1])
                files_and_lines.setdefault(file_path, []).append(line_no)

for file_path, lines_arr in files_and_lines.items():
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.readlines()
        
        changed = False
        for l in lines_arr:
            idx = l - 1
            if idx < len(content):
                # Replace the LAST occurrence of 'const ' on the line, or the first one. Let's just remove the first one.
                new_line = re.sub(r'\bconst\s+', '', content[idx], count=1)
                if new_line != content[idx]:
                    content[idx] = new_line
                    changed = True
        
        if changed:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.writelines(content)
            print(f'Fixed {file_path}')
    except Exception as e:
        print(f'Failed {file_path}: {e}')
