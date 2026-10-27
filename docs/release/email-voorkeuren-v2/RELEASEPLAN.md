# Releaseplan twintig leerlingvoorkeuren â€” 27 oktober 2026

Actuele feiten en beperkingen: STATUS.md. Nieuw lokaal bewijs:
../../qa/email-instellingen/aanvullend7-2026-10-27/RESULTAAT.json.
Het oudere A-integratiebewijs blijft intact en is niet herhaald.

1. Voltooi eigen B-integratie, gewone herlogin en accountisolatie. Leg beginstand vast,
   test alleen eigen voorkeuren en herstel die. Bewijs nieuwe7 live afzonderlijk.
2. Android: herstel de normale lokale Maps- en release-signingconfiguratie op de juiste
   buildmachine, zonder secrets in documentatie. Bouw met bestaande release-dart-defines:
   flutter build appbundle --release --build-name=1.0.2 --build-number=20
   Controleer eerst beschikbaarheid van buildnummer20 en valideer AAB/signing.
3. iOS op de bestaande Mac: controleer distributiecertificaat/private key en profiel via
   ./tooling/ios_release_preflight.sh. Los eventuele mismatch met de huidige development-
   configuratie op binnen de normale releaseprocedure. Bouw dezelfde versie:
   flutter build ipa --release --build-name=1.0.2 --build-number=20
4. Voer normale native release-/toestelcontrole uit, met push onafhankelijk van e-mail.
5. Upload/TestFlight/Play-track/publicatie alleen na afzonderlijk expliciet GO.

Backend20 is volgens MAIL al geÃ¯nstalleerd. Geen installatie herhalen. De gebruiker heeft
nu expliciet activerings-GO gegeven; MAIL voert de backendpreflight/activering uit waar de
technische poorten dat toelaten en rapporteert afwijkingen. Maximaal1 gemarkeerde testmail
naar de door de gebruiker bevestigde eigen mailbox; geen backfill of toestemming namens anderen.
Bezorgproef faalde voor verzending door SQL42883 enum/text. Nul mails, oorspronkelijke24
hersteld;20 leerlingketens blijven UIT. Eerst het concrete MAIL-herstelvoorstel afhandelen.
Eigen voorkeurherstel na onderbroken UI-test is nog niet bevestigd. Geen volledige releasevrijgave.
