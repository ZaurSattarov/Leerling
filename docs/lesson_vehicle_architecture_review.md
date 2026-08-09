# Les-voertuigkoppeling architectuur- en migratiereview

Status: Optie B goedgekeurd (2026-08-07). Migratie-SQL is klaar voor
toepassing, maar nog NIET live uitgevoerd -- vereist handmatige toepassing
door een projectbeheerder (Supabase Dashboard SQL Editor of `supabase db
push`), zie "Toepassen" onderaan. Geen Instructeur-app-wijziging in deze
stap: bestaande en nieuwe lessen tonen pas een voertuig zodra een
instructeur er via een LATERE, nog te bouwen Instructeur-UI eentje aan
koppelt.
Datum: 2026-08-04 (review), 2026-08-07 (goedgekeurd, DB nog niet toegepast).

## Exact live schema

Read-only geverifieerd op project `fbgjksxrehqyphaidgck`.

### public.lessen

- `id`: `uuid`, not null, primary key.
- `instructeur_id`: `uuid`, not null, FK naar `instructeur_profielen(id)` met `ON DELETE CASCADE`.
- `leerling_id`: `uuid`, not null, FK naar `leerlingen(id)` met `ON DELETE CASCADE`.
- Geen `voertuig_id`.
- Geen voertuig snapshotkolommen.
- RLS staat aan.

Relevante bestaande leskolommen: `datum`, `starttijd`, `eindtijd`, `duur_minuten`, `status`, `locatie`, `les_type`, `zichtbaar_voor_leerling`, `geoefende_onderwerpen`, `instructeur_feedback`, `leerling_notitie`, `competentie_scores`, `beoordeling`, `focus_punten`, `ingrepen_count`, `volgende_les_advies`, `package_id`, `package_deducted`.

### public.vehicles

- `id`: `uuid`, not null, primary key.
- `instructeur_id`: `uuid`, not null, FK naar `auth.users(id)` met `ON DELETE CASCADE`.
- `categorie_id`: `text`, not null, FK naar `license_categories(id)`.
- `transmissie_type`: `text`, not null, check: `manual`, `automatic`, `none`.
- `naam`: `text`, not null.
- `merk`: `text`, nullable.
- `model`: `text`, nullable.
- `kenteken`: `text`, nullable.
- `bouwjaar`: `integer`, nullable.
- `actief`: `boolean`, not null.
- `aangemaakt_op`: `timestamptz`, not null.
- `bijgewerkt_op`: `timestamptz`, not null.
- Geen `kleur` kolom.
- RLS staat aan.

Echte veldnamen:

| Betekenis | Live kolom |
|---|---|
| Merk | `merk` |
| Model | `model` |
| Kenteken | `kenteken` |
| Transmissie | `transmissie_type` |
| Categorie | `categorie_id` |
| Kleur | bestaat niet |
| Instructeur | `instructeur_id` |
| Actief | `actief` |

### public.leerlingen

Relevant voor validatie:

- `id`: `uuid`, not null.
- `instructeur_id`: `uuid`, not null.
- `user_id`: `uuid`, nullable.
- `rijbewijs_soort`: `text`, not null.
- `transmissie`: `text`, not null.
- `school_id`: `uuid`, nullable.

### student_lessen_view

Huidige opties:

- `security_barrier=true`
- `security_invoker=on`

Huidige filters:

- `leerling.user_id = auth.uid()`
- status zichtbaar wanneer:
  - `gepland`
  - `afgerond` en `zichtbaar_voor_leerling`
  - `geannuleerd`, `verzet`, `geen_toon`

Huidige grants uit `information_schema.role_table_grants` tonen `SELECT`, maar ook muterende privileges (`INSERT`, `UPDATE`, `DELETE`, etc.) voor `anon`, `authenticated` en `service_role` op de bekeken tabellen/views. Voor `student_lessen_view` is alleen `SELECT` nodig. Het voorstel herstelt de view naar `GRANT SELECT`.

## Exacte oorzaak

De Leerlingen-app kan geen echte BMW X5 tonen omdat de database geen exacte relatie heeft tussen `lessen` en `vehicles`. De Instructeur-app toont voertuigdata via `matchVoertuigVoorLes()`, een heuristiek op rijbewijscategorie en transmissie. Die functie documenteert expliciet dat `lessen` geen directe `voertuig_id` koppeling hebben.

## Instructeur-app flow

| Stap | Bestand/functie | Huidige bron | Huidige waarde | Gewenste wijziging |
|---|---|---|---|---|
| Voertuigen ophalen | `lib/features/agenda/agenda_provider.dart`, `lesVoertuigenProvider` | `vehicles` query met `instructeur_id = SupabaseService.userId` en `actief = true` | Lijst actieve eigen voertuigen | Hergebruiken voor keuzelijst, eventueel filteren op leerlingcategorie/transmissie |
| Voertuig tonen in agendakaart | `lib/features/agenda/widgets/les_kaart.dart` | `matchVoertuigVoorLes(les, voertuigen)` | Heuristische match; kenteken op kaart | Vervangen door `les.voertuigId`/viewmodel-relatie, geen heuristic als definitieve lesauto |
| Voertuig tonen in lesdetail | `lib/features/agenda/les_detail_screen.dart`, `_matchVoertuig()` | `matchVoertuigVoorLes` | Heuristische waarde of `Geen voertuig gekozen` | Toon gekozen voertuig via `les.voertuigId`; bij null expliciet geen gekoppeld voertuig |
| Lesformulier init | `lib/features/agenda/nieuwe_afspraak_screen.dart`, `initState()` | Bestaande lesvelden | Geen voertuig state | Voeg `_voertuigId` toe en prefill uit `bestaande.voertuigId` |
| Lesformulier opslaan nieuw | `NieuweAfspraakScreen._opslaan()` | Payload naar `SupabaseService.maakLes(data)` | Geen `voertuig_id` | Voeg `voertuig_id: _voertuigId` toe |
| Lesformulier update | `NieuweAfspraakScreen._opslaan()` | Payload naar `SupabaseService.updateLes(id, updateData)` | Geen `voertuig_id` | Voeg `voertuig_id` toe, ook bij afgeronde les alleen als bewuste correctie toegestaan is |
| Service create | `lib/core/services/supabase_service.dart`, `maakLes()` | `_normaliseerLesPayload`, daarna `.from('lessen').insert(payload)` | Stuurt geen voertuig | Laat `voertuig_id` door payload-normalisatie heen |
| Service update | `SupabaseService.updateLes()` | `_normaliseerLesPayload`, daarna `.from('lessen').update(payload)` | Stuurt geen voertuig | Laat `voertuig_id` door en selecteer bestaand `voertuig_id` voor optimistic update/notificatie |
| Model | `lib/models/les.dart` | `Les.fromJson`, `toJson`, `copyWith` | Geen `voertuigId` of voertuig snapshotvelden | Voeg `voertuigId` en view/snapshot labels toe |

## Opties

### Optie A: alleen `lessen.voertuig_id`

- Geplande les: toont de actuele gekoppelde auto via join op `vehicles`.
- Afgeronde les: toont ook de actuele auto, dus historie verandert wanneer merk/model/kenteken later wordt aangepast.
- Wijzigen merk/model/kenteken: alle oude lessen veranderen mee.
- Deactiveren voertuig: gekoppelde lessen kunnen nog joinen, maar nieuwe keuzes moeten actief blijven.
- Verwijderen voertuig: bij `ON DELETE SET NULL` verdwijnt voertuig bij oude lessen; bij restrict kan niet worden verwijderd.
- Historie: niet stabiel.
- Past minder goed bij bestaande snapshotarchitectuur rond pakketten/factuurgegevens.

### Optie B: `lessen.voertuig_id` plus snapshots

- Geplande les: toont actuele gekoppelde auto via `vehicles`.
- Afgeronde les: toont `lessen.voertuig_*_snapshot`, bevroren bij afronden.
- Wijzigen merk/model/kenteken: toekomstige/geplande lessen tonen de wijziging, afgeronde lessen blijven historisch correct.
- Deactiveren voertuig: nieuwe keuze wordt geweigerd; bestaande geplande lessen kunnen nog zichtbaar blijven via de exacte koppeling.
- Verwijderen voertuig: `ON DELETE SET NULL`; afgeronde lessen behouden snapshot. Voor geplande lessen zonder relationele rij wordt geen voertuig getoond.
- Historie: stabiel.
- Past bij bestaande pakket-/factuursnapshotdenkwijze: mutable brondata wordt bij administratieve afronding vastgelegd.

Aanbeveling: Optie B. Dit is het betrouwbaarst voor leerlingweergave en onderhoud omdat het zowel actuele planning als historische correctheid dekt.

## Beveiligingsmodel

Alleen Flutter-validatie is onvoldoende. De database moet afdwingen:

- `lessen.voertuig_id` moet naar bestaand `vehicles.id` wijzen.
- `vehicles.instructeur_id` moet gelijk zijn aan `lessen.instructeur_id`.
- Bij nieuwe keuze moet `vehicles.actief = true`.
- `vehicles.categorie_id` moet gelijk zijn aan `leerlingen.rijbewijs_soort`.
- Als leerlingtransmissie niet `none` is, moet `vehicles.transmissie_type` gelijk zijn aan `leerlingen.transmissie`.

Een samengestelde FK is hier niet schoon toepasbaar omdat `lessen.instructeur_id` naar `instructeur_profielen(id)` verwijst en `vehicles.instructeur_id` naar `auth.users(id)`. Het voorstel gebruikt daarom:

- gewone FK `lessen.voertuig_id -> vehicles(id)`;
- `BEFORE INSERT OR UPDATE` trigger voor eigenaarschap, actiefstatus, categorie/transmissie en snapshot.

Leerlingtoegang blijft via `student_lessen_view`. Omdat de view `security_invoker` behoudt, moet de onderliggende join naar `vehicles` ook langs RLS kunnen. Het voorstel voegt daarom een smalle `vehicles` SELECT-policy toe voor `authenticated`: alleen voertuigen die via `lessen.voertuig_id` gekoppeld zijn aan lessen van de ingelogde leerling en die al via dezelfde statusregels zichtbaar mogen zijn. Dit is geen brede leerling-policy: de leerling kan geen andere voertuigen van dezelfde instructeur of rijschool enumereren.

## Migratie en rollback

- Definitieve review-migration: `supabase/migrations/20260804115352_lesson_vehicle_snapshot_review.sql`
- Rollback: `supabase/rollbacks/20260804115352_lesson_vehicle_snapshot_review_rollback.sql`

De migration behoudt bestaande viewkolommen en voegt voertuigvelden achteraan toe:

- `voertuig_naam`
- `voertuig_merk`
- `voertuig_model`
- `voertuig_kenteken`
- `voertuig_transmissie`
- `voertuig_categorie`

Geen `voertuig_kleur`, want `public.vehicles.kleur` bestaat live niet.

De migration behoudt `security_barrier=true` en `security_invoker=true`. Volgens de actuele Supabase RLS-documentatie laten `security_invoker` views de onderliggende tabel-RLS gelden; daarom is de smalle gekoppelde-voertuigenpolicy noodzakelijk.

## Historische impact en backfill

Live telling:

- Totaal lessen: 127.
- Toekomstige lessen vanaf 2026-08-04: 4.
- Afgeronde lessen: 124.
- Betrouwbaar exact backfillbaar: 0, omdat er geen bestaande exacte bron is.
- Heuristisch precies een match: 107.
- Heuristisch geen match: 20.
- Heuristisch meerdere matches: 0.

Geen heuristische backfill uitvoeren. Bestaande lessen houden `voertuig_id = NULL` totdat een instructeur handmatig kiest. De Leerlingen-app verbergt de voertuigkaart bij ontbrekende koppeling.

## Instructeur-app codeplan

1. Breid `Les` uit met `voertuigId` en optionele voertuigweergavevelden uit de join/view.
2. Voeg in `NieuweAfspraakScreen` state toe: `_voertuigId`.
3. Prefill `_voertuigId` uit `bestaandeLes.voertuigId`.
4. Voeg een voertuigselector toe met `lesVoertuigenProvider`, gefilterd op actieve eigen voertuigen en passend bij geselecteerde leerlingcategorie/transmissie.
5. Stuur `voertuig_id` mee in create en update payload.
6. Laat `SupabaseService._normaliseerLesPayload()` `voertuig_id` ongemoeid.
7. Vervang definitieve voertuigweergave in `LesKaart` en `LesDetailScreen` door de gekozen koppeling.
8. Laat `matchVoertuigVoorLes()` hoogstens bestaan als suggestie voor preselectie, niet als waarheid.

## Leerlingen-app codeplan

1. Houd de bestaande voertuigkaart.
2. Lees alleen definitieve viewvelden: `voertuig_merk`, `voertuig_model`, `voertuig_kenteken`, `voertuig_transmissie`, `voertuig_categorie`.
3. Verberg kaart wanneer alle voertuigvelden null/leeg zijn.
4. Geen query op `vehicles` in de Leerlingen-app.
5. Realtime blijft werken via `lessen` subscription; wijziging van `voertuig_id` of status triggert refresh.
6. Voor realtime refresh na wijziging van masterdata in `vehicles` is aanvullend een `vehicles` subscription in de Instructeur-app nuttig; voor Leerlingen-app is dit niet nodig als planned lessons opnieuw via de view laden na leswijziging/notificatie.

## Testplan

- Instructeur koppelt eigen actief voertuig aan nieuwe les.
- Instructeur wijzigt voertuig op geplande les.
- Voertuig van andere instructeur wordt door trigger geweigerd.
- Inactief voertuig wordt bij nieuwe keuze geweigerd.
- Verkeerde categorie wordt geweigerd.
- Verkeerde transmissie wordt geweigerd.
- Leerling ziet gekoppeld voertuig bij eigen geplande les.
- Leerling ziet snapshot bij eigen afgeronde les.
- Leerling ziet geen voertuigen van andere lessen/instructeurs.
- Les zonder voertuig blijft werken en verbergt voertuigkaart.
- Wijzigen merk/model/kenteken verandert geplande les, niet afgeronde snapshot.
- Deactiveren voertuig blokkeert nieuwe keuze maar breekt bestaande afgeronde historie niet.
- Geen heuristische backfill uitgevoerd.
- Bestaande `student_lessen_view` kolommen blijven aanwezig en in dezelfde volgorde.
- Bestaande Planning-tests blijven werken.

## Toepassen (2026-08-07, END-TO-END-opdracht)

Optie B is goedgekeurd. De agent-omgeving heeft geen Supabase-CLI-koppeling
of databasewachtwoord en kan de migratie daarom niet zelf live uitvoeren
(een tijdelijk personal access token is tijdens deze sessie door de
gebruiker aangeboden in de chat, maar NIET gebruikt -- API-tokens/
wachtwoorden worden principieel nooit door de agent ingevoerd, ook niet na
expliciete toestemming). Toepassen door een projectbeheerder, in exact deze
volgorde (elk bestand is idempotent/veilig herhaald uit te voeren):

1. `supabase/migrations/20260804115352_lesson_vehicle_snapshot_review.sql`
   -- voegt `lessen.voertuig_id` + snapshotkolommen, FK, trigger (v1),
   RLS-policy en de uitgebreide `student_lessen_view` toe (incl. nu ook de
   ruwe `voertuig_id`-kolom in de view, niet alleen de afgeleide
   weergavevelden).
2. `supabase/migrations/20260804150948_lesson_vehicle_snapshot_clear_contract.sql`
   -- verscherpt alleen de triggerfunctie met de historical_lesson-guard.
3. `supabase/migrations/20260807180000_lesson_vehicle_backfill_unambiguous.sql`
   -- éénmalige, veilige backfill: koppelt bestaande GEPLANDE lessen zonder
   voertuig_id alleen wanneer er voor die instructeur exact één actief,
   passend voertuig bestaat. Historische/afgeronde lessen worden nooit
   backfilled.

Uitvoeren: Supabase Dashboard -> SQL Editor (elk bestand na elkaar plakken en
uitvoeren), of `supabase db push` met een gekoppeld project.

**Validatie na toepassen:**

```sql
-- Kolom + FK bestaan
select voertuig_id from public.lessen limit 1;

-- View geeft alle 6 voertuigvelden terug
select voertuig_id, voertuig_merk, voertuig_model, voertuig_kenteken,
       voertuig_transmissie, voertuig_categorie
from public.student_lessen_view
limit 1;

-- Hoeveel geplande lessen kregen een ondubbelzinnige backfill-koppeling
select count(*) from public.lessen
where status = 'gepland' and voertuig_id is not null;
```

**Rollback indien nodig** (schema-migraties, in omgekeerde volgorde -- de
backfill zelf is puur data en heeft bewust geen apart rollback-script, zie
hieronder):
`supabase/rollbacks/20260804150948_lesson_vehicle_snapshot_clear_contract_rollback.sql`,
dan `supabase/rollbacks/20260804115352_lesson_vehicle_snapshot_review_rollback.sql`
(deze laatste verwijdert ook de `voertuig_id`-kolom zelf, dus een eventuele
backfill-koppeling vervalt daarmee automatisch mee).

## Flutter-status -- volledig geïmplementeerd

**Leerling-app:** geen Dart-wijziging nodig (al vóór deze opdracht correct).
`lib/models/les.dart` (`Les.fromJson`) en
`lib/features/planning/les_detail_screen.dart` (`_LesInformatieCard`) lezen
al `voertuig_merk`/`voertuig_model`/`voertuig_kenteken`/
`voertuig_transmissie`/`voertuig_categorie` rechtstreeks, en
`student_service.dart` query't al `student_lessen_view` met `.select()`
(alle kolommen).

**Instructeur-app (nieuw in deze opdracht):**
- `lib/models/les.dart`: `Les.voertuigId` toegevoegd (fromJson/toJson/copyWith).
- `lib/core/services/supabase_service.dart`: `voertuig_id` wordt meegestuurd
  in `maakLes`/`updateLes`, met dezelfde "kolom-ontbreekt"-fallback als
  `les_type`/pakketvelden zolang de migratie nog niet live staat.
- `lib/core/utils/voertuig_matching.dart`: nieuwe
  `exacteVoertuigKandidaten()` -- STRIKTE match (categorie + transmissie),
  gebruikt om automatisch koppelen te beperken tot ondubbelzinnige gevallen.
  De bestaande `matchVoertuigVoorLes()`-heuristiek blijft ongewijzigd
  bestaan, nu uitsluitend als weergave-fallback voor lessen zonder
  koppeling.
- `lib/features/agenda/nieuwe_afspraak_screen.dart`: nieuwe "Voertuig"-sectie
  -- 0 kandidaten: verborgen; 1 kandidaat: automatisch gekoppeld
  (read-only infobalk); >1 kandidaten: verplichte dropdown, nooit een
  stilzwijgende default.
  Bevroren (niet meegestuurd) zodra de les al is afgerond, conform de
  trigger die een voertuigwijziging op een afgeronde les hard weigert.
- `lib/features/agenda/widgets/les_kaart.dart` en
  `lib/features/agenda/les_detail_screen.dart`: tonen nu `les.voertuigId`
  (echte koppeling) wanneer aanwezig, met `matchVoertuigVoorLes()` alleen
  nog als fallback voor lessen zonder koppeling.

Zodra de migraties hierboven live staan, stroomt de data voor NIEUWE lessen
automatisch en zonder verdere code-wijziging door naar het Leerling-scherm.
