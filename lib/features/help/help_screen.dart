import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_detail_header.dart';

/// Help & Support-hub -- 1-op-1 poort van de Instructeur-app
/// (support_hub_screen.dart): korte introtekst + twee tegels ("Chat met
/// support" en "Help & FAQ"). Zelfde bestaande Klantio-componenten
/// (MainDetailHeader/AppCard) i.p.v. een nieuw ontwerp.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          const MainDetailHeader(
            title: 'Help & Support',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Support',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Heb je hulp nodig met de app, facturen of instellingen? Neem gerust contact op.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SupportTegel(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Chat met support',
                  ondertitel: 'Stuur ons een bericht',
                  onTap: () => context.push('/help/support'),
                ),
                const SizedBox(height: 10),
                _SupportTegel(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & FAQ',
                  ondertitel: 'Veelgestelde vragen',
                  onTap: () => context.push('/help/faq'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportTegel extends StatelessWidget {
  final IconData icon;
  final String label;
  final String ondertitel;
  final VoidCallback onTap;

  const _SupportTegel({
    required this.icon,
    required this.label,
    required this.ondertitel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(icon: icon, color: AppColors.primary, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  ondertitel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textHint,
            size: 20,
          ),
        ],
      ),
    );
  }
}
