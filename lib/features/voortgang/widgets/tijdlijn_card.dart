import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/app_card.dart';
import '../voortgang_trends_provider.dart';

// ── Semantische kleuren (zelfde palet als voortgang_screen.dart) ──────────────

const _groen = Color(0xFF16A34A);
const _oranje = Color(0xFFD97706);
const _rood = Color(0xFFE11D48);
const _mutedSurface = Color(0xFFF0F2F5);
const _softSurface = Color(0xFFF8F8FA);

/// Gedeelde "Voortgang tijdlijn"-kaart -- gebruikt zowel op de hoofdpagina
/// van Voortgang (alleen de laatste les) als op het volledige
/// tijdlijnoverzicht (alle lessen), zodat beide exact dezelfde opbouw en
/// styling tonen.
class TijdlijnCard extends StatelessWidget {
  final List<LesTijdlijnItem> items;
  const TijdlijnCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const AppCard(
        child: EmptyState(
          icon: Icons.timeline_rounded,
          title: 'Nog geen tijdlijn',
          subtitle: 'Afgeronde lessen verschijnen hier.',
        ),
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...items.asMap().entries.map((entry) {
            final isLast = entry.key == items.length - 1;
            return _TijdlijnRij(item: entry.value, isLast: isLast);
          }),
        ],
      ),
    );
  }
}

class _TijdlijnRij extends StatelessWidget {
  final LesTijdlijnItem item;
  final bool isLast;

  const _TijdlijnRij({required this.item, required this.isLast});

  IconData get _eventIcon {
    return switch (item.eventType) {
      'beoordeling' => Icons.grade_rounded,
      'aandachtspunt' => Icons.flag_rounded,
      _ => Icons.check_circle_outline_rounded,
    };
  }

  String get _eventLabel {
    return switch (item.eventType) {
      'beoordeling' => 'Beoordeling',
      'aandachtspunt' => 'Aandachtspunt',
      _ => 'Les afgerond',
    };
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tijdlijn staaf
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F2F5),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(_eventIcon, color: AppColors.textPrimary, size: 14),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: const Color(0xFFE2E2E7),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _eventLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.25,
                          ),
                        ),
                      ),
                      if (item.beoordelingLabel != 'Geen beoordeling')
                        _BeoordelingBadge(label: item.beoordelingLabel),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Datum + tijd + lestype
                  Text(
                    '${item.datumLabel} · ${item.tijdLabel}'
                    '${item.lesType != null ? ' · ${item.lesType}' : ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  // Competentie verbeteringen
                  if (item.verbeteringen.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _mutedSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children:
                            item.verbeteringen.asMap().entries.map((entry) {
                          return Padding(
                            padding:
                                EdgeInsets.only(top: entry.key == 0 ? 0 : 6),
                            child: _TijdlijnScoreRij(score: entry.value),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  // Geoefende onderwerpen
                  if (item.onderwerpen.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Geoefend',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.onderwerpen.join(', '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],

                  // Instructeur feedback
                  if (item.feedback.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Opmerking',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _softSurface,
                        borderRadius: BorderRadius.circular(10),
                        border:
                            Border.all(color: AppColors.border, width: 0.75),
                      ),
                      child: Text(
                        item.feedback,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                          fontStyle: FontStyle.normal,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TijdlijnScoreRij extends StatelessWidget {
  final CompetentieDelta score;
  const _TijdlijnScoreRij({required this.score});

  Color get _kleur {
    if (score.delta >= 80) return _groen;
    if (score.delta >= 50) return _oranje;
    return _rood;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            score.naam,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 44,
          child: Text(
            '${score.delta}%',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: _kleur,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _BeoordelingBadge extends StatelessWidget {
  final String label;
  const _BeoordelingBadge({required this.label});

  Color get _kleur {
    return switch (label) {
      '5/5' || 'Goed' => _groen,
      '4/5' || 'Voldoende' => _oranje,
      _ => _rood,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E2E7), width: 0.75),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: _kleur,
        ),
      ),
    );
  }
}
