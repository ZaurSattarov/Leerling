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
            eyebrowText: 'PROFIEL',
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
                      icon: Icons.wifi_off_rounded,
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
                          icon: Icons.person_off_outlined,
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
                icon: Icons.badge_outlined,
                iconColor: AppColors.iconBlue,
                label: 'Naam',
                value: profiel.volledigeNaam,
              ),
              const Divider(height: 20),
              ProfileInfoRow(
                icon: Icons.phone_outlined,
                iconColor: AppColors.iconGreen,
                label: 'Telefoon',
                value: profiel.telefoon?.trim().isNotEmpty == true
                    ? profiel.telefoon!
                    : _leeg,
                isEmpty: profiel.telefoon?.trim().isNotEmpty != true,
              ),
              const Divider(height: 20),
              ProfileInfoRow(
                icon: Icons.email_outlined,
                iconColor: AppColors.iconPurple,
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
                icon: Icons.cake_outlined,
                iconColor: AppColors.iconAmber,
                label: 'Geboortedatum',
                value: geboortedatum ?? _leeg,
                isEmpty: geboortedatum == null,
              ),
              const Divider(height: 20),
              ProfileInfoRow(
                icon: Icons.location_on_outlined,
                iconColor: AppColors.iconSlate,
                label: 'Adres',
                value: profiel.adres?.trim().isNotEmpty == true
                    ? profiel.adres!
                    : _leeg,
                isEmpty: profiel.adres?.trim().isNotEmpty != true,
                maxValueLines: 3,
              ),
              const Divider(height: 20),
              ProfileInfoRow(
                icon: Icons.directions_car_outlined,
                iconColor: AppColors.iconDark,
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
            color: const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E2E7)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.iconDark, size: 18),
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
