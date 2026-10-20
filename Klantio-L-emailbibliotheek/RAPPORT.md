# Opleverrapport — Klantio L

20 oktober 2026.

**36 leerlinggerichte HTML-e-mails, tekstalternatieven en een lokale catalogus zijn gebouwd. Niets is gedeployd of verzonden.**

Open [de catalogus](index.html). De hele bundel staat in C:\PROJECTS\Leerling\Klantio-L-emailbibliotheek.

## Opgeleverd

- 36 genummerde templatebundels met Nederlandse onderwerpen, preheaders, HTML, tekst, variabelen en fictieve testgegevens.
- Eén gedeeld HTML-designsysteem, gebaseerd op de goedgekeurde instructeurbibliotheek. De recentere chatkleuren #1E2635/#D72F62 en info@klantio.com zijn behouden.
- Tien nieuwe originele leerlinggerichte thema’s met volledige figuren, zichtbare handen/benen/schoenen en bijbehorende SVG/PNG-bestanden op 1040 × 580. Geen stock, emoji of ongegenereerde placeholders.
- Creditnota en terugbetaling hebben afzonderlijke HTML-/tekstvarianten. De felicitatiemail gaat over een geslaagd praktijkexamen en claimt geen afgegeven rijbewijs.
- Getypeerde veldcontracten voor ieder type in [template-data.d.ts](src/template-data.d.ts). Een server moet deze presentatievelden uit betrouwbare brondata opbouwen; de interfaces bewijzen geen databasebeschikbaarheid.
- Een eigen Klantio L-previewsectie met dezelfde catalogusinterface, categorieën, zoeken, desktop/mobiel, ontvanger, eventstatus en variabelen. Er staat ook een link naar de bestaande instructeurcatalogus; die catalogus zelf is niet aangepast.
- Een lokale voorkeurendemo met vijf groepen en pure serverpolicy-/renderhelpers. Geen echte accountvoorkeuren gewijzigd.

## Tests

41 automatische ontwikkeltests geslaagd, 0 mislukt. 216 browser-/inhoudcontroles geslaagd over alle 36 typen: desktop 900 px, mobiel 390 px, smal 320 px, afbeeldingen uit, browser-dark-media en lange namen/speciale tekens/lege optionele toelichting.

Bewijs: [unit-tests.tap](qa/unit-tests.tap), [resultaten.json](qa/resultaten.json), 72 basis-screenshots in qa/screenshots en zeven contactbladen. De catalogusfilters, zoekfunctie en lokale opslag van de voorkeurendemo zijn gecontroleerd.

De instructeurbibliotheek is vóór deze taak volledig gehasht. De regressietest heeft vastgesteld dat alle opgenomen bestanden byte voor byte ongewijzigd zijn. Zie [instructeur-baseline.json](qa/instructeur-baseline.json). Dit is een bestandsregressietest, geen echte verzendtest.

Getest: juiste leerling/school, actuele objectversie, serverobjecttoegang, geen meldingen na rollback, geen eigen wijzigingsspam, feedbackvrijgave, betrouwbare voortgang, echte mijlpaal/pakketsaldo, examenuitslag, ingestelde herinneringstermijn, eigen factuur en geldstroom, betaalprovider versus handmatige status, creditnota versus refund, e-mailvoorkeuren en noodzakelijke accountmeldingen, dubbele businesskey, bundeling en begrensde retryhelper.

**Niet getest:** Gmail-, klassieke Outlook- en Apple Mail-inboxen; automatische darkmode-transformaties van die clients; echte iOS-/Android-toestellen; live Auth, bestaande lesbevestiging, support, inbound, IMAP/SMTP, push, Mollie en cronjobs; stagingdatabase, echte workerconcurrentie of Resend-verzending. Browser-dark-media is geen echte mailboxtransformatie.

## Bestaande architectuur en bevindingen

Lokaal gelezen: lib/app.dart, lib/core/services/communication_service.dart, lib/models/leerling_notificatie_voorkeuren.dart, de relevante delen van StudentService en het bestaande notificatie-instellingenscherm. AndroidManifest.xml registreert leerlingplanner/auth en leerlingplanner/factuur; Info.plist registreert het leerlingplanner-schema.

- De lokale leerling-CommunicationService bevat een geauthenticeerde aanroep naar de bestaande send-email voor password_changed. Dit is een lokaal aangetoond pad, geen live verstuurverificatie.
- De bestaande instructeur-lesbevestiging blijft intact. Type 07 mag pas worden aangesloten als dit event één centrale eigenaar en gedeelde duurzame dedupclaim heeft; voorkom een tweede parallelle bevestiging.
- Bestaande leerlingvoorkeuren zijn gekoppeld aan user_id en bevatten les-, factuur-, evaluatie- en examenkeuzes. Die velden bewijzen geen volledige operationele e-mailvoorkeurenflow. Het nieuwe voorstel staat apart en wijzigt de bestaande push-/inboxkeuzes niet.
- De canonical lokale instructeur-verzendfunctie bevat inmiddels template_sources.ts. De aangeleverde tekst over ‘lokaal ontbreekt’ kan dus verouderd zijn. Er is geen live bronvergelijking uitgevoerd en geen verzendcode overschreven.
- Lokale interne routes bestaan voor /planning/:id, /voortgang, /facturen/:id, /examens, /beschikbaarheid en accountinstellingen. Er is een concrete factuur-returnlink leerlingplanner://factuur?id=… die alleen als UI-hint naar de actuele factuur navigeert; de link bewijst geen betaling.
- Interne routes zijn niet hetzelfde als universele e-maillinks. Geen productiehost, fallback of terugkeer na login is verzonnen. Alle previewacties openen een lokale uitlegpagina.

De historische inventarisatie is als uitgangspunt gebruikt, niet opnieuw als live waarheid vastgesteld. Voor alle nieuwe operationele leerlingevents moet de koppeling nog worden geverifieerd en gebouwd. Er zijn geen ‘TRIGGER BESTAAT’/‘STAGING GEREED’-claims zonder bewijs.

## Backend en voorkeuren: voorbereidingsstatus

De helpers in backend/ controleren eigen accountbinding, huidige leerling-school-objectbinding, actuele status, vrijgegeven informatie, invoice/payment-eigendom, eventidentiteit en servervoorkeuren. Ze leveren uitsluitend een voorbereidingsplan of berichtobject met productionEnabled=false. De DemoOutbox is in-memory en uitsluitend bedoeld als testdubbel.

Nog NIET operationeel gebouwd: database-adapters, duurzame outbox, atomische claims, rate limits over meerdere workers, ondertekende webhookverwerking, echte retries/leases, schedulers, digestaggregatie, productieafbeeldingshosting, URL-resolver en Flutter-/stagingintegratie voor e-mailvoorkeuren. Het volledige notificatiesysteem uit de mastertekst is daarom niet als operationeel afgerond gepresenteerd.

## Nog nodig vóór GO-LIVE

1. De actuele live send-email/template_sources, de genoemde events en bestaande notificatie-/mailroutes read-only vergelijken met de lokale bronnen. Alleen betrouwbare bestaande gebeurtenissen aansluiten.
2. De eventadapter, beperkte ontvangerselectie en doel-URL’s onder bestaande RLS beveiligen; brondata en templatewaarden uit hetzelfde gecontroleerde snapshot halen.
3. Nieuwe voorkeuren en een duurzaam outboxontwerp beoordelen. Indien NIEUWE SQL nodig is: eerst volledige SQL tonen en expliciete goedkeuring verkrijgen; daarna pas de canonical Instructeur-migratieworkflow gebruiken. In deze bundel is geen migratie of uitvoerbare SQL gemaakt.
4. Op development/staging de bestaande Resend-infrastructuur integreren en queue-/webhookconcurrentie, retries en opt-out na enqueue testen. Zie [INTEGRATIE.md](backend/INTEGRATIE.md).
5. Echte inbox-/toesteltests en alle bestaande Auth/support/push/betaal-/mailboxregressies uitvoeren. Afzender en publieke HTTPS-afbeeldingshost verifiëren.
6. Voor concrete beoordeelde productieactivering expliciet GO-LIVE vragen. Geen productie-email naar echte leerlingen zonder dat akkoord.

## Alle 36 typen

Alle onderstaande typen hebben HTML en tekst, een eigen onderwerp/preheader, fictieve voorbeelddata, ontvangerspecificatie en een lokale preview. ‘Bestaande basis’ is hergebruik van inhoud of vormgeving, geen bewezen live leerlingtrigger.

| Nr. | Mail | Bestaande basis | Eventcontract | Triggerstatus |
| --- | --- | --- | --- | --- |
| 01 | [Welkom bij Klantio L](mails/01-welkom-bij-klantio-l/preview.html) | Nieuw leerlingontwerp | student.account_activated | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 02 | [E-mailadres bevestigen](mails/02-e-mailadres-bevestigen/preview.html) | email-bevestigen.html | auth.email_confirmation | BESTAANDE AUTH-FLOW BEHOUDEN; LIVE NIET GETEST |
| 03 | [Wachtwoord opnieuw instellen](mails/03-wachtwoord-opnieuw-instellen/preview.html) | wachtwoord-resetten.html | auth.password_recovery | BESTAANDE AUTH-FLOW BEHOUDEN; LIVE NIET GETEST |
| 04 | [Wachtwoord gewijzigd](mails/04-wachtwoord-gewijzigd/preview.html) | wachtwoord-gewijzigd.html | password_changed | LOKAAL AANROEPPAD AANGETOOND; LIVE NIET GETEST |
| 05 | [E-mailadres gewijzigd](mails/05-e-mailadres-gewijzigd/preview.html) | Nieuw leerlingontwerp | student.email_changed | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 06 | [Account gedeactiveerd](mails/06-account-gedeactiveerd/preview.html) | Nieuw leerlingontwerp | student.account_deactivated | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 07 | [Rijles ingepland](mails/07-rijles-ingepland/preview.html) | Bestaande les_bevestiging-flow (niet vervangen) | student.lesson_scheduled | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 08 | [Rijles verplaatst](mails/08-rijles-verplaatst/preview.html) | les-gewijzigd.html | student.lesson_rescheduled | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 09 | [Rijleslocatie gewijzigd](mails/09-rijleslocatie-gewijzigd/preview.html) | les-gewijzigd.html | student.lesson_location_changed | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 10 | [Rijles geannuleerd](mails/10-rijles-geannuleerd/preview.html) | les-geannuleerd.html | student.lesson_cancelled | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 11 | [Herinnering: morgen rijles](mails/11-herinnering-morgen-rijles/preview.html) | lesherinnering.html | student.lesson_reminder_tomorrow | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 12 | [Rijles begint binnenkort](mails/12-rijles-begint-binnenkort/preview.html) | Nieuw leerlingontwerp | student.lesson_reminder_due | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 13 | [Andere instructeur toegewezen](mails/13-andere-instructeur-toegewezen/preview.html) | Nieuw leerlingontwerp | student.lesson_instructor_changed | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 14 | [Rijles afgerond](mails/14-rijles-afgerond/preview.html) | Nieuw leerlingontwerp | student.lesson_completed | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 15 | [Beschikbaarheid bijgewerkt](mails/15-beschikbaarheid-bijgewerkt/preview.html) | Nieuw leerlingontwerp | student.availability_changed | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 16 | [Nieuwe lesevaluatie beschikbaar](mails/16-nieuwe-lesevaluatie-beschikbaar/preview.html) | Nieuw leerlingontwerp | student.evaluation_published | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 17 | [Voortgang bijgewerkt](mails/17-voortgang-bijgewerkt/preview.html) | Nieuw leerlingontwerp | student.progress_published | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 18 | [Nieuwe mijlpaal bereikt](mails/18-nieuwe-mijlpaal-bereikt/preview.html) | Nieuw leerlingontwerp | student.milestone_reached | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 19 | [Lespakket bijna op](mails/19-lespakket-bijna-op/preview.html) | pakket-bijna-op.html | student.package_low | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 20 | [Lespakket op](mails/20-lespakket-op/preview.html) | pakket-op.html | student.package_empty | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 21 | [Maandelijks voortgangsoverzicht](mails/21-maandelijks-voortgangsoverzicht/preview.html) | Nieuw leerlingontwerp | student.digest_progress_month | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 22 | [Praktijkexamen ingepland](mails/22-praktijkexamen-ingepland/preview.html) | examen-gepland.html | student.exam_scheduled | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 23 | [Praktijkexamen gewijzigd](mails/23-praktijkexamen-gewijzigd/preview.html) | Nieuw leerlingontwerp | student.exam_changed | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 24 | [Examenherinnering](mails/24-examenherinnering/preview.html) | examen-herinnering.html | student.exam_reminder | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 25 | [Examenresultaat beschikbaar](mails/25-examenresultaat-beschikbaar/preview.html) | examenresultaat.html | student.exam_result_registered | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 26 | [Gefeliciteerd, geslaagd!](mails/26-gefeliciteerd-geslaagd/preview.html) | examenresultaat.html | student.exam_passed | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 27 | [Nieuwe factuur](mails/27-nieuwe-factuur/preview.html) | nieuwe-factuur.html | student.invoice_issued | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 28 | [Factuurherinnering](mails/28-factuurherinnering/preview.html) | betalingsherinnering.html | student.invoice_due_soon | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 29 | [Factuur verlopen](mails/29-factuur-verlopen/preview.html) | betalingsherinnering.html | student.invoice_overdue | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 30 | [Betaling ontvangen](mails/30-betaling-ontvangen/preview.html) | Nieuw leerlingontwerp | student.payment_confirmed | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 31 | [Betaling niet gelukt](mails/31-betaling-niet-gelukt/preview.html) | Nieuw leerlingontwerp | student.payment_failed | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 32 | [Creditnota of terugbetaling](mails/32-creditnota-of-terugbetaling/preview.html) | Nieuw leerlingontwerp | student.invoice_adjusted | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 33 | [Uitnodiging voor Klantio L](mails/33-uitnodiging-voor-klantio-l/preview.html) | leerling-uitnodiging.html | student.invited | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 34 | [Account gekoppeld](mails/34-account-gekoppeld/preview.html) | Nieuw leerlingontwerp | student.link_confirmed | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 35 | [Weekoverzicht rijlessen](mails/35-weekoverzicht-rijlessen/preview.html) | Nieuw leerlingontwerp | student.digest_week_schedule | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |
| 36 | [Maandoverzicht](mails/36-maandoverzicht/preview.html) | Nieuw leerlingontwerp | student.digest_month | NIEUWE KOPPELING NIET GEBOUWD; LIVE TRIGGER NIET GEVERIFIEERD |

## Illustraties

- [welkom — PNG](assets/welkom.png) · [SVG-bron](assets/welkom.svg)
- [les-gepland — PNG](assets/les-gepland.png) · [SVG-bron](assets/les-gepland.svg)
- [les-verplaatst — PNG](assets/les-verplaatst.png) · [SVG-bron](assets/les-verplaatst.svg)
- [les-geannuleerd — PNG](assets/les-geannuleerd.png) · [SVG-bron](assets/les-geannuleerd.svg)
- [lesherinnering — PNG](assets/lesherinnering.png) · [SVG-bron](assets/lesherinnering.svg)
- [voortgang — PNG](assets/voortgang.png) · [SVG-bron](assets/voortgang.svg)
- [examen — PNG](assets/examen.png) · [SVG-bron](assets/examen.svg)
- [geslaagd — PNG](assets/geslaagd.png) · [SVG-bron](assets/geslaagd.svg)
- [betaling — PNG](assets/betaling.png) · [SVG-bron](assets/betaling.svg)
- [beveiliging — PNG](assets/beveiliging.png) · [SVG-bron](assets/beveiliging.svg)

## Technische grenzen en workflow

Geen bestaande bestanden in Leerling gewijzigd; alleen deze nieuwe map toegevoegd. Geen database-/productiewijzigingen, geen nieuwe provider, geen wijziging van Auth, Mollie, bedragen, abonnementsprijzen, push, support, inbound of IMAP/SMTP. Geen bestaande migratiegeschiedenis onderzocht of gerepareerd.

Graphify/Obsidian waren niet beschikbaar en zijn op basis van de eerder expliciet gevraagde bypass overgeslagen. Geen onjuiste gebruiks-, graphupdate- of Obsidian-syncclaim. Scope is SOLO en TEAM; de bestaande canonical leerlingtoewijzing blijft leidend. Productmodus wordt niet uit een abonnementsplan afgeleid.


## Gedeelde logo-uitlijning — 20 oktober 2026

Op expliciet gebruikersverzoek zijn het woordmerk en de rode streep in beide bibliotheken verticaal gecentreerd. De PNG heeft exact evenveel transparante ruimte boven en onder (16 bronpixels); de streep is 28 px hoog en de logoafbeelding 23 px. Gemeten visuele marge: 5,7 px boven én onder, op desktop en mobiel. Zie qa/logo-uitlijning.json. Alle bestaande basispreviews en variantscreenshots zijn vernieuwd.
