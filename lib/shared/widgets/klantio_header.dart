import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Klantio header-contract ─────────────────────────────────────────────────
//
// De ENIGE bron van waarheid voor hoogte, padding, titelstijl en
// leading/trailing-zonebreedte van elke paginaheader in de Leerling-app
// (hoofdtabs via MainTabHeader, detailpagina's via MainDetailHeader, Home
// via HomeHeader). Bepaald met Impeccable (layout.md/typeset.md): 56px
// contenthoogte onder de SafeArea komt overeen met Materials eigen
// AppBar-hoogte -- een bewust herkenbare, geen willekeurige waarde -- en is
// duidelijk compacter dan de vorige eyebrow+28px-titelopbouw (~79px).
// Wijzig deze waarden hier -- nooit lokaal per scherm een afwijkende
// hoogte/padding/lettergrootte kiezen.
const double kKlantioHeaderContentHeight = 56.0;
const double kKlantioHeaderZoneWidth = 44.0;
const double kKlantioHeaderHorizontalPadding = 16.0;
const double kKlantioHeaderTitleFontSize = 22.0;
const FontWeight kKlantioHeaderTitleWeight = FontWeight.w700;
const List<Color> kKlantioHeaderGradient = [
  Color(0xFF141C2B),
  Color(0xFF1A2D42),
];

TextStyle klantioHeaderTitleStyle({Color color = Colors.white}) {
  return GoogleFonts.inter(
    fontSize: kKlantioHeaderTitleFontSize,
    fontWeight: kKlantioHeaderTitleWeight,
    color: color,
    height: 1.1,
    letterSpacing: -0.3,
  );
}

/// Gedeelde header-romp: achtergrondverloop + SafeArea + vaste
/// contenthoogte + horizontale padding. [MainTabHeader], [MainDetailHeader]
/// (main_tab_header.dart / main_detail_header.dart) en `HomeHeader`
/// (home_header.dart) bouwen hier allemaal bovenop -- vóór deze refactor
/// had elk scherm zijn eigen kopie van dit Container+SafeArea+Padding-
/// blok, met (net) andere waarden per bestand. Volledig rechthoekig van
/// schermrand tot schermrand (geen BorderRadius, geen boxShadow, geen
/// horizontale marge buiten de content-padding).
class KlantioHeaderShell extends StatelessWidget {
  final Widget child;
  const KlantioHeaderShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: kKlantioHeaderGradient,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kKlantioHeaderContentHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: kKlantioHeaderHorizontalPadding),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Geometrisch gecentreerde titelrij: de titel staat altijd exact op het
/// horizontale midden van het SCHERM, ongeacht de breedte van [leading]/
/// [trailing] (bv. een StatusPill die breder is dan de standaard
/// iconknop). Een gewone Row+Expanded zou de titel alleen in de
/// RESTERENDE ruimte centreren -- een trailing-actie zou de titel dan
/// zichtbaar naar links duwen. Daarom een Stack: de titellaag centreert
/// zichzelf op de volledige breedte, onafhankelijk van leading/trailing.
class KlantioCenteredTitleRow extends StatelessWidget {
  /// Vast 44px-breed, gecentreerd. Null = lege plek (behoudt symmetrie).
  final Widget? leading;
  final String title;

  /// Rechts uitgelijnd; mag breder zijn dan de 44px-zone (bv. StatusPill)
  /// zonder de titelcentrering te beïnvloeden.
  final Widget? trailing;

  const KlantioCenteredTitleRow({
    super.key,
    this.leading,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Titellaag: centreert op de volledige beschikbare breedte, dus
        // altijd het echte midden van het scherm -- niet het midden van
        // wat er na leading/trailing overblijft.
        Positioned.fill(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: kKlantioHeaderZoneWidth + 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: klantioHeaderTitleStyle(),
              ),
            ),
          ),
        ),
        // Leading-zone: vaste 44px breedte, links.
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: kKlantioHeaderZoneWidth,
          child: leading == null ? const SizedBox.shrink() : Center(child: leading),
        ),
        // Trailing-zone: rechts uitgelijnd, natuurlijke breedte (kan >44px
        // zijn, bv. StatusPill) -- staat los van de titelcentrering.
        if (trailing != null)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Center(child: trailing),
          ),
      ],
    );
  }
}
