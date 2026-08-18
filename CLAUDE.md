# CLAUDE.md — Leerling App
> Project-specifieke instructies. Worden geladen bovenop de globale CLAUDE.md.

---

## Project
- **App:** Leerling-app bij Rijschool Planner / Klantio — companion-app voor rijlesleerlingen
- **Stack:** Flutter + Supabase + Riverpod + GoRouter
- Zusterrepo: `..\Instrecteur` (de instructeur-app, apart project)

---

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
   bepaal of de wijziging Instructeur, Admin Dashboard en/of Landing Page raakt. Vraag bij
   mogelijke/bevestigde impact eerst compact om scope, tenzij de gebruiker die al gaf.
3. Gebruik daarna de Graphify-workflow hierboven voor codeverbindingen.
4. Open minimale echte broncode, implementeer en test.
5. Voer de Graphify-eindcontrole uit.
6. Werk alleen relevante Obsidian-kennis bij (architectuurbeslissingen, data-/API-wijzigingen,
   synchronisatieregels, businessregels, openstaande bugs, cross-project impact) — niet bij
   triviale wijzigingen.

Zie ook: `00 - KLANTIO/AI Werkprotocol.md` (centraal protocol), `05 - Gedeelde Architectuur/`
(gedeelde datamodellen), `00 - KLANTIO/Cross-Project Impact.md` (openstaande cross-project
impact), `00 - KLANTIO/AI Omgeving.md` (lokale toolpaden, bv. Impeccable).

## Impeccable — Verplicht bij UI/Design

Bij iedere taak die UI/UX/design daadwerkelijk raakt (nieuw scherm, redesign, component,
formulier, modal, card, navigatie, layout, spacing, typografie, responsive gedrag, visuele
hiërarchie, UI/UX-correctie) is de Impeccable-skill VERPLICHT. Niet verplicht voor pure
backend/database/API/businesslogica zonder visuele impact.

Werkwijze: bepaal dat de taak UI/design raakt → laad/raadpleeg de Impeccable-skill (pad staat
in `00 - KLANTIO/AI Omgeving.md`) → pas daarna UI/design aan. Toon alleen wanneer Impeccable
daadwerkelijk succesvol geraadpleegd is exact:

🎨 IMPECCABLE: Skill wordt gebruikt voor deze UI/UX-taak.

Claim dit nooit wanneer de skill niet daadwerkelijk bereikbaar/gelezen is; meld dan expliciet
dat Impeccable niet gevonden is en ga niet stilzwijgend verder.
