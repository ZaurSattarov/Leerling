# Fase 4 — Architectuurcontrole (vóór akkoord)

> Uitsluitend onderzoek en analyse. **Geen Flutter-code, geen migraties, geen databasewijzigingen**
> uitgevoerd in deze stap — alle SQL hieronder is `BEGIN; ... ROLLBACK;`. Bronnen: de daadwerkelijke
> migratie die de snapshotfunctionaliteit invoerde (`20260727000000_instructor_lesson_packages_
> saldo_eenheid_en_leerling_snapshot.sql`, Instructeur-app-repo), het bijbehorende verificatiescript,
> `pg_constraint`/`pg_indexes`/`pg_trigger` van het live schema, en twee nieuwe rollback-only testruns.

---

## 1. Single Source of Truth per veld

| Veld | Aangemaakt | Wijzigbaar door | Eigenaar | Bron-tabel (SSOT) | Duplicatie? |
|---|---|---|---|---|---|
| `pakket_id` | Instructeur, bij toewijzing (leerling-formulier) | Instructeur (eigen leerling); leerling **niet** (Fase 2-trigger) | Instructeur | `leerlingen.pakket_id` (FK → `instructor_lesson_packages`) | Nee |
| `pakket` (enum basis/standaard/intensief/los_rijles) | Instructeur | Instructeur | Instructeur | `leerlingen.pakket` | Nee — apart, ouder concept dan `pakket_id`; beide bestaan naast elkaar (zie risico hieronder) |
| `pakket_naam`, `pakket_lessen` | Instructeur, via `berekenPakketToewijzing()` (snapshot) | Alleen opnieuw geschreven bij een bewuste nieuwe toewijzing | Instructeur | `leerlingen.*` (snapshot) | Nee, maar **wel** deels overlappend met de catalogus-kolommen `naam`/`aantal_lessen` op `instructor_lesson_packages` — dat is de bedoelde, gedocumenteerde snapshot-duplicatie (zie §2) |
| `pakket_prijs_cents`, `pakket_losse_les_prijs_cents`, `pakket_lesduur_minuten`, `pakket_praktijkexamen_inbegrepen`, `pakket_tussentijdse_toets_inbegrepen` | Instructeur, via `berekenPakketToewijzing()` (snapshot) | Idem | Instructeur | `leerlingen.*` (snapshot); catalogus-tegenhanger op `instructor_lesson_packages.pakketprijs/losse_lesprijs/lesduur_minuten/praktijkexamen_inbegrepen/tussentijdse_toets_inbegrepen` | Bewuste snapshot-duplicatie, zie §2 |
| `pakket_snapshot_vastgelegd_op` | Instructeur, via `berekenPakketToewijzing()` | Idem (nooit door client direct gezet — altijd `nu.toUtc()` in de toewijzingscode) | Instructeur/backend | `leerlingen.pakket_snapshot_vastgelegd_op` | Nee |
| `saldo_eenheid` (leerling-snapshot) | Instructeur, bij toewijzing | Idem | Instructeur | `leerlingen.saldo_eenheid` | Bewuste snapshot van `instructor_lesson_packages.saldo_eenheid` |
| `lessen_totaal` (= `pakket_lessen + losse_lessen`) | Instructeur | Instructeur | Instructeur | `leerlingen.lessen_totaal` | Nee |
| `lessen_gevolgd` | **Backend-trigger** (`fn_lesson_balance_sync`) bij elke lesstatuswijziging | Uitsluitend de trigger (`SECURITY DEFINER`) | Backend | `leerlingen.lessen_gevolgd` | Nee — enige bron |
| `pakket_minuten_totaal` (leerling-snapshot) | Instructeur, bij toewijzing (minutenpakket) | Instructeur | Instructeur | `leerlingen.pakket_minuten_totaal`; catalogus-tegenhanger `instructor_lesson_packages.pakket_minuten_totaal` | Bewuste snapshot-duplicatie |
| `pakket_minuten_verbruikt` | **Backend-trigger** | Uitsluitend de trigger | Backend | `leerlingen.pakket_minuten_verbruikt` | Nee — enige bron |
| `lessen_tegoed` | Onbekend/legacy | Onbekend | **Niemand actief** | `leerlingen.lessen_tegoed` | **Dode kolom** — wordt door geen enkele trigger, RPC of Instructeur-app-code gelezen of geschreven (opnieuw bevestigd, zie §2) |
| `rijbewijs_soort`, `transmissie`, `startdatum` | Instructeur | Instructeur | Instructeur | `leerlingen.*` (géén snapshot — altijd het huidige, live leerling-veld) | Nee |
| Catalogus zelf (`naam`, `categorie`, `transmissie`, `aantal_lessen`, `pakketprijs`, ...) | Instructeur, pakkettenbeheer | Instructeur | Instructeur | `instructor_lesson_packages.*` | Nee — dit IS de bron waaruit een snapshot ooit is gekopieerd |

**Belangrijkste bevinding:** de snapshot-duplicatie (leerlingen-kolommen die een kopie zijn van
catalogus-kolommen) is **geen ongewenste duplicatie** maar een **bewust ontwerp**, letterlijk zo
gedocumenteerd in de migratie zelf: "zodat een latere wijziging aan de pakkettemplate een reeds
toegewezen leerling nooit meer commercieel of inhoudelijk raakt." Dit is de industrie-standaard
"order snapshot"-pattern (vergelijkbaar met hoe een webshop de prijs op een bestelregel bevriest, los
van latere prijswijzigingen in de catalogus). Geen actie nodig hierop.

**Wél een reëel aandachtspunt:** `leerlingen.pakket` (het oude enum-veld: basis/standaard/intensief/
los_rijles) en `leerlingen.pakket_id` (verwijzing naar de nieuwere catalogus-tabel) bestaan **naast
elkaar**, ingevuld door dezelfde instructeur-actie maar conceptueel twee generaties van hetzelfde idee.
Dat is geen bug — het is nodig voor achterwaartse compatibiliteit met leerlingen die nooit een
catalogus-koppeling hebben gekregen — maar wel iets om bewust te houden: elke nieuwe leescode
(zoals mijn `LespakketDetail.resolve()`) moet `pakket_id` als leidend behandelen en `pakket` alleen als
allerlaatste fallback, nooit andersom.

---

## 2. Snapshot-strategie

**Sinds wanneer:** migratie `20260727000000` — geverifieerd door het bestand zelf te lezen, niet
aangenomen. Dat is exact één week vóór vandaag (2026-08-03).

**Waarom 33 van de 36 leerlingen geen snapshot hebben:** de migratie kiest **expliciet en met opzet**
voor een additieve strategie zonder backfill. Letterlijk citaat uit de migratie:

> "COMPATIBILITEITSSTRATEGIE (additief, GEEN backfill): [...] Er wordt GEEN bulk-UPDATE uitgevoerd op
> bestaande rijen: bestaande leerlingen houden lege (NULL) snapshotvelden."

Dit is dus geen technische schuld of oversight — het was een bewuste keuze van het opdrachtgevende team
op het moment van bouwen. Maar de consequentie (die kant is niet uitgewerkt in hun migratie-commentaar)
is precies wat jij nu terecht signaleert: zonder een actieve trigger is er geen enkel mechanisme dat
een legacy-leerling ooit automatisch een snapshot geeft, tenzij een instructeur toevallig opnieuw door
het pakket-toewijzingsformulier loopt voor die specifieke leerling.

**Wanneer wordt een snapshot precies aangemaakt** (uit `berekenPakketToewijzing()`, letterlijk de
brontekst, niet geïnterpreteerd):
1. Nieuwe leerling, pakket gekozen → **altijd** nieuwe snapshot.
2. Bestaande leerling, instructeur kiest bewust een ánder pakket-ID → **altijd** nieuwe snapshot.
3. Bestaande leerling, zelfde pakket-ID herkozen, **nog geen** volledige snapshot (legacy) → **alsnog**
   een snapshot vastgelegd (dit is het enige "organische" migratiepad dat vandaag bestaat).
4. Bestaande leerling, zelfde pakket-ID herkozen, **al** een snapshot → **niets** verandert (correct,
   voorkomt precies het probleem dat jij niet wilt: stilzwijgend heronderhandelen).
5. Geen pakketinteractie in het formulier → niets verandert.

**Krijgen nieuwe leerlingen automatisch een snapshot?** Ja — scenario 1 hierboven is onvoorwaardelijk.
Vanaf nu is elke nieuw aangemaakte, aan een pakket gekoppelde leerling per direct gesnapshot. Het
probleem beperkt zich dus tot de 33 al-bestaande leerlingen; het groeit niet vanzelf verder aan.

**Is backfill noodzakelijk?** Mijn advies: **ja, op termijn wél**, om precies de reden die je zelf
noemt — je wilt niet jarenlang twee paden (snapshot + live-catalogusfallback) naast elkaar hoeven
onderhouden en testen. Maar dit is een **instructeur-app-aangelegenheid**, geen Leerling-app-taak: de
snapshot-kolommen worden uitsluitend door de kant van de instructeur geschreven (en zijn sinds Fase 2
voor de leerling zelf geblokkeerd). Een eventuele backfill-migratie hoort dus in de Instructeur-app-repo
thuis, met een bewuste keuze: de HUIDIGE catalogusprijs als eenmalige "aangenomen historische snapshot"
vastleggen voor de 33 leerlingen zonder snapshot (met alle bijbehorende voor- en nadelen — zie
risico's), niet iets wat ik nu voor je zou moeten verzinnen zonder productbeslissing.

**Moeten bestaande leerlingen automatisch gemigreerd worden?** Zie hierboven — dat is een aparte,
bewuste beslissing die niet in deze (Leerling-app-)fase thuishoort, maar wel een reëel risico is zolang
hij niet genomen wordt (zie §4, "pakket wordt aangepast").

---

## 3. RLS-review (herhaald, met extra tests)

Beleid, ongewijzigd sinds vorige stap:

```sql
CREATE POLICY leerling_eigen_toegewezen_pakket_lezen
  ON public.instructor_lesson_packages
  FOR SELECT
  USING (
    id IN (
      SELECT pakket_id FROM public.leerlingen
      WHERE user_id = auth.uid() AND pakket_id IS NOT NULL
    )
  );
```

Nieuwe, rollback-only testrun (niets blijvend gewijzigd, onafhankelijk na afloop geverifieerd):
testsubject is een leerling gekoppeld aan instructeur `76fadc69` (die zelf **6** pakketten in de
catalogus heeft — bewust gekozen om enumeratie hard te kunnen testen, niet slechts 1 pakket).

| # | Test | Resultaat | Bewijs |
|---|---|---|---|
| 1 | Leerling leest **alleen** het eigen pakket | **GESLAAGD** | 1 rij bij directe id-lookup |
| 2 | Geen enumeratie: 5 ándere pakketten van **dezelfde** instructeur, stuk voor stuk op exact ID opgevraagd | **GEBLOKKEERD** | 0 van de 5 zichtbaar |
| 3 | Volledige tabel-scan (`SELECT * FROM instructor_lesson_packages`, geen filter) | **GESLAAGD** | precies **1** rij zichtbaar — bewijst dat er geen enkele bredere toegang bestaat, ongeacht hoe de query is opgebouwd |
| 4 | Pakket van een **andere rijschool** (andere `instructeur_id`) | **GEBLOKKEERD** | 0 rijen |
| 5 | UPDATE-poging op het eigen (wél leesbare) pakket | **GEBLOKKEERD** | 0 rijen gewijzigd — er bestaat geen leerling-schrijfpolicy, alleen SELECT |

Dit is sterker bewijs dan de vorige testronde: test 3 (volledige tabel-scan geeft precies 1 rij, niet
"0 of een fout") sluit uit dat er ergens een impliciete bredere toegang (bijvoorbeeld via een `anon`-rol
default of een vergeten `GRANT`) meespeelt. Test 2 bewijst specifiek dat het **niet uitmaakt dat de
pakketten van dezelfde instructeur komen** — de policy filtert op de koppeling van de leerling zelf, niet
op instructeur-nabijheid.

---

## 4. Architectuurcontrole — schaal en race conditions

**500 leerlingen bij één instructeur.** De policy-subquery
(`SELECT pakket_id FROM leerlingen WHERE user_id = auth.uid()`) gebruikt `idx_leerlingen_user_id`
(index op `user_id`, geverifieerd in `pg_indexes`) — dit is een unieke index-lookup naar **één** rij (de
leerling zelf), volledig onafhankelijk van hoeveel leerlingen die instructeur in totaal heeft. Het aantal
leerlingen van de instructeur speelt geen rol in de queryplan-kosten. De buitenste `id IN (...)` gebruikt
de primary-key-index van `instructor_lesson_packages`. Geen full table scans, geen N+1-risico. **Schaalt
zonder aanpassing.**

**Meerdere pakketten worden verwijderd.** FK `leerlingen_pakket_id_fkey` heeft `ON DELETE SET NULL`
(geverifieerd in `pg_constraint`, niet aangenomen). Verwijdert een instructeur een cataloguspakket, dan
wordt `pakket_id` voor alle daaraan gekoppelde leerlingen automatisch `NULL` — een leerling **met**
snapshot merkt hier niets van (de snapshotkolommen worden niet aangeraakt door deze FK-actie, blijven
voor altijd intact). Een leerling **zonder** snapshot verliest daarmee zijn enige koppeling naar de
catalogus en valt terug op de "Geen pakket ingesteld"-status in mijn implementatie — feitelijk correct
(er is dan geen enkele bron meer), maar het onderscheid met "had ooit een pakket, nu verwijderd" gaat
verloren in de huidige tekst. Kleine UX-verfijning voor een latere stap, geen dataintegriteitsrisico.

**Een pakket wordt aangepast (prijs/naam/etc.).** Voor gesnapshotte leerlingen: geen enkel effect
(bewezen in de vorige teststap: snapshotprijs bleef exact gelijk nadat de catalogusprijs live werd
gewijzigd). Voor de 33 legacy-leerlingen zonder snapshot: het getoonde bedrag verandert **onmiddellijk**
mee met de catalogus (ook bewezen: test 10 in de vorige ronde). **Dit is het belangrijkste
architectuurrisico dat ik heb gevonden**: een leerling zonder snapshot kan een prijsstijging te zien
krijgen zonder dat daar ooit een bewuste, opnieuw-akkoord-momenten aan vooraf is gegaan. Geen race
condition in technische zin (geen gelijktijdigheidsbug), wel een **product-/data-consistentierisico**
zolang er geen backfill plaatsvindt. Dit bevestigt nogmaals waarom een backfill-beslissing (§2) op
termijn nodig is.

**Een leerling wisselt van pakket.** Al volledig gedekt door de bestaande `berekenPakketToewijzing()`-
logica in de Instructeur-app (scenario 2 in §2): een bewust ander pakket-ID triggert altijd een verse
snapshot. Enkelvoudige, instructeur-geïnitieerde UPDATE — geen gelijktijdigheidsrisico te verwachten bij
normaal gebruik (één instructeur, één sessie per moment is de praktijk bij een rijschool).

**Een leerling wisselt van rijschool.** Dit bestaat **niet** als functionaliteit in de huidige code —
geen enkele service-methode of RPC die `instructeur_id` van een bestaande leerling overzet naar een
andere instructeur. Bovendien blokkeert de Fase 2-trigger dit expliciet vanaf de leerling-kant. Als dit
ooit gebouwd wordt: de pakket-snapshot hoort dan waarschijnlijk **ongeldig verklaard/gewist** te worden
bij een schooloverstap (een overeenkomst met school A is geen overeenkomst met school B) — dat is een
toekomstige productbeslissing, niet iets om nu te implementeren.

**Overige gecontroleerde race conditions:**
- De lesbalans-trigger (`fn_lesson_balance_sync`) gebruikt expliciet `SELECT ... FOR UPDATE` (rij-lock)
  op de leerling-rij bij elke les-statuswijziging — voorkomt dubbele afschrijving bij gelijktijdige
  updates. Al aanwezig, niet door mij aangeraakt.
- `leerlingen_instructeur_id_fkey` heeft `ON DELETE CASCADE` (geverifieerd): verwijdert een
  instructeur-account, dan verdwijnen ook al zijn leerlingen inclusief hun snapshots. Bestaand
  productgedrag, niets waar deze fase iets aan verandert — wel het vermelden waard als iemand ooit
  "instructeur-account verwijderen" bouwt.
- Er is **geen** optimistic-locking op de pakket-toewijzing zelf (twee gelijktijdige instructeur-sessies
  die hetzelfde moment een ander pakket opslaan voor dezelfde leerling: laatste write wint, standaard
  Postgres MVCC-gedrag). Laag risico gezien het gebruikspatroon (één instructeur, zelden gelijktijdige
  sessies), niet iets om nu op te lossen.

---

## 5. Toekomstvisie — examens, producten, abonnementen, cadeaubonnen, theorieproducten

**Kernprobleem als we het huidige lespakket-patroon herhalen:** voor élk nieuw producttype opnieuw 6-10
losse, nullable kolommen aan `leerlingen` toevoegen (zoals nu voor lespakket is gebeurd) schaalt niet.
Na vijf producttypen heeft `leerlingen` tientallen kolommen die voor de meeste rijen `NULL` zijn, en
moet elke leeskant (zoals mijn `LespakketDetail.resolve()`) opnieuw, apart, dezelfde
snapshot-vs-catalogus-resolutielogica herimplementeren per producttype. Dat is precies "over zes maanden
weer de database aanpassen."

**Aanbevolen richting voor een latere, apart te plannen architectuurstap** (niet nu bouwen): één
generieke, genormaliseerde tabel voor alles wat een leerling "bezit" of "gekoppeld heeft gekregen",
bijvoorbeeld conceptueel:

```
leerling_toewijzingen
  id, leerling_id, instructeur_id
  product_type        ('lespakket' | 'examen' | 'theorieproduct' | 'abonnement' | 'cadeaubon')
  catalogus_referentie (nullable, verwijst naar de betreffende catalogustabel voor dat type)
  naam_snapshot, prijs_cents_snapshot
  voorwaarden_snapshot (jsonb -- flexibel per producttype, geen kolomexplosie)
  vastgelegd_op, status ('actief' | 'gebruikt' | 'verlopen' | 'geannuleerd')
```

Eén tabel, één RLS-patroon (leerling leest alleen eigen rijen via `leerling_id`), één
snapshot-immutabiliteitsregel, herbruikbaar voor élk toekomstig producttype — in plaats van telkens een
nieuwe kolomset + nieuwe RLS-policy + nieuwe Dart-resolutieklasse.

**Per genoemd producttype, kort:**
- **Examens** — bestaat al **wél** als aparte tabel (`examens`, met `leerling_id`/`instructeur_id`), dus
  volgt al grotendeels het juiste patroon. Geen kolomexplosie op `leerlingen` hiervoor nodig.
- **Producten / theorieproducten / cadeaubonnen** — bestaan nog nergens; zouden direct in het
  voorgestelde genormaliseerde model passen in plaats van in losse `leerlingen`-kolommen.
- **Abonnementen** — let op: `instructeur_profielen` heeft al een uitgebreide reeks
  abonnement/Mollie/Stripe-kolommen voor het abonnement van de **instructeur zelf** (rijschool-niveau).
  Een toekomstig leerling-abonnement (bijvoorbeeld een terugkerend maandpakket) is conceptueel iets
  anders en hoort niet in diezelfde kolommenset thuis — weer een kandidaat voor het genormaliseerde model.

**Wat dit NIET betekent:** de huidige lespakket-implementatie (deze fase) hoeft niet met terugwerkende
kracht verplaatst te worden om dit te laten werken — een latere migratie naar het genormaliseerde model
kan de bestaande `leerlingen`-kolommen als startpunt/databron gebruiken. Dit is puur een aanbeveling voor
de vólgende keer dat er een nieuw producttype bij komt, geen reden om nu iets te herbouwen.

---

## 6. Bevestiging

- Geen Flutter-bestand gewijzigd in deze stap.
- Geen migratie toegevoegd of uitgevoerd in deze stap.
- Geen enkele databasewijziging uitgevoerd — alle SQL hierboven draaide in `BEGIN; ... ROLLBACK;` en is
  na afloop onafhankelijk geverifieerd als spoorloos.
- Alle bevindingen zijn gebaseerd op het daadwerkelijk lezen van de migratie, constraints, indexen en
  triggers — niet op aannames.

Wachten op jouw akkoord per punt voordat Fase 4-implementatie hervat wordt.
