import 'package:flutter/foundation.dart';

/// Security/AVG-hardening (2026-09-24).
///
/// `debugPrint` schrijft standaard OOK in een release-build naar de
/// platform-log (Android logcat / iOS oslog). De app logt op meerdere
/// plaatsen technische én bedrijfs-/persoonsgegevens (e-mailadressen bij
/// registratie/e-mailtemplates, exception-messages). In een release-build
/// mag geen enkele PII in de systeemlog belanden — die is op een toestel/
/// via `adb logcat` uitleesbaar en valt onder AVG (zie CLAUDE.md regel #8:
/// "Geen logging van persoonsgegevens").
///
/// Deze helper vervangt in een release-build `debugPrint` door een no-op,
/// zodat álle bestaande `debugPrint`-aanroepen in productie zwijgen zonder
/// dat elke afzonderlijke call-site aangepast hoeft te worden. In debug/
/// profile blijft logging volledig ongewijzigd.
///
/// `debugPrint` is een per-isolate globale functie: de vervanging werkt
/// alleen binnen het isolate waarin ze wordt aangeroepen. Roep
/// [installReleaseLogGuard] daarom aan als eerste regel van ELK top-level/
/// `@pragma('vm:entry-point')` entrypoint. De Leerling-app heeft op dit
/// moment alleen het hoofd-`main`; wordt in de toekomst een achtergrond-
/// isolate toegevoegd, dan MOET die hier ook aan.
void installReleaseLogGuard() {
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
}
