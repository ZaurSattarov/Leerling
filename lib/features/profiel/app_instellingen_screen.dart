import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/main_detail_header.dart';
import 'widgets/profiel_menu_widgets.dart';

class AppInstellingenScreen extends StatelessWidget {
  const AppInstellingenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 96;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        children: [
          const MainDetailHeader(
            title: 'App-instellingen',
            fallbackRoute: '/profiel',
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(0, 20, 0, bottomPadding),
              children: [
                const ProfielSectionTitle('MELDINGEN'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ProfielMenuCard(
                    children: [
                      ProfielMenuTile(
                        icon: Icons.notifications_none_rounded,
                        label: 'Notificatie-instellingen',
                        subtitle: 'Beheer je meldingsvoorkeuren',
                        onTap: () => context.push(
                          '/profiel/notificatie-instellingen',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const ProfielSectionTitle('MACHTIGINGEN'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ProfielMenuCard(
                    children: [
                      ProfielMenuTile(
                        icon: Icons.app_settings_alt_outlined,
                        label: 'App-machtigingen',
                        subtitle: 'Meldingen, camera en foto\'s',
                        onTap: () => context.push('/profiel/app-machtigingen'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const ProfielSectionTitle('BEVEILIGING'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ProfielMenuCard(
                    children: [
                      ProfielMenuTile(
                        icon: Icons.shield_outlined,
                        label: 'Beveiliging',
                        subtitle: 'Wachtwoord en accountbeveiliging',
                        onTap: () => context.push('/profiel/beveiliging'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
