import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../splash_phase_animations.dart';

/// Het Leerling-merkteken ("Behaald") dat zichzelf opbouwt.
///
/// Drie witte blokken (de basis: instructeur, lessen, oefening), één roze
/// blok (de leerling) en een wit hoekje in dat roze blok (het doel: het
/// rijbewijs). Elk onderdeel is een eigen SVG op hetzelfde 256x256-canvas,
/// zodat ze gestapeld exact het app-icoon vormen.
class SplashLogoMark extends StatelessWidget {
  static const _dir = 'assets/Splash Screen';

  final Key elementKey;
  final double size;
  final SplashPhaseAnimations phases;

  const SplashLogoMark({
    required this.elementKey,
    required this.size,
    required this.phases,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Eén eenheid van het 256-canvas; blokken zijn 72 eenheden, het doel 36.
    final u = size / 256;

    return RepaintBoundary(
      key: elementKey,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _MarkPiece(
              pieceKey: const ValueKey('splash-mark-wit-linksboven'),
              assetPath: '$_dir/leerling_mark_wit_linksboven.svg',
              size: size,
              appear: phases.markTopLeft,
              from: Offset(-18.7 * u, -18.7 * u),
              scaleFrom: 0.82,
              origin: const Alignment(-0.344, -0.344),
            ),
            _MarkPiece(
              pieceKey: const ValueKey('splash-mark-wit-linksonder'),
              assetPath: '$_dir/leerling_mark_wit_linksonder.svg',
              size: size,
              appear: phases.markBottomLeft,
              from: Offset(-18.7 * u, 18.7 * u),
              scaleFrom: 0.82,
              origin: const Alignment(-0.344, 0.344),
            ),
            _MarkPiece(
              pieceKey: const ValueKey('splash-mark-wit-rechtsonder'),
              assetPath: '$_dir/leerling_mark_wit_rechtsonder.svg',
              size: size,
              appear: phases.markBottomRight,
              from: Offset(18.7 * u, 18.7 * u),
              scaleFrom: 0.82,
              origin: const Alignment(0.344, 0.344),
            ),
            _MarkPiece(
              pieceKey: const ValueKey('splash-mark-roze'),
              assetPath: '$_dir/leerling_mark_roze.svg',
              size: size,
              appear: phases.markStudent,
              from: Offset(-43.2 * u, 43.2 * u),
              scaleFrom: 0.7,
              origin: const Alignment(0.344, -0.344),
            ),
            _MarkPiece(
              pieceKey: const ValueKey('splash-mark-doel'),
              assetPath: '$_dir/leerling_mark_doel.svg',
              size: size,
              appear: phases.markGoal,
              from: Offset(25.2 * u, -25.2 * u),
              scaleFrom: 0.4,
              origin: const Alignment(0.531, -0.531),
            ),
          ],
        ),
      ),
    );
  }
}

/// Eén onderdeel van het merkteken: schuift vanaf [from] naar zijn plek en
/// schaalt rond zijn eigen middelpunt ([origin]) van [scaleFrom] naar 1.
class _MarkPiece extends StatelessWidget {
  final Key pieceKey;
  final String assetPath;
  final double size;
  final Animation<double> appear;
  final Offset from;
  final double scaleFrom;
  final Alignment origin;

  const _MarkPiece({
    required this.pieceKey,
    required this.assetPath,
    required this.size,
    required this.appear,
    required this.from,
    required this.scaleFrom,
    required this.origin,
  });

  @override
  Widget build(BuildContext context) {
    // Bewust niet clampen voor de transform: het doel-hoekje mag licht
    // uitschieten (veertje). Opacity wordt wel begrensd.
    final t = appear.value;

    return KeyedSubtree(
      key: pieceKey,
      child: Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: from * (1.0 - t),
          child: Transform.scale(
            scale: scaleFrom + (1.0 - scaleFrom) * t,
            alignment: origin,
            child: SvgPicture.asset(assetPath, width: size, height: size),
          ),
        ),
      ),
    );
  }
}
