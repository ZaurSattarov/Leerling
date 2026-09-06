/// Geometrie van de splash-compositie (ICON + KLANTIO + LEERLINGENPORTAAL).
///
/// 1-op-1 dezelfde architectuur/percentages als de Instructeur-app
/// (rijschool-planner-flutter/lib/features/splash/splash_layout.dart) --
/// alleen de bron-afmetingen zijn hier die van de Leerlingen-app-assets.
///
/// De drie bestanden zijn uit hetzelfde Figma-frame geëxporteerd, dus hun
/// eigen breedte/hoogte coderen al de juiste ONDERLINGE schaalverhouding
/// (ICON t.o.v. KLANTIO t.o.v. LEERLINGENPORTAAL). Wat de SVG's niet
/// meegeven is hun onderlinge X/Y-positie in dat frame -- die tussenruimtes
/// zijn daarom, exact zoals bij de Instructeur-app, uitgedrukt als
/// proportionele fracties (schalen mee, blijven optisch gebalanceerd)
/// i.p.v. losse vaste pixels.
///
/// Responsiveness: één globale schaalfactor t.o.v. een aangenomen
/// Figma-ontwerpbreedte houdt de hele compositie -- ICON, KLANTIO,
/// LEERLINGENPORTAAL én de ruimtes ertussen -- proportioneel gelijk op elk
/// schermformaat, in plaats van vaste pixels.
class SplashLayout {
  SplashLayout._();

  /// Aangenomen ontwerpbreedte van het Figma-frame (zelfde als de
  /// Instructeur-app).
  static const double designWidth = 390;

  // Native afmetingen van de SVG-bronbestanden
  // (assets/Splash Screen/ -- Leerlingen-app).
  static const double lIconSourceSize = 139;
  static const double klantioSourceWidth = 233;
  static const double klantioSourceHeight = 42;
  static const double portaalSourceWidth = 147;
  static const double portaalSourceHeight = 11;

  /// Proportionele tussenruimtes -- zelfde fracties als de Instructeur-app
  /// (SplashLayout._gapLToKlantioFactor /
  /// _gapKlantioToRijplannerFactor / _rijplannerRightOverhangFactor).
  static const double _gapLToKlantioFactor = 0.10; // t.o.v. lIconSourceSize
  static const double _gapKlantioToPortaalFactor = 0.14; // t.o.v. klantioH

  /// LEERLINGENPORTAAL hangt net iets voorbij de rechterrand van KLANTIO
  /// (zelfde compositieregel als RIJPLANNER bij de Instructeur-app) -- als
  /// fractie van de eigen breedte.
  static const double _portaalRightOverhangFactor = 0.20;

  /// Kleine, extra verticale verschuiving van LEERLINGENPORTAAL naar
  /// beneden (los verzoek, alleen dit element). Dit is een pure
  /// paint-verschuiving (zie `Transform.translate` in `_SplashCanvas`) --
  /// telt niet mee in `totalHeight`/de centrering, dus ICON en KLANTIO
  /// blijven op exact dezelfde positie staan.
  static const double _portaalExtraDropFactor = 0.6; // t.o.v. portaalHeight

  /// Berekent de volledige, geschaalde compositiegeometrie voor een gegeven
  /// schermbreedte.
  static SplashComposition composeFor(double screenWidth) {
    final scale = (screenWidth / designWidth).clamp(0.8, 1.6);

    final lSize = lIconSourceSize * scale;
    final klantioWidth = klantioSourceWidth * scale;
    final klantioHeight = klantioSourceHeight * scale;
    final portaalWidth = portaalSourceWidth * scale;
    final portaalHeight = portaalSourceHeight * scale;

    final gapLToKlantio = lIconSourceSize * scale * _gapLToKlantioFactor;
    final gapKlantioToPortaal = klantioHeight * _gapKlantioToPortaalFactor;
    final portaalRightOverhang = portaalWidth * _portaalRightOverhangFactor;
    final portaalExtraDrop = portaalHeight * _portaalExtraDropFactor;

    return SplashComposition(
      scale: scale,
      lSize: lSize,
      klantioWidth: klantioWidth,
      klantioHeight: klantioHeight,
      portaalWidth: portaalWidth,
      portaalHeight: portaalHeight,
      gapLToKlantio: gapLToKlantio,
      gapKlantioToPortaal: gapKlantioToPortaal,
      portaalRightOverhang: portaalRightOverhang,
      portaalExtraDrop: portaalExtraDrop,
    );
  }
}

/// Kant-en-klare, geschaalde afmetingen/tussenruimtes voor één schermbreedte.
class SplashComposition {
  final double scale;
  final double lSize;
  final double klantioWidth;
  final double klantioHeight;
  final double portaalWidth;
  final double portaalHeight;
  final double gapLToKlantio;
  final double gapKlantioToPortaal;
  final double portaalRightOverhang;
  final double portaalExtraDrop;

  const SplashComposition({
    required this.scale,
    required this.lSize,
    required this.klantioWidth,
    required this.klantioHeight,
    required this.portaalWidth,
    required this.portaalHeight,
    required this.gapLToKlantio,
    required this.gapKlantioToPortaal,
    required this.portaalRightOverhang,
    required this.portaalExtraDrop,
  });

  /// Totale hoogte van de volledige compositie (ICON t/m LEERLINGENPORTAAL),
  /// voor verticale centrering als één geheel.
  double get totalHeight =>
      lSize + gapLToKlantio + klantioHeight + gapKlantioToPortaal + portaalHeight;
}
