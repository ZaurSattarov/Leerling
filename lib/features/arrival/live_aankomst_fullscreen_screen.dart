import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/geocoding_service.dart';
import '../../core/utils/maps_uri.dart';
import '../../models/les.dart';
import 'arrival_provider.dart';
import 'widgets/arrival_live_map.dart';

/// Interne kaartweergave voor de ophaallocatie van een les (Feature 2/4) --
/// ÉÉN gedeeld scherm voor zowel de statische ophaallocatie (geen actieve
/// Live Aankomst) als de live instructeur/lesauto-positie (actieve Live
/// Aankomst), i.p.v. twee losse fullscreen-implementaties. Puur consumer
/// van de al bestaande [arrivalControllerProvider] en
/// [geocodedLocationProvider] -- geen eigen/tweede Realtime-subscription,
/// geen nieuwe backend-aanroepen, geen nieuwe privacylogica.
///
/// Externe navigatie (Google Maps-app) is uitsluitend een expliciete,
/// secundaire actie via de "Route"-knop (`MapsUri.open`) -- de hoofdkaart
/// zelf opent nooit automatisch iets extern.
class LiveAankomstFullscreenScreen extends ConsumerStatefulWidget {
  final Les les;

  const LiveAankomstFullscreenScreen({super.key, required this.les});

  @override
  ConsumerState<LiveAankomstFullscreenScreen> createState() =>
      _LiveAankomstFullscreenScreenState();
}

class _LiveAankomstFullscreenScreenState
    extends ConsumerState<LiveAankomstFullscreenScreen> {
  // Onthoudt of dit scherm op enig moment tijdens zijn levensduur live is
  // geweest. Nodig om twee situaties te onderscheiden die anders identiek
  // zouden lijken (toonLiveKaart == false):
  // 1. Geopend vanaf de statische ophaallocatiekaart -- nooit live geweest
  //    -> gewoon de statische weergave tonen, scherm blijft open.
  // 2. Geopend terwijl Live Aankomst al actief was, die stopt/verloopt
  //    terwijl dit scherm open is -> direct terug (nooit de laatste
  //    locatie hier laten staan alsof hij nog actueel is).
  bool _wasLive = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(arrivalControllerProvider);
    final session = state.session;
    final location = state.location;
    final stale = location?.isStale() ?? false;

    final toonLiveKaart = session != null &&
        session.lessonId == widget.les.id &&
        session.isActive() &&
        session.isVisible &&
        location != null &&
        !stale;

    if (toonLiveKaart) {
      _wasLive = true;
    } else if (_wasLive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return const Scaffold(
          backgroundColor: AppColors.surface, body: SizedBox.shrink());
    }

    final adres = (widget.les.locatie ?? '').trim();
    // Provider-key is de lesson_id (niet het adres zelf) -- de
    // geocode-pickup Edge Function haalt `locatie` zelf server-side op,
    // RLS-scoped op basis van dat id. Zie geocoding_service.dart.
    final geocodedAsync =
        adres.isEmpty ? null : ref.watch(geocodedLocationProvider(widget.les.id));
    final geocoded = geocodedAsync?.valueOrNull;
    final pickupPositie =
        geocoded != null ? LatLng(geocoded.latitude, geocoded.longitude) : null;
    final geocodingBezig =
        !toonLiveKaart && (geocodedAsync?.isLoading ?? false);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: ArrivalLiveMap(
                key: ValueKey(
                  toonLiveKaart ? 'live-${session.id}' : 'pickup-${widget.les.id}',
                ),
                latitude: toonLiveKaart ? location.latitude : null,
                longitude: toonLiveKaart ? location.longitude : null,
                pickupPosition: pickupPositie,
                height: double.infinity,
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: _RondeKnop(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).pop(),
                semanticsLabel: 'Terug',
              ),
            ),
            if (adres.isNotEmpty)
              Positioned(
                top: 16,
                right: 16,
                // Secundaire, expliciete actie -- de hoofdkaart zelf opent
                // nooit automatisch extern Maps.
                child: _RondeKnop(
                  icon: Icons.directions_rounded,
                  onTap: () => MapsUri.open(context, adres),
                  semanticsLabel: 'Route openen in Maps',
                ),
              ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _StatusKaart(
                titel: toonLiveKaart ? 'Instructeur onderweg' : 'Ophaallocatie',
                locatie: adres,
                laden: geocodingBezig,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RondeKnop extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String semanticsLabel;

  const _RondeKnop({
    required this.icon,
    required this.onTap,
    required this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: AppColors.white,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: const Color(0xFF0F172A).withValues(alpha: 0.15),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: AppColors.textPrimary, size: 20),
          ),
        ),
      ),
    );
  }
}

class _StatusKaart extends StatelessWidget {
  final String titel;
  final String locatie;
  final bool laden;

  const _StatusKaart({
    required this.titel,
    required this.locatie,
    this.laden = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 0.75),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.directions_car_filled_rounded,
                color: AppColors.success, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titel,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (locatie.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    laden ? '$locatie · locatie zoeken…' : locatie,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
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
