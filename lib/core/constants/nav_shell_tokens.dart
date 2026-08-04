/// Gedeelde designtoken voor de bottom-padding die elk hoofdscherm
/// reserveert zodat scrollcontent nooit achter de zwevende bottom-navbar
/// verdwijnt. De navbar zelf (main_scaffold.dart) gebruikt weer zijn eigen
/// lokale constanten -- zie de toelichting daar.
///
/// 1-op-1 overgenomen uit de Instructeur-app
/// (rijschool-planner-flutter/lib/core/constants/nav_shell_tokens.dart).
class NavShellTokens {
  NavShellTokens._();

  /// Totale ruimte die de zwevende navbar onderaan het scherm inneemt
  /// (hoogte + ondermarge + wat ademruimte) -- de minimale bottom-padding
  /// die scrollcontent op elk hoofdscherm nodig heeft zodat de laatste
  /// regel nooit achter de balk verdwijnt. Schermen met een al grotere,
  /// doelbewust afgestemde bottom-padding (bv. voor een zwevende
  /// actieknop) hoeven dit niet te verlagen -- dit is een ondergrens.
  static const double contentBottomClearance = 96;
}
