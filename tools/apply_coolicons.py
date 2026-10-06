"""Vervangt Material `Icons.x` door `CoolIcons.y` in lib/ en voegt de import toe."""
import os, re, sys
sys.path.insert(0, os.path.dirname(__file__))
from coolicons_mapping import MAP

ROOT = os.path.join(os.path.dirname(__file__), '..', sys.argv[1] if len(sys.argv) > 1 else 'lib')
LIB = os.path.join(os.path.dirname(__file__), '..', 'lib')
pat = re.compile(r'(?<![A-Za-z0-9_])Icons\.([a-z0-9_]+)')
missing = set()
changed = 0
for dp, _, fs in os.walk(ROOT):
    for f in fs:
        if not f.endswith('.dart') or f == 'cool_icons.dart':
            continue
        p = os.path.join(dp, f)
        s = open(p).read()
        def rep(m):
            name = m.group(1)
            if name in MAP:
                return 'CoolIcons.' + MAP[name]
            missing.add(name)
            return m.group(0)
        n = pat.sub(rep, s)
        if n != s:
            if "cool_icons.dart'" not in n:
                if os.path.abspath(ROOT) == os.path.abspath(LIB):
                    rel = os.path.relpath(os.path.join(LIB, 'core', 'constants', 'cool_icons.dart'), dp)
                    imp = f"import '{rel}';\n"
                else:
                    imp = "import 'package:leerling_app/core/constants/cool_icons.dart';\n"
                # na de laatste import-regel invoegen
                lines = n.split('\n')
                last = max(i for i, l in enumerate(lines) if l.startswith('import '))
                lines.insert(last + 1, imp.rstrip('\n'))
                n = '\n'.join(lines)
            # `const Icon(CoolIcons.x)` blijft geldig (IconData is const)
            open(p, 'w').write(n)
            changed += 1
print('gewijzigd:', changed, 'niet gemapt:', sorted(missing))
