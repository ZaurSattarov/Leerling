import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/cool_icons.dart';

/// Framer Arrow Fill Button -- 1-op-1 replica van Hyperiux Vault Arrow Fill Button
/// (https://www.framer.com/marketplace/components/arrow-fill-button/).
///
/// Specificaties & Gedrag:
/// - Kleur: Exact #EB4C76 voor de rand, tekst, pijl en glow
/// - Icoon: Strak aan de rechterzijde gepositioneerd (geen logge container)
/// - Ruststand: Donkere/transparante pil met #EB4C76 rand, #EB4C76 tekst en #EB4C76 pijl
/// - Animatie (Hover / Klik op Inloggen):
///   1. Een solide witte cirkelfill expandeert vanuit de rechter pijl van rechts naar links over de gehele knop
///   2. De knop wordt volledig wit met de #EB4C76 tekst en pijl
///   3. De pijl animeert met een vloeiende slide-swap (schuift naar rechts weg en komt vanuit links weer binnen)
///   4. Na het klikken op 'Inloggen' speelt de animatie af en logt daarna direct in
class KlantioAuroraButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final double? width;
  final IconData? icon;
  final Color? accentColor;

  const KlantioAuroraButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.height = 52,
    this.width,
    this.icon = CoolIcons.chevronRight,
    this.accentColor,
  });

  @override
  State<KlantioAuroraButton> createState() => _KlantioAuroraButtonState();
}

class _KlantioAuroraButtonState extends State<KlantioAuroraButton>
    with SingleTickerProviderStateMixin {
  static const Color _defaultAccent = Color(0xFFEB4C76);

  late final AnimationController _animCtrl;
  late final Animation<double> _fillCurve;
  late final Animation<double> _arrowSwapCurve;

  bool _isHovered = false;
  bool _isPressed = false;
  bool _isTriggeringTap = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _fillCurve = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _arrowSwapCurve = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _onHoverEnter() {
    if (_isTriggeringTap) return;
    setState(() => _isHovered = true);
    _animCtrl.forward();
  }

  void _onHoverExit() {
    if (_isTriggeringTap) return;
    setState(() => _isHovered = false);
    if (!_isPressed) {
      _animCtrl.reverse();
    }
  }

  Future<void> _handleTap() async {
    final callback = widget.onPressed;
    if (callback == null || widget.isLoading || _isTriggeringTap) return;

    setState(() {
      _isTriggeringTap = true;
      _isPressed = true;
    });

    // Laat de expanding white fill & arrow slide animatie afspelen
    await _animCtrl.forward();

    if (mounted) {
      setState(() {
        _isPressed = false;
        _isTriggeringTap = false;
      });
      callback();
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;
    final accent = widget.accentColor ?? _defaultAccent;

    return AnimatedScale(
      scale: _isPressed ? 0.98 : (_isHovered ? 1.015 : 1.0),
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: MouseRegion(
        onEnter: enabled ? (_) => _onHoverEnter() : null,
        onExit: enabled ? (_) => _onHoverExit() : null,
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _isPressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _isPressed = false) : null,
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: enabled ? _handleTap : null,
          child: AnimatedBuilder(
            animation: _animCtrl,
            builder: (context, _) {
              final fillProgress = _fillCurve.value;
              final arrowProgress = _arrowSwapCurve.value;

              return Container(
                height: widget.height,
                width: widget.width ?? double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: enabled ? accent : accent.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: enabled
                      ? [
                          BoxShadow(
                            color: accent.withValues(
                                alpha: 0.25 + (fillProgress * 0.20)),
                            blurRadius: 16 + (fillProgress * 10),
                            offset: const Offset(0, 5),
                            spreadRadius: -2,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 1. Ruststand achtergrond (donker/transparante basis)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: enabled
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.2),
                          ),
                        ),
                      ),

                      // 2. Expanding White Fill (groeit vanuit de rechter pijl van rechts naar links)
                      if (enabled && fillProgress > 0.001)
                        Positioned.fill(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final origin = Offset(
                                constraints.maxWidth - 32.0,
                                constraints.maxHeight / 2,
                              );
                              final maxRadius = math.sqrt(
                                      origin.dx * origin.dx +
                                          origin.dy * origin.dy) +
                                  20.0;
                              final currentRadius = maxRadius * fillProgress;

                              return ClipPath(
                                clipper: _ExpandingCircleClipper(
                                  center: origin,
                                  radius: currentRadius,
                                ),
                                child: const ColoredBox(color: Colors.white),
                              );
                            },
                          ),
                        ),

                      // 3. Tekst in het midden ("Inloggen")
                      Positioned.fill(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 48),
                            child: Text(
                              widget.text,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                color: enabled
                                    ? accent
                                    : accent.withValues(alpha: 0.5),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 4. Rechter Pijl Icoon & Slide-swap animatie
                      Positioned(
                        right: 20,
                        child: widget.isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: accent,
                                ),
                              )
                            : ClipRect(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      // Uitgaande pijl: schuift naar rechts weg met fade-out
                                      if (arrowProgress < 0.98)
                                        Transform.translate(
                                          offset:
                                              Offset(22.0 * arrowProgress, 0),
                                          child: Opacity(
                                            opacity: (1.0 - arrowProgress)
                                                .clamp(0.0, 1.0),
                                            child: Icon(
                                              widget.icon ??
                                                  CoolIcons.chevronRight,
                                              color: enabled
                                                  ? accent
                                                  : accent.withValues(
                                                      alpha: 0.5),
                                              size: 20,
                                            ),
                                          ),
                                        ),

                                      // Inkomende pijl: schuift vanuit links naar het centrum met fade-in
                                      if (arrowProgress > 0.02)
                                        Transform.translate(
                                          offset: Offset(
                                              -22.0 * (1.0 - arrowProgress), 0),
                                          child: Opacity(
                                            opacity:
                                                arrowProgress.clamp(0.0, 1.0),
                                            child: Icon(
                                              widget.icon ??
                                                  CoolIcons.chevronRight,
                                              color: accent,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Custom Clipper voor de van rechts naar links expanderende cirkelfill
class _ExpandingCircleClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  _ExpandingCircleClipper({required this.center, required this.radius});

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(covariant _ExpandingCircleClipper oldClipper) {
    return oldClipper.center != center || oldClipper.radius != radius;
  }
}
