import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Klantio header-contract ─────────────────────────────────────────────────
//
// 1-op-1 gelijk aan de Instructeur-app (rijschool-planner-flutter/
// lib/shared/widgets/klantio_header.dart). De ENIGE bron van waarheid voor
// hoogte, padding, titelstijl en leading/trailing-zonebreedte van elke
// paginaheader in de Leerling-app (hoofdtabs via MainTabHeader,
// detailpagina's via MainDetailHeader, Home via HomeHeader).
// 56px contenthoogte onder de SafeArea komt overeen met Materials eigen
// AppBar-hoogte -- een bewust herkenbare, geen willekeurige waarde.
// Wijzig deze waarden hier -- nooit lokaal per scherm een afwijkende
// hoogte/padding/lettergrootte kiezen.
const double kKlantioHeaderContentHeight = 56.0;
const double kKlantioHeaderZoneWidth = 44.0;
const double kKlantioHeaderHorizontalPadding = 16.0;
const double kKlantioHeaderTitleFontSize = 22.0;
const FontWeight kKlantioHeaderTitleWeight = FontWeight.w700;
const List<Color> kKlantioHeaderGradient = [
  Color(0xFFFFFFFF),
  Color(0xFFFFFFFF),
];

TextStyle klantioHeaderTitleStyle({BuildContext? context, Color? color}) {
  return GoogleFonts.inter(
    fontSize: kKlantioHeaderTitleFontSize,
    fontWeight: kKlantioHeaderTitleWeight,
    color: color ?? const Color(0xFFF8FAFC),
    height: 1.1,
    letterSpacing: -0.3,
  );
}

/// Gedeelde header-romp: lichte/witte achtergrond + SafeArea + vaste
/// contenthoogte + horizontale padding (1-op-1 afgestemd op Klantio Admin Dashboard).
class KlantioHeaderShell extends StatelessWidget {
  final Widget child;
  const KlantioHeaderShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Donkere headerbalk -> lichte statusbalk-iconen (klok, batterij).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: _shell(),
    );
  }

  Widget _shell() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E2635),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF263347),
            width: 1,
          ),
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
/// [trailing] (bv. een statuspil die breder is dan de standaard iconknop).
/// Een gewone Row+Expanded zou de titel alleen in de RESTERENDE ruimte
/// centreren -- een trailing-actie zou de titel dan zichtbaar naar links
/// duwen. Daarom een Stack: de titellaag centreert zichzelf op de volledige
/// breedte, onafhankelijk van leading/trailing.
class KlantioCenteredTitleRow extends StatelessWidget {
  /// Vast 44px-breed, gecentreerd. Null = lege plek (behoudt symmetrie).
  final Widget? leading;
  final String title;

  /// Rechts uitgelijnd; mag breder zijn dan de 44px-zone (bv. statuspil)
  /// zonder de titelcentrering te beïnvloeden.
  final Widget? trailing;
  final double titleHorizontalPadding;

  const KlantioCenteredTitleRow({
    super.key,
    this.leading,
    required this.title,
    this.trailing,
    this.titleHorizontalPadding = kKlantioHeaderZoneWidth + 8,
  });

  @override
  Widget build(BuildContext context) {
    final titleWidget = Text(
      title,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: klantioHeaderTitleStyle(context: context),
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        // Titellaag: centreert op de volledige beschikbare breedte, dus
        // altijd het echte midden van het scherm -- niet het midden van
        // wat er na leading/trailing overblijft.
        Positioned.fill(
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: titleHorizontalPadding),
              child: titleHorizontalPadding > kKlantioHeaderZoneWidth + 8
                  ? FittedBox(fit: BoxFit.scaleDown, child: titleWidget)
                  : titleWidget,
            ),
          ),
        ),
        // Leading-zone: vaste 44px breedte, links.
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: kKlantioHeaderZoneWidth,
          child: leading == null
              ? const SizedBox.shrink()
              : Center(child: leading),
        ),
        // Trailing-zone: rechts uitgelijnd, natuurlijke breedte (kan >44px
        // zijn, bv. statuspil) -- staat los van de titelcentrering.
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
