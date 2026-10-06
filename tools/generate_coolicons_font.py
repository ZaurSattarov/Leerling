"""Bouwt assets/fonts/CoolIcons.ttf + lib/core/constants/cool_icons.dart uit de
coolicons-zip (assets/coolicons _ Free Iconset (Community).zip).

Alle coolicons zijn streek-paden (stroke 2, ronde caps/joins op een 24x24 grid).
Het script zet de streken om naar vlakken (skia-pathops), bouwt een TrueType-font
en genereert een Dart-klasse met IconData-constanten.

Gebruik (vanuit de Leerling-root):
    pip install fonttools skia-pathops
    python tools/generate_coolicons_font.py
"""
import re
import sys
import zipfile
from pathlib import Path

import pathops
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.svgLib.path import parse_path

ROOT = Path(__file__).resolve().parent.parent
ZIP = ROOT / 'assets' / 'coolicons _ Free Iconset (Community).zip'
OUT_FONT = ROOT / 'assets' / 'fonts' / 'CoolIcons.ttf'
OUT_DART = ROOT / 'lib' / 'core' / 'constants' / 'cool_icons.dart'

UPM = 1000
ASCENT = 800
DESCENT = 200
SCALE = UPM / 24.0
STROKE = 2.0 * SCALE
FIRST_CODEPOINT = 0xE000


def camel(name: str) -> str:
    parts = [p for p in re.split(r'[_\W]+', name) if p]
    out = parts[0].lower() + ''.join(p[:1].upper() + p[1:].lower() for p in parts[1:])
    if out[0].isdigit():
        out = 'i' + out
    return out


def glyph_from_svg(svg: str):
    ds = re.findall(r'<path[^>]*?\sd="([^"]+)"', svg)
    if not ds:
        raise ValueError('geen path')
    combined = pathops.Path()
    for d in ds:
        stroke_path = pathops.Path()
        # y-flip + schaal: SVG (0,0 linksboven) -> font (baseline onderaan)
        tpen = TransformPen(stroke_path.getPen(), (SCALE, 0, 0, -SCALE, 0, ASCENT))
        parse_path(d, tpen)
        stroke_path.stroke(STROKE, pathops.LineCap.ROUND_CAP,
                           pathops.LineJoin.ROUND_JOIN, 4)
        stroke_path.convertConicsToQuads(0.1)
        combined.addPath(stroke_path) if hasattr(combined, 'addPath') else combined.__iadd__(stroke_path)
    try:
        combined.simplify(fix_winding=True, keep_starting_points=False)
    except pathops.PathOpsError:
        # Afronden op hele font-eenheden lost degeneratie in de stroke op.
        rounded = pathops.Path()
        pen = rounded.getPen()
        for verb, pts in combined.segments:
            pts = [(round(x), round(y)) for x, y in pts]
            getattr(pen, {'moveTo': 'moveTo', 'lineTo': 'lineTo', 'qCurveTo': 'qCurveTo',
                          'curveTo': 'curveTo', 'closePath': 'closePath'}[verb])(*pts)
        combined = rounded
        combined.simplify(fix_winding=True, keep_starting_points=False)
    tt = TTGlyphPen(None)
    combined.draw(Cu2QuPen(tt, max_err=0.8, reverse_direction=True))
    glyph = tt.glyph()
    # lsb moet gelijk zijn aan xMin, anders verschuift FreeType het icoon.
    glyph.recalcBounds(None)
    return glyph, int(glyph.xMin)


def main():
    icons = []  # (dartnaam, glyphnaam, categorie, bestandsnaam, glyph)
    with zipfile.ZipFile(ZIP) as zf:
        for info in sorted(zf.infolist(), key=lambda i: i.filename):
            if not info.filename.lower().endswith('.svg'):
                continue
            parts = Path(info.filename).parts
            cat, stem = parts[-2], Path(parts[-1]).stem
            glyph, lsb = glyph_from_svg(zf.read(info).decode('utf-8'))
            icons.append([camel(stem), cat, stem, glyph, lsb])

    # Eigen aanvullingen in dezelfde stijl (komen NA de coolicons, zodat bestaande
    # codepoints stabiel blijven): tools/extra_icons/*.svg
    for extra in sorted((ROOT / 'tools' / 'extra_icons').glob('*.svg')):
        glyph, lsb = glyph_from_svg(extra.read_text(encoding='utf-8'))
        icons.append([camel(extra.stem), 'Extra', extra.stem, glyph, lsb])

    seen = {}
    for ic in icons:
        seen.setdefault(ic[0], []).append(ic)
    for name, group in seen.items():
        if len(group) > 1:
            for ic in group:
                ic[0] = camel(ic[1] + '_' + ic[2])

    glyph_order = ['.notdef'] + [f'ci{i:04d}' for i in range(len(icons))]
    cmap = {FIRST_CODEPOINT + i: f'ci{i:04d}' for i in range(len(icons))}
    glyphs = {'.notdef': TTGlyphPen(None).glyph()}
    for i, ic in enumerate(icons):
        glyphs[f'ci{i:04d}'] = ic[3]

    fb = FontBuilder(UPM, isTTF=True)
    fb.setupGlyphOrder(glyph_order)
    fb.setupCharacterMap(cmap)
    fb.setupGlyf(glyphs)
    metrics = {'.notdef': (UPM, 0)}
    for i, ic in enumerate(icons):
        metrics[f'ci{i:04d}'] = (UPM, ic[4])
    fb.setupHorizontalMetrics(metrics)
    fb.setupHorizontalHeader(ascent=ASCENT, descent=-DESCENT)
    fb.setupNameTable({'familyName': 'CoolIcons', 'styleName': 'Regular'})
    fb.setupOS2(sTypoAscender=ASCENT, sTypoDescender=-DESCENT, usWinAscent=ASCENT,
                usWinDescent=DESCENT, sTypoLineGap=0)
    fb.setupPost()
    OUT_FONT.parent.mkdir(parents=True, exist_ok=True)
    fb.save(str(OUT_FONT))

    lines = [
        '// GENERATED door tools/generate_coolicons_font.py -- niet handmatig bewerken.',
        '// Bron: coolicons (https://coolicons.cool, CC BY 4.0).',
        "import 'package:flutter/widgets.dart';",
        '',
        '/// Centrale icoonset (coolicons) als lettertype: werkt overal waar een',
        '/// [IconData] verwacht wordt, kleur en grootte zoals bij gewone iconen.',
        'class CoolIcons {',
        '  const CoolIcons._();',
        '',
        "  static const String _family = 'CoolIcons';",
        '',
    ]
    for i, ic in enumerate(icons):
        lines.append(f'  /// {ic[1]} / {ic[2]}')
        lines.append(f'  static const IconData {ic[0]} =')
        lines.append(f"      IconData(0x{FIRST_CODEPOINT + i:04x}, fontFamily: _family);")
    lines.append('}')
    OUT_DART.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    print(f'{len(icons)} iconen -> {OUT_FONT.name}, {OUT_DART.name}')


if __name__ == '__main__':
    sys.exit(main())
