import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/lespakket_detail.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/settings_design.dart';
import '../../shared/widgets/status_badge.dart';
import '../voortgang/lespakket_detail_provider.dart';
import '../../core/constants/cool_icons.dart';

/// Profiel -> Rijopleiding -> Lespakket (Fase 4). Bewust een NIEUW, apart
/// scherm/route (i.p.v. het bestaande /voortgang/lespakket te hergebruiken):
/// dat scherm wordt ook vanuit het Voortgang-tabblad geopend, dat in deze
/// fase nog niet mag wijzigen. Zelfde bestaande stijl (MainDetailHeader,
/// AppCard, IconBadge, SectionHeader) als alle andere detailschermen in de
/// app -- geen nieuw ontwerp.
class ProfielLespakketScreen extends ConsumerWidget {
  const ProfielLespakketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(lespakketDetailProvider);

    // Alleen-lezen (pakketgegevens komen van de rijschool): dus geen vinkje.
    return SettingsBodyScaffold(
      titel: 'Lespakket',
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.invalidate(lespakketDetailProvider),
              child: detailAsync.when(
                loading: () => ListView(
                  padding: const EdgeInsets.all(20),
                  children: const [
                    SkeletonBox(height: 140, radius: 18),
                    SizedBox(height: 14),
                    SkeletonCard(),
                    SizedBox(height: 10),
                    SkeletonCard(),
                  ],
                ),
                error: (e, _) => ListView(
                  children: [
                    const SizedBox(height: 60),
                    EmptyState(
                      icon: CoolIcons.cloudOff,
                      title: 'Kon pakketgegevens niet laden',
                      subtitle: e.toString(),
                    ),
                  ],
                ),
                data: (detail) {
                  if (detail == null || !detail.heeftPakket) {
                    return ListView(
                      children: const [
                        SizedBox(height: 60),
                        EmptyState(
                          icon: CoolIcons.archive,
                          title: 'Geen pakket ingesteld',
                          subtitle:
                              'Je instructeur heeft nog geen lespakket aan je gekoppeld.',
                        ),
                      ],
                    );
                  }
                  if (!detail.heeftGegevens) {
                    return ListView(
                      children: const [
                        SizedBox(height: 60),
                        EmptyState(
                          icon: CoolIcons.circleWarning,
                          title: 'Pakketgegevens niet beschikbaar',
                          subtitle:
                              'Neem contact op met je rijschool voor de voorwaarden van je lespakket.',
                        ),
                      ],
                    );
                  }
                  return _LespakketDetailBody(detail: detail);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LespakketDetailBody extends StatelessWidget {
  final LespakketDetail detail;
  const _LespakketDetailBody({required this.detail});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _KopKaart(detail: detail),
        const SizedBox(height: 14),
        _VoortgangKaart(detail: detail),
        SizedBox(height: 22),
        SectionHeader(title: 'Pakketvoorwaarden'),
        SizedBox(height: 12),
        _VoorwaardenKaart(detail: detail),
        if (detail.praktijkexamenInbegrepen ||
            detail.tussentijdseToetsInbegrepen) ...[
          SizedBox(height: 22),
          SectionHeader(title: 'Inbegrepen'),
          SizedBox(height: 12),
          _InbegrepenKaart(detail: detail),
        ],
        if (!detail.heeftSnapshot) ...[
          SizedBox(height: 16),
          _LegacyMelding(),
        ],
        SizedBox(height: 24),
      ],
    );
  }
}

class _KopKaart extends StatelessWidget {
  final LespakketDetail detail;
  _KopKaart({required this.detail});

  Color get _statusKleur {
    switch (detail.statusLabel) {
      case 'Volledig gebruikt':
        return AppColors.dangerSolid;
      case 'Bijna op':
        return AppColors.warningSolid;
      case 'Actief':
        return AppColors.successSolid;
      default:
        return AppColors.dark3;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconBadge(
                icon: CoolIcons.archive,
                color: AppColors.primary,
                size: 44,
              ),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  detail.pakketnaam,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              SizedBox(width: 10),
              // Statusbadge rechtsboven -- zelfde neutrale/gebordeerde
              // stijl als StatusPill/FactuurStatusUi elders in de app
              // (geen pastel-getinte achtergrond meer).
              _StatusBadge(label: detail.statusLabel, kleur: _statusKleur),
            ],
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (detail.rijbewijsCategorie?.isNotEmpty == true)
                _Badge(label: detail.rijbewijsCategorie!.toUpperCase()),
              if (_transmissieLabel != null) _Badge(label: _transmissieLabel!),
            ],
          ),
        ],
      ),
    );
  }

  String? get _transmissieLabel {
    switch (detail.transmissie) {
      case 'manual':
        return 'Schakel';
      case 'automatic':
        return 'Automaat';
      default:
        return null;
    }
  }
}

/// Statusbadge (bv. "Actief"): dezelfde solide [StatusBadge] als de rest van
/// de app (1-op-1 Instructeur-app): vol kleurvlak, witte hoofdletters.
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color kleur;
  _StatusBadge({required this.label, required this.kleur});

  @override
  Widget build(BuildContext context) =>
      StatusBadge(label: label, backgroundColor: kleur);
}

class _Badge extends StatelessWidget {
  final String label;
  _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _VoortgangKaart extends StatelessWidget {
  final LespakketDetail detail;
  _VoortgangKaart({required this.detail});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Voortgang',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Spacer(),
              Text(
                '${detail.percentageLabel}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: detail.percentageAfgerond,
              minHeight: 9,
              backgroundColor: AppColors.borderLight,
              valueColor: AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricTile(label: 'Totaal', value: detail.totaalLabel),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Gevolgd',
                  value: detail.gevolgdLabel,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Resterend',
                  value: detail.resterendLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  _MetricTile({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.isDark(context)
            ? const Color(0xFF283244)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(context), width: 0.75),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color ?? AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textHint,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _VoorwaardenKaart extends StatelessWidget {
  final LespakketDetail detail;
  const _VoorwaardenKaart({required this.detail});

  @override
  Widget build(BuildContext context) {
    final rijen = <Widget>[];

    if (detail.lesduurMinuten > 0) {
      rijen.add(_VoorwaardeRij(
        icon: CoolIcons.clock,
        label: 'Lesduur',
        waarde: '${detail.lesduurMinuten} minuten',
      ));
    }
    if (detail.pakketprijs != null) {
      rijen.add(_VoorwaardeRij(
        icon: CoolIcons.creditCard01,
        label: 'Pakketprijs',
        waarde: detail.prijsLabel,
      ));
    }
    if (detail.losseLesprijs != null && detail.losseLesprijs! > 0) {
      rijen.add(_VoorwaardeRij(
        icon: CoolIcons.creditCard01,
        label: 'Losse lesprijs',
        waarde:
            '€ ${detail.losseLesprijs!.toStringAsFixed(2).replaceAll('.', ',')}',
      ));
    }
    if (detail.startdatum?.isNotEmpty == true) {
      rijen.add(_VoorwaardeRij(
        icon: CoolIcons.calendar,
        label: 'Startdatum',
        waarde: detail.startdatum!,
      ));
    }

    if (rijen.isEmpty) {
      return AppCard(
        child: Text(
          'Geen aanvullende voorwaarden bekend.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      );
    }

    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < rijen.length; i++) ...[
            if (i != 0) const Divider(height: 20),
            rijen[i],
          ],
        ],
      ),
    );
  }
}

class _VoorwaardeRij extends StatelessWidget {
  final IconData icon;
  final String label;
  final String waarde;

  const _VoorwaardeRij({
    required this.icon,
    required this.label,
    required this.waarde,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconBadge(icon: icon, color: AppColors.iconSlate, size: 34),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ),
        Text(
          waarde,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
      ],
    );
  }
}

class _InbegrepenKaart extends StatelessWidget {
  final LespakketDetail detail;
  const _InbegrepenKaart({required this.detail});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          if (detail.praktijkexamenInbegrepen) ...[
            const _InbegrepenRij(label: 'Praktijkexamen'),
          ],
          if (detail.praktijkexamenInbegrepen &&
              detail.tussentijdseToetsInbegrepen)
            const Divider(height: 20),
          if (detail.tussentijdseToetsInbegrepen) ...[
            const _InbegrepenRij(label: 'Tussentijdse toets (TTT)'),
          ],
        ],
      ),
    );
  }
}

class _InbegrepenRij extends StatelessWidget {
  final String label;
  const _InbegrepenRij({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const IconBadge(
          icon: CoolIcons.circleCheck,
          color: AppColors.successSolid,
          size: 34,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}

class _LegacyMelding extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(CoolIcons.info, color: AppColors.iconPrimary, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Deze voorwaarden komen uit de huidige pakkettencatalogus van je '
              'rijschool, niet uit een vastgelegde overeenkomst. Neem contact op '
              'met je instructeur als je twijfelt.',
              style: TextStyle(
                  fontSize: 12, height: 1.4, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
