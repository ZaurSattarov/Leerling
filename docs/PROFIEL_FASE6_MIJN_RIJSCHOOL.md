# Fase 6 — Profiel: Mijn rijschool (oplevering)

Status: geïmplementeerd, geverifieerd, wacht op akkoord. Scope: uitsluitend
het onderdeel "Mijn rijschool" binnen de Profiel-tab.

## 1. Bron van waarheid per rijschoolveld

| UI-veld | Tabel | Kolom | Eigenaar | Read-only |
|---|---|---|---|---|
| Rijschoolnaam | `instructeur_profielen` | `rijschool_naam` | Instructeur | Ja |
| Logo | `instructeur_profielen` | `logo_url` | Instructeur | Ja |
| Adres | `instructeur_profielen` | `adres`, `postcode`, `stad` | Instructeur | Ja |
| Website | `instructeur_profielen` | `website` | Instructeur | Ja |
| KvK-nummer | `instructeur_profielen` | `kvk_nummer` | Instructeur | Ja |

Leslocatie/vestiging: **bestaat niet** als kolom op `instructeur_profielen`
(live schema gecontroleerd) — dus terecht niet getoond, geen verzonnen veld.
Postcode/stad worden niet los getoond maar zijn onderdeel van
`Instructeur.volledigAdres` (bestaande, ongewijzigde getter die adres +
postcode + stad combineert).

## 2. Bron van waarheid per instructeurveld

| UI-veld | Tabel | Kolom | Eigenaar | Read-only |
|---|---|---|---|---|
| Instructeurnaam | `instructeur_profielen` | `naam` | Instructeur | Ja |
| Telefoon | `instructeur_profielen` | `telefoon` | Instructeur | Ja |
| E-mailadres | `instructeur_profielen` | `email` | Instructeur | Ja |

**`leerlingen.school_id` → `schools` is onderzocht en bewust niet gebruikt.**
Live gecontroleerd: `school_id` is `NULL` voor beide bestaande leerling-rijen;
de `schools`-tabel bevat sowieso geen profielvelden (alleen `id`, `name`,
`owner_id`, timestamps — puur een organisatie-/facturatiegroepering voor
meerdere instructeurs, gebruikt door `school_subscriptions`/`school_addons`);
en er bestaat geen enkele RLS-policy die een leerling toegang geeft tot
`schools` (alleen `owner_id = auth.uid()` voor UPDATE en `get_my_school_id()`
voor SELECT — beide instructeur-scope, geen leerling-pad). `leerlingen.
instructeur_id → instructeur_profielen` blijft dus de enige, juiste en
volledige bron — exact zoals al vastgelegd in `docs/PROFIEL_ARCHITECTUUR.md`
sectie 3.

De leerling mag niets van dit alles wijzigen — geen enkele UPDATE-policy op
`instructeur_profielen` staat de leerling toe, geverifieerd (zie §6).

## 3. Aangepaste modellen/query/provider

- **`lib/models/instructeur.dart`** — 2 velden toegevoegd: `website`,
  `kvkNummer` (+ `fromJson`-mapping). Alle overige velden (incl. `logoUrl`,
  `whatsappNummer`) bestonden al maar werden nog niet getoond.
- **`lib/core/services/student_service.dart`** — `getMijnInstructeur()`'s
  kolomselectie uitgebreid met `website, kvk_nummer`. Geen nieuwe methode,
  geen nieuwe service.
- **`lib/features/profiel/rijschool_provider.dart`** (nieuw bestand) — de
  bestaande `_instructeurProvider` (voorheen privé in `profiel_screen.dart`)
  is hierheen verplaatst en publiek gemaakt als `mijnInstructeurProvider`.
  **Geen nieuwe provider** — dezelfde `FutureProvider.autoDispose`, dezelfde
  query, nu herbruikbaar door zowel de bestaande "Contact met
  instructeur"-tegel (Communicatie-sectie, ongewijzigd gedrag) als het nieuwe
  detailscherm.
- **`lib/features/profiel/mijn_rijschool_screen.dart`** (nieuw) — het
  detailscherm zelf, uitsluitend UI + validatie, geen eigen databronlogica.

## 4. Afhandeling ontbrekende relaties

Eén controlepunt dekt beide gevraagde gevallen: `mijnInstructeurProvider`
retourneert `null` zodra `leerlingen.instructeur_id` niet naar een
leesbare `instructeur_profielen`-rij verwijst (ontbrekende/ongeldige
instructeur-relatie) — de nu-bevestigde niet-toepasselijkheid van
`school_id` (§2) betekent dat er in de praktijk geen tweede, apart te
bewaken relatie is. Bij `null` toont het scherm een `EmptyState` ("Nog geen
rijschool gekoppeld"), geen crash. Bij een providerfout (bv. netwerk) toont
het scherm een aparte foutstatus. Binnen de body zijn ook individuele
optionele velden (website, KvK) defensief met `?.trim().isNotEmpty` in
plaats van directe null-dereferentie.

## 5. Veilige contactacties

Alle acties zijn opt-in — een rij verschijnt alleen als de actie echt kan
worden uitgevoerd:

| Actie | Validatie |
|---|---|
| Bellen | `telefoon` genormaliseerd naar cijfers + optioneel leidend `+`; actie verborgen als er na normaliseren niets overblijft |
| E-mailen | Regex-validatie (`^[^\s@]+@[^\s@]+\.[^\s@]+$`) vóór `mailto:` |
| Website openen | Alleen als de waarde letterlijk met `https://` begint én een geldige `Uri` met niet-leeg `host` oplevert — `http://` of een ontbrekend schema wordt genegeerd (niet getoond als actie, wel als platte tekst in de Rijschool-kaart als de waarde bestaat) |
| Route openen | Bestaande `Instructeur.volledigAdres`-getter + `Uri.encodeComponent(...)` naar Google Maps — exact het patroon dat al elders in de app gebruikt werd |

Gebruikt overal `url_launcher` met `LaunchMode.externalApplication` — zelfde
package/aanpak als de rest van de app (`help_screen.dart`, de bestaande
`_openUrl`/`_ContactActiesSheet` in `profiel_screen.dart`). Geen nieuwe
url-service, geen dynamische HTML, geen andere schema's dan `https:`,
`tel:`, `mailto:`.

## 6. RLS-controle (live database, rollback-only)

Eerste testrun gaf een fout-positief: de eerste beschikbare leerling-rij in
deze database heeft toevallig `user_id = instructeur_id` (een test-/
devaccount waarbij de instructeur zichzelf ooit als "eigen leerling" heeft
gekoppeld) — daardoor leek een "leerling"-sessie de instructeur_profielen-rij
te kunnen updaten, wat in werkelijkheid gewoon de instructeur was die zijn
eigen rij updatete. Herkend, opnieuw getest met de andere, echt losstaande
leerling (`user_id ≠ instructeur_id`) — dat gaf het juiste, geruststellende
resultaat:

- Leerling kan de eigen gekoppelde instructeur lezen — ✅
- Leerling kan geen niet-gekoppelde instructeur enumereren — ✅ (0 rijen)
- Leerling ziet in totaal precies 1 instructeur-rij (geen enumeratie via een
  kale `SELECT *`) — ✅
- Leerling kan `instructeur_profielen` niet wijzigen (UPDATE raakt 0 rijen)
  — ✅
- Sanity-check: leerling ziet ook maar 1 eigen rij in `leerlingen` zelf — ✅

Geen databasewijziging nodig — de bestaande RLS-policies
(`leerling_instructeur_profiel_lezen` / `student_instructeur_select`, en de
afwezigheid van een leerling-UPDATE-policy) waren al correct.

## 7. Aangepaste/nieuwe bestanden

- `lib/models/instructeur.dart` — `website`, `kvkNummer` toegevoegd
- `lib/core/services/student_service.dart` — kolomselectie uitgebreid
- `lib/features/profiel/rijschool_provider.dart` — **nieuw**, provider
  gepromoveerd van privé naar gedeeld
- `lib/features/profiel/mijn_rijschool_screen.dart` — **nieuw**, het
  detailscherm
- `lib/features/profiel/profiel_screen.dart` — "MIJN RIJSCHOOL"-sectie
  vervangen door één tegel naar `/profiel/mijn-rijschool` (zelfde patroon
  als Persoonlijke gegevens/Lespakket); nu-ongebruikte `_SectieSkeleton`
  opgeruimd
- `lib/app.dart` — route `/profiel/mijn-rijschool` geregistreerd

Geen nieuwe tabel, geen nieuwe service, geen dubbele provider.

## 8. Test- en analyseresultaten

- `flutter analyze --no-fatal-infos --no-fatal-warnings`: **0 nieuwe
  issues** (de 2 resterende warnings bestonden al vóór Fase 6, buiten scope).
- `flutter test`: **44/44 geslaagd**, geen regressie.
- Live data-verificatie tegen de echte gekoppelde rijschool ("Rijschool
  Klantio", Amsterdam): rijschoolnaam, adres, telefoon (`+31 6 28 45 91 03`),
  website (`https://klantio.nl`) en KvK-nummer (`82943716`) zijn stuk voor
  stuk gecontroleerd tegen de live database en komen overeen met wat het
  scherm zal tonen — inclusief dat `logo_url` daar `null` is (dus initialen-
  fallback 'R' te zien zal zijn) en dat het `naam`-veld van de instructeur in
  deze specifieke rij toevallig een e-mailadres bevat in plaats van een
  persoonsnaam — dat is de daadwerkelijk opgeslagen waarde en wordt terecht
  ongewijzigd getoond (geen opschoning van bronwaarden, dat zou eigen
  interpretatie toevoegen aan instructeur-data).
- Synchronisatie (test 13 uit de lijst) is architecturaal geverifieerd, niet
  los end-to-end getest: `ref.invalidate(mijnInstructeurProvider)` op
  pull-to-refresh is exact hetzelfde, al-bewezen `FutureProvider.
  autoDispose`-patroon als bij Lespakket en Persoonlijke gegevens — geen
  nieuw mechanisme, dus geen aparte cross-app-test nodig.
- Regressie Lespakket/Persoonlijke gegevens: bevestigd via de volledige
  testsuite + `git status` (deze fase heeft `lespakket_detail_screen.dart`,
  `persoonlijke_gegevens_screen.dart` en `profielfoto_editor.dart` niet
  aangeraakt).

## 9. Bevestiging scope

Alleen "Mijn rijschool" is aangepast. Persoonlijke gegevens, profielfoto,
Lespakket, Beschikbaarheid, Facturen, Meldingen, Instellingen, Home,
Planning, Voortgang en de navbar zijn ongewijzigd. De enige aanraking van
`profiel_screen.dart` buiten de Mijn-rijschool-tegel was het opruimen van de
nu-dode `_SectieSkeleton`-klasse (rechtstreeks gevolg van het vervangen van
de inline kaart door een tegel, geen zelfstandige wijziging).

## 10. Beslispunten

Geen die eerst goedkeuring nodig hebben — er was geen databasewijziging
nodig (§6) en er zijn geen nieuwe afwegingen zoals bij eerdere fases. Eén
kleine, lage-impact ontwerpkeuze die ik zelf heb gemaakt en hier expliciet
benoem: WhatsApp is bewust **niet** toegevoegd aan de nieuwe CONTACT-sectie,
ook al bestaat `whatsapp_nummer` en wordt het al gebruikt in de bestaande
"Contact met instructeur"-actieblad (Communicatie-sectie, ongewijzigd). Jouw
voorbeeld noemde expliciet alleen "Bellen, mailen, route" voor deze sectie;
WhatsApp blijft zo exclusief bij de al bestaande, aparte contactflow — geen
duplicaat UI voor dezelfde actie.

---

**Wacht op akkoord voordat we verdergaan met het volgende profielonderdeel.**
