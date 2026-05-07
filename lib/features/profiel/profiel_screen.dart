import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
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
                      ProfileAvatar(
                        profiel: profiel,
                        onTap: profiel == null
                            ? null
                            : () => _kiesProfielfoto(context, ref, profiel),
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
                            color: Colors.white.withValues(alpha: 0.84),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18)),
                        ),
                        child: Text(
                          profiel != null ? _pakketBadgeLabel(profiel) : '',
                          style: const TextStyle(
                              color: Colors.white,
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
                                    iconColor: AppColors.dark3,
                                    label: 'Telefoon',
                                    value: profiel.telefoon!,
                                  ),
                                if (profiel.geboortedatum?.isNotEmpty ==
                                    true) ...[
                                  const Divider(height: 20),
                                  _InfoTile(
                                    icon: Icons.cake_outlined,
                                    iconColor: AppColors.dark3,
                                    label: 'Geboortedatum',
                                    value: profiel.geboortedatum!,
                                  ),
                                ],
                                const Divider(height: 20),
                                _InfoTile(
                                  icon: Icons.school_outlined,
                                  iconColor: AppColors.dark3,
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
                                      color: AppColors.dark3,
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
                                    iconColor: AppColors.dark3,
                                    label: 'Adres',
                                    value: instructeur.volledigAdres!,
                                  ),
                                ],
                                if (instructeur.telefoon?.isNotEmpty ==
                                    true) ...[
                                  const Divider(height: 20),
                                  _InfoTile(
                                    icon: Icons.phone_outlined,
                                    iconColor: AppColors.dark3,
                                    label: 'Telefoon',
                                    value: instructeur.telefoon!,
                                  ),
                                ],
                                if (instructeur.email?.isNotEmpty == true) ...[
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
                          icon: Icons.schedule_outlined,
                          iconColor: AppColors.dark3,
                          label: 'Mijn beschikbaarheid',
                          onTap: () => context.push('/beschikbaarheid'),
                        ),
                        const Divider(height: 20),
                        _ActionTile(
                          icon: Icons.notifications_outlined,
                          iconColor: AppColors.primary,
                          label: 'Meldingen',
                          onTap: () => context.go('/notificaties'),
                        ),
                        const Divider(height: 20),
                        _ActionTile(
                          icon: Icons.help_outline_rounded,
                          iconColor: AppColors.infoSolid,
                          label: 'Help & ondersteuning',
                          onTap: () => showAppSnackBar(context,
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
                      style: TextStyle(fontSize: 12, color: AppColors.textHint),
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

  String _pakketBadgeLabel(LeerlingProfiel profiel) {
    if (profiel.lessenTotaal > 0) {
      return '${profiel.pakket.label} pakket - ${profiel.lessenTotaal} lessen';
    }
    return 'Pakket: ${profiel.pakket.label}';
  }

  Future<void> _kiesProfielfoto(
    BuildContext context,
    WidgetRef ref,
    LeerlingProfiel profiel,
  ) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              _PhotoSourceTile(
                icon: Icons.photo_library_outlined,
                label: 'Kies uit galerij',
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              const Divider(height: 18),
              _PhotoSourceTile(
                icon: Icons.photo_camera_outlined,
                label: 'Maak foto',
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return;

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 900,
        imageQuality: 82,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final extensie = image.name.split('.').last;
      if (context.mounted) {
        showAppSnackBar(context, 'Profielfoto uploaden...');
      }
      await StudentService.uploadMijnProfielfoto(
        leerlingId: profiel.id,
        bytes: bytes,
        bestandExtensie: extensie,
      );
      ref.invalidate(mijnProfielProvider);
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Profielfoto bijgewerkt',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    }
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

class ProfileAvatar extends StatelessWidget {
  final LeerlingProfiel? profiel;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    required this.profiel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profiel?.avatarUrl;
    final initialen = profiel == null
        ? '?'
        : '${profiel!.voornaam.isNotEmpty ? profiel!.voornaam[0] : ''}${profiel!.achternaam.isNotEmpty ? profiel!.achternaam[0] : ''}'
            .toUpperCase();

    return Semantics(
      button: true,
      label: 'Profielfoto wijzigen',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: AppColors.dark3,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: ClipOval(
                child: avatarUrl?.isNotEmpty == true
                    ? CachedNetworkImage(
                        imageUrl: avatarUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        errorWidget: (_, __, ___) =>
                            _InitialsAvatar(initialen: initialen),
                      )
                    : _InitialsAvatar(initialen: initialen),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 2,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.dark, width: 2),
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  color: Colors.white,
                  size: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initialen;

  const _InitialsAvatar({required this.initialen});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initialen.isEmpty ? '?' : initialen,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PhotoSourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PhotoSourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.dark3,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
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
