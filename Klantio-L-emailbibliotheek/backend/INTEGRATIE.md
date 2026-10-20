# Serverintegratie — nog niet aangesloten

De code in deze map is pure ontwikkelvoorbereiding. Er is geen HTTP-verzendendpoint, nieuwe provider, database-adapter, queueworker, webhook of cron. Gebruik bij integratie uitsluitend de bestaande centrale `send-email` + Resend-architectuur in het Instructeur-project.

## Vertrouwde adapter

`prepareNotification` accepteert alleen template-ID, event-ID en ontvanger-ID. De adapter laadt de overige gegevens zelf. Laat nooit een leerlingclient de flags, status, school-ID, ontvanger, bedragen of vrijgave aanleveren. Een boolean `verified` vormt op zichzelf geen beveiligingsbewijs.

- `loadVerifiedEvent(id)`: haalt een echt gecommitte event en zijn actuele versie/status op. Verifieert de bestaande businessgebeurtenis en bijbehorende brondata. Het schoolaccount krijgt een echte `productMode`; deze wordt niet uit een abonnementsnaam afgeleid.
- `loadRecipient(id)`: bindt de echte authgebruiker aan het eigen leerlingrecord via de bestaande `leerlingen.user_id`-koppeling, het actuele `school_id` en een veilig vastgesteld e-mailadres. Inactieve of overgedragen schoolkoppelingen mogen geen oude schoolgegevens blijven ontvangen.
- `canReadObject({userId, studentId, schoolId, entityId})`: toetst het object aan bestaande RLS-/eigenaarsregels. Niet alleen ‘is ingelogd’, maar precies deze les/factuur/evaluatie/examenafspraak moet aan precies deze leerling en huidige school toebehoren. `leerlingen.instructeur_id` en `leerlingen.school_id` blijven de canonical toewijzing.
- `loadPreferences(userId)`: haalt de afzonderlijke e-mailvoorkeuren op. De bestaande leerlingvoorkeuren zijn niet automatisch een e-mailmodel. De voorbereiding vereist een globale optionele e-mailschakelaar plus groepsvoorkeuren. Geen nieuwe optionele groep activeren als voorkeuren ontbreken of niet leesbaar zijn.
- `sessionIdentity()` en `savePreferences`: schrijven uitsluitend voorkeuren van de geverifieerde eigen sessie. De lokale webdemo is geen implementatie van deze opslag.

Accountmails gebruiken de eigen geverifieerde accountbinding, ook vóór een rijschoolkoppeling. Uitnodigingen krijgen een afzonderlijke targetbinding, veilige vervaldatum en bestaande koppelingsactie. Ze kennen zelf geen toegang toe. Deactivering mag alleen voor het eigen account worden gemeld.

## Bronstatus en inhoud

Rijlesherinneringen vereisen een echte bestaande herinneringsconfiguratie en een nog niet begonnen les. Evaluaties vereisen definitieve publicatie en menselijke vrijgave. Voortgang vereist vrijgegeven actuele gegevens; mijlpalen vereisen werkelijk behaalde drempels. Geen concept-AI-inhoud, slaagkans of nieuwe detectiefunctie toevoegen.

Facturen zijn uitsluitend **rijschoolfacturen van de leerling**, nooit platformabonnementsfacturen. Controleer `invoiceStudentId`, `invoiceSchoolId`, eurocenten, EUR en actuele openstaande status. Betalingen vereisen betrouwbare verwerking van de bestaande Mollie/providergebeurtenis. Een betaal-returnlink of handmatig vinkje ‘betaald’ is geen betalingsbewijs. Creditnota’s vereisen een echte grootboekmutatie; refunds vereisen bevestigde geldteruggave. Bouw de rendererwaarden uit datzelfde gecontroleerde snapshot, niet uit een los clientobject.

## Deduplicatie, voorkeuren en verzending

De voorbereide businesskey identificeert school, ontvanger, eventfamilie en echte statusovergang. Dezelfde Mollie-webhook/retry moet dezelfde sleutel opleveren. Koppel nieuwe lesbevestiging 07 aan de reeds bestaande instructeur-lesbevestiging: kies één eigenaar voor verzending en één gezamenlijke duurzame claim. Voor examenuitslag en geslaagdmail moet per uitslag één contentvariant worden gekozen.

`DemoOutbox` is uitsluitend een vluchtige testdubbel en garandeert geen duurzaamheid of cross-process uitsluiting. Nog te bouwen: atomaire unieke claims, leases, persistente status, school-/ontvangerratelimits, begrensde retries, webhookhandtekeningcontrole, bounce-/deliverystatus, provider-idempotency en herstel na onzekere netwerkuitkomst. Gebruik de bestaande provider; geen nieuwe verzenddienst toevoegen.

Hercontroleer bij elke workerpoging de huidige toegang, voorkeuren en objectstatus. Een inmiddels betaalde factuur krijgt geen herinnering; ingetrokken toegang of een geannuleerde les trekt een verouderde wachtrijmail in. Bundel snelle leswijzigingen gedurende het ingestelde venster. Overzichten zijn optioneel, niet leeg, per leerling/school/periode en in `Europe/Amsterdam`; ook de onderliggende categorie-opt-out blijft gelden. De helper is nog geen scheduler of digestaggregator.

Essentiële beveiligings- en noodzakelijke account-/koppelingsberichten vallen buiten gewone optionele groepen. Factuur- en betalingsmails zijn hier als optionele operationele meldingen voorbereid, niet als marketing. Bevestig vóór activering per type welke administratieve communicatie werkelijk noodzakelijk is en hoe die juridisch/productmatig wordt behandeld; schakel niet zonder besluit financiële mails stilzwijgend om naar onuitschakelbaar.

Log alleen minimale metadata zoals template-ID en gehashte eventkey. Geen e-mailinhoud, raw tokens, leerlingfeedback of betaalgegevens in logs. Publieke afbeeldingsbestanden bevatten geen persoonsgegevens of echte bedragen.

## Migraties en productie

Er is geen SQL of migratie toegevoegd. Als een duurzame outbox of voorkeurentabel een NIEUWE schemawijziging vereist, toon eerst de volledige SQL en verkrijg expliciete toestemming. Gebruik alleen de canonical migratieroot in het Instructeur-repo. Bestaande migratiegeschiedenis wordt niet onderzocht of gerepareerd voor deze bibliotheek.

Vereiste live/stagingregressies: Auth OTP/confirm/recovery, password_changed, bestaande les_bevestiging, support/staff-inbox, Resend inbound, IMAP/SMTP, push, cronjobs en Mollie. Ook echte iOS-/Android-app-links met/zonder sessie, objecttoegang na login, workerconcurrentie en webhookreplay moeten nog worden getest. Geen van deze garanties volgt uit de lokale pure tests.
