import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/avatar_service.dart';
import '../../core/services/student_service.dart';
import '../../models/leerling_profiel.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/snackbar.dart';
import '../../core/constants/cool_icons.dart';
import '../../shared/widgets/main_scaffold.dart';

// Gedeelde profielfoto-weergave + upload-flow (Fase 5). Eerder inline in
// profiel_screen.dart -- hierheen verplaatst zodat zowel de profielkaart
// bovenaan Profiel als het nieuwe "Persoonlijke gegevens"-detailscherm
// dezelfde, enige implementatie van de upload-orkestratie gebruiken i.p.v.
// een tweede kopie. De onderliggende dataflow is ongewijzigd:
// StudentService.uploadMijnProfielfoto() -> avatars-bucket + leerlingen.
// avatar_url, daarna mijnProfielProvider invalideren. Dit is de ENIGE kolom
// die de leerling zelf mag wijzigen (Fase 2-trigger op leerlingen dwingt dat
// af, ook als dit component ergens verkeerd zou worden aangeroepen).

/// Avatar met ingebouwde tap-to-change-upload-flow. Toont foto/initialen,
/// een camera-badge, en een laadstatus tijdens het uploaden.
class EditableProfielAvatar extends ConsumerStatefulWidget {
  final LeerlingProfiel? profiel;
  final double size;

  /// Toon de camera-badge (standaard). De profielkaart bovenaan Profiel
  /// toont, net als de Instructeur-app, geen badge.
  final bool toonBadge;

  const EditableProfielAvatar({
    super.key,
    required this.profiel,
    this.size = 66,
    this.toonBadge = true,
  });

  @override
  ConsumerState<EditableProfielAvatar> createState() =>
      _EditableProfielAvatarState();
}

class _EditableProfielAvatarState extends ConsumerState<EditableProfielAvatar> {
  bool _busy = false;

  Future<void> _kiesProfielfoto() async {
    final profiel = widget.profiel;
    if (profiel == null || _busy) return;

    final source = await metNativeNavAfgedekt<ImageSource>(
      context,
      () => showModalBottomSheet<ImageSource>(
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
                PhotoSourceTile(
                  icon: CoolIcons.image01,
                  label: 'Kies uit galerij',
                  onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                ),
                const Divider(height: 18),
                PhotoSourceTile(
                  icon: CoolIcons.image02,
                  label: 'Maak foto',
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 900,
        imageQuality: 82,
      );
      if (image == null) return;

      setState(() => _busy = true);
      final bytes = await image.readAsBytes();
      final extensie = image.name.split('.').last;
      await StudentService.uploadMijnProfielfoto(
        leerlingId: profiel.id,
        bytes: bytes,
        bestandExtensie: extensie,
      );
      ref.invalidate(mijnProfielProvider);
      if (mounted) {
        showAppSnackBar(context, 'Profielfoto bijgewerkt', isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _busy ? 0.6 : 1,
      child: ProfileAvatar(
        profiel: widget.profiel,
        size: widget.size,
        onTap: _busy ? null : _kiesProfielfoto,
        busy: _busy,
        toonBadge: widget.toonBadge,
      ),
    );
  }
}

/// Zuiver presentationeel: toont foto/initialen + camera-badge. Geen eigen
/// upload-logica (zie [EditableProfielAvatar] daarvoor).
class ProfileAvatar extends StatelessWidget {
  final LeerlingProfiel? profiel;
  final VoidCallback? onTap;
  final double size;
  final bool busy;
  final bool toonBadge;

  const ProfileAvatar({
    super.key,
    required this.profiel,
    required this.onTap,
    this.size = 66,
    this.busy = false,
    this.toonBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profiel?.avatarUrl;
    final avatarAsset = AvatarService.assetPathFor(profiel?.avatarId);
    final initialen = profiel == null
        ? '?'
        : '${profiel!.voornaam.isNotEmpty ? profiel!.voornaam[0] : ''}${profiel!.achternaam.isNotEmpty ? profiel!.achternaam[0] : ''}'
            .toUpperCase();

    Widget avatarContent;
    if (avatarUrl?.isNotEmpty == true) {
      avatarContent = CachedNetworkImage(
        imageUrl: avatarUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Center(
          child: Text(initialen,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
        ),
        errorWidget: (_, __, ___) => _InitialsAvatar(initialen: initialen),
      );
    } else if (avatarAsset != null) {
      avatarContent = Image.asset(
        avatarAsset,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _InitialsAvatar(initialen: initialen),
      );
    } else {
      avatarContent = _InitialsAvatar(initialen: initialen);
    }

    return Semantics(
      button: onTap != null,
      label: 'Profielfoto wijzigen',
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: ClipOval(child: avatarContent),
            ),
            if (onTap != null && toonBadge)
              Positioned(
                right: -2,
                bottom: -2,
                // Camera-badge 1-op-1 uit de Instructeur-app (_EditProfielScreen):
                // donkere cirkel (#1C2938), witte rand, wit icoon.
                child: Container(
                  width: size >= 80 ? 28 : 25,
                  height: size >= 80 ? 28 : 25,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2938),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: busy
                      ? const Padding(
                          padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(CoolIcons.image02,
                          color: Colors.white, size: 13),
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
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class PhotoSourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const PhotoSourceTile({
    super.key,
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
              child: Icon(icon, color: AppColors.iconPrimary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              CoolIcons.chevronRight,
              color: AppColors.iconPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
