import json
import re
import os

def apply_l10n():
    arb_path = r'c:\project\NutriFit_Flutter_Supabase\lib\l10n\app_en.arb'
    dart_path = r'c:\project\NutriFit_Flutter_Supabase\lib\main.dart'

    with open(arb_path, 'r', encoding='utf-8') as f:
        arb = json.load(f)

    # Reverse map: string -> key
    str_to_key = {v: k for k, v in arb.items() if not k.startswith('@')}

    with open(dart_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add imports
    if "import 'package:flutter_gen/gen_l10n/app_localizations.dart';" not in content:
        content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:flutter_localizations/flutter_localizations.dart';\nimport 'package:flutter_gen/gen_l10n/app_localizations.dart';")

    # Replace strings
    for string_val, key in str_to_key.items():
        # Escape string for regex
        escaped_str = re.escape(string_val)
        
        # Replace Text('...')
        content = re.sub(rf"Text\(\s*'{escaped_str}'\s*\)", rf"Text(AppLocalizations.of(context)!.{key})", content)
        content = re.sub(rf'Text\(\s*"{escaped_str}"\s*\)', rf"Text(AppLocalizations.of(context)!.{key})", content)

        # Replace label: '...'
        content = re.sub(rf"(label|hintText|title)\s*:\s*'{escaped_str}'", rf"\1: AppLocalizations.of(context)!.{key}", content)
        content = re.sub(rf'(label|hintText|title)\s*:\s*"{escaped_str}"', rf"\1: AppLocalizations.of(context)!.{key}", content)

    # Strip const from common layout widgets to prevent invalid constant errors
    for widget in ['Text', 'Row', 'Column', 'Padding', 'Center', 'SizedBox', 'Container', 'ListTile', 'Card', 'Icon', 'CircleAvatar']:
        content = re.sub(rf"const\s+{widget}\(", rf"{widget}(", content)

    with open(dart_path, 'w', encoding='utf-8') as f:
        f.write(content)

    print("Applied localization strings to main.dart.")

if __name__ == '__main__':
    apply_l10n()
