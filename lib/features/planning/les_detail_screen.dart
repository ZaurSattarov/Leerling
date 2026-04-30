import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/datum_utils.dart';
import '../../models/les.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/status_pill.dart';
import '../../shared/widgets/snackbar.dart';
import 'planning_provider.dart';

class LesDetailScreen extends ConsumerWidget {
  final String id;
  const LesDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lesAsync = ref.watch(lesDetailProvider(id));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Les detail'),
        actions: [
          lesAsync.when(
            data: (les) => les != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: StatusPill.les(les.status),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: lesAsync.when(
        data: (les) {
          if (les == null) {
            return const Center(
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Les niet gevonden',
                subtitle: 'Deze les bestaat niet of je hebt geen toegang.',
              ),
            );
          }
          return _LesDetailBody(les: les);
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: EmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'Kon les niet laden',
            subtitle: e.toString(),
          ),
        ),
      ),
    );
  }
}

class _LesDetailBody extends StatelessWidget {
  final Les les;
  const _LesDetailBody({required this.les});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_car_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      DatumUtils.relatiefDatum(les.datum),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  DatumUtils.langeDatum(les.datum),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${les.starttijd} – ${les.eindtijd}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        DatumUtils.duurLabel(les.duurMinuten),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Info rows
          AppCard(
            child: Column(
              children: [
                if (les.instructeurNaam?.isNotEmpty == true)
                  _InfoRow(
                    icon: Icons.person_rounded,
                    iconColor: AppColors.infoSolid,
                    label: 'Instructeur',
                    value: les.instructeurNaam!,
                  ),
                if (les.locatie?.isNotEmpty == true) ...[
                  const Divider(height: 20),
                  _InfoRow(
                    icon: Icons.location_on_rounded,
                    iconColor: AppColors.primary,
                    label: 'Locatie',
                    value: les.locatie!,
                  ),
                ],
                const Divider(height: 20),
                _InfoRow(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppColors.dark3,
                  label: 'Status',
                  valueWidget: StatusPill.les(les.status),
                ),
              ],
            ),
          ),

          if (les.notities?.isNotEmpty == true) ...[
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const IconBadge(
                          icon: Icons.notes_rounded,
                          color: AppColors.dark3,
                          size: 32),
                      const SizedBox(width: 10),
                      const Text('Notities van instructeur',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    les.notities!,
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5),
                  ),
                ],
              ),
            ),
          ],

          // Action buttons
          if (les.status == LesStatus.gepland) ...[
            const SizedBox(height: 20),
            if (les.locatie?.isNotEmpty == true)
              _ActionButton(
                icon: Icons.navigation_rounded,
                label: 'Navigeer naar locatie',
                color: AppColors.infoSolid,
                onTap: () => _openNavigation(context, les.locatie!),
              ),
            if (les.instructeurTelefoon?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.call_rounded,
                      label: 'Bellen',
                      color: AppColors.successSolid,
                      onTap: () => _bel(context, les.instructeurTelefoon!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.message_rounded,
                      label: 'WhatsApp',
                      color: AppColors.whatsapp,
                      onTap: () =>
                          _whatsapp(context, les.instructeurTelefoon!),
                    ),
                  ),
                ],
              ),
            ],
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _openNavigation(BuildContext context, String locatie) async {
    final encoded = Uri.encodeComponent(locatie);
    final uri = Uri.parse('https://maps.google.com/?q=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        showAppSnackBar(context, 'Kan navigatie niet openen', isError: true);
      }
    }
  }

  Future<void> _bel(BuildContext context, String telefoon) async {
    final uri = Uri.parse('tel:$telefoon');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _whatsapp(BuildContext context, String telefoon) async {
    final nr = telefoon.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('https://wa.me/$nr');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: Colors.white, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ),
        valueWidget ??
            Text(
              value ?? '',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}
