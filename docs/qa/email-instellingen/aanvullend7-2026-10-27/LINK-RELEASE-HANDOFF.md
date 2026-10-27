# Leerling — definitieve lokale bronoverdracht, 27 oktober 2026

Lokale wijzigingen gereed voor review; geen release, publicatie of volledige live-integratie.
Alle20 canonical e-mailvoorkeuren staan in de bestaande app. De oorspronkelijke13 en push
blijven behouden. Aanvullend is de permanente blokkade op opnieuw openen van dezelfde
mail-link vervangen door een2secondenvenster, uitsluitend voor geldige e-mailopenlinks.
De bestaande logout-clear wist zowel het pending lesdoel als dat venster; legacy callbacks
houden hun bestaande afhandeling. Parser/allowlist/login/rechten zijn niet verruimd.

## Werkelijk lokaal bewezen

-12gerichte voorkeurtests eerder PASS: extra7 provider/SDK/MockClient-RPC aan/uit en readback,
  defaults,20providerkeuzes,20UI-schakelaars,320px/130% tekst en masteruit met behoud keuzes/push.
-3nieuwe deduptests PASS: dubbele cold-startdelivery geweigerd binnen2seconden; dezelfde URI
  vanaf2seconden opnieuw geaccepteerd; ander lesdoel meteen mogelijk; logout-clear wist alles.
-Gerichte analyse van app.dart, email_link_route.dart en de gewijzigde routetest: geen issues.
  Eerdere gerichte voorkeuranalyse ook schoon. Geen ongewijzigde oude suites/A-tests herhaald.
-Officiele incrementele Graphify-update geslaagd; graph.json geldig5754nodes/8050edges en
  acceptOpenLink via leerling-MCP zichtbaar. Geen volledige semantische analyse. SQL-parser
  ontbreekt voor14ongewijzigdeSQLbestanden; er is geenSQL gewijzigd in deze app.

## Routes en native declaraties

Zowel leerlingplanner://open?route=/planning/<UUID> als
https://app.klantio.com/open/leerling?route=%2Fplanning%2F<UUID> wordt lokaal geaccepteerd.
app.dart bewaart het doel in geheugen, gaat via splash/login en neemt het bij /home
weer op. /planning/:id bestaat binnen StudentProfileGate. Lesdetails komen via de eigen
SDK uit student_lessen_view, niet uit mailinhoud. Null toont geen lesdetails; backendview/RLS
blijft beslissend. Geheugenopslag bewijst geen behoud na procesbeëindiging.
Android heeft custom/HTTPS-openfilters; iOS heeft customscheme en associated-domain-entitlement.
Deze bronbewijzen zijn geen live native OS-verificatie of echt accountisolatiebewijs.

## Openstaande live- en releasevoorwaarden

Gebruiker vroeg expliciet verder te gaan zonder emulator, omdat die vastloopt. Geen verdere
emulatorcontrole uitgevoerd. Tijdelijke voorkeurherstelstatus is NIET bevestigd: oorspronkelijk
master en alle20 onderwerpen uit; master/L11/L12/L35/L21 zijn tijdelijk aan opgeslagen en
L24 was aangeklikt zonder gecontroleerd eindresultaat. L30/L31 niet gewijzigd. Eerst deze5
onderwerpen uitzetten en daarna masteruit; push behouden. Beginstand/journal zijn bewaard.

B-identiteit/verschilA, gewone herlogin, verkeerde-accountles geweigerd, geen oude accountstate,
echte toegankelijke les openen via nativecold/warm/login zijn NIET bewezen. Hiervoor blijft
een menselijke eigen B-login/MFA vereist. Geen nieuw account, impersonatie of extra mail.

AndroiddebugAPK is eerder gebouwd/opnieuw geïnstalleerd; de debugverbinding viel weg.
Die binary is niet bewezen gebonden aan de daarna toegevoegde dedupfix. AndroidreleaseAAB
bleef geblokkeerd op Maps-configuratie; key.properties ontbreekt hier. iOSdistributiesigning/
archive/IPA vereist de Mac. Vrij buildnummer20 controleren, normale toestel/releasecontroles
uitvoeren en apart upload/publicatieGO verkrijgen. Geen werkende releaseclaim op basis van
bronhashes, debugAPK of de15lokale tests.

## MAIL-uitkomst en bundel

FINAL-REPAIR-AND-MAIL-VERIFIED.json van MAIL daadwerkelijk gelezen: enumreparatie20261027082000
geverifieerd; exact1synthetischeL07 providerpoging geaccepteerd en inboxontvangst door gebruiker
bevestigd. Die preview bevatte geen echte les-ID; de voorbeeldknop naar klantio.com bewijst
geen echte-lesnavigatie. Mailbudget0.24oorspronkelijke ketens actief,23geïnstalleerdUIT,
waaronder20normale leerlingketens. Geen backendcode/worker/infrastructuur door Agent2 gewijzigd.

LINK-RELEASE-HANDOFF.json bevat actueleHEAD, alle relevante bron/nativeSHA256's, de7gewijzigde
Dart/testbestanden,3testuitslagen en patchSHA256. LEERLING-LOCAL-REVIEW.patch is tegen dieHEAD;
geen automatische toepassing, commit of push. De reviewZIP bevat de7bestanden, patch, manifest
en dit rapport. Het is een bronreviewbundel, geen installeerbare APK/IPA of publicatievrijgave.
