import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/avatar_service.dart';
import '../../core/services/student_service.dart';
import '../../shared/providers/auth_provider.dart';
import '../../core/constants/cool_icons.dart';
import '../../shared/widgets/settings_design.dart';

class ProfielAfrondenScreen extends ConsumerStatefulWidget {
  const ProfielAfrondenScreen({super.key});
  @override
  ConsumerState<ProfielAfrondenScreen> createState() =>
      _ProfielAfrondenScreenState();
}

class _ProfielAfrondenScreenState extends ConsumerState<ProfielAfrondenScreen> {
  final _achternaam = TextEditingController();
  final _adres = TextEditingController();
  DateTime? _geboortedatum;
  String? _avatarId;
  // Probleem 7 (aanmeld herstelronde): canonical waarden 'man'/'vrouw' —
  // optioneel, blokkeert profiel afronden niet (zie isProfielCompleet).
  String? _geslacht;
  bool _saving = false;
  String? _error;
  bool _prefilled = false;

  @override
  void dispose() {
    _achternaam.dispose();
    _adres.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: 'Geboortedatum',
    );
    if (result != null) setState(() => _geboortedatum = result);
  }

  Future<void> _save() async {
    if (_achternaam.text.trim().isEmpty) {
      setState(() => _error = 'Achternaam is verplicht.');
      return;
    }
    if (_geboortedatum == null) {
      setState(() => _error = 'Kies je geboortedatum.');
      return;
    }
    if (_avatarId == null) {
      setState(() => _error = 'Kies een avatar.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await StudentService.voltooiMijnProfiel(
        achternaam: _achternaam.text,
        geboortedatum: _geboortedatum!,
        avatarId: _avatarId!,
        geslacht: _geslacht,
        adres: _adres.text,
      );
      ref.invalidate(mijnProfielProvider);
      final profile = await ref.read(mijnProfielProvider.future);
      if (!mounted) return;
      if (profile?.isProfielCompleet != true) {
        setState(() {
          _saving = false;
          _error = 'Profiel is nog niet volledig opgeslagen. Probeer opnieuw.';
        });
        return;
      }
      context.go('/home');
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = StudentService.currentUser?.email ?? '';
    final profile = ref.watch(mijnProfielProvider).valueOrNull;
    if (!_prefilled && profile != null) {
      _prefilled = true;
      _achternaam.text = profile.achternaam;
      _avatarId = profile.avatarId;
      _adres.text = profile.adres ?? '';
      _geslacht = profile.geslacht;
      final rawDate = profile.geboortedatum;
      if (rawDate != null) _geboortedatum = DateTime.tryParse(rawDate);
    }
    // Opbouw 1-op-1 als de bewerkschermen in de Instructeur-app: label boven
    // het veld, gecentreerde titel en het groene vinkje rechtsboven om op te
    // slaan (i.p.v. een losse knop onderaan).
    return Scaffold(
      backgroundColor: SettingsDesign.background,
      appBar: AppBar(
        backgroundColor: SettingsDesign.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'Maak je profiel af',
          style: TextStyle(
              color: SettingsDesign.title,
              fontSize: 20,
              fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          tooltip: 'Uitloggen',
          icon: Icon(CoolIcons.logOut,
              color: SettingsDesign.iconDark, size: 22),
          onPressed: _saving
              ? null
              : () async {
                  await StudentService.uitloggen();
                  ref.invalidate(mijnProfielProvider);
                  if (context.mounted) context.go('/login');
                },
        ),
        actions: [
          IconButton(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(CoolIcons.check,
                    color: SettingsDesign.switchOn, size: 28),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: SettingsDesign.screenPadding,
          children: [
            Text(
              'Je profiel is al gekoppeld. Vul de ontbrekende gegevens aan om Klantio te gebruiken.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: SettingsDesign.readOnlyText,
              ),
            ),
            const SizedBox(height: 24),
            SettingsVeld(
              controller: _achternaam,
              label: 'Achternaam',
              hint: 'Achternaam',
            ),
            const SizedBox(height: 14),
            SettingsWaarde(label: 'E-mailadres', waarde: email),
            const SizedBox(height: 14),
            const SettingsSectieLabel('Geboortedatum'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                height: 48,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _geboortedatum == null
                      ? 'Kies geboortedatum'
                      : '${_geboortedatum!.day}-${_geboortedatum!.month}-${_geboortedatum!.year}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: _geboortedatum == null
                        ? SettingsDesign.fieldLabel
                        : SettingsDesign.title,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SettingsVeld(
              controller: _adres,
              label: 'Adres',
              hint: 'Adres',
            ),
            const SizedBox(height: 14),
            const SettingsSectieLabel('Geslacht'),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: _GeslachtOptie(
                  label: 'Man',
                  selected: _geslacht == 'man',
                  onTap: () => setState(() => _geslacht = 'man'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _GeslachtOptie(
                  label: 'Vrouw',
                  selected: _geslacht == 'vrouw',
                  onTap: () => setState(() => _geslacht = 'vrouw'),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            const SettingsSectieLabel('Kies een avatar'),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5, mainAxisSpacing: 10, crossAxisSpacing: 10),
              itemCount: AvatarService.avatars.length,
              itemBuilder: (_, index) {
                final avatar = AvatarService.avatars[index];
                final selected = avatar.id == _avatarId;
                return InkWell(
                    onTap: () => setState(() => _avatarId = avatar.id),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 3)),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(avatar.assetPath,
                                fit: BoxFit.cover))));
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!,
                  style: TextStyle(
                      fontSize: 14, color: AppColors.dangerText))
            ],
          ],
        ),
      ),
    );
  }
}

// Probleem 3 (aanmeld herstelronde, vervolg): geen Material-chip-widget meer
// — de standaard geselecteerde chip-stijl valt terug op
// colorScheme.secondaryContainer (een licht getinte kleur), niet op het
// solide Klantio primary-token. Deze widget dwingt de gevraagde solid/wit-
// op-geselecteerd, wit/donker-op-ongeselecteerd stijl expliciet af.
class _GeslachtOptie extends StatelessWidget {
  const _GeslachtOptie({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
