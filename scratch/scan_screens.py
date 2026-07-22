import re
import os

def scan_project():
    dart_files = []
    for root, dirs, files in os.walk("lib"):
        for f in files:
            if f.endswith(".dart"):
                dart_files.append(os.path.join(root, f))
    
    classes = []
    screens = []
    
    for df in dart_files:
        with open(df, "r", encoding="utf-8") as f:
            content = f.read()
        
        # Match class ClassName extends ...
        found_classes = re.findall(r'class\s+([A-Za-z0-9_]+)\s+extends\s+([A-Za-z0-9_]+)', content)
        for cls, base in found_classes:
            classes.append((cls, base, df))
            if base in ["StatelessWidget", "StatefulWidget", "ConsumerWidget", "HookWidget", "State"]:
                screens.append(cls)

    print(f"Total Dart files scanned: {len(dart_files)}")
    print(f"Total classes extending Widget/State: {len(screens)}")
    print("\nAll Widget/State Classes:")
    for s in sorted(set(screens)):
        print(f" - {s}")

if __name__ == "__main__":
    scan_project()
