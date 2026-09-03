import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../../arrival/live_aankomst_banner_logic.dart';

/// Altijd-aanwezige Live Aankomst-banner op Lesdetails (2026-09-03).
///
/// ÉÉN widget, drie visuele staten (zie [LiveAankomstBannerStatus]) -- de
/// banner zelf bestaat/verdwijnt nooit op basis van "is het venster al
/// open", alleen de content verandert. Renderen (of niet) gebeurt door de
/// aanroeper (`_LiveAankomstSectie` in les_detail_screen.dart), die
/// [LiveAankomstBannerStatus]? al op `null` heeft geëvalueerd voor
/// "helemaal geen banner" (niet eligible / les niet gepland / moment al
/// gepasseerd zonder sessie).
///
/// Bewust GEEN kaart/locatie hier -- dat blijft uitsluitend de bestaande
/// ophaallocatie-sectie (Status 3: "daaronder" de bestaande live kaart,
/// ongewijzigd). Deze banner toont nooit een lege Maps-sectie, nooit een
/// nep-locatie/ETA.
class LiveAankomstBanner extends StatelessWidget {
  final LiveAankomstBannerStatus status;
  final DateTime? vensterOpentOp;

  const LiveAankomstBanner({
    super.key,
    required this.status,
    this.vensterOpentOp,
  });

  @override
  Widget build(BuildContext context) {
    final (icoon, iconBg, iconColor, titel, tekst) = switch (status) {
      LiveAankomstBannerStatus.voorVenster => (
          Icons.location_on_outlined,
          const Color(0xFFF0F2F5),
          AppColors.textPrimary,
          'Live Aankomst',
          vensterOpentOp != null
              ? 'De live locatie van je instructeur wordt zichtbaar vanaf '
                  '${DateFormat('HH:mm').format(vensterOpentOp!)}.'
              : 'De live locatie van je instructeur wordt binnenkort zichtbaar.',
        ),
      LiveAankomstBannerStatus.vensterOpenNietGestart => (
          Icons.location_on_outlined,
          AppColors.primaryLight,
          AppColors.primary,
          'Live Aankomst',
          'Je instructeur kan vanaf nu zijn live locatie delen. Zodra hij '
              'onderweg is, zie je hem hier op de kaart.',
        ),
      LiveAankomstBannerStatus.actief => (
          Icons.directions_car_filled_rounded,
          AppColors.successBg,
          AppColors.success,
          'Live Aankomst actief',
          'Je instructeur is onderweg. Je kunt zijn locatie hieronder live '
              'volgen.',
        ),
    };

    return Semantics(
      label: '$titel. $tekst',
      child: AppCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icoon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tekst,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
