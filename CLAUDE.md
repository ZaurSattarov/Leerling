# CLAUDE.md — Leerling App
> Project-specifieke instructies. Worden geladen bovenop de globale CLAUDE.md.

---

## Project
- **App:** Leerling-app bij Rijschool Planner / Klantio — companion-app voor rijlesleerlingen
- **Stack:** Flutter + Supabase + Riverpod + GoRouter
- Zusterrepo: `..\Instrecteur` (de instructeur-app, apart project)

---

## Klantio Mandatory Startup Preflight

VOOR iedere programmeeropdracht, VOORDAT broncode wordt gewijzigd:

1. Lees deze projectinstructies.
2. Lees (niet de hele vault):
   - `00 - KLANTIO/Product Architectuur/Solo & Team - Canonical Architectuur.md` (**leidend**)
   - `01 - ARCHITECTUUR/Solo-vs-Team.md`
   - `01 - ARCHITECTUUR/Productarchitectuur.md`
3. Bepaal zelfstandig: **SCOPE = SOLO | TEAM | BEIDE**. Algemene functionaliteit → **BEIDE**.
4. Datascope: `product_mode`, `instructeur_id`, `school_id`, assignment, effectieve permissions, RLS.
5. Cross-project impact: **GEEN / MOGELIJK / BEVESTIGD** — zelf bepalen. MOGELIJK ≠ vragen.
6. Skills via `00 - KLANTIO/AI Skills Register.md`.
7. Graphify: `graphify-leerling` (hieronder).
8. Daarna pas minimale broncode.

`product_mode` ≠ abonnementsplan. Nooit cross-school. Canonical assignment: `leerlingen.instructeur_id` + `leerlingen.school_id`.

Toon compact `KLANTIO PREFLIGHT`. Niet vragen of het Solo of Team is als architectuur het antwoord geeft.

**ARCHITECTUURCONFLICT:** STOP en rapporteer. Geen stille nieuwe architectuur.

Canonical Solo/Team-updateplicht: nieuwe goedgekeurde Solo/Team-regel → eerst de leidende Obsidian-notitie bijwerken.

Codex: `AGENTS.md`. Cursor: `.cursor/rules/klantio-workflow.mdc` (`alwaysApply: true`).

Canonical Supabase-migrations: Instructeur-repo. Geen tweede migration-tree hier.

## Graphify MCP — Verplichte Workflow

Dit project heeft een geïndexeerde code-graph via de Graphify MCP-server **`graphify-leerling`**
(graph: `graphify-out/graph.json`, scope: `lib/` + `supabase/` + `docs/`/`test/`). De
Instrecteur-app (apart repo) heeft zijn eigen server: `graphify-instrecteur`. Gebruik nooit de
verkeerde server voor de verkeerde app.

### Verplichte zichtbare status — bij iedere programmeeropdracht, zonder uitzondering

VOORDAT bronbestanden worden geopend, geanalyseerd of gewijzigd, toon exact:

🔎 GRAPHIFY: Ik gebruik Graphify MCP om eerst de relevante code en verbindingen te bepalen.

Roep daarna daadwerkelijk `graphify-leerling` aan. Toon deze melding nooit als Graphify niet
daadwerkelijk wordt gebruikt. Als de MCP-server niet bereikbaar is, meld exact:

⚠️ GRAPHIFY: MCP is niet beschikbaar. Ik ga niet verder met de programmeeropdracht totdat dit is opgelost.

Ga in dat geval niet stilzwijgend verder met een brede repositoryscan.

### Werkwijze

1. Gebruik `query_graph`, `get_node`, `get_neighbors`, `get_community`, `graph_stats`, `god_nodes`
   of `shortest_path` om te bepalen welke bestanden/classes/functies relevant zijn.
2. Open daarna alleen de bronbestanden die Graphify aanwijst via `source_file` — geen speculatief
   browsen door onverwante mappen, geen brede `Grep`/`Glob` over heel `lib/` als de graph al genoeg
   oplevert.
3. Lees niet standaard het volledige `GRAPH_REPORT.md` — dat is een auditrapport voor mensen, geen
   contextbron voor code-taken.
4. Controleer tijdens implementatie altijd de echte broncode; de graph is een routekaart, geen
   vervanging voor broncode.
5. Gebruik nooit automatisch de graph van het andere project.
6. Val alleen terug op een reguliere zoekactie als Graphify niets relevants vindt (bv. recent
   gewijzigde, nog niet geïndexeerde bestanden — run dan `/graphify --update`).

### Eindcontrole — na iedere programmeeropdracht

Bepaal of de codegraph structureel is gewijzigd: bestand toegevoegd/verwijderd/verplaatst/hernoemd,
class/functie/methode toegevoegd/verwijderd/hernoemd, import/dependency gewijzigd, provider/notifier/
service/repository gewijzigd, navigatieroute gewijzigd, nieuwe koppeling tussen modules, Supabase-call
of datastroom structureel gewijzigd. Alleen tekst/kleur/padding/marge-wijzigingen tellen niet als
structureel.

**Bij structurele wijziging:**
1. Voer de bestaande incrementele update uit via `tools\update_graphify.cmd` (draait `/graphify --update`).
2. Voer GEEN volledige semantische heranalyse uit.
3. Valideer `graph.json` en controleer via MCP of de nieuwe node/relatie zichtbaar is; meld expliciet
   als een MCP/Claude-herstart nodig is omdat de oude graph nog in het geheugen zit.
4. Werk `GRAPH_REPORT.md` alleen bij na een grote feature/refactor/architectuurwijziging, of op
   expliciet verzoek.
5. Toon als laatste zichtbare regel exact:

   ✅ GRAPHIFY: graph.json is bijgewerkt met de nieuwste codeverbindingen.

**Zonder structurele wijziging:** voer geen update uit en toon exact:

✅ GRAPHIFY: Graphify is gebruikt; graph.json hoefde niet bijgewerkt te worden.

### Tokenbesparing

Houd queryresultaten compact (directe buren / kleine community, geen honderden nodes zonder
noodzaak), lees nooit het volledige `graph.json` of `GRAPH_REPORT.md` in de modelcontext, en open
alleen de minimaal noodzakelijke bronbestanden. Een programmeeropdracht geldt niet als afgerond
zonder de eindcontrole hierboven.

---

## Klantio-Knowledge (centraal projectgeheugen)

Dit project maakt deel uit van het grotere Klantio-platform (Instructeur, Leerling, Admin
Dashboard, Landing Page). Voor iedere structurele programmeertaak:

1. Raadpleeg relevante context uit de centrale Obsidian-vault **Klantio-Knowledge** via de
   Obsidian MCP — alleen `02 - Leerling/Status.md`, eventueel
   `00 - KLANTIO/Project Status.md` bij cross-project context, en hooguit enkele direct
   relevante notities. Lees nooit automatisch de hele vault.
2. Voer de verplichte cross-project preflight uit (zie `00 - KLANTIO/AI Werkprotocol.md`):
   bepaal zelfstandig of de wijziging Instructeur, Admin Dashboard en/of Landing Page raakt.
   Vraag de gebruiker **niet** als bestaande architectuur het antwoord geeft.
3. Raadpleeg daarna de relevante goedgekeurde skill(s) volgens `00 - KLANTIO/AI Skills
   Register.md` (skill-first, implementation-second) VOORDAT zelf een oplossing wordt
   ontworpen — bij mobiele Flutter-UI bv. `mobile-app-ui-design → impeccable →
   flutter-claude-code`.
4. Gebruik daarna de Graphify-workflow hierboven voor codeverbindingen.
5. Open minimale echte broncode, implementeer en test.
6. Voer de Graphify-eindcontrole uit.
7. Werk alleen relevante Obsidian-kennis bij (architectuurbeslissingen, data-/API-wijzigingen,
   synchronisatieregels, businessregels, openstaande bugs, cross-project impact) — niet bij
   triviale wijzigingen.

Zie ook: `00 - KLANTIO/AI Werkprotocol.md` (centraal protocol), `00 - KLANTIO/AI Skills
Register.md` (verplichte skill-router), `05 - Gedeelde Architectuur/` (gedeelde datamodellen),
`00 - KLANTIO/Cross-Project Impact.md` (openstaande cross-project impact), `00 - KLANTIO/AI
Omgeving.md` (lokale toolpaden/skill-root).

## Skill-router — Verplicht

Voor iedere programmeeropdracht geldt `00 - KLANTIO/AI Skills Register.md`: skill-first,
implementation-second. Voor mobiele UI is de vaste routering `mobile-app-ui-design →
impeccable → ui-ux-pro-max`, gecombineerd met `flutter-claude-code`/`flutter-claude-skills`
voor de technische implementatie. Toon de verplichte zichtbare skillstatus
(`🧩 SKILL: Laden → ...`, `✅ SKILL: Gebruikt → ...`) en de eindmelding
(`🧩 Skills gebruikt: ...`) exact zoals in dat register beschreven. Dit vervangt de losse
Impeccable-melding van eerdere sessies.
