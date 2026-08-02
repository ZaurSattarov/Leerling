import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../features/notificaties/notificaties_provider.dart';

// 1-op-1 overgenomen uit de Instructeur-app (rijschool-planner-flutter,
// lib/shared/widgets/app_header.dart) -- de Leerlingen-header uit die app
// is de vastgestelde bron van waarheid voor de buitenvorm van alle
// hoofdtabs: volledig rechthoekig van schermrand tot schermrand (GEEN
// BorderRadius, GEEN boxShadow, GEEN horizontale marge). Alleen content
// (leading/eyebrowText/title/actions) verschilt per scherm.

/// Enige gedeelde hoofdheader voor alle hoofdtabs (Home, Planning,
/// Voortgang, Facturen, Profiel, Lesvoorbereiding).
class MainTabHeader extends StatelessWidget {
  final Widget? leading;
  final String eyebrowText;
  final String title;
  final List<Widget> actions;

  const MainTabHeader({
    super.key,
    this.leading,
    required this.eyebrowText,
    required this.title,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF141C2B), Color(0xFF1A2D42)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 10)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      eyebrowText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white54,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < actions.length; i++) ...[
                actions[i],
                if (i != actions.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Gedeelde ronde header-actieknop -- zelfde vorm/grootte/kleur overal: een
/// CircleAvatar van 40x40.
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
    final knop = CircleAvatar(
      radius: 20,
      backgroundColor:
          actief ? AppColors.primary : Colors.white.withValues(alpha: 0.13),
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
      constraints: const BoxConstraints(minWidth: 18),
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        '$count',
        style: GoogleFonts.inter(
          color: AppColors.textPrimary,
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
