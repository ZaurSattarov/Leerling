"""Zet de kleur van losse Icon-widgets op AppColors.iconPrimary (#111827),
zoals in de Instructeur-app. Wit (op gekleurde vlakken) en statuskleuren
(success/danger/warning/info) blijven ongewijzigd."""
import os, re
ROOT = os.path.join(os.path.dirname(__file__), '..', 'lib')
MUTED = ['AppColors.textSecondary', 'AppColors.textHint', 'AppColors.iconDark', 'AppColors.textPrimary',
         'AppColors.iconBlue', 'AppColors.iconGreen', 'AppColors.iconPurple', 'AppColors.iconOrange',
         'AppColors.iconTeal', 'AppColors.iconAmber', 'AppColors.iconSlate', 'AppColors.iconRed',
         'AppColors.primary', 'AppColors.dark', 'AppColors.textMuted', 'Color(0xFF475569)',
         'Color(0xFF64748B)', 'Color(0xFF94A3B8)', 'Color(0xFF6B7280)', 'Color(0xFF9CA3AF)']
SKIP = {'main_scaffold.dart', 'toast.dart', 'app_error_banner.dart', 'isomorphic_icons.dart',
        'klantio_aurora_button.dart', 'social_login_widgets.dart', 'status_badge.dart',
        'main_tab_header.dart', 'main_detail_header.dart', 'home_header.dart', 'klantio_header.dart'}

def end_of(s, i):
    d = 0
    for j in range(i, len(s)):
        if s[j] == '(':
            d += 1
        elif s[j] == ')':
            d -= 1
            if d == 0:
                return j + 1
    return -1

total = 0
for dp, _, fs in os.walk(ROOT):
    for f in fs:
        if not f.endswith('.dart') or f in SKIP:
            continue
        p = os.path.join(dp, f)
        s = open(p).read()
        out, pos, n = [], 0, 0
        for m in re.finditer(r'(?<![A-Za-z_])Icon\(', s):
            if m.start() < pos:
                continue
            e = end_of(s, m.end() - 1)
            blk = s[m.start():e]
            nb = blk
            for c in MUTED:
                nb = re.sub(r'color:\s*(?:const )?' + re.escape(c) + r'(?=[,)\s])', 'color: AppColors.iconPrimary', nb)
            if nb != blk:
                n += 1
            out.append(s[pos:m.start()] + nb)
            pos = e
        out.append(s[pos:])
        ns = ''.join(out)
        if n:
            open(p, 'w').write(ns)
            total += n
print('iconen omgekleurd:', total)
