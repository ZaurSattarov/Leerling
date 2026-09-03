import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../features/notificaties/notificaties_provider.dart';
import 'klantio_header.dart';

/// Enige gedeelde hoofdheader voor de hoofdtabs met een gecentreerde
/// standaardtitel (Planning, Voortgang, Facturen, Profiel). Home heeft een
/// eigen `HomeHeader` (home_header.dart) -- persoonlijke begroeting i.p.v.
/// een gecentreerde titel -- maar bouwt op dezelfde [KlantioHeaderShell]
/// zodat de hoogte overal identiek blijft (geen layout-jump bij tabwissel).
///
/// Geen eyebrow-label meer (voorheen een kleine tekst boven de titel,
/// bv. "PLANNING" boven "Mijn lessen") -- voegde geen noodzakelijke
/// informatie toe en maakte de header onnodig hoog.
class MainTabHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;

  const MainTabHeader({
    super.key,
    required this.title,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return KlantioHeaderShell(
      child: KlantioCenteredTitleRow(
        title: title,
        trailing: actions.isEmpty ? null : _ActionsRow(actions: actions),
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  final List<Widget> actions;
  const _ActionsRow({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          actions[i],
          if (i != actions.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

/// Gedeelde ronde header-actieknop -- 1-op-1 gelijk aan de Instructeur-app:
/// cirkel 40x40, wit icoon exact in het midden, badge rechtsboven.
class MainHeaderIconKnop extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool actief;
  final double iconSize;
  final int? badgeCount;

  const MainHeaderIconKnop({
    super.key,
    required this.icon,
    required this.onTap,
    this.actief = false,
    this.iconSize = 20,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final knop = Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: actief
            ? AppColors.primary
            : Colors.white.withValues(alpha: 0.13),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
    return GestureDetector(
      onTap: onTap,
      child: (badgeCount ?? 0) > 0
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                knop,
                Positioned(
                  right: -4,
                  top: -4,
                  child: _HeaderBadgePil(count: badgeCount!),
                ),
              ],
            )
          : knop,
    );
  }
}

class _HeaderBadgePil extends StatelessWidget {
  final int count;

  const _HeaderBadgePil({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('main_header_notification_badge'),
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 10,
          height: 1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Meldingenknop gekoppeld aan [ongelezenNotificatiesProvider] -- gebruikt
/// door alle hoofdtabs zodat elke tab exact dezelfde knop (stijl én
/// gedrag) toont.
class MainHeaderNotificatieKnop extends ConsumerWidget {
  const MainHeaderNotificatieKnop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ongelezenAantal =
        ref.watch(ongelezenNotificatiesProvider).valueOrNull ?? 0;
    return MainHeaderIconKnop(
      icon: Icons.notifications_none_rounded,
      badgeCount: ongelezenAantal,
      onTap: () => context.push('/notificaties'),
    );
  }
}
