import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_detail_header.dart';

class AppMachtigingenScreen extends StatelessWidget {
  const AppMachtigingenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 96;

    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: Column(
        children: [
          const MainDetailHeader(
            title: 'Machtigingen',
            fallbackRoute: '/profiel',
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, bottom),
              children: const [
                AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconBadge(
                        icon: Icons.notifications_none_rounded,
                        color: AppColors.iconPrimary,
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: _InfoText(
                          title: 'Meldingen',
                          subtitle:
                              'Belangrijke berichten blijven zichtbaar in de app. Meldingen buiten de app worden later ondersteund.',
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                AppCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconBadge(
                        icon: Icons.photo_camera_outlined,
                        color: AppColors.iconPrimary,
                      ),
                      SizedBox(width: 14),
                      Expanded(
                        child: _InfoText(
                          title: 'Camera en foto\'s',
                          subtitle:
                              'Deze machtiging wordt alleen gevraagd wanneer je een profielfoto maakt of kiest.',
                        ),
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

class _InfoText extends StatelessWidget {
  final String title;
  final String subtitle;

  const _InfoText({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.35,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
