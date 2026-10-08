import 'package:flutter/material.dart';

import 'profiel_menu_widgets.dart';

/// Actierij in een instellingenscherm. Zelfde opbouw als de menutegels van
/// het Profiel-hoofdscherm ([ProfielMenuTile], 1-op-1 de Instructeur-app).
class SettingsActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String semanticLabel;
  final VoidCallback? onTap;

  const SettingsActionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.semanticLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: onTap != null,
      enabled: onTap != null,
      label: semanticLabel,
      child: ProfielMenuTile(
        icon: icon,
        label: title,
        subtitle: subtitle,
        onTap: onTap,
      ),
    );
  }
}
