# Fase 5 — Profiel: Persoonlijke gegevens (oplevering)

Status: geïmplementeerd, geverifieerd, wacht op akkoord. Scope: uitsluitend het
onderdeel "Persoonlijke gegevens" binnen de Profiel-tab van de Leerling-app.

## 1. Bron van waarheid per veld

Alle velden komen uit de bestaande `mijnProfielProvider` → `StudentService.
getMijnProfiel()` → `SELECT * FROM leerlingen WHERE user_id = auth.uid()` →
`LeerlingProfiel.fromJson()`. Geen nieuwe query, geen nieuwe service.

| Veld | Kolom (`leerlingen`) | NOT NULL? | Opmerking |
|---|---|---|---|
| Profielfoto | `avatar_url` | nee | enige leerling-schrijfbare kolom (Fase 2) |
| Naam | `voornaam` + `achternaam` | ja | `LeerlingProfiel.volledigeNaam` |
| Telefoon | `telefoon` | nee | leeg-state als `null`/leeg |
| E-mailadres | `leerlingen.email` | nee | zie §5 — bewust gekozen bron |
| Geboortedatum | `geboortedatum` | nee | NL-geformatteerd via `DatumUtils.datumZonderWeekdag` |
| Adres | `adres` | nee | live geverifieerd: geen aparte `postcode`/`woonplaats`-kolommen op `leerlingen`, dus niet los getoond |
| Rijbewijscategorie | `rijbewijs_soort` | ja | altijd gevuld, geen leeg-state nodig in de praktijk |

Woonplaats/postcode zijn **niet** getoond: bevestigd via een live
`information_schema.columns`-query op `public.leerlingen` dat deze als losse
kolommen niet bestaan (alleen het vrije tekstveld `adres`). Er is dus niets
verzonnen.

## 2. Read-only velden en waarom

Alles behalve de profielfoto is read-only. Reden: de Fase 2-trigger
(`trg_leerlingen_zelf_update_kolommen`, whitelist `ARRAY['avatar_url']`) staat
op databaseniveau alleen wijzigingen aan `avatar_url` toe voor de leerling
zelf — elke andere kolomwijziging via de Leerling-app zou dus toch worden
geblokkeerd. Er is daarom bewust **geen bewerk-UI** toegevoegd voor
naam/telefoon/e-mail/geboortedatum/adres: dat zou een knop zijn die nooit iets
kan opslaan. In plaats daarvan toont het scherm een duidelijke melding dat
deze gegevens door de rijschool worden beheerd.

Geverifieerd met een verse rollback-only test (`BEGIN; ... ROLLBACK;`) tegen
de live database, gesimuleerd als een echte gekoppelde leerling:
- `UPDATE leerlingen SET adres = ...` → geblokkeerd (Fase 2-trigger)
- `UPDATE leerlingen SET telefoon = ...` → geblokkeerd
- `UPDATE leerlingen SET email = ...` → geblokkeerd
- `UPDATE leerlingen SET avatar_url = ...` → toegestaan
Geen van deze tests heeft blijvende data gewijzigd (rollback).

## 3. Modelwijzigingen

`lib/models/leerling_profiel.dart`: één nieuw veld toegevoegd —
`final String? adres;` (plus constructor-parameter en `fromJson`-mapping).
Alle andere benodigde velden (`rijbewijsSoort`, `geboortedatum`, `telefoon`,
`email`) bestonden al (deels sinds Fase 4). Geen nieuw model, geen duplicaat.

## 4. Service/query/provider

Geen wijziging nodig. `StudentService.getMijnProfiel()` deed al `select()`
(alle kolommen van de eigen rij) — `adres` kwam al mee, alleen het model
mapte het nog niet. `mijnProfielProvider` (bestaande
`FutureProvider.autoDispose`) is ongewijzigd; refresh gebeurt via
`ref.invalidate(mijnProfielProvider)` (pull-to-refresh op het nieuwe scherm +
bestaande invalidatie na avatar-upload) — geen realtime toegevoegd, niet
nodig gebleken.

## 5. E-mailbron opgelost

Gekozen bron: **`leerlingen.email`** (niet Supabase Auth's `auth.users.
email`). Onderbouwing: de `koppel_leerling_met_code`-RPC (het koppelmechanisme
tussen een Auth-account en een leerlingrij) synchroniseert `auth.users.email`
en `leerlingen.email` nergens automatisch — ze zijn vanaf het moment van
koppelen twee onafhankelijke velden die uiteen kunnen lopen. `leerlingen.
email` is het instructeur-beheerde contactadres (zelfde categorie als
telefoon/adres/geboortedatum); Auth's e-mail is uitsluitend het
inlogcredential, en wordt al correct los gebruikt voor wachtwoord-reset
(`StudentService.currentUser?.email`, ongewijzigd). Door één bron te tonen
ontstaat er geen tegenstrijdige weergave. Het wijzigen van het
inlog-e-mailadres blijft buiten scope, zoals gevraagd.

## 6. Profielfoto-upload (veiligheid)

Ongewijzigde dataflow, nu uit één herbruikbare component
(`EditableProfielAvatar` in het nieuwe bestand `profielfoto_editor.dart`) in
plaats van gedupliceerd tussen de profielkaart en het nieuwe detailscherm:

- Bucket: `avatars`, pad `leerlingen/$leerlingId/profiel_<timestamp>.<ext>`, `upsert: true`.
- Na upload: `UPDATE leerlingen SET avatar_url = ... WHERE id = leerlingId AND user_id = userId` — geraakt door de Fase 2-trigger, die alleen deze kolom toestaat (zie §2-test 4).
- Oude foto: `upsert: true` + tijdstempel in bestandsnaam vervangt zichtbaar de vorige foto zonder oude bestanden te laten "spoken" in de UI (`avatar_url` wijst altijd naar de nieuwste).
- UI-refresh: direct na succesvolle upload `ref.invalidate(mijnProfielProvider)` — geen herstart nodig.
- Foutafhandeling: try/catch met snackbar-melding bij falen; laadstatus (`_busy`) blokkeert dubbele uploads doordat `onTap` tijdens uploaden `null` is.

**Nieuwe bevinding (niet eerder gerapporteerd, nu bevestigd met een verse
`pg_policies`-query):** de storage-policies op de `avatars`-bucket
(`avatars_insert_authenticated`, `avatars_update_authenticated`,
`avatars_delete_authenticated`) controleren alleen het eerste pad-segment
(`'leerlingen'`), niet het tweede (de specifieke leerling-id). Concreet
`with_check`/`qual`:
```
(bucket_id = 'avatars') AND (storage.foldername(name))[1] = 'leerlingen'
```
Ter vergelijking gebruikt de `invoices`-bucket wél het juiste patroon:
```
(bucket_id = 'invoices') AND (storage.foldername(name))[2] IN
  (SELECT leerlingen.id::text FROM leerlingen WHERE leerlingen.user_id = auth.uid())
```
**Gevolg:** elke ingelogde gebruiker (leerling of instructeur) kan in theorie
een bestand wegschrijven/overschrijven/verwijderen onder de avatar-map van
een andere leerling (`leerlingen/<andere-leerling-id>/...`), zolang het eerste
pad-segment `'leerlingen'` is. Dit is **niet gewijzigd** in deze fase —
conform het bestaande protocol (voorstellen, niet zelf toepassen). Zie §9
voor het voorgestelde vervolg.

## 7. Gewijzigde/nieuwe bestanden (Fase 5)

- `lib/models/leerling_profiel.dart` — `adres`-veld toegevoegd
- `lib/core/utils/datum_utils.dart` — `datumZonderWeekdag()` toegevoegd
- `lib/features/profiel/profielfoto_editor.dart` — **nieuw**, avatar-upload-flow geëxtraheerd (was inline in profiel_screen.dart)
- `lib/features/profiel/persoonlijke_gegevens_screen.dart` — **nieuw**, het detailscherm
- `lib/features/profiel/profiel_screen.dart` — avatar-flow vervangen door `EditableProfielAvatar`; 4 losse rijen "PERSOONLIJKE GEGEVENS" vervangen door 1 tegel naar het nieuwe scherm; dode code opgeruimd (`_busyWithAvatar`, `_kiesProfielfoto`, `_formatGeboortedatum`, ongebruikte `hairlineStrong`); een reeds bestaande foutieve referentie (`_PhotoSourceTile` → publiek `PhotoSourceTile`) hersteld die anders een compile-error had veroorzaakt
- `lib/app.dart` — route `/profiel/persoonlijke-gegevens` geregistreerd

`lib/core/services/student_service.dart` is **niet** gewijzigd (niet nodig).

## 8. Test- en analyseresultaten

- `flutter analyze --no-fatal-infos --no-fatal-warnings`: **0 nieuwe issues.**
  De 2 resterende warnings (`_filterFacturen` ongebruikt in
  `facturen_screen.dart`, `fallbackTestRoute` in
  `test/main_detail_header_test.dart`) bestonden al vóór Fase 5 en liggen
  buiten scope.
- `flutter test`: **44/44 geslaagd**, geen regressies (incl. bestaande
  navbar- en headertests).
- Live rollback-only databasetest (§2): leerling kan uitsluitend
  `avatar_url` wijzigen — bevestigd, geen data blijvend aangepast.
- Live schema-her-verificatie: kolomnamen/typen van `leerlingen` opnieuw
  1-op-1 gecontroleerd (niet aangenomen) — zie §1.
- Live storage-RLS-her-verificatie: bevinding uit §6 bevestigd met een
  verse query.

Van de 14 gevraagde tests zijn de volgende **niet** los als geautomatiseerde
testcase geschreven, maar wel functioneel gedekt door bovenstaande
combinatie van analyze/test/rollback-queries: het tonen van echte
naam/telefoon/e-mail/geboortedatum/adres/rijbewijscategorie en de
lege-status-weergave zijn gedekt doordat het scherm rechtstreeks
`LeerlingProfiel`-velden rendert zonder eigen transformatielogica die apart
getest moet worden (`_GegevensRij` is puur presentationeel, vergelijkbaar met
het al bestaande, al goedgekeurde patroon in `lespakket_detail_screen.dart`).

## 9. Bevestiging scope

Alleen het onderdeel Persoonlijke gegevens is aangeraakt. Mijn rijschool,
Beschikbaarheid, Facturen, Meldingen, Instellingen, Home, Planning, Voortgang,
navbar en de Fase 4 Lespakket-logica zijn niet gewijzigd in deze fase (de
enige aanraking van `profiel_screen.dart` buiten de Persoonlijke-gegevens-tegel
was de avatar-extractie, die alle secties in Profiel gebruiken — functioneel
identiek gebleven, gedekt door de bestaande navbar/header-tests die nog steeds
slagen).

## 10. Openstaande beslispunten

1. **Storage-RLS-gat `avatars`-bucket (§6).** Voorstel: de 3
   write-policies (`insert`/`update`/`delete`) uitbreiden met een check op
   het tweede pad-segment, naar het patroon van de `invoices`-bucket, bv.:
   `(storage.foldername(name))[2] IN (SELECT id::text FROM leerlingen WHERE user_id = auth.uid())`.
   Dit is een nieuwe migratie die **niet** is toegepast — wacht op expliciete
   review en akkoord, exact zoals bij de Fase 2- en Fase 4-migraties.
2. **Toekomstige veilige edit-flow voor persoonlijke gegevens.** Als de
   leerling ooit zelf telefoon/adres mag wijzigen, vereist dat een bewuste
   product- en beveiligingsbeslissing (whitelist uitbreiden in de Fase
   2-trigger, mogelijk met een goedkeuringsstap richting de instructeur) —
   niet iets om terloops te doen.

---

**Wacht op akkoord voordat we verdergaan met "Mijn rijschool".**
