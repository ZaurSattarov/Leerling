import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/contact_uri.dart';
import '../../models/instructeur.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_detail_header.dart';
import 'rijschool_provider.dart';
import 'widgets/profile_info_row.dart';

/// Profiel -> Mijn rijschool (Fase 6). Volledig read-only: alle velden komen
/// uit `instructeur_profielen` via de al bestaande `mijnInstructeurProvider`
/// (StudentService.getMijnInstructeur(), gescoped op leerlingen.
/// instructeur_id). RLS (leerling_instructeur_profiel_lezen /
/// student_instructeur_select) laat de leerling uitsluitend de eigen
/// gekoppelde instructeur lezen, geen UPDATE-policy -- er is dus bewust geen
/// bewerk-UI. `leerlingen.school_id` is onderzocht als mogelijke tweede bron
/// maar bleek voor beide bestaande leerlingen NULL en de `schools`-tabel
/// bevat geen profielvelden en geen leerling-leesrecht -- terecht niet
/// gebruikt, zie docs/PROFIEL_FASE6_MIJN_RIJSCHOOL.md.
class MijnRijschoolScreen extends ConsumerWidget {
  const MijnRijschoolScreen({super.key});

  static const _leeg = 'Niet ingesteld door je rijschool';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instructeurAsync = ref.watch(mijnInstructeurProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          const MainDetailHeader(
            title: 'Mijn rijschool',
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.invalidate(mijnInstructeurProvider),
              child: instructeurAsync.when(
                loading: () => ListView(
                  padding: const EdgeInsets.all(20),
                  children: const [
                    SkeletonBox(height: 100, radius: 18),
                    SizedBox(height: 14),
                    SkeletonCard(),
                    SizedBox(height: 10),
                    SkeletonCard(),
                  ],
                ),
                error: (e, _) => ListView(
                  children: [
                    const SizedBox(height: 60),
                    EmptyState(
                      icon: Icons.wifi_off_rounded,
                      title: 'Kon rijschool niet laden',
                      subtitle: e.toString(),
                    ),
                  ],
                ),
                data: (instructeur) {
                  if (instructeur == null) {
                    return ListView(
                      children: const [
                        SizedBox(height: 60),
                        EmptyState(
                          icon: Icons.school_outlined,
                          title: 'Nog geen rijschool gekoppeld',
                        ),
                      ],
                    );
                  }
                  return _MijnRijschoolBody(instructeur: instructeur);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MijnRijschoolBody extends StatelessWidget {
  final Instructeur instructeur;
  const _MijnRijschoolBody({required this.instructeur});

  static const _leeg = MijnRijschoolScreen._leeg;

  bool get _heeftGeldigeWebsite => _isValidHttpsUrl(instructeur.website);

  bool get _heeftGeldigTelefoonnummer =>
      ContactUri.tel(instructeur.telefoon) != null;

  bool get _heeftGeldigEmail => _isValidEmail(instructeur.email);

  bool get _heeftInstructeurSectie =>
      instructeur.naam?.trim().isNotEmpty == true ||
      instructeur.telefoon?.trim().isNotEmpty == true ||
      instructeur.email?.trim().isNotEmpty == true;

  bool get _heeftContactSectie =>
      _heeftGeldigTelefoonnummer ||
      _heeftGeldigEmail ||
      _heeftGeldigeWebsite ||
      instructeur.volledigAdres != null;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _RijschoolKaart(instructeur: instructeur),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Rijschool'),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              ProfileInfoRow(
                icon: Icons.store_outlined,
                iconColor: AppColors.iconBlue,
                label: 'Rijschoolnaam',
                value: instructeur.weergaveNaam,
              ),
              const Divider(height: 20),
              ProfileInfoRow(
                icon: Icons.location_on_outlined,
                iconColor: AppColors.iconSlate,
                label: 'Adres',
                value: _formatAdres(instructeur) ?? _leeg,
                isEmpty: _formatAdres(instructeur) == null,
                maxValueLines: 3,
              ),
              if (instructeur.website?.trim().isNotEmpty == true) ...[
                const Divider(height: 20),
                ProfileInfoRow(
                  icon: Icons.language_outlined,
                  iconColor: AppColors.iconPurple,
                  label: 'Website',
                  value: instructeur.website!.trim(),
                  maxValueLines: 2,
                ),
              ],
              if (instructeur.kvkNummer?.trim().isNotEmpty == true) ...[
                const Divider(height: 20),
                ProfileInfoRow(
                  icon: Icons.badge_outlined,
                  iconColor: AppColors.iconDark,
                  label: 'KvK-nummer',
                  value: instructeur.kvkNummer!.trim(),
                ),
              ],
            ],
          ),
        ),
        if (_heeftInstructeurSectie) ...[
          const SizedBox(height: 22),
          const SectionHeader(title: 'Jouw instructeur'),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                ProfileInfoRow(
                  icon: Icons.person_outline,
                  iconColor: AppColors.iconGreen,
                  label: 'Naam instructeur',
                  value: instructeur.naam?.trim().isNotEmpty == true
                      ? instructeur.naam!.trim()
                      : _leeg,
                  isEmpty: instructeur.naam?.trim().isNotEmpty != true,
                ),
                if (instructeur.telefoon?.trim().isNotEmpty == true) ...[
                  const Divider(height: 20),
                  ProfileInfoRow(
                    icon: Icons.phone_outlined,
                    iconColor: AppColors.iconAmber,
                    label: 'Telefoon',
                    value: instructeur.telefoon!.trim(),
                  ),
                ],
                if (instructeur.email?.trim().isNotEmpty == true) ...[
                  const Divider(height: 20),
                  ProfileInfoRow(
                    icon: Icons.email_outlined,
                    iconColor: AppColors.iconPurple,
                    label: 'E-mail',
                    value: instructeur.email!.trim(),
                    maxValueLines: 2,
                  ),
                ],
              ],
            ),
          ),
        ],
        if (_heeftContactSectie) ...[
          const SizedBox(height: 22),
          const SectionHeader(title: 'Contact'),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                if (_heeftGeldigTelefoonnummer)
                  _ContactActieRij(
                    icon: Icons.call_outlined,
                    iconColor: AppColors.iconGreen,
                    label: 'Bellen',
                    waarde: instructeur.telefoon!.trim(),
                    onTap: () => _openUri(
                        context, ContactUri.tel(instructeur.telefoon)!),
                  ),
                if (_heeftGeldigTelefoonnummer &&
                    (_heeftGeldigEmail || instructeur.volledigAdres != null))
                  const Divider(height: 20),
                if (_heeftGeldigEmail)
                  _ContactActieRij(
                    icon: Icons.email_outlined,
                    iconColor: AppColors.iconPurple,
                    label: 'E-mailen',
                    waarde: instructeur.email!.trim(),
                    onTap: () =>
                        _openUri(context, ContactUri.email(instructeur.email)!),
                  ),
                if (_heeftGeldigEmail &&
                    (_heeftGeldigeWebsite || instructeur.volledigAdres != null))
                  const Divider(height: 20),
                if (_heeftGeldigeWebsite)
                  _ContactActieRij(
                    icon: Icons.language_outlined,
                    iconColor: AppColors.iconPurple,
                    label: 'Website openen',
                    waarde: instructeur.website!.trim(),
                    onTap: () => _openUri(
                        context, Uri.parse(instructeur.website!.trim())),
                  ),
                if (_heeftGeldigeWebsite && instructeur.volledigAdres != null)
                  const Divider(height: 20),
                if (instructeur.volledigAdres != null)
                  _ContactActieRij(
                    icon: Icons.directions_outlined,
                    iconColor: AppColors.iconBlue,
                    label: 'Route openen',
                    waarde: _formatAdres(instructeur)!,
                    onTap: () => _openUri(
                      context,
                      Uri.parse(
                        'https://maps.google.com/?q=${Uri.encodeComponent(_formatAdres(instructeur)!)}',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}

class _RijschoolKaart extends StatelessWidget {
  final Instructeur instructeur;
  const _RijschoolKaart({required this.instructeur});

  @override
  Widget build(BuildContext context) {
    final logoUrl = instructeur.logoUrl?.trim();
    return AppCard(
      child: Row(
        children: [
          _RijschoolLogo(logoUrl: logoUrl, naam: instructeur.weergaveNaam),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instructeur.weergaveNaam,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (instructeur.naam?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    instructeur.naam!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RijschoolLogo extends StatelessWidget {
  final String? logoUrl;
  final String naam;
  const _RijschoolLogo({required this.logoUrl, required this.naam});

  @override
  Widget build(BuildContext context) {
    final initiaal =
        naam.trim().isNotEmpty ? naam.trim()[0].toUpperCase() : '?';
    Widget content;
    if (logoUrl?.isNotEmpty == true) {
      content = CachedNetworkImage(
        imageUrl: logoUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Center(
          child: Text(initiaal,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
        ),
        errorWidget: (_, __, ___) => Center(
          child: Text(initiaal,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800)),
        ),
      );
    } else {
      content = Center(
        child: Text(initiaal,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800)),
      );
    }
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: content,
      ),
    );
  }
}

class _ContactActieRij extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String waarde;
  final VoidCallback onTap;

  const _ContactActieRij({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.waarde,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          IconBadge(icon: icon, color: iconColor, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  waarde,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }
}

// ── Validatie & veilig openen ────────────────────────────────────────────
// Zelfde per-scherm patroon als elders in de app (help_screen.dart,
// profiel_screen.dart) -- geen gedeelde url-service, wel met expliciete
// validatie vóór openen, specifiek voor Fase 6.

String? _formatAdres(Instructeur instructeur) {
  final straat = instructeur.adres?.trim();
  final postcode = instructeur.postcode?.trim();
  final stad = instructeur.stad?.trim();
  if (straat?.isNotEmpty != true && stad?.isNotEmpty != true) return null;
  final tweedeRegel = [postcode, stad]
      .where((value) => value?.isNotEmpty == true)
      .map((value) => value!)
      .join(' ');
  if (straat?.isNotEmpty == true && tweedeRegel.isNotEmpty) {
    return '$straat\n$tweedeRegel';
  }
  return straat?.isNotEmpty == true ? straat : tweedeRegel;
}

bool _isValidHttpsUrl(String? url) {
  if (url == null) return false;
  final trimmed = url.trim();
  if (!trimmed.startsWith('https://')) return false;
  final uri = Uri.tryParse(trimmed);
  return uri != null &&
      uri.hasScheme &&
      uri.scheme == 'https' &&
      uri.host.isNotEmpty;
}

bool _isValidEmail(String? email) {
  if (email == null) return false;
  final trimmed = email.trim();
  if (trimmed.isEmpty) return false;
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmed);
}

/// Normaliseert naar een veilige `tel:`-URI, of null als er geen bruikbaar
/// nummer is. Strip alles behalve cijfers en een optioneel leidend '+'.
Future<void> _openUri(BuildContext context, Uri uri) async {
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
