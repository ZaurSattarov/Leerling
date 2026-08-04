import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../shared/widgets/snackbar.dart';

/// Gedeelde helper om een locatie (plaatsnaam of volledig adres) in een
/// externe kaarten-app te openen. Gebruikt uitsluitend `https://`- en
/// `geo:`-URI's -- geen bespoke custom app-schemes die op iOS eerst in
/// Info.plist (`LSApplicationQueriesSchemes`) whitelisted moeten worden.
/// Zowel `https`
/// als `geo` staan al in android/app/src/main/AndroidManifest.xml's
/// `<queries>`-blok (resp. voor Mollie/PDF-links en de bestaande
/// navigatieknop) -- er is dus geen platformconfiguratie nodig.
///
/// Nooit rauwe tekst concateneren: elke query loopt via `Uri`'s eigen
/// `queryParameters`, die zelf URL-encodeert.
class MapsUri {
  MapsUri._();

  /// Geordende lijst van kandidaat-URI's voor [locatie], van meest native
  /// (per platform) tot generieke browserfallback. [open] probeert ze op
  /// volgorde.
  static List<Uri> candidatesFor(String locatie) {
    final query = locatie.trim();
    if (query.isEmpty) return const [];

    final browserFallback = Uri.https(
      'www.google.com',
      '/maps/search/',
      {'api': '1', 'query': query},
    );

    if (!kIsWeb && Platform.isIOS) {
      return [
        // Apple Maps -- standaard veilige fallback op iOS: een universal
        // link, dus geopend door de Kaarten-app als die geïnstalleerd is
        // (altijd het geval op iOS), anders gewoon in Safari.
        Uri.https('maps.apple.com', '/', {'q': query}),
        // Google Maps -- eveneens een universal link; iOS geeft dit door
        // aan de Google Maps-app als die geïnstalleerd is en ondersteund
        // wordt, anders valt hij terug op de browser (zelfde URL als
        // browserFallback hieronder).
        browserFallback,
      ];
    }
    if (!kIsWeb && Platform.isAndroid) {
      return [
        // Android geo-query -- opent de systeem-appkiezer met alle
        // geïnstalleerde kaarten-apps (meestal Google Maps).
        Uri(scheme: 'geo', path: '0,0', queryParameters: {'q': query}),
        browserFallback,
      ];
    }
    return [browserFallback];
  }

  /// Probeert elke kandidaat-URI voor [locatie] op volgorde te openen.
  /// Retourneert `true` zodra er één lukt. Toont een nette Nederlandse
  /// foutmelding (geen technische tekst) wanneer geen enkele optie geopend
  /// kon worden.
  static Future<bool> open(BuildContext context, String locatie) async {
    for (final uri in candidatesFor(locatie)) {
      try {
        if (await canLaunchUrl(uri)) {
          final gelukt =
              await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (gelukt) return true;
        }
      } catch (_) {
        // Probeer de volgende kandidaat.
      }
    }
    if (context.mounted) {
      showAppSnackBar(
        context,
        'De kaart kon niet worden geopend. Probeer het later opnieuw.',
        isError: true,
      );
    }
    return false;
  }
}
