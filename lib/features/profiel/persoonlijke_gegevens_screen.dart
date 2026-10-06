import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/datum_utils.dart';
import '../../models/leerling_profiel.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_detail_header.dart';
import 'profielfoto_editor.dart';
import 'widgets/profile_info_row.dart';
import '../../core/constants/cool_icons.dart';

/// Profiel -> Persoonlijke gegevens (Fase 5). Alle getoonde velden komen
/// rechtstreeks uit `leerlingen` (via het al bestaande mijnProfielProvider /
/// LeerlingProfiel-model, geen nieuwe query) -- uitsluitend `avatar_url` is
/// hier bewerkbaar (via [EditableProfielAvatar], zelfde upload-flow als de
/// profielkaart bovenaan Profiel). Alle overige velden zijn read-only: de
/// Instructeur-app is de bron, en de Fase 2-kolombeveiligingstrigger op
/// `leerlingen` staat de leerling zelf toe uitsluitend `avatar_url` te
/// wijzigen. Zie docs/PROFIEL_ARCHITECTUUR.md en
/// docs/PROFIEL_STAP2_BEVEILIGING.md.
class ProfielPersoonlijkeGegevensScreen extends ConsumerWidget {
  const ProfielPersoonlijkeGegevensScreen({super.key});

  static const _leeg = 'Niet ingevuld';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profielAsync = ref.watch(mijnProfielProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          const MainDetailHeader(
            title: 'Persoonlijke gegevens',
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => ref.invalidate(mijnProfielProvider),
              child: profielAsync.when(
                loading: () => ListView(
                  padding: const EdgeInsets.all(20),
                  children: const [
                    SkeletonBox(height: 120, radius: 18),
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
                      icon: CoolIcons.cloudOff,
                      title: 'Kon gegevens niet laden',
                      subtitle: e.toString(),
                    ),
                  ],
                ),
                data: (profiel) {
                  if (profiel == null) {
                    return ListView(
                      children: const [
                        SizedBox(height: 60),
                        EmptyState(
                          icon: CoolIcons.userClose,
                          title: 'Geen profiel gevonden',
                        ),
                      ],
                    );
                  }
                  return _PersoonlijkeGegevensBody(profiel: profiel);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersoonlijkeGegevensBody extends StatelessWidget {
  final LeerlingProfiel profiel;
  const _PersoonlijkeGegevensBody({required this.profiel});

  static const _leeg = ProfielPersoonlijkeGegevensScreen._leeg;

  @override
  Widget build(BuildContext context) {
    final geboortedatum = profiel.geboortedatum?.trim().isNotEmpty == true
        ? DatumUtils.datumZonderWeekdag(profiel.geboortedatum!)
        : null;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _FotoKaart(profiel: profiel),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Contactgegevens'),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              ProfileInfoRow(
                icon: CoolIcons.userCardId,
                iconColor: AppColors.iconPrimary,
                label: 'Naam',
                value: profiel.volledigeNaam,
              ),
              const Divider(height: 20),
              ProfileInfoRow(
                icon: CoolIcons.phone,
                iconColor: AppColors.iconPrimary,
                label: 'Telefoon',
                value: profiel.telefoon?.trim().isNotEmpty == true
                    ? profiel.telefoon!
                    : _leeg,
                isEmpty: profiel.telefoon?.trim().isNotEmpty != true,
              ),
              const Divider(height: 20),
              ProfileInfoRow(
                icon: CoolIcons.mail,
                iconColor: AppColors.iconPrimary,
                label: 'E-mailadres',
                value: profiel.email?.trim().isNotEmpty == true
                    ? profiel.email!
                    : _leeg,
                isEmpty: profiel.email?.trim().isNotEmpty != true,
                maxValueLines: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Overige gegevens'),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            children: [
              ProfileInfoRow(
                icon: CoolIcons.gift,
                iconColor: AppColors.iconPrimary,
                label: 'Geboortedatum',
                value: geboortedatum ?? _leeg,
                isEmpty: geboortedatum == null,
              ),
              const Divider(height: 20),
              ProfileInfoRow(
                icon: CoolIcons.mapPin,
                iconColor: AppColors.iconPrimary,
                label: 'Adres',
                value: profiel.adres?.trim().isNotEmpty == true
                    ? profiel.adres!
                    : _leeg,
                isEmpty: profiel.adres?.trim().isNotEmpty != true,
                maxValueLines: 3,
              ),
              const Divider(height: 20),
              ProfileInfoRow(
                icon: CoolIcons.carAuto,
                iconColor: AppColors.iconPrimary,
                label: 'Rijbewijscategorie',
                value: profiel.rijbewijsSoort?.trim().isNotEmpty == true
                    ? profiel.rijbewijsSoort!.toUpperCase()
                    : _leeg,
                isEmpty: profiel.rijbewijsSoort?.trim().isNotEmpty != true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.neutralBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              Icon(CoolIcons.info, color: AppColors.iconPrimary, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Deze gegevens worden beheerd door je rijschool. Klopt er iets '
                  'niet? Neem contact op met je instructeur om het te laten '
                  'aanpassen.',
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _FotoKaart extends StatelessWidget {
  final LeerlingProfiel profiel;
  const _FotoKaart({required this.profiel});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          EditableProfielAvatar(profiel: profiel, size: 72),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profiel.volledigeNaam,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tik op de foto om je profielfoto te wijzigen',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
