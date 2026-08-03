import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../models/instructeur.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_detail_header.dart';
import 'rijschool_provider.dart';

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
            eyebrowText: 'PROFIEL',
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
      _normalizedTelUri(instructeur.telefoon) != null;

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
              _GegevensRij(
                icon: Icons.store_outlined,
                iconColor: AppColors.iconBlue,
                label: 'Naam',
                waarde: instructeur.weergaveNaam,
              ),
              const Divider(height: 20),
              _GegevensRij(
                icon: Icons.location_on_outlined,
                iconColor: AppColors.iconSlate,
                label: 'Adres',
                waarde: instructeur.volledigAdres ?? _leeg,
              ),
              if (instructeur.website?.trim().isNotEmpty == true) ...[
                const Divider(height: 20),
                _GegevensRij(
                  icon: Icons.language_outlined,
                  iconColor: AppColors.iconPurple,
                  label: 'Website',
                  waarde: instructeur.website!.trim(),
                ),
              ],
              if (instructeur.kvkNummer?.trim().isNotEmpty == true) ...[
                const Divider(height: 20),
                _GegevensRij(
                  icon: Icons.badge_outlined,
                  iconColor: AppColors.iconDark,
                  label: 'KvK-nummer',
                  waarde: instructeur.kvkNummer!.trim(),
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
                _GegevensRij(
                  icon: Icons.person_outline,
                  iconColor: AppColors.iconGreen,
                  label: 'Naam',
                  waarde: instructeur.naam?.trim().isNotEmpty == true
                      ? instructeur.naam!.trim()
                      : _leeg,
                ),
                if (instructeur.telefoon?.trim().isNotEmpty == true) ...[
                  const Divider(height: 20),
                  _GegevensRij(
                    icon: Icons.phone_outlined,
                    iconColor: AppColors.iconAmber,
                    label: 'Telefoon',
                    waarde: instructeur.telefoon!.trim(),
                  ),
                ],
                if (instructeur.email?.trim().isNotEmpty == true) ...[
                  const Divider(height: 20),
                  _GegevensRij(
                    icon: Icons.email_outlined,
                    iconColor: AppColors.iconPurple,
                    label: 'E-mail',
                    waarde: instructeur.email!.trim(),
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
                        context, _normalizedTelUri(instructeur.telefoon)!),
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
                    onTap: () => _openUri(
                        context, 'mailto:${instructeur.email!.trim()}'),
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
                    onTap: () => _openUri(context, instructeur.website!.trim()),
                  ),
                if (_heeftGeldigeWebsite && instructeur.volledigAdres != null)
                  const Divider(height: 20),
                if (instructeur.volledigAdres != null)
                  _ContactActieRij(
                    icon: Icons.directions_outlined,
                    iconColor: AppColors.iconBlue,
                    label: 'Route openen',
                    waarde: instructeur.volledigAdres!,
                    onTap: () => _openUri(
                      context,
                      'https://maps.google.com/?q=${Uri.encodeComponent(instructeur.volledigAdres!)}',
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
    final initiaal = naam.trim().isNotEmpty ? naam.trim()[0].toUpperCase() : '?';
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

class _GegevensRij extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String waarde;

  const _GegevensRij({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.waarde,
  });

  @override
  Widget build(BuildContext context) {
    final isLeeg = waarde == MijnRijschoolScreen._leeg;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconBadge(icon: icon, color: iconColor, size: 34),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ),
        Flexible(
          child: Text(
            waarde,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isLeeg ? AppColors.textHint : AppColors.textPrimary,
              fontStyle: isLeeg ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
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

bool _isValidHttpsUrl(String? url) {
  if (url == null) return false;
  final trimmed = url.trim();
  if (!trimmed.startsWith('https://')) return false;
  final uri = Uri.tryParse(trimmed);
  return uri != null && uri.hasScheme && uri.scheme == 'https' && uri.host.isNotEmpty;
}

bool _isValidEmail(String? email) {
  if (email == null) return false;
  final trimmed = email.trim();
  if (trimmed.isEmpty) return false;
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmed);
}

/// Normaliseert naar een veilige `tel:`-URI, of null als er geen bruikbaar
/// nummer is. Strip alles behalve cijfers en een optioneel leidend '+'.
String? _normalizedTelUri(String? telefoon) {
  if (telefoon == null) return null;
  final digits = telefoon.replaceAll(RegExp(r'[^\d+]'), '');
  if (digits.isEmpty) return null;
  return 'tel:$digits';
}

Future<void> _openUri(BuildContext context, String uriString) async {
  final uri = Uri.tryParse(uriString);
  if (uri == null) return;
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
