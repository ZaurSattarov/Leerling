import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/cool_icons.dart';
import '../../shared/widgets/isomorphic_icons.dart';
import '../../shared/widgets/settings_design.dart';
import 'widgets/profiel_menu_widgets.dart';

/// Profiel -> App-instellingen.
/// Bevat app-voorkeuren zoals donkere modus.
class AppInstellingenScreen extends ConsumerWidget {
  const AppInstellingenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SettingsBodyScaffold(
      titel: 'App-instellingen',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          ProfielMenuCard(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(CoolIcons.moon, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Donkere modus',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Schakel tussen lichte en donkere weergave',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : const Color(0xFF7B8089),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const IsomorphicDarkModeToggle(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
