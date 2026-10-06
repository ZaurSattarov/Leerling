import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../features/notificaties/notificaties_provider.dart';
import 'isomorphic_icons.dart';
import 'klantio_header.dart';

/// Enige gedeelde hoofdheader voor de hoofdtabs met een gecentreerde
/// standaardtitel (Planning, Voortgang, Facturen, Profiel). Home heeft een
/// eigen `HomeHeader` (home_header.dart) -- persoonlijke begroeting i.p.v.
/// een gecentreerde titel -- maar bouwt op dezelfde [KlantioHeaderShell]
/// zodat de hoogte overal identiek blijft (geen layout-jump bij tabwissel).
///
/// 1-op-1 gelijk aan de Instructeur-app (rijschool-planner-flutter/
/// lib/shared/widgets/main_tab_header.dart).
class MainTabHeader extends StatelessWidget {
  final String title;
  final Widget? leading;
  final List<Widget> actions;

  const MainTabHeader({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return KlantioHeaderShell(
      child: KlantioCenteredTitleRow(
        title: title,
        leading: leading,
        titleHorizontalPadding: actions.length > 1
            ? actions.length * 40.0 + (actions.length - 1) * 8 + 8
            : kKlantioHeaderZoneWidth + 8,
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

/// Gedeelde squircle header-actieknop -- zelfde vorm/grootte/kleur als Admin Dashboard:
/// 40x40 squircle (12px radius) met border en lichte achtergrond.
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
    final knop = SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: Icon(
          icon,
          color: actief ? AppColors.primary : const Color(0xFFF8FAFC),
          size: iconSize,
        ),
      ),
    );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: (badgeCount ?? 0) > 0
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                knop,
                Positioned(
                  right: -2,
                  top: -2,
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

/// Gedeelde meldingenknop: de geanimeerde bel uit de Instructeur-app,
/// gekoppeld aan [ongelezenNotificatiesProvider] -- elke hoofdtab toont
/// exact dezelfde knop (stijl én gedrag).
class MainHeaderNotificatieKnop extends ConsumerWidget {
  const MainHeaderNotificatieKnop({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ongelezenAantal =
        ref.watch(ongelezenNotificatiesProvider).valueOrNull ?? 0;

    return Semantics(
      button: true,
      label: ongelezenAantal > 0
          ? 'Meldingen, $ongelezenAantal ongelezen'
          : 'Meldingen',
      child: IsomorphicHeaderBellButton(
        onTap: () => context.push('/notificaties'),
        unreadCount: ongelezenAantal,
        size: 40,
      ),
    );
  }
}
