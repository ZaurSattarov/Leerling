# Architectuurdocument — Profiel-tab (Fase 3)

> Analyse-only. Geen code, geen UI gewijzigd. Bouwt voort op `docs/PROFIEL_AUDIT.md` (Stap 1) en
> `docs/PROFIEL_STAP2_BEVEILIGING.md` (Stap 2). Bronnen: Leerling-app code, Instructeur-app code
> (`rijschool-planner-flutter`), en het live Supabase-schema van project `fbgjksxrehqyphaidgck`
> (`information_schema`, `pg_policies`, `pg_constraint`), opgevraagd via de Management API.

## Twee architecturale basisfeiten (gelden voor alle onderdelen hieronder)

1. **Geen van beide apps heeft een aparte "repository"-laag.** Leerling gebruikt `StudentService`
   (`lib/core/services/student_service.dart`), Instructeur gebruikt `SupabaseService`
   (`lib/core/services/supabase_service.dart`) — beide zijn `static`-methode-klassen die rechtstreeks de
   Supabase-client aanroepen. Die klasse **is** in dit project de repository. Waar hieronder "repository"
   staat, bedoel ik dus telkens deze service-klasse — er bestaat geen aparte, dunnere laag eronder.
2. **Er is geen letterlijk hergebruik van Dart-code mogelijk tussen de twee apps.** Het zijn twee losse
   Flutter-projecten met eigen `pubspec.yaml`, geen gedeeld package. "Hergebruiken van de Instructeur-app"
   betekent in de praktijk: **dezelfde Supabase-tabellen, kolommen en RPC's aanspreken** — niet dezelfde
   Dart-klasse importeren. Het dependency-overzicht in sectie 12 is daarom een *conceptuele* mapping
   (welke kant schrijft, welke kant moet exact dezelfde bron lezen), geen lijst van te importeren bestanden.

Synchronisatieschema, generiek (geldt voor bijna elk onderdeel — de enige variabele is de tabel en welke
kant schrijft):

```
Instructeur-app UI
     │  SupabaseService.xxx()
     ▼
Supabase-tabel (RLS: instructeur_id = auth.uid())
     │
     │  (zelfde tabel, andere RLS-policy: user_id/leerling_id via leerlingen.user_id = auth.uid())
     ▼
StudentService.xxx()  (= repository, Leerling-app)
     ▼
Riverpod-provider (Leerling-app, feature-lokaal)
     ▼
Profiel-tab widget
```

Er is dus **geen aparte synchronisatiestap** nodig (geen sync-job, geen webhook, geen polling) — beide apps
lezen/schrijven dezelfde rij in dezelfde tabel, direct via Postgres. "Synchroon" is hier synoniem met
"zelfde tabel, zelfde rij, RLS bepaalt wie wat mag".

---

## 1. Persoonlijke gegevens

| # | Vraag | Antwoord |
|---|---|---|
| 1 | Waar komt de data vandaan? | Instructeur-app, ingevoerd bij leerling-aanmaak/-bewerking |
| 2 | Welke tabel? | `public.leerlingen` |
| 3 | Welke kolommen? | `voornaam`, `achternaam`, `email`, `telefoon`, `geboortedatum`, `adres` |
| 4 | Welke repository? | `StudentService` (Leerling) / `SupabaseService` (Instructeur) — zie basisfeit 1 |
| 5 | Welke service? | Idem — er is geen aparte servicelaag boven de repository |
| 6 | Welke provider? | `mijnProfielProvider` (`shared/providers/auth_provider.dart`) → `StudentService.getMijnProfiel()` |
| 7 | Eigenaar van de data? | Instructeur |
| 8 | Read-only of bewerkbaar (in Leerling-app)? | Read-only |
| 9 | Welke app schrijft? | Uitsluitend Instructeur-app (`SupabaseService.updateLeerling`/`maakLeerling`, RLS `Eigen leerlingen updaten`: `instructeur_id = auth.uid()`) |
| 10 | Synchronisatie met Instructeur-app? | Automatisch/direct — zelfde rij, zelfde tabel. Databaseniveau afgedwongen sinds Fase 2: leerling kan deze kolommen zelf niet overschrijven (trigger `trg_leerlingen_zelf_update_kolommen`) |

**Afwijking:** `adres` bestaat als kolom, wordt gelezen noch getoond door de Leerling-app (`LeerlingProfiel`-
model mist het veld). Zie sectie 13.

---

## 2. Profielfoto

| # | Vraag | Antwoord |
|---|---|---|
| 1 | Waar komt de data vandaan? | **Twee bronnen, bewust gescheiden**: (a) een door de leerling zelf geüploade foto, (b) in theorie een vooraf ingesteld avatar-icoon (niet geïmplementeerd voor leerlingen) |
| 2 | Welke tabel? | `public.leerlingen` + Supabase Storage bucket `avatars` |
| 3 | Welke kolommen? | `avatar_url` (bewerkbaar door leerling), `avatar_id` (kolom bestaat, wordt door geen van beide apps voor leerlingen gebruikt) |
| 4/5 | Repository/service | `StudentService.uploadMijnProfielfoto()` |
| 6 | Provider | Geen apart provider-bestand — de upload-actie roept de service direct aan vanuit `_ProfielHubState` in `profiel_screen.dart` en invalidateert daarna `mijnProfielProvider` |
| 7 | Eigenaar van de data? | **Leerling zelf** (enige uitzondering op "Instructeur is bron") |
| 8 | Read-only of bewerkbaar? | Bewerkbaar |
| 9 | Welke app schrijft? | Leerling-app (foto-upload); Instructeur-app schrijft dit veld niet in de code die ik heb gecontroleerd, maar had er op RLS-niveau vóór Fase 2 wel toegang toe als "wie mag alles" — dat gold voor instructeur al vanuit `instructeur_id`-scope en is ongewijzigd |
| 10 | Synchronisatie? | Automatisch — instructeur ziet dezelfde `avatar_url` direct in zijn eigen leerlingenlijst |

**Bevestiging Fase 2:** dit is sinds de migratie de **enige** kolom die de leerling zelf mag schrijven op
`leerlingen`, op databaseniveau afgedwongen (niet alleen door de Flutter-UI).

---

## 3. Mijn rijschool

| # | Vraag | Antwoord |
|---|---|---|
| 1 | Waar komt de data vandaan? | Instructeur-app, instellingenscherm "Bedrijfsgegevens" |
| 2 | Welke tabel? | `public.instructeur_profielen` |
| 3 | Welke kolommen? | `rijschool_naam`, `naam`, `telefoon`, `email`, `adres`, `postcode`, `stad`, `website`, `logo_url`, `whatsapp_nummer` |
| 4/5 | Repository/service | `StudentService.getMijnInstructeur()` (expliciete kolomselectie, geen `select *`) |
| 6 | Provider | Lokale `_instructeurProvider` (`FutureProvider.autoDispose`, gedefinieerd bovenaan `profiel_screen.dart`) |
| 7 | Eigenaar van de data? | Instructeur |
| 8 | Read-only of bewerkbaar? | Read-only (100% — geen enkele leerling-UPDATE-policy op deze tabel) |
| 9 | Welke app schrijft? | Uitsluitend Instructeur-app (`Eigen profiel updaten` / `eigen_instructeur_updaten`, beide `id = auth.uid()`) |
| 10 | Synchronisatie? | Automatisch/direct. RLS-scope bevestigd: leerling ziet alléén de eigen gekoppelde instructeur (`leerling_instructeur_profiel_lezen`: `id IN (SELECT instructeur_id FROM leerlingen WHERE user_id = auth.uid())`) |

**Afwijking:** `website` bestaat, wordt door `getMijnInstructeur()` niet geselecteerd en dus nergens getoond
in "Mijn rijschool". Zie sectie 13.

---

## 4. Rijopleiding (overzicht: pakket, voortgang, examenstatus)

| # | Vraag | Antwoord |
|---|---|---|
| 1 | Waar komt de data vandaan? | Instructeur-app (pakket-toewijzing, lesregistratie, examenregistratie) |
| 2 | Welke tabel(len)? | `leerlingen` (basisvelden) + `student_lessen_view` (lessen) + `examens` + `student_exam_readiness` (view) |
| 3 | Welke kolommen? | `leerlingen.pakket`, `.rijbewijs_soort`, `.lessen_totaal`, `.lessen_gevolgd`; lessen-view: status/datum; `examens`: volledige rij |
| 4/5 | Repository/service | `StudentService.getMijnLessenVoorPakket()`, `.getMijnExamens()`, `.getExamReadiness()` |
| 6 | Provider | `lespakketVoortgangProvider` (`voortgang/lespakket_voortgang_provider.dart`), `examensProvider`, `examenadviesProvider` |
| 7 | Eigenaar van de data? | Instructeur (pakket/lessen/examens) — de percentage-/telling-weergave is client-side afgeleid, geen aparte bron |
| 8 | Read-only of bewerkbaar? | Read-only |
| 9 | Welke app schrijft? | Instructeur-app: `pakket`/`lessen_totaal` bij toewijzing, `lessen_gevolgd` automatisch bij lesregistratie (`SupabaseService`, regel ~1260-1263: `update({'lessen_gevolgd': afgerondeCount})`), `examens` bij examenregistratie |
| 10 | Synchronisatie? | Automatisch/direct. Sinds Fase 2 ook op databaseniveau afgedwongen dat leerling deze velden niet zelf kan overschrijven |

**Belangrijk, geen bug:** `LespakketVoortgang.fromProfiel()` (`core/utils/lespakket_voortgang.dart`)
berekent "resterend"/"nog in te plannen"/percentage **client-side**, maar telt daarvoor de **echte**
`lessen`-rijen (status = afgerond/gepland) — dit is weergavelogica over al-bestaande, autoritatieve data,
geen dubbele businesslogica. Bevat een expliciete fallback (`gebruiktFallback`) naar
`profiel.lessenGevolgd` alléén wanneer de lessenlijst leeg is — dat is dus een bewuste, gelabelde
noodgreep, geen verborgen aanname.

**Afwijking:** `examen_datum` (kolom op `leerlingen`, apart van de `examens`-tabel) bestaat, wordt nergens
gelezen. Zie sectie 13.

---

## 5. Lespakket (detail: welk pakket, welke voorwaarden)

Dit is de diepere laag onder "Rijopleiding" — welk *specifiek* pakket is toegewezen en tegen welke
voorwaarden, niet alleen de tellingen.

| # | Vraag | Antwoord |
|---|---|---|
| 1 | Waar komt de data vandaan? | Instructeur-app: (a) pakkettencatalogus, (b) toewijzing aan een specifieke leerling |
| 2 | Welke tabel(len)? | `public.instructor_lesson_packages` (catalogus, door instructeur beheerd) + `public.leerlingen` (toewijzing + **snapshot**) |
| 3 | Welke kolommen? | Catalogus: `naam`, `categorie`, `transmissie`, `aantal_lessen`, `lesduur_minuten`, `pakketprijs`, `losse_lesprijs`, `praktijkexamen_inbegrepen`, `tussentijdse_toets_inbegrepen`, `actief`. Snapshot op `leerlingen`: `pakket_id` (FK), `pakket_naam`, `pakket_lessen`, `pakket_prijs_cents`, `pakket_losse_les_prijs_cents`, `pakket_lesduur_minuten`, `pakket_praktijkexamen_inbegrepen`, `pakket_tussentijdse_toets_inbegrepen`, `pakket_snapshot_vastgelegd_op` |
| 4/5 | Repository/service | Instructeur-app: `SupabaseService` (regel ~1280, leest `instructor_lesson_packages` om leerlingenlijst te verrijken). Leerling-app: **niets** — deze kolommen worden nergens gelezen |
| 6 | Provider | Geen (Leerling-app) |
| 7 | Eigenaar van de data? | Instructeur (catalogus én toewijzing) |
| 8 | Read-only of bewerkbaar? | Zou read-only moeten zijn voor de leerling — nu simpelweg niet zichtbaar |
| 9 | Welke app schrijft? | Instructeur-app: catalogus bij pakketbeheer, snapshot-kolommen op het moment van toewijzing aan een leerling (vandaar `pakket_snapshot_vastgelegd_op` — vastgelegde voorwaarden op toewijzingsmoment, blijven ongewijzigd ook als de instructeur de catalogusprijs later aanpast — bewust ontwerp, geen bug) |
| 10 | Synchronisatie? | Automatisch/direct, zodra de Leerling-app deze kolommen gaat uitlezen |

**Grootste architectuur-afwijking van dit hele document:** de Leerling-app toont vandaag alleen
`leerlingen.pakket` (het simpele enum: basis/standaard/intensief/los_rijles) en negeert zowel de
snapshot-kolommen als de catalogus. Het daadwerkelijk toegewezen pakket — met naam, prijs en
voorwaarden zoals die golden op het moment van toewijzing — is dus onzichtbaar voor de leerling. Zie
sectie 13, prioriteit hoog.

---

## 6. Beschikbaarheid

| # | Vraag | Antwoord |
|---|---|---|
| 1 | Waar komt de data vandaan? | De leerling zelf |
| 2 | Welke tabel? | `public.leerling_beschikbaarheid` |
| 3 | Welke kolommen? | `leerling_id`, `instructeur_id`, `dag_van_week`, `start_tijd`, `eind_tijd`, `voorkeur_score` |
| 4/5 | Repository/service | `StudentService.getMijnBeschikbaarheid()` / `.voegBeschikbaarheidToe()` / `.updateBeschikbaarheid()` / `.verwijderBeschikbaarheid()` |
| 6 | Provider | Geen apart providerbestand — `beschikbaarheid_screen.dart` roept de service rechtstreeks aan vanuit lokale widget-state |
| 7 | Eigenaar van de data? | **Leerling** (enige onderdeel, samen met profielfoto, waar dit zo hoort) |
| 8 | Read-only of bewerkbaar? | Volledig CRUD |
| 9 | Welke app schrijft? | Leerling-app schrijft; Instructeur-app leest (`instructeur_besch_select_leerlingen`: `instructeur_id = auth.uid()`) |
| 10 | Synchronisatie? | Automatisch/direct — zelfde tabel, instructeur ziet wijzigingen zonder vertraging |

Geen afwijking. Dit onderdeel is al 100% correct opgezet — precies het patroon dat de overige
leerling-eigen data (zodra die wordt uitgebreid) zou moeten volgen.

---

## 7. Facturen

| # | Vraag | Antwoord |
|---|---|---|
| 1 | Waar komt de data vandaan? | Instructeur-app (facturatie) |
| 2 | Welke tabel? | `public.facturen` |
| 3 | Welke kolommen? | Leerling-app leest de volledige rij (`select()` zonder projectie) — relevant: `status`, `bedrag_cents`, `vervaldatum`, `betaal_link_url`/`mollie_checkout_url`/`stripe_checkout_url`, `invoice_pdf_url`/`download_url`/`pdf_url` |
| 4/5 | Repository/service | `StudentService.getMijnFacturen()` / `.getFactuur()` / `.requestMollieFactuurPayment()` |
| 6 | Provider | `facturenProvider` / `factuurDetailProvider` (`features/facturen/facturen_provider.dart`), met realtime-subscriptie (`StudentService.subscribeFacturen`) |
| 7 | Eigenaar van de data? | Instructeur |
| 8 | Read-only of bewerkbaar? | Read-only (betalen gebeurt via een externe checkout-link, niet door de rij zelf te wijzigen) |
| 9 | Welke app schrijft? | Instructeur-app schrijft de factuur; het betaalproces zelf loopt via een Edge Function (`create-factuur-payment`) die de status bijwerkt na een geslaagde betaling — geen van beide Flutter-apps schrijft de betaalstatus rechtstreeks |
| 10 | Synchronisatie? | Automatisch/direct + realtime (Postgres changes-subscriptie op `leerling_id`) |

Geen afwijking in dit onderdeel zelf. Kleine, onschadelijke redundantie al genoteerd in
`docs/PROFIEL_AUDIT.md`: twee functioneel identieke SELECT-policies (`student_facturen_select` en
`leerling_eigen_facturen_lezen`) — geen gedragsverschil, puur opschoonpotentieel voor een latere stap.

---

## 8. Meldingen

| # | Vraag | Antwoord |
|---|---|---|
| 1 | Waar komt de data vandaan? | Instructeur-app (of systeemgegenereerd namens de instructeur) |
| 2 | Welke tabel? | `public.leerling_notificaties` |
| 3 | Welke kolommen? | `titel`, `omschrijving`, `type`, `gelezen`, `aangemaakt_op` |
| 4/5 | Repository/service | `StudentService.getMijnNotificaties()` / `.markeerGelezen()` / `.markeerAllesGelezen()` |
| 6 | Provider | `notificatiesProvider` / `ongelezenNotificatiesProvider` (`features/notificaties/notificaties_provider.dart`), met realtime-subscriptie |
| 7 | Eigenaar van de data? | Instructeur (schrijft), leerling mag alleen `gelezen` markeren |
| 8 | Read-only of bewerkbaar? | Read-only, behalve het veld `gelezen` |
| 9 | Welke app schrijft? | Instructeur-app schrijft de melding zelf; leerling-app schrijft uitsluitend `gelezen = true` (policy `student_notificaties_update`, kolom-breedte niet expliciet beperkt door een trigger zoals bij `leerlingen` — zie risico's) |
| 10 | Synchronisatie? | Automatisch/direct + realtime |

**Let op voor latere tabs (Home):** `leerling_notificaties` is **niet dezelfde tabel** als `notificaties`,
die de Instructeur-app voor zíjn eigen meldingen gebruikt (`NotificatieService`, zie
`core/services/notificatie_service.dart`). Dit is bewust — twee verschillende doelgroepen — geen
duplicatie, maar wel iets om expliciet te onthouden zodat niemand per ongeluk de verkeerde tabel gaat
hergebruiken bij het bouwen van de Home-tab.

**Klein, ongeadresseerd risico (buiten scope van deze stap, alleen ter constatering):** anders dan
`leerlingen` heeft `leerling_notificaties` nog géén kolombeveiligingstrigger — de RLS `WITH CHECK` op
`student_notificaties_update` beperkt de rij, niet expliciet de kolom. In de praktijk update de Flutter-code
alleen `gelezen`, maar zoals bij `leerlingen` vóór Fase 2 is dat een UI-belofte, geen databasegarantie.
Voorstel om dit in een latere, apart goed te keuren stap op dezelfde manier (kolomtrigger) te dichten —
niet nu, dat valt buiten "alleen Profiel-architectuur analyseren".

---

## 9. Instellingen

| Sub-item | Bron | Tabel | Eigenaar | Bewerkbaar | Schrijvende app |
|---|---|---|---|---|---|
| Wachtwoord wijzigen | Supabase Auth | `auth.users` (via Auth-API, geen directe tabeltoegang) | Leerling zelf | Ja | Leerling-app (`auth.resetPasswordForEmail`) — gedeelde identiteitsprovider, geen aparte "wachtwoord"-tabel per app |
| Privacy / voorwaarden | Statische externe URL (`klantio.nl/privacy`) | — | — | — | Geen database-eigenaarschap van toepassing; bedrijfsbrede link, geen leerling-/instructeurdata |
| Help / support | `/help`-scherm (contact + FAQ, statische content) | — | — | — | Geen database-afhankelijkheid |
| App-versie | Hardcoded string in de UI | — | — | — | Zie afwijkingen (sectie 13) — hoort uit de build-metadata te komen, niet uit een losse string |
| Account verwijderen | **Geen backend** | — | — | — | Niet geïmplementeerd voor leerlingen; Instructeur-app heeft wél een eigen verwijderflow (andere tabel/rol), niet herbruikbaar zonder een equivalente leerling-RPC |
| Taal | **Lokale device-instelling**, geen Supabase-kolom | — | — | — | Bevestigd: Instructeur-app's `taalProvider` gebruikt `SharedPreferences`, niet `instructeur_profielen` — als dit ooit voor leerlingen gebouwd wordt, hoort het volgens hetzelfde patroon lokaal te blijven, geen nieuwe kolom nodig |

Geen van deze sub-items heeft een repository/provider in de klassieke zin — ze zijn ofwel Auth-API-calls,
ofwel statische content, ofwel (bewust) nog niet geïmplementeerd.

---

## 10. Account (uitloggen, sessie)

| # | Vraag | Antwoord |
|---|---|---|
| 1 | Waar komt de data vandaan? | Supabase Auth-sessie |
| 2 | Welke tabel? | Geen directe tabeltoegang — `auth.users` intern via de Auth-API |
| 3 | Welke kolommen? | N.v.t. |
| 4/5 | Repository/service | `StudentService.uitloggen()` (`client.auth.signOut()`), `StudentService.currentUser` |
| 6 | Provider | `currentUserProvider` / `isLoggedInProvider` / `authStateProvider` (`shared/providers/auth_provider.dart`) |
| 7 | Eigenaar van de data? | Leerling zelf (het is zijn sessie) |
| 8 | Read-only of bewerkbaar? | Actie (uitloggen), geen data om te lezen/schrijven |
| 9 | Welke app schrijft? | N.v.t. — gedeelde Supabase Auth-laag, geen van beide apps "bezit" dit apart |
| 10 | Synchronisatie? | N.v.t. |

Geen afwijking.

---

## 11. Overzichtstabel (compact)

| Onderdeel | Tabel(len) | Eigenaar | Leerling: read-only/bewerkbaar | Databaseniveau afgedwongen? |
|---|---|---|---|---|
| Persoonlijke gegevens | `leerlingen` | Instructeur | Read-only | ✅ Ja (Fase 2 trigger) |
| Profielfoto | `leerlingen.avatar_url` + storage | **Leerling** | Bewerkbaar | ✅ Ja (enige whitelisted kolom) |
| Mijn rijschool | `instructeur_profielen` | Instructeur | Read-only | ✅ Ja (geen leerling-UPDATE-policy) |
| Rijopleiding | `leerlingen`, lessen-view, `examens` | Instructeur | Read-only | ✅ Ja (Fase 2 trigger dekt `leerlingen`-kolommen) |
| Lespakket (detail) | `instructor_lesson_packages`, snapshot op `leerlingen` | Instructeur | Read-only (maar nog niet zichtbaar) | ✅ Ja (Fase 2 trigger) |
| Beschikbaarheid | `leerling_beschikbaarheid` | **Leerling** | Volledig CRUD | ✅ Ja (eigen RLS, correct gescoped) |
| Facturen | `facturen` | Instructeur | Read-only | ✅ Ja (geen leerling-UPDATE-policy) |
| Meldingen | `leerling_notificaties` | Instructeur (behalve `gelezen`) | Read-only + `gelezen` | ⚠️ Rij-niveau ja, kolom-niveau nog niet (zie sectie 8) |
| Instellingen | Auth / statisch / geen | Leerling (auth) | N.v.t. per sub-item | N.v.t. |
| Account | Auth-sessie | Leerling | N.v.t. | N.v.t. |

---

## 12. Dependency-overzicht (conceptuele mapping, geen code-import)

| Onderdeel | Instructeur-app tegenhanger | Leerling-app tegenhanger (bestaand) | Hergebruik-conclusie |
|---|---|---|---|
| Profiel lezen | `profielProvider` → `SupabaseService.getProfiel()` | `mijnProfielProvider` → `StudentService.getMijnProfiel()` | Structureel al identiek patroon; leest dezelfde soort tabel (elk zijn eigen profieltabel) — niets te hergebruiken, wel te bevestigen dat het patroon consistent blijft |
| Leerlingbeheer (instructeur-kant) | `leerlingenProvider` / `SupabaseService.getLeerlingen()` / `.updateLeerling()` | — (leerling heeft geen "lijst van leerlingen") | N.v.t. — asymmetrisch per ontwerp |
| Pakkettencatalogus | `SupabaseService` leest `instructor_lesson_packages` | **Ontbreekt** | Leerling-app moet een eigen, read-only query op `instructor_lesson_packages` (via `pakket_id`) toevoegen aan `StudentService` — geen bestaande Instructeur-Dart-code te hergebruiken, wel exact dezelfde tabel/kolommen aanspreken |
| Facturen | `facturenProvider` / `SupabaseService.getFacturen()` | `facturenProvider` / `StudentService.getMijnFacturen()` | Al parallel opgebouwd, zelfde tabel, andere RLS-scope (instructeur ziet alles van zijn leerlingen, leerling ziet alleen eigen facturen) |
| Meldingen | `notificatiesProvider` / `NotificatieService` (tabel `notificaties`) | `notificatiesProvider` / `StudentService` (tabel `leerling_notificaties`) | **Niet** hergebruikbaar 1-op-1 — bewust verschillende tabellen voor verschillende doelgroepen (zie sectie 8) |
| Beschikbaarheid | Instructeur leest via `instructeur_besch_select_leerlingen`-policy (geen apart providerbestand gevonden voor instructeur-kant van deze tabel) | `beschikbaarheid_screen.dart` (volledige CRUD) | Leerling-app is hier de schrijvende kant — geen Instructeur-patroon om te spiegelen, dit is het enige onderdeel waar de rollen omgedraaid zijn |
| Wachtwoord/Auth | Supabase Auth direct | Supabase Auth direct | Identieke, gedeelde laag — geen appspecifieke code nodig aan geen van beide kanten |
| Taal-instelling | `TaalNotifier` + `SharedPreferences` (lokaal, geen tabel) | Nog niet gebouwd | Zelfde patroon aanhouden áls dit ooit gebouwd wordt: lokaal, geen Supabase-kolom |
| Account verwijderen | `SupabaseService.verwijderAccount()`-achtige flow (instructeur-specifiek — verwijdert `instructeur_profielen`-rij + gerelateerde data) | **Ontbreekt volledig** | Niet direct herbruikbaar (andere tabel, andere cascade-regels voor `leerlingen`/`lessen`/`facturen`). Vereist een **nieuwe**, apart te ontwerpen en te beveiligen RPC specifiek voor het verwijderen van een leerling-account — expliciet géén onderdeel van deze architectuurstap |

---

## 13. Afwijkingen — data die nog niet uit de juiste bron komt

Alleen de daadwerkelijke afwijkingen, met prioriteit. "Juiste bron" bestaat in alle gevallen al in
Supabase; het gaat uitsluitend om ontbrekende leescode aan de Leerling-kant, niet om ontbrekende
data of nieuwe tabellen.

| # | Afwijking | Kolom(men) | Tabel | Prioriteit | Actie (niet nu uitvoeren) |
|---|---|---|---|---|---|
| 1 | Toegewezen lespakket (naam, prijs, voorwaarden) niet zichtbaar — alleen het generieke pakket-enum wordt getoond | `pakket_naam`, `pakket_lessen`, `pakket_prijs_cents`, `pakket_losse_les_prijs_cents`, `pakket_lesduur_minuten`, `pakket_praktijkexamen_inbegrepen`, `pakket_tussentijdse_toets_inbegrepen`, `pakket_snapshot_vastgelegd_op` | `leerlingen` | **Hoog** | `LeerlingProfiel`-model + `StudentService` uitbreiden met deze kolommen |
| 2 | Adres niet zichtbaar in Persoonlijke gegevens | `adres` | `leerlingen` | Middel | Model + UI uitbreiden |
| 3 | Rijbewijscategorie niet zichtbaar | `rijbewijs_soort` | `leerlingen` | Middel | Model + UI uitbreiden |
| 4 | Eerstvolgend examen niet samengevat op de kaart (alleen navigatielink naar `/examens`) | `examen_datum` | `leerlingen` | Laag | Optioneel, UX-keuze |
| 5 | Website van de rijschool niet getoond in "Mijn rijschool" | `website` | `instructeur_profielen` | Laag | `getMijnInstructeur()`-select uitbreiden |
| 6 | `lessen_tegoed` vs. client-side `lessen_totaal - lessen_gevolgd` — mogelijk twee bronnen voor hetzelfde begrip, nog niet geverifieerd welke leidend is | `lessen_tegoed` | `leerlingen` | Middel — **eerst verifiëren met de instructeur-kant vóór er iets aan gebouwd wordt** | Uitzoeken, niet zomaar gebruiken |
| 7 | App-versie in "Over de app" is een losse, hardcoded string | — | — | Laag | `package_info_plus` toevoegen |
| 8 | Kolombeveiliging op `leerling_notificaties` nog niet zo strikt als op `leerlingen` (rij-niveau wel correct, kolom-niveau niet expliciet afgedwongen) | — | `leerling_notificaties` | Laag/Middel | Zelfde triggerpatroon als Fase 2, als aparte, goed te keuren stap |

Geen van deze afwijkingen vereist een nieuwe tabel, een nieuwe repository, een nieuwe service, of
gedupliceerde businesslogica — in alle gevallen bestaat de brondata al en ontbreekt uitsluitend leescode
aan de Leerling-kant.

---

## Samenvatting

- Persoonlijke gegevens, Mijn rijschool, Rijopleiding, Lespakket en Facturen: **Instructeur-app is en
  blijft de bron**, Leerling-app is en blijft read-only, en dat is sinds Fase 2 ook op databaseniveau
  afgedwongen voor `leerlingen`.
- Profielfoto en Beschikbaarheid: bewuste, correct geïmplementeerde uitzonderingen waar de leerling zelf
  eigenaar is.
- Meldingen: Instructeur schrijft, leerling leest + markeert gelezen — correct, met één klein
  vervolgpunt (kolombeveiliging) voor een latere stap.
- Instellingen/Account: grotendeels Auth-laag of statische content, geen eigen dataeigenaarschap-vraagstuk.
- Geen enkele afwijking vraagt om een nieuwe tabel, nieuwe repository, nieuwe service of gedupliceerde
  businesslogica — alleen om het uitbreiden van bestaande modellen/services met kolommen die al bestaan.

Wachten op akkoord voordat er één regel code wordt aangepast.
