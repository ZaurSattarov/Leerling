import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/datum_utils.dart';
import '../../models/examen.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_detail_header.dart';
import 'examens_provider.dart';

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

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          const MainDetailHeader(
            title: 'Mijn examens',
          ),
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
                            icon: Icons.quiz_outlined,
                            title: 'Geen examens',
                            subtitle:
                                'Je instructeur heeft nog geen examens ingepland.',
                          ),
                        );
                      }

                      final gepland = examens
                          .where((e) => e.status == ExamenStatus.gepland)
                          .toList();
                      final afgerond = examens
                          .where((e) => e.status != ExamenStatus.gepland)
                          .toList();

                      return SliverPadding(
                        padding: const EdgeInsets.all(20),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            if (gepland.isNotEmpty) ...[
                              const SectionHeader(title: 'Gepland'),
                              const SizedBox(height: 12),
                              ...gepland.map(
                                (examen) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _ExamenCard(
                                    key: _keyForExamen(examen.id),
                                    examen: examen,
                                    highlighted: examen.id == highlightId,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            if (afgerond.isNotEmpty) ...[
                              const SectionHeader(title: 'Resultaten'),
                              const SizedBox(height: 12),
                              ...afgerond.map(
                                (examen) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _ExamenCard(
                                    key: _keyForExamen(examen.id),
                                    examen: examen,
                                    highlighted: examen.id == highlightId,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
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
                        icon: Icons.wifi_off_rounded,
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

  Color get _statusColor {
    switch (examen.status) {
      case ExamenStatus.geslaagd:
        return AppColors.successSolid;
      case ExamenStatus.gezakt:
        return AppColors.dangerSolid;
      case ExamenStatus.gepland:
        return AppColors.infoSolid;
    }
  }

  IconData get _typeIcon {
    switch (examen.type) {
      case ExamenType.praktijk:
        return Icons.directions_car_rounded;
      case ExamenType.theorie:
        return Icons.menu_book_rounded;
      case ExamenType.ttt:
        return Icons.assignment_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: highlighted
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
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
              IconBadge(icon: _typeIcon, color: _statusColor, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      examen.type.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DatumUtils.langeDatum(examen.datum),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(status: examen.status),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (examen.tijdstip?.isNotEmpty == true) ...[
                const Icon(Icons.schedule_outlined,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  examen.tijdstip!,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 16),
              ],
              if (examen.locatie?.isNotEmpty == true) ...[
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    examen.locatie!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
          if (examen.pogingNummer > 1) ...[
            const SizedBox(height: 8),
            Text(
              'Poging ${examen.pogingNummer}',
              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
          if (examen.foutpunten != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 14, color: AppColors.textHint),
                const SizedBox(width: 4),
                Text(
                  '${examen.foutpunten} foutpunten',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
          if (examen.notities?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(
              examen.notities!,
              style: const TextStyle(
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

class _StatusBadge extends StatelessWidget {
  final ExamenStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color borderColor;
    final Color textColor;
    switch (status) {
      case ExamenStatus.geslaagd:
        backgroundColor = AppColors.successBg;
        borderColor = AppColors.successBorder;
        textColor = AppColors.successSolid;
        break;
      case ExamenStatus.gezakt:
        backgroundColor = AppColors.dangerBg;
        borderColor = AppColors.dangerBorder;
        textColor = AppColors.dangerSolid;
        break;
      case ExamenStatus.gepland:
        backgroundColor = AppColors.infoBg;
        borderColor = AppColors.infoBorder;
        textColor = AppColors.infoText;
        break;
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 0.75),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
