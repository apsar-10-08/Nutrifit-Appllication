with open(r'c:\project\NutriFit_Flutter_Supabase\lib\main.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()
with open(r'c:\project\NutriFit_Flutter_Supabase\scratch\search_results.txt', 'w', encoding='utf-8') as out:
    for i, line in enumerate(lines):
        if any(w in line.lower() for w in ['language', 'english', 'tamil', 'lang']):
            out.write(f"{i+1}: {line}")
