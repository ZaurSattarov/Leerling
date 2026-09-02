import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/nav_shell_tokens.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_detail_header.dart';
import 'account_deletion_flow.dart';
import 'widgets/profiel_menu_widgets.dart';

class PrivacyJuridischScreen extends StatelessWidget {
  const PrivacyJuridischScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          MainDetailHeader(
            title: 'Privacy, gegevens & juridisch',
            onBack: () => context.pop(),
            fallbackRoute: '/profiel',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(8, 0, 8, 10),
                  child: Text(
                    'JURIDISCHE DOCUMENTEN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Color(0xFF7B8089),
                    ),
                  ),
                ),
                ProfielMenuCard(
                  children: [
                    ProfielMenuTile(
                      icon: Icons.privacy_tip_rounded,
                      label: 'Privacybeleid',
                      subtitle: 'Gegevens, rechten en bewaartermijnen',
                      onTap: () => context.push('/profiel/privacy-beleid'),
                    ),
                    const Divider(height: 1, indent: 62),
                    ProfielMenuTile(
                      icon: Icons.article_rounded,
                      label: 'Algemene voorwaarden',
                      subtitle: 'Gebruik van de app',
                      onTap: () =>
                          context.push('/profiel/algemene-voorwaarden'),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Padding(
                  padding: EdgeInsets.fromLTRB(8, 0, 8, 10),
                  child: Text(
                    'PRIVACY & MIJN GEGEVENS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Color(0xFF7B8089),
                    ),
                  ),
                ),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: Color(0xFFE11D48),
                        size: 18,
                      ),
                    ),
                    title: const Text(
                      'Account verwijderen',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: const Text(
                      'Verwijder je Klantio-account en persoonlijke profiel',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: Color(0xFF7B8089),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0x52222936),
                      size: 17,
                    ),
                    onTap: () => AccountDeletionFlow.start(context),
                  ),
                ),
                SizedBox(height: NavShellTokens.contentBottomClearance),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
