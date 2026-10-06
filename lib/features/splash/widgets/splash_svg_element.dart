import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Eén los splash-onderdeel: een bestaand SVG-asset, ongewijzigd getekend,
/// met zijn eigen fade/scale-appear-animatie, of met [wipe] een onthulling
/// van links naar rechts (zelfde als de Instructeur-app gebruikt voor het
/// woordmerk).
///
/// 1-op-1 dezelfde widget als de Instructeur-app
/// (rijschool-planner-flutter/lib/features/splash/widgets/splash_svg_element.dart).
/// Puur een aanstuur-wrapper -- er wordt niets in de SVG zelf aangepast of
/// opnieuw getekend.
class SplashSvgElement extends StatelessWidget {
  final Key elementKey;
  final String assetPath;
  final double width;
  final double height;

  /// 0.0 = onzichtbaar, 1.0 = volledig verschenen (fade + lichte scale-in).
  final Animation<double> appear;

  /// Startwaarde van de scale-in (bv. 0.92 voor ICON, 0.97 voor KLANTIO).
  final double appearScaleFrom;

  /// Onthul van links naar rechts met een harde, schone rand in plaats van
  /// faden.
  final bool wipe;

  const SplashSvgElement({
    required this.elementKey,
    required this.assetPath,
    required this.width,
    required this.height,
    required this.appear,
    this.appearScaleFrom = 1.0,
    this.wipe = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: elementKey,
      child: AnimatedBuilder(
        animation: appear,
        builder: (context, _) {
          if (wipe) {
            return ClipRect(
              clipper: _WipeClipper(appear.value.clamp(0.0, 1.0)),
              child: SizedBox(
                width: width,
                height: height,
                child: SvgPicture.asset(assetPath, fit: BoxFit.contain),
              ),
            );
          }
          final scale = appearScaleFrom +
              (1.0 - appearScaleFrom) * appear.value.clamp(0.0, 1.0);
          return Opacity(
            opacity: appear.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              child: SizedBox(
                width: width,
                height: height,
                child: SvgPicture.asset(assetPath, fit: BoxFit.contain),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Onthult het linkerdeel van het element tot [progress] van de breedte.
/// De layout-grootte verandert niet -- alleen wat er getekend wordt.
class _WipeClipper extends CustomClipper<Rect> {
  final double progress;

  const _WipeClipper(this.progress);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, size.width * progress, size.height);

  @override
  bool shouldReclip(_WipeClipper oldClipper) => oldClipper.progress != progress;
}
