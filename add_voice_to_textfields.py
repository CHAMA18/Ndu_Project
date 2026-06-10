#!/usr/bin/env python3
"""
Bulk-replace TextField → VoiceTextField and TextFormField → VoiceTextFormField
across the Ndu_Project Flutter codebase.

Rules:
- Skip files that already use VoiceTextField/VoiceTextFormField
- Skip widget definition files (the voice_text_field.dart itself)
- Skip import lines
- Replace TextField( → VoiceTextField( and TextFormField( → VoiceTextFormField(
- Add the import for voice_text_field.dart to each modified file
- Do NOT replace if the line starts with 'import' or 'class ' or 'abstract '
- Do NOT replace inside comments
- Skip password/obscureText fields (will set enableVoice: false)
"""

import os
import re
import sys

PROJECT_DIR = '/home/z/my-project/Ndu_Project/lib'
VOICE_IMPORT = "import 'package:ndu_project/widgets/voice_text_field.dart';"

# Files to skip entirely
SKIP_FILES = {
    'voice_text_field.dart',
    'expanding_text_field.dart',
    'ai_suggesting_textfield.dart',
    'inline_editable_text.dart',
}

# Patterns to skip (password fields, obscure text)
OBSOLETE_PATTERNS = [
    r'obscureText\s*:\s*true',
]

def should_skip_file(filepath):
    """Check if file should be skipped entirely."""
    basename = os.path.basename(filepath)
    if basename in SKIP_FILES:
        return True
    return False

def has_obscure_text_nearby(lines, line_idx, window=5):
    """Check if obscureText: true is near this line (within window lines)."""
    start = max(0, line_idx - window)
    end = min(len(lines), line_idx + window + 1)
    for i in range(start, end):
        if re.search(r'obscureText\s*:\s*true', lines[i]):
            return True
    return False

def process_file(filepath):
    """Process a single file, replacing TextField/TextFormField with voice versions."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    
    # Check if file already has voice imports
    has_voice_import = VOICE_IMPORT in content
    
    # Check if file has any TextField or TextFormField to replace
    has_textfield = bool(re.search(r'\bTextField\(', content))
    has_textformfield = bool(re.search(r'\bTextFormField\(', content))
    
    if not has_textfield and not has_textformfield:
        return False
    
    lines = content.split('\n')
    new_lines = []
    modified = False
    
    for i, line in enumerate(lines):
        stripped = line.strip()
        
        # Skip import lines
        if stripped.startswith('import '):
            new_lines.append(line)
            continue
        
        # Skip class definitions
        if stripped.startswith('class ') or stripped.startswith('abstract '):
            new_lines.append(line)
            continue
        
        # Skip comments
        if stripped.startswith('//') or stripped.startswith('/*') or stripped.startswith('*'):
            new_lines.append(line)
            continue
        
        # Skip if inside a string (simple heuristic)
        if stripped.startswith("'") or stripped.startswith('"'):
            new_lines.append(line)
            continue
        
        # Replace TextField( with VoiceTextField(
        if re.search(r'\bTextField\(', line):
            # Check for obscureText nearby
            is_obscure = has_obscure_text_nearby(lines, i)
            
            # Replace the occurrence
            new_line = re.sub(r'\bTextField\(', 'VoiceTextField(', line)
            
            # If obscure text field, add enableVoice: false after the opening
            if is_obscure:
                # Find the position right after VoiceTextField(
                idx = new_line.find('VoiceTextField(')
                if idx != -1:
                    insert_pos = idx + len('VoiceTextField(')
                    new_line = new_line[:insert_pos] + '\n        enableVoice: false,' + new_line[insert_pos:]
            
            new_lines.append(new_line)
            modified = True
            continue
        
        # Replace TextFormField( with VoiceTextFormField(
        if re.search(r'\bTextFormField\(', line):
            is_obscure = has_obscure_text_nearby(lines, i)
            
            new_line = re.sub(r'\bTextFormField\(', 'VoiceTextFormField(', line)
            
            if is_obscure:
                idx = new_line.find('VoiceTextFormField(')
                if idx != -1:
                    insert_pos = idx + len('VoiceTextFormField(')
                    new_line = new_line[:insert_pos] + '\n        enableVoice: false,' + new_line[insert_pos:]
            
            new_lines.append(new_line)
            modified = True
            continue
        
        new_lines.append(line)
    
    if not modified:
        return False
    
    # Add import if needed
    content = '\n'.join(new_lines)
    
    if not has_voice_import:
        # Find the last import line and add after it
        import_lines = []
        other_lines = []
        in_imports = True
        for line in content.split('\n'):
            if in_imports and line.strip().startswith('import '):
                import_lines.append(line)
            else:
                if in_imports and line.strip() == '':
                    import_lines.append(line)
                else:
                    in_imports = False
                    other_lines.append(line)
        
        # Add our import at the end of import block
        import_lines.append(VOICE_IMPORT)
        content = '\n'.join(import_lines + other_lines)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    return True

def main():
    modified_count = 0
    skipped_count = 0
    
    for root, dirs, files in os.walk(PROJECT_DIR):
        for filename in files:
            if not filename.endswith('.dart'):
                continue
            
            filepath = os.path.join(root, filename)
            
            if should_skip_file(filepath):
                skipped_count += 1
                continue
            
            try:
                if process_file(filepath):
                    modified_count += 1
                    rel_path = os.path.relpath(filepath, PROJECT_DIR)
                    print(f'  Modified: {rel_path}')
            except Exception as e:
                print(f'  ERROR processing {filepath}: {e}')
    
    print(f'\nSummary:')
    print(f'  Modified: {modified_count} files')
    print(f'  Skipped:  {skipped_count} files')

if __name__ == '__main__':
    main()
