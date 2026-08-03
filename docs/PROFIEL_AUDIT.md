# Audit — Profiel-tab (Fase 1, Stap 1 + 2)

> Alleen-lezen audit. Geen code gewijzigd. Bronnen: `lib/features/profiel/profiel_screen.dart`,
> `lib/core/services/student_service.dart`, `lib/models/*`, en de live Supabase-schema
> (`information_schema`, `pg_policies`, `pg_constraint`) van project `fbgjksxrehqyphaidgck`,
> opgevraagd via de Supabase Management API. Vergeleken met de schrijf-kant in
> `rijschool-planner-flutter/lib/core/services/supabase_service.dart` (Instructeur-app).

---

## STAP 1 — Audit

### 1. Widgets van de Profiel-tab

Alles in `lib/features/profiel/profiel_screen.dart` (1 bestand, geen sub-repository):

| Widget | Rol |
|---|---|
| `ProfielScreen` | Scaffold + `MainTabHeader`, watcht `mijnProfielProvider` |
| `_ProfielHub` | Statefull hoofdcontainer: avatar-upload state, alle acties (wachtwoord, uitloggen, contact) |
| `_ProfielIdentiteitskaart` | Profielkaart (avatar, naam, statusbadge, pakketchip, infochips) |
| `_StatusBadge` | Kleurcodering op `LeerlingStatus` |
| `_PakketChip` | Toont `PakketType.label` |
| `_DarkInfoChip` | Telefoon-/lessen-chip in de kaart |
| `_ProfielMenuTile` | Herbruikbare rij (icoon + label + subtitle/trailing + optionele chevron) — draagt alle secties |
| `_sectieKaart()` | Wrapper-functie: witte kaart om een lijst tegels |
| `_SectieSkeleton` | Laadstatus per kaart (bv. tijdens instructeur-fetch) |
| `_DangerRow` | Rode actierij (Uitloggen) |
| `_ContactActiesSheet` | Bottom sheet: bellen/WhatsApp instructeur |
| `_ProfielShimmer` | Laadstatus hele scherm |
| `ProfileAvatar`, `_InitialsAvatar`, `_PhotoSourceTile` | Avatar-weergave + upload-picker (galerij/camera) |

### 2. Services gebruikt

Uitsluitend `StudentService` (`lib/core/services/student_service.dart`) — een `static`-methode-klasse die
**rechtstreeks** de Supabase-client aanroept. Er is **geen aparte repository-laag**; `StudentService` vervult
die rol al. Vanuit Profiel aangeroepen:

| Methode | Doel |
|---|---|
| `StudentService.getMijnProfiel()` (via `mijnProfielProvider`) | Eigen leerling-record ophalen |
| `StudentService.getMijnInstructeur(instructeurId)` (via lokale `_instructeurProvider`) | Gekoppelde instructeur ophalen |
| `StudentService.uploadMijnProfielfoto(...)` | Profielfoto uploaden + `avatar_url` bijwerken |
| `StudentService.stuurWachtwoordReset(email)` | Wachtwoord-resetmail versturen (Supabase Auth) |
| `StudentService.uitloggen()` | Supabase Auth sign-out |
| `StudentService.currentUser` | Auth-sessie (voor het e-mailadres bij wachtwoord-reset) |

### 3. Repositories

Geen. `StudentService` **is** de enige data-toegangslaag in deze app (net als `SupabaseService` in de
Instructeur-app). Er is dus niets om te "hergebruiken" op repository-niveau — wel is `StudentService` zelf
al 1-op-1 het juiste hergebruik-punt; geen nieuwe klasse nodig.

### 4. Supabase-queries die de Profiel-tab (indirect) uitvoert

```
select() from leerlingen              .eq('user_id', user.id).maybeSingle()      -- getMijnProfiel
select(kolommenlijst) from instructeur_profielen .eq('id', instructeurId).maybeSingle() -- getMijnInstructeur
update({'avatar_url': ...}) on leerlingen .eq('id', leerlingId).eq('user_id', userId)   -- uploadMijnProfielfoto
storage.from('avatars').uploadBinary(...)                                              -- uploadMijnProfielfoto
auth.resetPasswordForEmail(email)                                                       -- wachtwoord wijzigen
auth.signOut()                                                                          -- uitloggen
```

Navigatie-doelen die vanuit Profiel bereikbaar zijn maar hun eigen queries hebben (niet in dit audit-bestand
zelf): `/voortgang`, `/voortgang/lespakket`, `/examens`, `/notificaties`, `/facturen`, `/help`.

### 5. Tabellen gebruikt

| Tabel | Actie vanuit Profiel |
|---|---|
| `leerlingen` | `SELECT` (eigen rij) + `UPDATE` (alleen `avatar_url` vanuit de Flutter-code) |
| `instructeur_profielen` | `SELECT` (read-only) |
| `storage.avatars` (bucket) | `INSERT`/upload (foto-bestand) |
| `auth.users` (Supabase Auth) | reset-mail, sign-out |

### 6. Kolommen gelezen

**`leerlingen`** (via `LeerlingProfiel.fromJson`, `select()` zonder kolombeperking — hele rij):
`id, instructeur_id, voornaam, achternaam, email, telefoon, avatar_url, avatar_id, geboortedatum, pakket,
status, lessen_totaal, lessen_gevolgd, notities, vaardigheden, user_id, gekoppeld_op, aangemaakt_op,
bijgewerkt_op`.

**`instructeur_profielen`** (expliciete kolomselectie in `getMijnInstructeur`):
`id, rijschool_naam, naam, telefoon, email, adres, postcode, stad, logo_url, whatsapp_nummer`.

### 7. Kolommen geschreven

Alleen `leerlingen.avatar_url`, via `uploadMijnProfielfoto`. Dat is het **enige** schrijfpad dat de Flutter-UI
aanbiedt binnen Profiel.

> ⚠️ Zie Stap 2 hieronder — op databaseniveau is dit niet afgedwongen. Dat is de belangrijkste bevinding van
> deze audit.

### 8. Hardcoded waardes gevonden

| Plek | Waarde | Risico |
|---|---|---|
| `_toonOverDeApp()` | `'Leerling App · versie 1.0.7'` | Moet meelopen met de build (bv. via `package_info_plus`), nu een losse string die kan gaan afwijken van `pubspec.yaml` |
| `_openUrl('https://klantio.nl/privacy')` | Privacy-URL | Zelfde patroon als `help_screen.dart` (consistent in de app), maar niet uit een instelling/tabel — is een statische bedrijfslink, geen leerling-/instructeurdata, dus geen ownership-conflict; wel technisch "hardcoded" |
| `naam = p?.volledigeNaam ?? 'Mijn profiel'` | Fallback-label bij ontbrekend profiel | Dit is een lege-staat-label, geen nepdata — verschijnt alleen als er nog geen profiel is |
| `instructeur = 'Instructeur'` fallback in `_ProfielMenuTile` (Mijn rijschool) | Fallback-label | Zelfde soort lege-staat-tekst, geen dummy-data |

### 9. Dummy data aanwezig

**Geen.** Er zit geen gemockte/fake dataset in `profiel_screen.dart`. Alles loopt door
`mijnProfielProvider` / `_instructeurProvider`, die beide echte Supabase-calls doen.

### 10. Onderdelen al volledig gesynchroniseerd

- **Persoonlijke gegevens** (naam, telefoon, e-mail, geboortedatum): read-only, rechtstreeks uit `leerlingen`
  — dezelfde tabel die de Instructeur-app beheert. Geen duplicatie.
- **Mijn rijschool**: read-only uit `instructeur_profielen`, RLS scoped op de eigen gekoppelde instructeur.
  Geen duplicatie.
- **Beschikbaarheid** (bereikbaar via Profiel maar los scherm): volledige CRUD op `leerling_beschikbaarheid`,
  correct RLS-gescoped op eigen leerling-rij, en **dezelfde tabel** die de Instructeur-app leest — dus
  direct zichtbaar daar, geen sync-vertraging.
- **Meldingen**: zelfde tabel (`leerling_notificaties`) en kolommen als de rest van het notificatiesysteem.
  Geen los meldingensysteem gebouwd.
- **Wachtwoord wijzigen / Uitloggen**: beide via Supabase Auth zelf — de enige juiste bron voor
  credentials, gedeeld door beide apps van nature (geen aparte "wachtwoord"-tabel).

### 11. Onderdelen die nog ontbreken of risico's bevatten

1. **KRITIEK — RLS/GRANT-gat op `leerlingen`.** Zie Stap 2, "Profielfoto"-rij. De Flutter-UI schrijft alleen
   `avatar_url`, maar de database staat élke geauthenticeerde gebruiker toe om élke kolom van hun eigen
   `leerlingen`-rij te updaten — inclusief `instructeur_id`, `school_id`, `pakket`, `lessen_gevolgd`,
   `lessen_totaal`, `status`. Dit is geen Flutter-bug maar een databasegat; moet met een aparte, expliciet
   goedgekeurde stap dichtgezet worden (kolom-specifieke `GRANT`, of een `SECURITY DEFINER`-RPC voor alleen
   de avatar).
2. **Stale TODO-comment in `student_service.dart`** ("avatar_url moet nog toegevoegd worden aan
   `leerlingen`") — de kolom **bestaat al** in productie. De comment is verouderd en zou verwijderd moeten
   worden zodra dat expliciet gevraagd wordt (nu geen code aangepast, puur audit).
3. **`leerlingen.adres` en `leerlingen.rijbewijs_soort` bestaan al** maar worden nergens gelezen door de
   Leerling-app (`LeerlingProfiel`-model mist ze) — dus "Adres" en "Rijbewijscategorie" uit jouw sjabloon
   ontbreken nog puur omdat het model ze niet uitleest, niet omdat de data niet bestaat. Geen nieuwe
   kolom nodig.
4. **`leerlingen.examen_datum` bestaat al** en wordt nergens gebruikt — zou een "eerstvolgend examen"-regel
   op de Rijopleiding-kaart kunnen voeden zonder extra query.
5. **Examenstatus/examenadvies in Profiel is nu alleen een navigatielink** (naar `/examens`), geen
   samengevatte data op de kaart zelf.
6. **Account verwijderen**: geen backend-RPC/policy hiervoor beschikbaar voor leerlingen (de Instructeur-app
   heeft wel zo'n flow voor instructeurs). Kan pas gebouwd worden na een expliciete backend-beslissing —
   nu bewust niet in de UI opgenomen.
7. **App-versie in "Over de app"** is een losse string, niet gekoppeld aan de build (zie Stap 8 hierboven).
8. **`lessen_tegoed`-kolom** bestaat op `leerlingen` naast `lessen_totaal`/`lessen_gevolgd`, maar wordt door
   geen van beide apps se gelezen in de code die ik heb gecontroleerd — mogelijk een tweede, losstaande
   plek waar "resterende lessen" wordt bijgehouden. Waard om te verifiëren voordat Rijopleiding méér gaat
   tonen, zodat er niet per ongeluk twee verschillende "resterend"-getallen ontstaan.

---

## STAP 2 — Data-eigenaarschap

### Persoonlijke gegevens

| Veld | Bron | Tabel | Kolom | Read-only/bewerkbaar (UI) | Wie mag wijzigen | Welke app schrijft |
|---|---|---|---|---|---|---|
| Naam | Instructeur-app | `leerlingen` | `voornaam`, `achternaam` | Read-only | Instructeur | Instructeur-app (leerlingenbeheer) |
| Telefoon | Instructeur-app | `leerlingen` | `telefoon` | Read-only | Instructeur | Instructeur-app |
| E-mail | Instructeur-app | `leerlingen` | `email` | Read-only | Instructeur | Instructeur-app |
| Adres | Instructeur-app | `leerlingen` | `adres` | **Ontbreekt in UI** (kolom bestaat wel) | Instructeur | Instructeur-app |
| Geboortedatum | Instructeur-app | `leerlingen` | `geboortedatum` | Read-only | Instructeur | Instructeur-app |
| Profielfoto | Leerling (bewuste uitzondering) | `leerlingen` + `storage.avatars` | `avatar_url` | Bewerkbaar | Leerling zelf | Leerling-app |

> ⚠️ Bij Profielfoto: dit is het enige veld dat de Flutter-app bewust schrijft. Op databaseniveau is dat
> **niet afgedwongen** — zie kritieke bevinding hierboven. Functioneel werkt het vandaag (kolom bestaat,
> RLS laat de eigen rij toe), maar de "alleen avatar_url"-belofte wordt alleen door de app-code bewaakt,
> niet door de database.

### Mijn rijschool

| Veld | Bron | Tabel | Kolom |
|---|---|---|---|
| Rijschoolnaam | Instructeur-app | `instructeur_profielen` | `rijschool_naam` |
| Adres | Instructeur-app | `instructeur_profielen` | `adres`, `postcode`, `stad` |
| Telefoon | Instructeur-app | `instructeur_profielen` | `telefoon` |
| E-mail | Instructeur-app | `instructeur_profielen` | `email` |
| Website | Instructeur-app | `instructeur_profielen` | `website` (bestaat, nog niet getoond in Profiel) |
| Instructeur (naam) | Instructeur-app | `instructeur_profielen` | `naam` |
| Route openen | — | — | client-side berekend (Google Maps-link van het adres, geen eigen kolom) |

100% read-only voor de leerling, bevestigd via RLS (`leerling_instructeur_profiel_lezen`: alleen de eigen
gekoppelde instructeur is zichtbaar; geen `UPDATE`-policy voor de rol die leerlingen gebruiken).

### Rijopleiding

| Veld | Bron | Tabel | Kolom |
|---|---|---|---|
| Lespakket | Instructeur-app | `leerlingen` | `pakket` (+ detailkolommen `pakket_naam`, `pakket_lessen`, `pakket_prijs_cents`, ...) |
| Aantal lessen | Instructeur-app | `leerlingen` | `lessen_totaal` |
| Lessen gevolgd | Instructeur-app (via lesregistratie) | `leerlingen` | `lessen_gevolgd` |
| Resterende lessen | — | — | client-side `lessen_totaal - lessen_gevolgd`; ⚠️ er bestaat óók een kolom `lessen_tegoed` die niet gebruikt wordt — te verifiëren of dit hetzelfde getal hoort te zijn |
| Examenstatus / -advies | Instructeur-app | `examens` (+ view `student_exam_readiness`) | volledige rij, read-only voor leerling |

Alles komt uit dezelfde tabellen als de Instructeur-app gebruikt om lessen/examens te registreren — geen
duplicaten, geen eigen berekeningen die van de instructeur-cijfers afwijken (behalve het bovenstaande
`lessen_tegoed`-punt, dat nog niet door de Leerling-app gebruikt wordt).

### Beschikbaarheid

Bevestigd: **volledig leerling-eigendom**, zoals gevraagd.

| Actie | RLS-policy | Scope |
|---|---|---|
| Lezen eigen | `leerling_besch_select_eigen` | `leerling_id IN (leerlingen waar user_id = auth.uid())` |
| Toevoegen | `leerling_besch_insert_eigen` | idem |
| Wijzigen | `leerling_besch_update_eigen` | idem |
| Verwijderen | `leerling_besch_delete_eigen` | idem |
| Instructeur leest mee | `instructeur_besch_select_leerlingen` | `instructeur_id = auth.uid()` |

Rechtstreeks zichtbaar in de Instructeur-app zodra opgeslagen (zelfde tabel, geen sync-stap nodig).

### Facturen

Read-only, tabel `facturen`, RLS via `student_facturen_select` / `leerling_eigen_facturen_lezen` (twee
functioneel identieke policies — geen bug, wel een kleine opschoonkans voor een latere fase). Geen eigen
berekeningen anders dan weergave-aggregaten over reeds bestaande rijen (bv. het overzichtskaartje in
`facturen_screen.dart` — dat is buiten Fase 1 en niet aangeraakt).

### Meldingen

Tabel `leerling_notificaties`. Instructeur schrijft (`instructeur_notificaties_all`,
`instructeur_id = auth.uid()`); leerling leest en markeert alleen `gelezen` (`student_notificaties_select` /
`student_notificaties_update`). Zelfde bron als de rest van het notificatiesysteem — geen apart systeem.

### Instellingen

| Item | Bron | Status |
|---|---|---|
| Wachtwoord wijzigen | Supabase Auth (`auth.resetPasswordForEmail`) | Werkend, correcte gedeelde bron |
| Privacy | Statische externe URL | Werkend, geen database-ownership van toepassing |
| Voorwaarden | Niet in Profiel — wel al aanwezig op `/help` | Werkend via Help-scherm |
| Help / Support | `/help`-scherm (contact + FAQ + juridisch) | Werkend |
| App-versie | Hardcoded string | Werkt, maar niet build-gekoppeld (zie bevinding 7) |
| Account verwijderen | **Geen backend beschikbaar** | Ontbrekend — bewust niet in UI |
| Uitloggen | Supabase Auth (`signOut`) | Werkend |

---

## Samenvatting — belangrijkste actiepunten voor latere, apart goed te keuren stappen

1. **Databasegat dichten**: kolom-specifieke schrijfrechten op `leerlingen` voor de `authenticated`-rol
   (alleen `avatar_url`/`avatar_id`), zodat de "leerling mag alleen zijn foto wijzigen"-belofte ook op
   databaseniveau geldt.
2. **Stale TODO-comment verwijderen** in `student_service.dart` (avatar-kolom bestaat al).
3. **`LeerlingProfiel`-model uitbreiden** met `adres` en `rijbewijs_soort` (kolommen bestaan al) zodra de
   UI die wil tonen.
4. **`lessen_tegoed` vs. `lessen_totaal - lessen_gevolgd`** verifiëren voordat Rijopleiding meer gaat tonen.
5. **App-versie** later via `package_info_plus` in plaats van een losse string.
6. **Account verwijderen**: apart, expliciet te plannen backend-stuk (RPC + policy), geen UI vooruitlopen.

Geen van deze punten is in deze stap gewijzigd. Wachten op jouw akkoord per punt, zoals afgesproken
("1. Audit → 2. Databron bepalen → 3. Repository controleren → 4. UI koppelen → 5. Synchronisatie testen").
