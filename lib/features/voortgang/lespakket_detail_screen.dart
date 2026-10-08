import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/datum_utils.dart';
import '../../models/les.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_detail_header.dart';
import '../../shared/widgets/status_pill.dart';
import 'lespakket_voortgang_provider.dart';
import '../../core/constants/cool_icons.dart';

class LespakketDetailScreen extends ConsumerWidget {
  const LespakketDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(lespakketVoortgangProvider);

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        children: [
          const MainDetailHeader(
            title: 'Lespakket & voortgang',
          ),
          Expanded(
            child: dataAsync.when(
              data: (data) {
                if (data == null) {
                  return const EmptyState(
                    icon: CoolIcons.userClose,
                    title: 'Geen profiel gevonden',
                  );
                }
                return _LespakketDetailBody(data: data);
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => EmptyState(
                icon: CoolIcons.cloudOff,
                title: 'Kon lespakket niet laden',
                subtitle: e.toString(),
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
                      icon: CoolIcons.navigation,
                      color: AppColors.primary,
                      size: 42,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
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
                if (!data.heeftPakket || data.heeftExtraLessen)
                  const SizedBox(height: 16),
                if (!data.heeftPakket)
                  const _InlineNotice(
                    icon: CoolIcons.info,
                    text: 'Geen pakket ingesteld',
                  )
                else if (data.heeftExtraLessen)
                  _InlineNotice(
                    icon: CoolIcons.addPlusCircle,
                    text:
                        '${data.extraLessen} extra les${data.extraLessen == 1 ? '' : 'sen'} gevolgd boven je pakket.',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _MetricRij(
            links: _MetricTile(label: 'Totaal', value: '${data.totaalLessen}'),
            rechts: _MetricTile(
              label: 'Afgerond',
              value: '${data.afgerondeLessen}',
              color: AppColors.successSolid,
            ),
          ),
          const SizedBox(height: 10),
          _MetricRij(
            links: _MetricTile(
              label: 'Gepland',
              value: '${data.geplandeLessen}',
              color: AppColors.infoSolid,
            ),
            rechts: _MetricTile(
              label: 'Resterend',
              value: '${data.nogTeGebruiken}',
              color: AppColors.primary,
            ),
          ),
          // Alleen tonen als het afwijkt van "Resterend" -- anders dubbel.
          if (data.nogInTePlannen != data.nogTeGebruiken) ...[
            const SizedBox(height: 10),
            _MetricTile(
              label: 'Nog in te plannen',
              value: '${data.nogInTePlannen}',
              color: AppColors.primary,
              breed: true,
            ),
          ],
          const SizedBox(height: 10),
          AppCard(
            backgroundColor: AppColors.neutralBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Zo rekenen we',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  // Canonical bugfix (2026-09-10): 'afgerond' komt altijd uit
                  // de servergegevens (lessen_gevolgd), nooit meer uit een
                  // client-side telling -- geen fallback-uitleg meer nodig.
                  'Afgerond komt uit de servergegevens van je instructeur. '
                  'Alleen geplande pakketlessen tellen apart als "Gepland". '
                  'Geannuleerd, verzet en geen toon tellen niet als verbruikt.',
                  style: TextStyle(
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
                icon: CoolIcons.calendarClose,
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

class _MetricRij extends StatelessWidget {
  final Widget links;
  final Widget rechts;

  const _MetricRij({required this.links, required this.rechts});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: links),
          const SizedBox(width: 10),
          Expanded(child: rechts),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool breed;

  const _MetricTile({
    required this.label,
    required this.value,
    this.color,
    this.breed = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: color ?? AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
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
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.iconPrimary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
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
      onTap: () {
        HapticFeedback.selectionClick();
        context.push('/planning/${les.id}');
      },
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
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
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
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (les.instructeurNaam?.isNotEmpty == true) ...[
                  const SizedBox(height: 3),
                  Text(
                    les.instructeurNaam!,
                    style: TextStyle(
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
        return CoolIcons.check;
      case LesStatus.gepland:
        return CoolIcons.calendarCheck;
      case LesStatus.geannuleerd:
      case LesStatus.verzet:
      case LesStatus.geen_toon:
        return CoolIcons.calendarClose;
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
