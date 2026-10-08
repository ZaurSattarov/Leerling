import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/cool_icons.dart';
import '../../core/utils/contact_uri.dart';
import '../../models/instructeur.dart';
import '../../models/leerling_voertuig.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/klantio_pressable.dart';
import '../../shared/widgets/settings_design.dart';
import '../../shared/widgets/snackbar.dart';
import 'rijschool_provider.dart';

/// Profiel -> Mijn rijschool. Volledig alleen-lezen: alle velden komen uit
/// `instructeur_profielen` via de al bestaande `mijnInstructeurProvider`
/// (StudentService.getMijnInstructeur(), gescoped op leerlingen.
/// instructeur_id). RLS laat de leerling uitsluitend de eigen gekoppelde
/// instructeur lezen en er is geen UPDATE-policy -- dus bewust GEEN
/// bewerk-UI en GEEN groen vinkje. Zie docs/PROFIEL_FASE6_MIJN_RIJSCHOOL.md.
///
/// Opbouw 1-op-1 als de Rijschoolgegevens-scherm van de Instructeur-app
/// ([SettingsScaffold]: label boven een wit alleen-lezen veld). De velden
/// zijn leerling-eigen.
class MijnRijschoolScreen extends ConsumerWidget {
  const MijnRijschoolScreen({super.key});

  static const _leeg = 'Niet ingesteld door je rijschool';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instructeurAsync = ref.watch(mijnInstructeurProvider);
    final voertuigAsync = ref.watch(mijnVoertuigProvider);

    return instructeurAsync.when(
      loading: () => const SettingsScaffold(
        titel: 'Mijn rijschool',
        children: [
          SkeletonBox(height: 56, radius: 16),
          SizedBox(height: 16),
          SkeletonBox(height: 56, radius: 16),
          SizedBox(height: 16),
          SkeletonBox(height: 56, radius: 16),
        ],
      ),
      error: (e, _) => SettingsScaffold(
        titel: 'Mijn rijschool',
        children: [
          const SizedBox(height: 60),
          EmptyState(
            icon: CoolIcons.cloudOff,
            title: 'Kon rijschool niet laden',
            subtitle: e.toString(),
          ),
        ],
      ),
      data: (instructeur) {
        if (instructeur == null) {
          return const SettingsScaffold(
            titel: 'Mijn rijschool',
            children: [
              SizedBox(height: 60),
              EmptyState(
                icon: CoolIcons.bookOpen,
                title: 'Nog geen rijschool gekoppeld',
              ),
            ],
          );
        }
        return _MijnRijschoolBody(
          instructeur: instructeur,
          voertuig: voertuigAsync.valueOrNull,
          voertuigLaden: voertuigAsync.isLoading,
        );
      },
    );
  }
}

class _MijnRijschoolBody extends StatelessWidget {
  final Instructeur instructeur;
  final LeerlingVoertuig? voertuig;
  final bool voertuigLaden;
  const _MijnRijschoolBody({
    required this.instructeur,
    this.voertuig,
    this.voertuigLaden = false,
  });

  static const _leeg = MijnRijschoolScreen._leeg;
  static const _gat = SizedBox(height: 14);
  static const _groepGat = SizedBox(height: 24);

  bool get _heeftGeldigeWebsite => _isValidHttpsUrl(instructeur.website);

  bool get _heeftGeldigTelefoonnummer =>
      ContactUri.tel(instructeur.telefoon) != null;

  bool get _heeftGeldigEmail => _isValidEmail(instructeur.email);

  bool get _heeftContactSectie =>
      _heeftGeldigTelefoonnummer ||
      _heeftGeldigEmail ||
      _heeftGeldigeWebsite ||
      instructeur.volledigAdres != null;

  String _of(String? v) => v?.trim().isNotEmpty == true ? v!.trim() : _leeg;

  @override
  Widget build(BuildContext context) {
    final contactRijen = <Widget>[
      if (_heeftGeldigTelefoonnummer)
        _ContactActieRij(
          label: 'Bellen',
          waarde: instructeur.telefoon!.trim(),
          onTap: () => _openUri(context, ContactUri.tel(instructeur.telefoon)!),
        ),
      if (_heeftGeldigEmail)
        _ContactActieRij(
          label: 'E-mailen',
          waarde: instructeur.email!.trim(),
          onTap: () => _openUri(context, ContactUri.email(instructeur.email)!),
        ),
      if (_heeftGeldigeWebsite)
        _ContactActieRij(
          label: 'Website openen',
          waarde: instructeur.website!.trim(),
          onTap: () =>
              _openUri(context, Uri.parse(instructeur.website!.trim())),
        ),
      if (instructeur.volledigAdres != null)
        _ContactActieRij(
          label: 'Route openen',
          waarde: _formatAdres(instructeur)!.replaceAll('\n', ', '),
          onTap: () => _openUri(context, _routeUri(_formatAdres(instructeur)!)),
        ),
    ];

    return SettingsScaffold(
      titel: 'Mijn rijschool',
      children: [
        // ── Rijschool ──
        SettingsWaarde(
            label: 'Rijschoolnaam', waarde: instructeur.weergaveNaam),
        _gat,
        SettingsWaarde(
          label: 'Adres',
          waarde: _formatAdres(instructeur) ?? _leeg,
          maxLines: 3,
        ),
        if (instructeur.website?.trim().isNotEmpty == true) ...[
          _gat,
          SettingsWaarde(label: 'Website', waarde: instructeur.website!.trim()),
        ],
        if (instructeur.kvkNummer?.trim().isNotEmpty == true) ...[
          _gat,
          SettingsWaarde(
              label: 'KvK-nummer', waarde: instructeur.kvkNummer!.trim()),
        ],

        // ── Voertuig ──
        _groepGat,
        if (voertuig != null) ...[
          SettingsWaarde(label: 'Kenteken', waarde: _of(voertuig!.kenteken)),
          _gat,
          SettingsWaarde(label: 'Merk / model', waarde: _of(voertuig!.naam)),
        ] else
          SettingsWaarde(
            label: 'Toegewezen voertuig',
            waarde: voertuigLaden ? 'Laden…' : 'Nog geen voertuig toegewezen',
          ),

        // ── Jouw instructeur ──
        _groepGat,
        SettingsWaarde(
            label: 'Naam instructeur', waarde: _of(instructeur.naam)),
        if (instructeur.telefoon?.trim().isNotEmpty == true) ...[
          _gat,
          SettingsWaarde(
              label: 'Telefoon instructeur',
              waarde: instructeur.telefoon!.trim()),
        ],
        if (instructeur.email?.trim().isNotEmpty == true) ...[
          _gat,
          SettingsWaarde(
              label: 'E-mail instructeur', waarde: instructeur.email!.trim()),
        ],

        // ── Contact (tikbare acties) ──
        if (_heeftContactSectie) ...[
          _groepGat,
          SettingsCard(children: [
            for (var i = 0; i < contactRijen.length; i++) ...[
              if (i > 0) const SettingsDivider(),
              contactRijen[i],
            ],
          ]),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Tikbare actie in dezelfde rij-stijl als de Instructeur-instellingen
/// ([SettingsDesign.titleStyle]/[SettingsDesign.subtitleStyle]).
class _ContactActieRij extends StatelessWidget {
  final String label;
  final String waarde;
  final VoidCallback onTap;

  const _ContactActieRij({
    required this.label,
    required this.waarde,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return KlantioPressable(
      onTap: onTap,
      child: Padding(
        padding: SettingsDesign.rowPadding,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: SettingsDesign.titleStyle),
                  const SizedBox(height: 4),
                  Text(
                    waarde,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SettingsDesign.subtitleStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(CoolIcons.chevronRight,
                color: SettingsDesign.chevron, size: 20),
          ],
        ),
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

/// Opent [uri] in de bijbehorende app (bellen, mail, browser, kaart). Zonder
/// eerst `canLaunchUrl` te vragen: op iOS geeft dat false voor schema's die
/// niet in LSApplicationQueriesSchemes staan, terwijl het openen zelf prima
/// werkt. Lukt het niet (bv. simulator zonder Telefoon-app), dan volgt een
/// duidelijke melding i.p.v. dat er niets gebeurt.
Future<void> _openUri(BuildContext context, Uri uri) async {
  var gelukt = false;
  try {
    gelukt = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    gelukt = false;
  }
  if (!gelukt && context.mounted) {
    showAppSnackBar(
      context,
      'Openen lukt niet op dit toestel.',
      isError: true,
    );
  }
}

/// Kaart-URL: Apple Plans op iOS, Google Maps elders.
Uri _routeUri(String adres) {
  final q = Uri.encodeComponent(adres.replaceAll('\n', ', '));
  return Platform.isIOS
      ? Uri.parse('https://maps.apple.com/?daddr=$q&dirflg=d')
      : Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$q');
}
