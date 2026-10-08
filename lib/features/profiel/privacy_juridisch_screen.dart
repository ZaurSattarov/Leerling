import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/settings_design.dart';
import 'widgets/profiel_menu_widgets.dart';
import '../../core/constants/cool_icons.dart';

class PrivacyJuridischScreen extends StatelessWidget {
  const PrivacyJuridischScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsBodyScaffold(
      titel: 'Privacy, gegevens & juridisch',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
              children: [
                const SettingsKop('JURIDISCHE DOCUMENTEN'),
                ProfielMenuCard(
                  children: [
                    ProfielMenuTile(
                      icon: CoolIcons.shieldCheck,
                      label: 'Privacybeleid',
                      subtitle: 'Gegevens, rechten en bewaartermijnen',
                      onTap: () => context.push('/profiel/privacy-beleid'),
                    ),
                    const Divider(height: 1, indent: 62),
                    ProfielMenuTile(
                      icon: CoolIcons.fileDocument,
                      label: 'Algemene voorwaarden',
                      subtitle: 'Gebruik van de app',
                      onTap: () =>
                          context.push('/profiel/algemene-voorwaarden'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
