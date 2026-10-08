import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/datum_utils.dart';
import '../../models/examen.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/settings_design.dart';
import '../../shared/widgets/status_pill.dart';
import 'examens_provider.dart';
import '../../core/constants/cool_icons.dart';

class ExamensScreen extends ConsumerStatefulWidget {
  final String? highlightExamId;

  const ExamensScreen({super.key, this.highlightExamId});

  @override
  ConsumerState<ExamensScreen> createState() => _ExamensScreenState();
}

class _ExamensScreenState extends ConsumerState<ExamensScreen> {
  final _cardKeys = <String, GlobalKey>{};
  var _didScrollToHighlight = false;

  GlobalKey _keyForExamen(String examenId) =>
      _cardKeys.putIfAbsent(examenId, GlobalKey.new);

  void _scrollToHighlight(List<Examen> examens) {
    final targetId = widget.highlightExamId?.trim();
    if (targetId == null || targetId.isEmpty || _didScrollToHighlight) return;
    if (!examens.any((e) => e.id == targetId)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cardContext = _cardKeys[targetId]?.currentContext;
      if (cardContext == null) return;
      Scrollable.ensureVisible(
        cardContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.15,
      );
      _didScrollToHighlight = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final examensAsync = ref.watch(examensProvider);
    final highlightId = widget.highlightExamId?.trim();

    // Vanuit Profiel bereikt: zelfde subscherm-opbouw als de rest van Profiel.
    return SettingsBodyScaffold(
      titel: 'Mijn examens',
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.invalidate(examensProvider),
              child: CustomScrollView(
                slivers: [
                  examensAsync.when(
                    data: (examens) {
                      if (highlightId != null && highlightId.isNotEmpty) {
                        _scrollToHighlight(examens);
                      }

                      if (examens.isEmpty) {
                        return const SliverFillRemaining(
                          child: EmptyState(
                            icon: CoolIcons.circleHelp,
                            title: 'Geen examens',
                            subtitle:
                                'Je instructeur heeft nog geen examens ingepland.',
                          ),
                        );
                      }

                      // Gegroepeerd per type: de typenaam is de sectiekop (zoals
                      // de rest van Profiel), niet meer een titel in elke kaart.
                      final groepen = <ExamenType, List<Examen>>{};
                      for (final e in examens) {
                        groepen.putIfAbsent(e.type, () => []).add(e);
                      }
                      const volgorde = [
                        ExamenType.praktijk,
                        ExamenType.theorie,
                        ExamenType.ttt,
                      ];

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            for (final type in volgorde)
                              if (groepen[type]?.isNotEmpty == true) ...[
                                SettingsKop(type.label),
                                ...groepen[type]!.map(
                                  (examen) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _ExamenCard(
                                      key: _keyForExamen(examen.id),
                                      examen: examen,
                                      highlighted: examen.id == highlightId,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                              ],
                          ]),
                        ),
                      );
                    },
                    loading: () => SliverPadding(
                      padding: const EdgeInsets.all(20),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          const SkeletonCard(),
                          const SizedBox(height: 10),
                          const SkeletonCard(),
                          const SizedBox(height: 10),
                          const SkeletonCard(),
                        ]),
                      ),
                    ),
                    error: (e, _) => SliverFillRemaining(
                      child: EmptyState(
                        icon: CoolIcons.cloudOff,
                        title: 'Kon examens niet laden',
                        subtitle: e.toString(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamenCard extends StatelessWidget {
  final Examen examen;
  final bool highlighted;

  const _ExamenCard({
    super.key,
    required this.examen,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: highlighted
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary, width: 2),
            )
          : null,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DatumUtils.langeDatum(examen.datum),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                StatusPill.examen(examen.status),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (examen.tijdstip?.isNotEmpty == true) ...[
                  Text(
                    // 09:00:00 -> 09:00
                    examen.tijdstip!.length >= 5
                        ? examen.tijdstip!.substring(0, 5)
                        : examen.tijdstip!,
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 16),
                ],
                if (examen.locatie?.isNotEmpty == true) ...[
                  Expanded(
                    child: Text(
                      examen.locatie!,
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            if (examen.foutpunten != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${examen.foutpunten} foutpunten',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
            if (examen.notities?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text(
                examen.notities!,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
