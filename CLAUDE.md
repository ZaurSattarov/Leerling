# CLAUDE.md — Leerling App
> Project-specifieke instructies. Worden geladen bovenop de globale CLAUDE.md.

---

## Project
- **App:** Leerling-app bij Rijschool Planner / Klantio — companion-app voor rijlesleerlingen
- **Stack:** Flutter + Supabase + Riverpod + GoRouter
- Zusterrepo: `..\Instrecteur` (de instructeur-app, apart project)

---

## Graphify MCP — Verplicht Raadplegen Bij Code-taken

Deze app heeft een geïndexeerde code-graph via de Graphify MCP-server `graphify-leerling`
(graph: `graphify-out/graph.json`, scope: `lib/` + `supabase/` + `docs/`/`test/`).
De Instrecteur-app (ander repo) heeft zijn eigen server: `graphify-instrecteur`. Gebruik
nooit de verkeerde server voor de verkeerde app.

Bij elke programmeeropdracht (bug fix, feature, refactor, "waar zit X", "hoe werkt Y"):

1. **Raadpleeg eerst Graphify MCP** (`graphify-leerling`) — gebruik `query_graph`,
   `get_node`, `get_neighbors`, `graph_stats`, `god_nodes` of `shortest_path` om te
   bepalen welke bestanden/classes/functies relevant zijn, vóórdat je bestanden opent.
2. **Open alleen de bronbestanden** die Graphify aanwijst via het `source_file`-veld —
   geen speculatief browsen door onverwante mappen.
3. **Lees NIET standaard het volledige `GRAPH_REPORT.md`** — dat is een audit-rapport
   voor mensen (god nodes, surprising connections, hyperedges), geen contextbron voor
   code-taken. Gebruik de MCP-tools voor gerichte queries in plaats daarvan.
4. **Geen brede repository-scan** (bv. volledige `Grep`/`Glob` over heel `lib/`) als de
   Graphify-graph al voldoende resultaat geeft. Val pas terug op een reguliere zoekactie
   als Graphify niets relevants vindt (bv. voor recent gewijzigde bestanden die nog niet
   geïndexeerd zijn — run dan `/graphify --update`).

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
