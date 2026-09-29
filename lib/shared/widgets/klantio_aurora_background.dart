import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// Vloeiend geanimeerde Aurora Mesh / Floating Blobs achtergrond
/// Geïnspireerd op het Framer-ontwerp (https://modern-copywriter-290003.framer.app/)
/// met SaaS / Klantio merkkleuren (Klantio-roze, SaaS-indigo, warm koraal).
class KlantioAuroraBackground extends StatefulWidget {
  final Widget child;
  final bool isDark;

  const KlantioAuroraBackground({
    super.key,
    required this.child,
    this.isDark = false,
  });

  @override
  State<KlantioAuroraBackground> createState() =>
      _KlantioAuroraBackgroundState();
}

class _KlantioAuroraBackgroundState extends State<KlantioAuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final baseColor = isDark ? const Color(0xFF0F111E) : const Color(0xFFF9FAFC);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Basis achtergrondkleur
        ColoredBox(color: baseColor),

        // 2. Geanimeerde zwevende aurora blobs
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              return CustomPaint(
                painter: _AuroraBlobsPainter(
                  progress: _ctrl.value,
                  isDark: isDark,
                ),
                size: Size.infinite,
              );
            },
          ),
        ),

        // 3. Frosted glassmorphism blur overlay
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: ColoredBox(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.25),
            ),
          ),
        ),

        // 4. Inhoud (Login formulier / widgets)
        widget.child,
      ],
    );
  }
}

class _AuroraBlobsPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _AuroraBlobsPainter({
    required this.progress,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress * 2 * math.pi;

    // SaaS & Klantio merkkleuren
    final klantioPink = isDark
        ? const Color(0xFFD63060).withValues(alpha: 0.40)
        : const Color(0xFFD63060).withValues(alpha: 0.26);

    final saasIndigo = isDark
        ? const Color(0xFF4F46E5).withValues(alpha: 0.35)
        : const Color(0xFF6366F1).withValues(alpha: 0.22);

    final saasCyanCoral = isDark
        ? const Color(0xFF06B6D4).withValues(alpha: 0.28)
        : const Color(0xFFFF7A8A).withValues(alpha: 0.24);

    final w = size.width;
    final h = size.height;

    // Blob 1: Klantio Rose (bovenzijde / midden bewegend)
    final blob1Center = Offset(
      w * 0.35 + math.sin(t) * (w * 0.22),
      h * 0.22 + math.cos(t * 0.8) * (h * 0.15),
    );
    final blob1Radius = math.min(w, h) * (0.42 + math.sin(t * 1.2) * 0.05);

    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [klantioPink, klantioPink.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: blob1Center, radius: blob1Radius));
    canvas.drawCircle(blob1Center, blob1Radius, paint1);

    // Blob 2: SaaS Indigo (rechtsboven / rechtsmidden)
    final blob2Center = Offset(
      w * 0.72 + math.cos(t * 1.1) * (w * 0.20),
      h * 0.40 + math.sin(t * 0.9) * (h * 0.18),
    );
    final blob2Radius = math.min(w, h) * (0.48 + math.cos(t) * 0.06);

    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [saasIndigo, saasIndigo.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: blob2Center, radius: blob2Radius));
    canvas.drawCircle(blob2Center, blob2Radius, paint2);

    // Blob 3: Warm Coral / Pastel Accent (onderzijde / linksonder)
    final blob3Center = Offset(
      w * 0.45 + math.sin(t * 0.7 + 1.0) * (w * 0.25),
      h * 0.78 + math.cos(t * 1.3) * (h * 0.14),
    );
    final blob3Radius = math.min(w, h) * (0.45 + math.sin(t * 0.8) * 0.05);

    final paint3 = Paint()
      ..shader = RadialGradient(
        colors: [saasCyanCoral, saasCyanCoral.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: blob3Center, radius: blob3Radius));
    canvas.drawCircle(blob3Center, blob3Radius, paint3);
  }

  @override
  bool shouldRepaint(covariant _AuroraBlobsPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
