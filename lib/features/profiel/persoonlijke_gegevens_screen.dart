import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/cool_icons.dart';
import '../../core/services/student_service.dart';
import '../../core/utils/datum_utils.dart';
import '../../models/leerling_profiel.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/settings_design.dart';
import '../../shared/widgets/toast.dart';
import 'profielfoto_editor.dart';

/// Profiel -> Persoonlijke gegevens.
///
/// Opbouw 1-op-1 als de profiel-bewerkschermen in de Instructeur-app
/// ([SettingsScaffold]: gecentreerde titel, label boven het veld, witte
/// velden van 56px).
///
/// Wat mag de leerling hier bewerken? Voornaam, achternaam, telefoon,
/// geboortedatum en adres (groen vinkje rechtsboven) plus de profielfoto (tik
/// op de foto, direct opgeslagen). NIET: rijbewijscategorie en e-mailadres.
/// Opslaan loopt via de RPC `update_leerling_profiel`; de kolombeveiligings-
/// trigger op `leerlingen` blijft voor rechtstreekse updates fail-closed.
/// Zie docs/PROFIEL_STAP2_BEVEILIGING.md.
class ProfielPersoonlijkeGegevensScreen extends ConsumerWidget {
  const ProfielPersoonlijkeGegevensScreen({super.key});

  static const _leeg = 'Niet ingevuld';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profielAsync = ref.watch(mijnProfielProvider);

    return profielAsync.when(
      loading: () => const SettingsScaffold(
        titel: 'Persoonlijke gegevens',
        children: [
          SkeletonBox(height: 96, radius: 48),
          SizedBox(height: 24),
          SkeletonBox(height: 56, radius: 16),
          SizedBox(height: 16),
          SkeletonBox(height: 56, radius: 16),
          SizedBox(height: 16),
          SkeletonBox(height: 56, radius: 16),
        ],
      ),
      error: (e, _) => SettingsScaffold(
        titel: 'Persoonlijke gegevens',
        children: [
          const SizedBox(height: 60),
          EmptyState(
            icon: CoolIcons.cloudOff,
            title: 'Kon gegevens niet laden',
            subtitle: e.toString(),
          ),
        ],
      ),
      data: (profiel) {
        if (profiel == null) {
          return const SettingsScaffold(
            titel: 'Persoonlijke gegevens',
            children: [
              SizedBox(height: 60),
              EmptyState(
                icon: CoolIcons.userClose,
                title: 'Geen profiel gevonden',
              ),
            ],
          );
        }
        return _Inhoud(profiel: profiel);
      },
    );
  }
}

class _Inhoud extends ConsumerStatefulWidget {
  final LeerlingProfiel profiel;
  const _Inhoud({required this.profiel});

  @override
  ConsumerState<_Inhoud> createState() => _InhoudState();
}

class _InhoudState extends ConsumerState<_Inhoud> {
  late final TextEditingController _voornaam;
  late final TextEditingController _achternaam;
  late final TextEditingController _telefoon;
  late final TextEditingController _adres;
  late final TextEditingController _email;
  late final TextEditingController _rijbewijs;
  DateTime? _geboortedatum;
  bool _bezig = false;

  static const _leeg = ProfielPersoonlijkeGegevensScreen._leeg;

  @override
  void initState() {
    super.initState();
    final p = widget.profiel;
    _voornaam = TextEditingController(text: p.voornaam);
    _achternaam = TextEditingController(text: p.achternaam);
    _telefoon = TextEditingController(text: p.telefoon ?? '');
    _adres = TextEditingController(text: p.adres ?? '');
    _email = TextEditingController(
        text: p.email?.trim().isNotEmpty == true ? p.email!.trim() : _leeg);
    _rijbewijs = TextEditingController(
        text: p.rijbewijsSoort?.trim().isNotEmpty == true
            ? p.rijbewijsSoort!.trim().toUpperCase()
            : _leeg);
    _geboortedatum =
        p.geboortedatum != null ? DateTime.tryParse(p.geboortedatum!) : null;
  }

  @override
  void dispose() {
    for (final c in [
      _voornaam,
      _achternaam,
      _telefoon,
      _adres,
      _email,
      _rijbewijs
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _kiesDatum() async {
    final nu = DateTime.now();
    final gekozen = await showDatePicker(
      context: context,
      initialDate: _geboortedatum ?? DateTime(nu.year - 18),
      firstDate: DateTime(nu.year - 120),
      lastDate: nu,
      helpText: 'Geboortedatum',
    );
    if (gekozen != null) setState(() => _geboortedatum = gekozen);
  }

  Future<void> _opslaan() async {
    if (_voornaam.text.trim().isEmpty || _achternaam.text.trim().isEmpty) {
      AppToast.fout(context, 'Vul je voor- en achternaam in.');
      return;
    }
    setState(() => _bezig = true);
    try {
      await StudentService.updateMijnProfiel(
        voornaam: _voornaam.text,
        achternaam: _achternaam.text,
        telefoon: _telefoon.text,
        geboortedatum: _geboortedatum,
        adres: _adres.text,
      );
      ref.invalidate(mijnProfielProvider);
      if (!mounted) return;
      AppToast.succes(context, 'Gegevens opgeslagen');
      Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) {
        AppToast.fout(
          context,
          e.toString().replaceFirst('Exception: ', '').trim().isEmpty
              ? 'Opslaan mislukt'
              : 'Opslaan mislukt. Probeer het later opnieuw.',
        );
      }
    } finally {
      if (mounted) setState(() => _bezig = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final datumTekst = _geboortedatum != null
        ? DatumUtils.datumZonderWeekdag(
            '${_geboortedatum!.year.toString().padLeft(4, '0')}-'
            '${_geboortedatum!.month.toString().padLeft(2, '0')}-'
            '${_geboortedatum!.day.toString().padLeft(2, '0')}')
        : null;

    // Bewerkbaar door de leerling: voornaam, achternaam, telefoon,
    // geboortedatum, adres -> groen vinkje rechtsboven (Instructeur-stijl).
    // Alleen-lezen (grijs): e-mailadres (account) en rijbewijscategorie
    // (door de rijschool beheerd).
    return SettingsScaffold(
      titel: 'Persoonlijke gegevens',
      onSave: _bezig ? null : _opslaan,
      bezig: _bezig,
      children: [
        const SizedBox(height: 12),
        Center(child: EditableProfielAvatar(profiel: widget.profiel, size: 96)),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Tik op de foto om je profielfoto te wijzigen',
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: SettingsDesign.readOnlyText,
            ),
          ),
        ),
        const SizedBox(height: 32),
        SettingsVeld(controller: _voornaam, label: 'Voornaam'),
        const SizedBox(height: 14),
        SettingsVeld(controller: _achternaam, label: 'Achternaam'),
        const SizedBox(height: 14),
        SettingsVeld(
          controller: _telefoon,
          label: 'Telefoon',
          keyboard: TextInputType.phone,
        ),
        const SizedBox(height: 14),
        const SettingsSectieLabel('Geboortedatum'),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _kiesDatum,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 48,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              datumTekst ?? 'Kies je geboortedatum',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: datumTekst == null
                    ? SettingsDesign.fieldLabel
                    : SettingsDesign.title,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SettingsVeld(controller: _adres, label: 'Adres', maxLines: 3),
        const SizedBox(height: 14),
        SettingsVeld(controller: _email, label: 'E-mailadres', enabled: false),
        const SizedBox(height: 14),
        SettingsVeld(
          controller: _rijbewijs,
          label: 'Rijbewijscategorie',
          enabled: false,
        ),
        const SizedBox(height: 12),
        Text(
          'Je e-mailadres hoort bij je account. Je rijbewijscategorie wordt '
          'door je rijschool beheerd; neem contact op met je instructeur om '
          'die te laten aanpassen.',
          style: TextStyle(
            fontSize: 14,
            height: 1.35,
            color: SettingsDesign.readOnlyText,
          ),
        ),
      ],
    );
  }
}
