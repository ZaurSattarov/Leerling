import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/datum_utils.dart';
import '../../models/les.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/gradient_header.dart';
import '../../shared/widgets/status_pill.dart';
import 'lespakket_voortgang_provider.dart';

class LespakketDetailScreen extends ConsumerWidget {
  const LespakketDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(lespakketVoortgangProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const DetailGradientHeader(title: 'Lespakket & voortgang'),
          Expanded(
            child: dataAsync.when(
              data: (data) {
                if (data == null) {
                  return const Center(
                    child: EmptyState(
                      icon: Icons.person_off_outlined,
                      title: 'Geen profiel gevonden',
                    ),
                  );
                }
                return _LespakketDetailBody(data: data);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Kon lespakket niet laden',
                  subtitle: e.toString(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LespakketDetailBody extends ConsumerWidget {
  final LespakketVoortgangData data;

  const _LespakketDetailBody({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tijdlijn = data.tijdlijnLessen;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async => ref.refresh(lespakketVoortgangProvider.future),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const IconBadge(
                      icon: Icons.route_rounded,
                      color: AppColors.primary,
                      size: 42,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lespakket',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            data.pakketLabel,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${data.percentageLabel}%',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: data.percentageAfgerond,
                    minHeight: 9,
                    backgroundColor: AppColors.borderLight,
                    valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                if (!data.heeftPakket)
                  const _InlineNotice(
                    icon: Icons.info_outline_rounded,
                    text: 'Geen pakket ingesteld',
                  )
                else if (data.heeftExtraLessen)
                  _InlineNotice(
                    icon: Icons.add_circle_outline_rounded,
                    text:
                        '${data.extraLessen} extra les${data.extraLessen == 1 ? '' : 'sen'} gevolgd boven je pakket.',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.75,
            children: [
              _MetricTile(label: 'Totaal', value: '${data.totaalLessen}'),
              _MetricTile(
                label: 'Afgerond',
                value: '${data.afgerondeLessen}',
                color: AppColors.successSolid,
              ),
              _MetricTile(
                label: 'Gepland',
                value: '${data.geplandeLessen}',
                color: AppColors.infoSolid,
              ),
              _MetricTile(
                label: 'Resterend',
                value: '${data.nogTeGebruiken}',
                color: AppColors.primary,
              ),
              _MetricTile(
                label: 'Nog in te plannen',
                value: '${data.nogInTePlannen}',
                color: AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppCard(
            backgroundColor: AppColors.neutralBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Zo rekenen we',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.gebruiktFallback
                      ? 'Omdat er geen afgeronde lessen in de opgehaalde lessenlijst staan, gebruiken we tijdelijk de profielwaarde lessen_gevolgd.'
                      : 'Alleen afgeronde lessen tellen als verbruikt. Geplande lessen tellen apart. Geannuleerd, verzet en geen toon tellen niet als verbruikt.',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader(title: 'Lessen tijdlijn'),
          const SizedBox(height: 12),
          if (tijdlijn.isEmpty)
            const AppCard(
              child: EmptyState(
                icon: Icons.event_busy_rounded,
                title: 'Nog geen lessen',
                subtitle:
                    'Afgeronde en geplande lessen verschijnen hier zodra ze beschikbaar zijn.',
              ),
            )
          else
            ...tijdlijn.map(
              (les) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LesTimelineCard(les: les),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    this.color = AppColors.dark3,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InlineNotice({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E2E7)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LesTimelineCard extends StatelessWidget {
  final Les les;

  const _LesTimelineCard({required this.les});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(
            icon: _icon,
            color: _iconColor,
            size: 38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        DatumUtils.langeDatum(les.datum),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    StatusPill.les(les.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${les.starttijd} - ${les.eindtijd}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (les.instructeurNaam?.isNotEmpty == true) ...[
                  const SizedBox(height: 3),
                  Text(
                    les.instructeurNaam!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData get _icon {
    switch (les.status) {
      case LesStatus.afgerond:
        return Icons.check_rounded;
      case LesStatus.gepland:
        return Icons.event_available_rounded;
      case LesStatus.geannuleerd:
      case LesStatus.verzet:
      case LesStatus.geen_toon:
        return Icons.event_busy_rounded;
    }
  }

  Color get _iconColor {
    switch (les.status) {
      case LesStatus.afgerond:
        return AppColors.successSolid;
      case LesStatus.gepland:
        return AppColors.infoSolid;
      case LesStatus.geannuleerd:
      case LesStatus.verzet:
        return AppColors.dark3;
      case LesStatus.geen_toon:
        return AppColors.dangerSolid;
    }
  }
}
