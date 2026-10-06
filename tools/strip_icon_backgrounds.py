"""Verwijdert grijze/pastel vlakken achter iconen (Instructeur-app-stijl:
alleen het icoon, in AppColors.iconPrimary). Zoekt `Container(` /
`AnimatedContainer(`-blokken waarvan de decoration alleen een neutrale vulling
(+ evt. radius/rand) heeft en waarvan het kind direct een Icon is."""
import os, re, sys
ROOT = os.path.join(os.path.dirname(__file__), '..', 'lib')
GRAYS = ['AppColors.neutralBg', 'AppColors.iconPrimaryBg', 'AppColors.iconNeutralBg',
         'AppColors.iconBlueBg', 'AppColors.iconGreenBg', 'AppColors.iconRedBg',
         'AppColors.iconOrangeBg', 'AppColors.borderLight', 'AppColors.surface',
         'Color(0xFFF1F1F1)', 'Color(0xFFF4F5F7)', 'Color(0xFFF0F2F5)', 'AppColors.primaryLight']
MUTED = ['AppColors.textSecondary', 'AppColors.textHint', 'AppColors.iconDark',
         'Color(0xFF475569)', 'const Color(0xFF475569)', 'AppColors.iconBlue', 'AppColors.iconGreen',
         'AppColors.iconPurple', 'AppColors.iconOrange', 'AppColors.iconTeal', 'AppColors.iconAmber',
         'AppColors.iconSlate', 'AppColors.primary', 'AppColors.textPrimary']

def block_end(s, i):
    """i wijst naar '('; geeft index na de bijbehorende ')'."""
    depth = 0
    for j in range(i, len(s)):
        c = s[j]
        if c == '(':
            depth += 1
        elif c == ')':
            depth -= 1
            if depth == 0:
                return j + 1
    return -1

def process(s):
    out = []
    pos = 0
    count = 0
    for m in re.finditer(r'\b(Container|AnimatedContainer)\(', s):
        if m.start() < pos:
            continue
        open_i = m.end() - 1
        end = block_end(s, open_i)
        body = s[open_i + 1:end - 1]
        dm = re.search(r'decoration: (?:const )?BoxDecoration\(', body)
        if not dm:
            continue
        d_open = dm.end() - 1
        d_end = block_end(body, d_open)
        deco = body[d_open + 1:d_end - 1]
        cm = re.search(r'color: (?:const )?([^,\n]+?),', deco)
        if not cm or cm.group(1).strip() not in [g.replace('const ', '') for g in GRAYS]:
            continue
        # decoration mag alleen kleur / radius / vorm / rand bevatten
        rest = re.sub(r'border: Border\.all\((?:[^()]|\([^()]*\))*\),', '', deco)
        rest = re.sub(r'color: [^,\n]+,', '', rest)
        rest = re.sub(r'borderRadius:\s*BorderRadius\.circular\([^)]*\),', '', rest)
        rest = re.sub(r'shape: BoxShape\.\w+,', '', rest)
        if rest.strip():
            continue
        after = body[d_end:]
        # kind moet direct een Icon zijn (evt. via Center)
        km = re.search(r'child: (?:const )?(?:Center\(\s*child: (?:const )?)?Icon\(', after)
        if not km or after[:km.start()].strip(' ,\n') != '':
            continue
        # decoration-regel verwijderen
        dline_start = body.rfind('\n', 0, dm.start()) + 1
        new_body = body[:dline_start] + body[d_end:].lstrip(',').lstrip('\n')
        # icoonkleur naar iconPrimary (statuskleuren blijven)
        def recolor(t):
            for mu in MUTED:
                t = t.replace(f'color: {mu},', 'color: AppColors.iconPrimary,').replace(f'color: {mu})', 'color: AppColors.iconPrimary)')
            return t
        new_body = recolor(new_body)
        out.append(s[pos:open_i + 1] + new_body + ')')
        pos = end
        count += 1
    out.append(s[pos:])
    return ''.join(out), count

total = 0
for dp, _, fs in os.walk(ROOT):
    for f in fs:
        if not f.endswith('.dart') or f in ('main_scaffold.dart', 'app_error_banner.dart', 'toast.dart'):
            continue
        p = os.path.join(dp, f)
        s = open(p).read()
        n, c = process(s)
        if c:
            open(p, 'w').write(n)
            total += c
            print(os.path.relpath(p, ROOT), c)
print('totaal', total)
