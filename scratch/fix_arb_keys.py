import json
import os
import glob
import re

for arb_file in glob.glob(r'c:\project\NutriFit_Flutter_Supabase\lib\l10n\*.arb'):
    with open(arb_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    new_data = {}
    for k, v in data.items():
        new_k = k
        if re.match(r'^\d', k):
            new_k = 'num' + k
        new_data[new_k] = v
        
    with open(arb_file, 'w', encoding='utf-8') as f:
        json.dump(new_data, f, indent=2, ensure_ascii=False)

print("Fixed ARB keys.")
