import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';
import '../../models/instructeur.dart';
import '../../models/leerling_profiel.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/snackbar.dart';

final _instructeurProvider =
    FutureProvider.autoDispose<Instructeur?>((ref) async {
  final profiel = await ref.watch(mijnProfielProvider.future);
  if (profiel == null) return null;
  return StudentService.getMijnInstructeur(profiel.instructeurId);
});

class ProfielScreen extends ConsumerWidget {
  const ProfielScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profielAsync = ref.watch(mijnProfielProvider);
    final instructeurAsync = ref.watch(_instructeurProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(mijnProfielProvider);
          ref.invalidate(_instructeurProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.dark,
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 28),
                child: profielAsync.when(
                  data: (profiel) => Column(
                    children: [
                      // Avatar
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white24, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            profiel != null
                                ? '${profiel.voornaam[0]}${profiel.achternaam[0]}'
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profiel?.volledigeNaam ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (profiel?.email?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          profiel!.email!,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.55),
                              fontSize: 13),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          profiel != null
                              ? profiel.pakket.label
                              : '',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Center(
                    child: SizedBox(
                      height: 80,
                      child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2),
                    ),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
            ),

            // Body
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Student info
                  profielAsync.when(
                    data: (profiel) => profiel != null
                        ? AppCard(
                            child: Column(
                              children: [
                                if (profiel.telefoon?.isNotEmpty == true)
                                  _InfoTile(
                                    icon: Icons.phone_outlined,
                                    iconColor: AppColors.successSolid,
                                    label: 'Telefoon',
                                    value: profiel.telefoon!,
                                  ),
                                if (profiel.geboortedatum?.isNotEmpty ==
                                    true) ...[
                                  const Divider(height: 20),
                                  _InfoTile(
                                    icon: Icons.cake_outlined,
                                    iconColor: AppColors.primary,
                                    label: 'Geboortedatum',
                                    value: profiel.geboortedatum!,
                                  ),
                                ],
                                const Divider(height: 20),
                                _InfoTile(
                                  icon: Icons.school_outlined,
                                  iconColor: AppColors.infoSolid,
                                  label: 'Status',
                                  value: profiel.status.label,
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SkeletonCard(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 20),

                  // Rijschool / instructor info
                  const SectionHeader(title: 'Mijn rijschool'),
                  const SizedBox(height: 12),
                  instructeurAsync.when(
                    data: (instructeur) => instructeur != null
                        ? AppCard(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const IconBadge(
                                      icon: Icons.directions_car_rounded,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            instructeur.weergaveNaam,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          if (instructeur.naam?.isNotEmpty ==
                                              true)
                                            Text(
                                              instructeur.naam!,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      AppColors.textSecondary),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (instructeur.volledigAdres != null) ...[
                                  const Divider(height: 20),
                                  _InfoTile(
                                    icon: Icons.location_on_outlined,
                                    iconColor: AppColors.primary,
                                    label: 'Adres',
                                    value: instructeur.volledigAdres!,
                                  ),
                                ],
                                if (instructeur.telefoon?.isNotEmpty ==
                                    true) ...[
                                  const Divider(height: 20),
                                  _InfoTile(
                                    icon: Icons.phone_outlined,
                                    iconColor: AppColors.successSolid,
                                    label: 'Telefoon',
                                    value: instructeur.telefoon!,
                                  ),
                                ],
                                if (instructeur.email?.isNotEmpty ==
                                    true) ...[
                                  const Divider(height: 20),
                                  _InfoTile(
                                    icon: Icons.email_outlined,
                                    iconColor: AppColors.infoSolid,
                                    label: 'E-mail',
                                    value: instructeur.email!,
                                  ),
                                ],
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SkeletonCard(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 20),

                  // Actions
                  const SectionHeader(title: 'Account'),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      children: [
                        _ActionTile(
                          icon: Icons.notifications_outlined,
                          iconColor: AppColors.warningSolid,
                          label: 'Meldingen',
                          onTap: () => context.go('/notificaties'),
                        ),
                        const Divider(height: 20),
                        _ActionTile(
                          icon: Icons.help_outline_rounded,
                          iconColor: AppColors.infoSolid,
                          label: 'Help & ondersteuning',
                          onTap: () => showAppSnackBar(
                              context,
                              'Neem contact op met je rijschool voor hulp.'),
                        ),
                        const Divider(height: 20),
                        _ActionTile(
                          icon: Icons.logout_rounded,
                          iconColor: AppColors.dangerSolid,
                          label: 'Uitloggen',
                          labelColor: AppColors.dangerText,
                          onTap: () => _uitloggen(context, ref),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Center(
                    child: Text(
                      'Mijn Rijschool Leerling App',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textHint),
                    ),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uitloggen(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Uitloggen',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Weet je zeker dat je wilt uitloggen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dangerSolid),
            child: const Text('Uitloggen'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await StudentService.uitloggen();
    if (context.mounted) context.go('/login');
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
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
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
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
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: labelColor ?? AppColors.textPrimary,
              ),
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }
}
