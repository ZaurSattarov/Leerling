import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/lespakket_detail.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_detail_header.dart';
import '../voortgang/lespakket_detail_provider.dart';

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

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          const MainDetailHeader(
            title: 'Lespakket',
          ),
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
                      icon: Icons.wifi_off_rounded,
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
                          icon: Icons.inventory_2_outlined,
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
                          icon: Icons.error_outline_rounded,
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
        const SizedBox(height: 22),
        const SectionHeader(title: 'Pakketvoorwaarden'),
        const SizedBox(height: 12),
        _VoorwaardenKaart(detail: detail),
        if (detail.praktijkexamenInbegrepen ||
            detail.tussentijdseToetsInbegrepen) ...[
          const SizedBox(height: 22),
          const SectionHeader(title: 'Inbegrepen'),
          const SizedBox(height: 12),
          _InbegrepenKaart(detail: detail),
        ],
        if (!detail.heeftSnapshot) ...[
          const SizedBox(height: 16),
          _LegacyMelding(),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _KopKaart extends StatelessWidget {
  final LespakketDetail detail;
  const _KopKaart({required this.detail});

  Color get _statusKleur {
    switch (detail.statusLabel) {
      case 'Volledig gebruikt':
        return AppColors.dangerSolid;
      case 'Bijna op':
        return AppColors.warningSolid;
      case 'Actief':
        return AppColors.successSolid;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconBadge(
                icon: Icons.inventory_2_rounded,
                color: AppColors.primary,
                size: 44,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  detail.pakketnaam,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Statusbadge rechtsboven -- zelfde neutrale/gebordeerde
              // stijl als StatusPill/FactuurStatusUi elders in de app
              // (geen pastel-getinte achtergrond meer).
              _StatusBadge(label: detail.statusLabel, kleur: _statusKleur),
            ],
          ),
          const SizedBox(height: 12),
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

/// Statusbadge (bv. "Actief") -- zelfde neutrale/gebordeerde badge-stijl als
/// [StatusPill]/`FactuurStatusUi` elders in de app (grijze achtergrond,
/// dunne rand, solide semantische tekstkleur) i.p.v. een fletse pastel-
/// getinte achtergrond in de statuskleur zelf.
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color kleur;
  const _StatusBadge({required this.label, required this.kleur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E2E7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: kleur, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: kleur,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E2E7)),
      ),
      child: Text(
        label,
        style: const TextStyle(
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
  const _VoortgangKaart({required this.detail});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Voortgang',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${detail.percentageLabel}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: detail.percentageAfgerond,
              minHeight: 9,
              backgroundColor: AppColors.borderLight,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MetricTile(label: 'Totaal', value: detail.totaalLabel),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Gevolgd',
                  value: detail.gevolgdLabel,
                  color: AppColors.successSolid,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  label: 'Resterend',
                  value: detail.resterendLabel,
                  color: AppColors.primary,
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
  final Color color;

  const _MetricTile({
    required this.label,
    required this.value,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.75),
      ),
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
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
        icon: Icons.schedule_outlined,
        label: 'Lesduur',
        waarde: '${detail.lesduurMinuten} minuten',
      ));
    }
    if (detail.pakketprijs != null) {
      rijen.add(_VoorwaardeRij(
        icon: Icons.euro_rounded,
        label: 'Pakketprijs',
        waarde: detail.prijsLabel,
      ));
    }
    if (detail.losseLesprijs != null && detail.losseLesprijs! > 0) {
      rijen.add(_VoorwaardeRij(
        icon: Icons.payments_outlined,
        label: 'Losse lesprijs',
        waarde:
            '€ ${detail.losseLesprijs!.toStringAsFixed(2).replaceAll('.', ',')}',
      ));
    }
    if (detail.startdatum?.isNotEmpty == true) {
      rijen.add(_VoorwaardeRij(
        icon: Icons.event_outlined,
        label: 'Startdatum',
        waarde: detail.startdatum!,
      ));
    }

    if (rijen.isEmpty) {
      return const AppCard(
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
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ),
        Text(
          waarde,
          style: const TextStyle(
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
          icon: Icons.check_circle_rounded,
          color: AppColors.successSolid,
          size: 34,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
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
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E2E7)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.iconDark, size: 18),
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
