import 'package:flutter/material.dart';

import '../../core/constants/cool_icons.dart';
import '../../shared/widgets/settings_design.dart';
import 'widgets/profiel_menu_widgets.dart';

/// Profiel -> Machtigingen. Alleen uitleg (de systeemmachtigingen worden door
/// iOS/Android beheerd) -- dus niets te bewerken en geen groen vinkje.
class AppMachtigingenScreen extends StatelessWidget {
  const AppMachtigingenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsBodyScaffold(
      titel: 'Machtigingen',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: const [
          ProfielMenuCard(
            children: [
              ProfielMenuTile(
                icon: CoolIcons.bell,
                label: 'Meldingen',
                subtitle:
                    'Belangrijke berichten blijven zichtbaar in de app. Meldingen buiten de app worden later ondersteund.',
              ),
              Divider(height: 1, indent: 62),
              ProfielMenuTile(
                icon: CoolIcons.image02,
                label: 'Camera en foto\'s',
                subtitle:
                    'Deze machtiging wordt alleen gevraagd wanneer je een profielfoto maakt of kiest.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
