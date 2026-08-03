# Technisch voorstel — gecontroleerde snapshot-backfill voor bestaande leerlingen

> **Status: voorstel, niet uitgevoerd.** Geen migratie, geen script, geen databasewijziging in deze
> stap. Hoort thuis in de **Instructeur-app-repo** (`rijschool-planner-flutter`) — dat is de kant die de
> snapshot-kolommen op `leerlingen` schrijft; de Leerling-app raakt deze kolommen sinds Fase 2 niet
> aan. Dit document is de voorbereiding daarvan, opgesteld vanuit het Leerling-app-onderzoek.

## Aanleiding

`docs/PROFIEL_FASE4_ARCHITECTUURCONTROLE.md` §2 en §4: 33 leerlingen hebben een geldig `pakket_id`
maar nog geen `pakket_snapshot_vastgelegd_op`. Zolang dat zo blijft, verandert hun getoonde pakketprijs/
-voorwaarden mee met elke toekomstige catalogusaanpassing door de instructeur — geen bewuste
her-overeenkomst, puur een neveneffect van de huidige "additief, geen backfill"-migratiestrategie.

## 1. Welke 33 leerlingen worden geraakt

Scope-query (read-only, uitgevoerd ter voorbereiding van dit voorstel — niets geschreven):

```sql
select count(*) as totaal_kandidaten,
       count(*) filter (where p.id is null) as pakket_verwijst_naar_niet_bestaand_pakket,
       count(*) filter (where p.id is not null and p.actief = false) as pakket_inactief,
       count(*) filter (where p.id is not null and p.actief = true) as pakket_actief,
       count(distinct l.instructeur_id) as aantal_instructeurs
from public.leerlingen l
left join public.instructor_lesson_packages p on p.id = l.pakket_id
where l.pakket_id is not null
  and l.pakket_snapshot_vastgelegd_op is null;
```

**Resultaat op dit moment:** 33 kandidaten, verdeeld over 1 instructeur in de huidige dataset, **allemaal**
met een nog bestaand, actief cataloguspakket (0 met een verwijderde referentie, 0 met een inactief
pakket). Dat is de gunstigste uitgangssituatie, maar het uitvoeringsscript hieronder moet de overige
gevallen (verwijderd/inactief) toch afhandelen — andere omgevingen of een latere uitvoering kunnen dat
wél tegenkomen.

**Exacte selectiecriteria voor het uitvoeringsscript:**
```sql
where pakket_id is not null and pakket_snapshot_vastgelegd_op is null
```

## 2. Welke catalogusvelden naar welke snapshotkolommen

Exact dezelfde mapping als `berekenPakketToewijzing()` (Instructeur-app, `core/utils/
leerling_pakket_snapshot.dart`) al gebruikt bij een normale toewijzing — de backfill simuleert dus geen
nieuw gedrag, hij past de bestaande, al-geteste toewijzingslogica eenmalig met terugwerkende kracht toe:

| Bron (`instructor_lesson_packages`) | Doel (`leerlingen`) |
|---|---|
| `saldo_eenheid` | `saldo_eenheid` |
| `pakket_minuten_totaal` (alleen bij minuten-modus) | `pakket_minuten_totaal` |
| `pakketprijs * 100` (round) | `pakket_prijs_cents` |
| `losse_lesprijs * 100` (round) | `pakket_losse_les_prijs_cents` |
| `lesduur_minuten` | `pakket_lesduur_minuten` |
| `praktijkexamen_inbegrepen` | `pakket_praktijkexamen_inbegrepen` |
| `tussentijdse_toets_inbegrepen` | `pakket_tussentijdse_toets_inbegrepen` |
| — | `pakket_snapshot_vastgelegd_op = now()` |
| `naam` (alleen als `pakket_naam` op leerlingen nog leeg is) | `pakket_naam` |

`pakket_id`, `pakket_lessen` en `pakket_naam` bestaan voor deze 33 leerlingen meestal al (oudere
migraties, zie `docs/PROFIEL_FASE4_ARCHITECTUURCONTROLE.md` §1) — die worden **niet** overschreven als
ze al gevuld zijn, alleen de ontbrekende commerciële/functionele velden worden aangevuld.

**Expliciete beperking:** dit is de **huidige** catalogusprijs op het moment van backfill, niet de
historisch correcte prijs op het moment van oorspronkelijke toewijzing (die data bestaat nergens — er is
nooit een snapshot geweest). Dit moet als zodanig gecommuniceerd worden aan de opdrachtgever vóór
uitvoering: de backfill *bevriest vanaf nu*, hij reconstrueert geen verleden.

## 3. Conflictcontrole

Vóór elke write, per kandidaat-rij:
- **Skip als er tussentijds al een snapshot is bijgekomen** (`pakket_snapshot_vastgelegd_op IS NOT NULL`
  op het moment van uitvoeren) — voorkomt dat de backfill een net door de instructeur zelf vastgelegde,
  mogelijk andere snapshot overschrijft. Simpele opnieuw-lees-vlak-vóór-write, geen race conditions te
  verwachten (eenmalig, buiten kantooruren uit te voeren batchjob).
- **Skip als `pakket_id` tussentijds is gewijzigd** naar een ander pakket dan waarop de preview (§5)
  gebaseerd was — zelfde principe.
- Beide gevallen loggen als "overgeslagen, reden: tussentijds gewijzigd" in het auditlog (§7), geen
  stille no-op.

## 4. Ontbrekende of verwijderde cataloguspakketten

Voor de (in de huidige dataset niet voorkomende, maar mogelijk elders wel aanwezige) leerlingen waarvan
`pakket_id` naar een inmiddels verwijderd pakket verwijst: onmogelijk, want `ON DELETE SET NULL` op de
FK betekent dat `pakket_id` dan al `NULL` is (geverifieerd in Fase 4-architectuurcontrole) — zo'n
leerling valt dan al buiten de selectiecriteria van §1 (`pakket_id is not null`). Het enige resterende
geval is een **inactief maar nog wél bestaand** pakket (`actief = false`): dat pakket **wordt gewoon
gesnapshot** zoals het nu is — "inactief" betekent alleen dat een instructeur het niet meer aan nieuwe
leerlingen kan toewijzen, niet dat de gegevens ongeldig zijn voor een bestaande overeenkomst.

## 5. Preview / dry-run

Verplichte stap vóór enige write: een read-only rapport per kandidaat-rij (leerling-id, huidige
`pakket_id`, cataloguspakketnaam, te bevriezen prijs/voorwaarden), geëxporteerd voor beoordeling door de
opdrachtgever. Geen enkele write totdat dit rapport expliciet is goedgekeurd. Technisch: dezelfde
`SELECT`-query als het uitvoeringsscript, maar dan zonder de `UPDATE`-stap — letterlijk hetzelfde
scriptbestand met een `--dry-run`-vlag die de `UPDATE` overslaat en in plaats daarvan naar het
auditlog schrijft wat ZOU gebeuren.

## 6. Auditlog

Elke daadwerkelijke wijziging (en elke bewust overgeslagen rij, zie §3) wordt weggeschreven naar de
bestaande `lesson_credit_changes`-achtige logtabel-conventie die dit project al gebruikt voor
saldo-wijzigingen (zie `fn_lesson_balance_sync`), of een vergelijkbare, nieuw aan te maken
`pakket_snapshot_backfill_log`-tabel met minimaal: `leerling_id`, `pakket_id`, `oude_waarden` (jsonb,
vóór de backfill — altijd NULL hier, maar consistent gelogd), `nieuwe_waarden` (jsonb), `uitgevoerd_op`,
`uitgevoerd_door`. Dit is zelf ook een nieuwe migratie/tabel — expliciet **niet** in deze stap te bouwen,
onderdeel van de latere, aparte uitvoering.

## 7. Rollbackstrategie

Omdat elke geraakte rij vóór de backfill `pakket_snapshot_vastgelegd_op IS NULL` had, is "terugdraaien"
eenvoudig en ondubbelzinnig: `UPDATE leerlingen SET pakket_prijs_cents = NULL, pakket_losse_les_prijs_
cents = NULL, pakket_lesduur_minuten = NULL, pakket_praktijkexamen_inbegrepen = NULL, pakket_
tussentijdse_toets_inbegrepen = NULL, pakket_snapshot_vastgelegd_op = NULL WHERE id = ANY(<lijst van
tijdens deze backfill geraakte leerling-id's>)` — geen enkel risico op het per ongeluk resetten van een
snapshot die al vóór de backfill bestond, omdat die leerlingen per definitie buiten de selectiecriteria
vielen. De lijst met geraakte id's komt rechtstreeks uit het auditlog (§6), niet uit een nieuwe query op
dat moment (voorkomt dat een ondertussen organisch ontstane snapshot per ongeluk wordt teruggedraaid).

## 8. Expliciete bevestiging vóór uitvoering

Uitvoeringsvolgorde, geen stap overslaan:
1. Dry-run/preview (§5) genereren en delen.
2. Opdrachtgever beoordeelt en geeft **schriftelijk/expliciet** akkoord op de preview-inhoud (niet op het
   concept — op de daadwerkelijke rijenlijst).
3. Pas dan het uitvoeringsscript in transactie draaien, met het auditlog als onderdeel van dezelfde
   transactie (alles-of-niets).
4. Na uitvoering: controlerapport (aantal gewijzigd, aantal overgeslagen + reden) terugkoppelen.

## Samenvatting van openstaande technische schuld

- Backfill zelf: **niet uitgevoerd**, dit document is uitsluitend het voorstel.
- Nieuwe auditlog-tabel/migratie voor de backfill: **niet gebouwd**, hoort bij de uitvoeringsstap.
- Zolang de backfill niet is uitgevoerd, blijft het in Fase 4 geïdentificeerde risico bestaan (legacy-
  leerlingen zien catalogusprijswijzigingen live) — bewust geaccepteerd voor nu, met dit voorstel als
  concreet vervolgpad zodra gewenst.
