# Klantio Agent Instructions

Before making code changes:

1. Read this file and `CLAUDE.md` (Graphify `graphify-leerling`, skills).
2. Read mandatory Klantio-Knowledge (not the whole vault):
   - `00 - KLANTIO/Product Architectuur/Solo & Team - Canonical Architectuur.md` (leading)
   - `01 - ARCHITECTUUR/Solo-vs-Team.md`
   - `01 - ARCHITECTUUR/Productarchitectuur.md`
3. Determine SOLO / TEAM / BEIDE. General Klantio features default to BEIDE, with correct per-mode data/permission scoping.
4. Determine data scope: `product_mode`, `instructeur_id`, `school_id`, assignments, effective permissions, RLS. `product_mode` is never inferred from subscription plan.
5. Classify cross-project impact: GEEN / MOGELIJK / BEVESTIGD. Do not ask the user when architecture already determines scope.
6. Follow Graphify/skills workflows in this file and `CLAUDE.md`.
7. Show compact `KLANTIO PREFLIGHT`.
8. Only then modify code.

If Obsidian, database/RLS and code conflict: STOP and report ARCHITECTUURCONFLICT.

Canonical migrations live in the Instructor repo.

Flutter root: `C:\PROJECTS\Leerling`.

---

# Project Richtlijn Voor Codex — Leerling App

Werk standaard in: `C:\Users\zaurs\Documents\ZaurProject\Leerling`

Belangrijke bestanden:
- Flutter app: `lib`
- App routes: `lib\app.dart`
- Supabase migraties voor deze app: `supabase\migrations`

Zusterrepo (apart project, niet hetzelfde als deze app): `..\Instrecteur`

## Graphify MCP — Verplicht Raadplegen Bij Code-taken

Er is een geïndexeerde code-graph beschikbaar via de MCP-server `graphify-leerling`
(graph.json onder `graphify-out/`, scope: `lib/` + `supabase/` + `docs/`/`test/`).
De Instrecteur-app (apart repo, `..\Instrecteur`) heeft zijn eigen server:
`graphify-instrecteur`. Gebruik nooit de verkeerde server voor de verkeerde app.

Bij programmeeropdrachten:

1. Raadpleeg eerst `graphify-leerling` (`query_graph`, `get_node`, `get_neighbors`,
   `graph_stats`, `god_nodes`, `shortest_path`) om te bepalen welke bestanden relevant zijn.
2. Open alleen de bronbestanden die Graphify aanwijst via `source_file` — geen
   speculatief doorzoeken van onverwante mappen.
3. Lees niet standaard het volledige `GRAPH_REPORT.md` — dat is een audit-rapport voor
   mensen, geen contextbron. Gebruik de MCP-tools voor gerichte queries.
4. Geen brede repository-scan als de graph al genoeg oplevert. Val pas terug op een
   reguliere zoekactie als Graphify niets relevants vindt (en run dan evt.
   `/graphify --update` voor recent gewijzigde bestanden).

---

## Graphify MCP — verplichte workflow

**Voor dit project (Leerling) uitsluitend: `graphify-leerling`.** Gebruik nooit
`graphify-instrecteur` hier — dat hoort bij het aparte Instrecteur-repo.

Graphify is de primaire code-index voor dit project.

### Bij het starten van een programmeersessie

1. Controleer of de juiste Graphify MCP-server beschikbaar is.
2. Voer een kleine graph_stats-controle uit.
3. Bouw niet automatisch de volledige graph opnieuw.
4. Lees niet automatisch het volledige GRAPH_REPORT.md.
5. Gebruik de bestaande graph.json als actuele code-index.
6. Wanneer de MCP-server niet beschikbaar is, stop dan en meld duidelijk dat Graphify niet bereikbaar is voordat breed door de repository wordt gezocht.

### Aan het begin van iedere programmeeropdracht

Toon als eerste korte statusregel exact:

🔎 Graphify MCP wordt gebruikt om de relevante code en verbindingen te bepalen.

Daarna:

1. Raadpleeg eerst de juiste Graphify MCP-server.
2. Gebruik query_graph, get_node, get_neighbors, get_community, shortest_path of andere passende Graphify-tools.
3. Bepaal daarmee:
   - relevante bestanden
   - classes en functies
   - imports
   - directe afhankelijkheden
   - gekoppelde providers, services en repositories
   - routes en navigatieverbindingen
   - mogelijke impact van de wijziging
4. Open daarna alleen de minimaal noodzakelijke echte bronbestanden.
5. Voer geen brede repositoryscan uit wanneer Graphify voldoende resultaat geeft.
6. Lees niet standaard het volledige GRAPH_REPORT.md.
7. Geef geen lang Graphify-rapport aan de gebruiker, tenzij daar expliciet om wordt gevraagd.
8. Toon alleen kort welke relevante bestanden via Graphify zijn geselecteerd.

### Tijdens de uitvoering

1. Controleer echte broncode voordat code wordt gewijzigd; de graph is een routekaart en geen vervanging voor broncode.
2. Behoud bestaande functionaliteit tenzij de opdracht expliciet iets anders vraagt.
3. Open extra bestanden alleen wanneer Graphify of de reeds geopende code aantoont dat die noodzakelijk zijn.
4. Gebruik nooit automatisch de graph van het andere project.

### Na iedere programmeeropdracht

Bepaal eerst of de codegraph structureel is veranderd.

Een Graphify-update is verplicht wanneer één of meer van deze zaken zijn gewijzigd:

- bestand toegevoegd, verwijderd, verplaatst of hernoemd
- class toegevoegd, verwijderd of hernoemd
- functie of methode toegevoegd, verwijderd of hernoemd
- import of dependency gewijzigd
- provider, notifier, service of repository gewijzigd
- navigatieroute gewijzigd
- nieuwe koppeling tussen modules gemaakt
- Supabase-aanroep of datastroom structureel gewijzigd
- meerdere bestaande onderdelen anders met elkaar verbonden

Wanneer uitsluitend tekst, kleur, padding, marges of andere niet-structurele UI-eigenschappen zijn gewijzigd, hoeft graph.json niet opnieuw te worden opgebouwd.

Wanneer een graph-update nodig is:

1. Gebruik uitsluitend de officiële incrementele Graphify-update voor dit project.
2. Voer geen volledige semantische heranalyse uit.
3. Werk de bestaande graph.json in graphify-out bij.
4. Valideer dat graph.json geldig is.
5. Controleer via MCP of de nieuwe of gewijzigde node/relatie zichtbaar is.
6. Herstart of herlaad de MCP-server wanneer de geïnstalleerde versie gewijzigde graph.json-bestanden niet live herlaadt.
7. Werk GRAPH_REPORT.md alleen bij na:
   - een grote feature
   - een grote refactor
   - een architectuurwijziging
   - of wanneer de gebruiker dat expliciet vraagt

Toon als laatste korte statusregel één van deze twee exacte meldingen:

Wanneer de graph is bijgewerkt:

✅ Graphify MCP gebruikt en graph.json incrementeel bijgewerkt met de nieuwe codeverbindingen.

Wanneer geen graph-update nodig was:

✅ Graphify MCP gebruikt; graph.json hoefde voor deze niet-structurele wijziging niet te worden bijgewerkt.

### Tokenbesparing

- Houd Graphify-queryresultaten compact.
- Toon geen volledige communities of honderden nodes zonder noodzaak.
- Vraag alleen directe buren of een kleine relevante community op.
- Open alleen de minimaal noodzakelijke bronbestanden.
- Lees niet het volledige graph.json-bestand in de modelcontext.
- Lees niet standaard het volledige GRAPH_REPORT.md.
- Gebruik MCP-tools om gerichte delen uit de graph op te vragen.

### Incrementele update-opdracht (gevalideerd)

Zie `tools\update_graphify.cmd` in dit project — draait `/graphify --update` (de officiële
incrementele-update-modus van de geïnstalleerde graphify-versie) vanuit de projectroot.

---

## Graphify MCP — Verplichte Zichtbare Status en Eindcontrole (aangescherpt)

> Dit is de strengere, verplichte versie van de statusmeldingen hierboven. Bij afwijking
> tussen deze sectie en de eerdere Graphify-secties in dit bestand, geldt deze sectie.

### Verplichte zichtbare Graphify-status — bij iedere programmeeropdracht, zonder uitzondering

1. VOORDAT bronbestanden worden geopend, geanalyseerd of gewijzigd, moet als eerste
   zichtbare statusmelding exact worden getoond:

   🔎 GRAPHIFY: Ik gebruik Graphify MCP om eerst de relevante code en verbindingen te bepalen.

2. Daarna moet daadwerkelijk de juiste Graphify MCP-server worden aangeroepen: **`graphify-leerling`**.
3. Alleen nadat Graphify daadwerkelijk is geraadpleegd mogen de minimaal noodzakelijke
   bronbestanden worden geopend.
4. De beginmelding mag NOOIT worden getoond als Graphify niet daadwerkelijk wordt gebruikt.
5. Als Graphify MCP niet bereikbaar is, meld dan exact:

   ⚠️ GRAPHIFY: MCP is niet beschikbaar. Ik ga niet verder met de programmeeropdracht totdat dit is opgelost.

   Ga in dat geval niet stilzwijgend verder met een brede repositoryscan.

### Verplichte eindcontrole — na iedere programmeeropdracht

Bepaal na iedere programmeeropdracht of de codegraph structureel is gewijzigd (zie de
lijst met structurele wijzigingen hierboven).

**Als er een structurele wijziging is:**

1. Voer de bestaande incrementele Graphify-update uit via `tools\update_graphify.cmd`.
2. Voer GEEN volledige semantische Graphify-heranalyse uit.
3. Valideer graph.json.
4. Controleer indien mogelijk via MCP of de nieuwe nodes/verbindingen zichtbaar zijn.
5. Als MCP nog de oude graph in het geheugen heeft, meld expliciet dat een MCP/Claude-herstart nodig is.
6. Toon als LAATSTE zichtbare regel exact:

   ✅ GRAPHIFY: graph.json is bijgewerkt met de nieuwste codeverbindingen.

**Als er geen structurele wijziging is:**

Voer geen onnodige Graphify-update uit. Toon als LAATSTE zichtbare regel exact:

✅ GRAPHIFY: Graphify is gebruikt; graph.json hoefde niet bijgewerkt te worden.

### Belangrijk

- Deze begin- en eindmeldingen zijn VERPLICHT.
- Een programmeeropdracht geldt niet als volledig afgerond wanneer de Graphify-eindcontrole ontbreekt.
- GRAPH_REPORT.md hoeft NIET na iedere opdracht opnieuw gegenereerd te worden.
- graph.json is de actuele machineleesbare graph die via MCP wordt gebruikt.
- Beperk tokengebruik: gerichte queries, minimale relevante nodes, minimale bronbestanden,
  geen volledige graph in context laden, geen volledige GRAPH_REPORT.md lezen tenzij noodzakelijk.
