import re
import os
import json

def main():
    with open(r'c:\project\NutriFit_Flutter_Supabase\lib\main.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # Find all Text('...') and label: '...' and hintText: '...'
    # This is a naive regex but it gives us an idea.
    text_matches = re.findall(r"Text\(\s*'([^']+)'\s*\)", content)
    label_matches = re.findall(r"(?:label|hintText|title)\s*:\s*'([^']+)'", content)
    t_matches = re.findall(r"c\.t\(\s*'([^']+)'\s*\)", content)
    
    all_strings = set(text_matches + label_matches + t_matches)
    
    # Filter out empty strings or those with interpolations $
    all_strings = {s for s in all_strings if not '$' in s and len(s) > 1}
    
    print(f"Found {len(all_strings)} unique strings.")
    
    arb_data = {}
    for s in sorted(all_strings):
        # Create a key
        key = re.sub(r'[^a-zA-Z0-9]', '', s.title())
        key = key[0].lower() + key[1:] if key else 'empty'
        arb_data[key] = s
        
    os.makedirs(r'c:\project\NutriFit_Flutter_Supabase\lib\l10n', exist_ok=True)
    with open(r'c:\project\NutriFit_Flutter_Supabase\lib\l10n\app_en.arb', 'w', encoding='utf-8') as f:
        json.dump(arb_data, f, indent=2, ensure_ascii=False)

if __name__ == '__main__':
    main()
