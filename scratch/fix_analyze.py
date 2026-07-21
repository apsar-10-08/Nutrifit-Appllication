import re

def fix_analyze():
    with open(r'c:\project\NutriFit_Flutter_Supabase\lib\main.dart', 'r', encoding='utf-8') as f:
        content = f.read()

    # Fix import
    content = content.replace("import 'package:flutter_gen/gen_l10n/app_localizations.dart';", "import 'l10n/app_localizations.dart';")

    # Fix _warmupExercises
    content = content.replace('final _warmupExercises = [', 'List<WarmupExercise> _warmupExercises(BuildContext context) => [')
    content = content.replace('_warmupExercises.asMap()', '_warmupExercises(context).asMap()')
    content = content.replace('_warmupExercises.length', '_warmupExercises(context).length')
    content = content.replace('_warmupExercises[index]', '_warmupExercises(context)[index]')

    # Fix const [ ... AppLocalizations.of(context) ... ]
    # We can just blindly replace "const [" with "[" for DropdownMenuItem
    content = content.replace('items:const [DropdownMenuItem', 'items: [DropdownMenuItem')

    # Fix specific segment button const
    content = content.replace('segments:const [ButtonSegment', 'segments: [ButtonSegment')

    # Any other const [...] containing AppLocalizations
    # This regex looks for const [...] containing AppLocalizations and removes const
    def replace_const_list(match):
        return match.group(0).replace('const [', '[')
    
    content = re.sub(r'const\s*\[[^\]]+AppLocalizations[^\]]+\]', replace_const_list, content)

    with open(r'c:\project\NutriFit_Flutter_Supabase\lib\main.dart', 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_analyze()
