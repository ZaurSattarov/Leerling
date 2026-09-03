import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'examenadvies_data.dart';
import 'examenadvies_ontwikkeling.dart';

class ExamenadviesSparkline extends StatelessWidget {
  final ExamenadviesSparklineData? data;

  const ExamenadviesSparkline({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final chart = data;
    if (chart == null || !chart.heeftChart) {
      return const Text(
        'Na meerdere beoordelingen zie je hier je ontwikkeling.',
        style: TextStyle(
          fontSize: 12,
          height: 1.4,
          color: AppColors.textHint,
        ),
      );
    }

    final kleur = _trendKleur(chart.trend);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_trendIcoon(chart.trend), size: 16, color: kleur),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                chart.categorie,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: kleur,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          width: double.infinity,
          child: CustomPaint(
            painter: _SparklinePainter(punten: chart.punten, kleur: kleur),
          ),
        ),
      ],
    );
  }
}

Color _trendKleur(VaardigheidTrend trend) {
  return switch (trend) {
    VaardigheidTrend.stijgt => AppColors.successSolid,
    VaardigheidTrend.daalt => AppColors.dangerSolid,
    VaardigheidTrend.stabiel => AppColors.textSecondary,
    VaardigheidTrend.onbekend => AppColors.textHint,
  };
}

IconData _trendIcoon(VaardigheidTrend trend) {
  return switch (trend) {
    VaardigheidTrend.stijgt => Icons.trending_up_rounded,
    VaardigheidTrend.daalt => Icons.trending_down_rounded,
    VaardigheidTrend.stabiel => Icons.trending_flat_rounded,
    VaardigheidTrend.onbekend => Icons.trending_flat_rounded,
  };
}

class _SparklinePainter extends CustomPainter {
  final List<double> punten;
  final Color kleur;

  const _SparklinePainter({required this.punten, required this.kleur});

  @override
  void paint(Canvas canvas, Size size) {
    if (punten.length < 2 || size.width <= 0 || size.height <= 0) return;

    const minY = 1.0;
    const maxY = 5.0;
    final dx = size.width / (punten.length - 1);
    final path = Path();

    Offset punt(int i) {
      final x = dx * i;
      final t = (punten[i] - minY) / (maxY - minY);
      final y = size.height - (t.clamp(0.0, 1.0) * size.height);
      return Offset(x, y);
    }

    path.moveTo(punt(0).dx, punt(0).dy);
    for (var i = 1; i < punten.length; i++) {
      path.lineTo(punt(i).dx, punt(i).dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = kleur
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.75
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final vul = Paint()..color = kleur;
    for (var i = 0; i < punten.length; i++) {
      canvas.drawCircle(punt(i), 2.2, vul);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.punten != punten || oldDelegate.kleur != kleur;
  }
}
