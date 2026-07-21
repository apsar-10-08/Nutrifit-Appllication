import json
import os
import glob

for arb_file in glob.glob(r'c:\project\NutriFit_Flutter_Supabase\lib\l10n\*.arb'):
    with open(arb_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    if 'continue' in data:
        data['continueKey'] = data.pop('continue')
        
    with open(arb_file, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)

print("Fixed continue keyword.")
