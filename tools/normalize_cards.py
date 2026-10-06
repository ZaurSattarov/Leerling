"""Zet kaartstijlen in lib/ om naar het Klantio-design-systeem van de
Instructeur-app: wit vlak, 12px radius, 1px AppColors.border-rand, geen
schaduw; neutrale vlakken #F1F1F1 (AppColors.neutralBg)."""
import os, re
ROOT = os.path.join(os.path.dirname(__file__), '..', 'lib')
card = re.compile(
    r'(color: (?:AppColors\.white|AppColors\.cardBg|Colors\.white),\s*\n\s*)'
    r'borderRadius: BorderRadius\.circular\((?:14|16|18|20|22|24)\),(\s*\n\s*)'
    r'border: Border\.all\(\s*color: AppColors\.(?:border|borderLight)(?:,\s*width: [0-9.]+)?\s*,?\s*\),'
    r'(?:\s*\n\s*boxShadow: \[\s*BoxShadow\([^\]]*?\),\s*\],)?'
)
tap = re.compile(r'GestureDetector\(\s*\n(\s*)onTap: ([^,\n]+),\s*\n(\s*)child: Container\(')
stats = {}
SKIP = {'app_error_banner.dart'}
for dp, _, fs in os.walk(ROOT):
    for f in fs:
        if not f.endswith('.dart') or f in SKIP:
            continue
        p = os.path.join(dp, f)
        s = open(p).read()
        o = s
        s, n1 = card.subn(lambda m: m.group(1) + 'borderRadius: BorderRadius.circular(12),' + m.group(2) + 'border: Border.all(color: AppColors.border),', s)
        s = s.replace('Color(0xFFF0F2F5)', 'AppColors.neutralBg')
        s = s.replace('Color(0xFFE2E2E7)', 'AppColors.border')
        s = s.replace('const AppColors.neutralBg', 'AppColors.neutralBg').replace('const AppColors.border', 'AppColors.border')
        n2 = 0
        if n1:
            s, n2 = tap.subn(lambda m: 'KlantioPressable(\n' + m.group(1) + 'onTap: ' + m.group(2) + ',\n' + m.group(3) + 'child: Container(', s)
            if n2 and 'klantio_pressable.dart' not in s:
                rel = os.path.relpath(os.path.join(ROOT, 'shared', 'widgets', 'klantio_pressable.dart'), dp)
                lines = s.split('\n'); last = max(i for i, l in enumerate(lines) if l.startswith('import '))
                lines.insert(last + 1, f"import '{rel}';"); s = '\n'.join(lines)
        if s != o:
            open(p, 'w').write(s)
            stats[os.path.relpath(p, ROOT)] = (n1, n2)
for k, v in sorted(stats.items()):
    print(k, v)
