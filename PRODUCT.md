# Product

## Register

product

## Users

Leerlingen (rijleerlingen) van Nederlandse rijscholen die met een Klantio-instructeur werken. Zij gebruiken de app onderweg, vaak kort tussen andere dingen door (op de fiets/bus naar de les, vlak voor een afspraak), om hun volgende les, voortgang, facturen en profiel te checken. Laag geduld voor frictie, hoge behoefte aan direct scanbare informatie (tijd, locatie, status).

## Product Purpose

De Klantio Leerlingen-app is de leerling-facing tegenhanger van de Klantio Rijschool Planner (instructeur-app). Het toont lesplanning, voortgang (CBR-competenties, lespakket), facturen/betalingen en profielgegevens die de instructeur beheert. Succes = een leerling kan in enkele seconden zien wanneer/waar de volgende les is en die informatie meteen kunnen gebruiken (bv. navigeren naar de ophaallocatie).

## Brand Personality

Betrouwbaar, opgeruimd, direct. Geen speelse SaaS-clichés; een rustige, volwassen tool die naast een schoolagenda/bankapp past. Donkere navy shell-headers met precieze witte typografie, lichte kaart-gebaseerde content, één merkkleur (roze/rood #F3456B) die spaarzaam en doelgericht wordt ingezet voor actie/nadruk -- nooit decoratief.

## Anti-references

Geen speelse gradients, geen "big number hero metric"-kaarten, geen pastel-kleurenwaaier, geen dichte kaarten-in-kaarten. Niet de generieke "AI SaaS dashboard"-look (zachte gradient-cards, gekleurde iconen op gekleurde achtergronden, overal afgeronde 24px+ hoeken). Bestaande project-regel (zie CLAUDE.md): icon-achtergronden zijn altijd neutraal grijs (`0xFFF0F2F5`) met een semantische icoonkleur erbovenop -- nooit een gekleurd vlak met wit icoon.

## Design Principles

- Eén blik, geen graven: de belangrijkste actie (navigeren naar de ophaallocatie) moet in één tik bereikbaar zijn, zonder een aparte tegel te hoeven zoeken.
- Bestaand systeem eerst: hergebruik de gevestigde Klantio-designtokens (AppColors, AppCard, ProfileDetailRow-achtige rijen) in plaats van nieuwe ad-hoc stijlen te verzinnen.
- Functie boven versiering: een kaartpreview is een leesbaarheids- en oriëntatiehulpmiddel, geen decoratie -- als er geen betrouwbare previewbron is, een eerlijke, duidelijk herkenbare placeholder tonen in plaats van iets te faken.
- Nooit lege/valse data tonen: geen `null`/`-`/placeholder-tekst; ontbrekende data betekent het hele element verbergen.

## Accessibility & Inclusion

WCAG-conform contrast op alle tekst over de kaartpreview (overlay-gradient verplicht). Volledige kaart als één tikdoel met een duidelijk semantisch label (screenreader: "Open ophaallocatie in Maps"). Layout blijft leesbaar/zonder overflow bij 130% tekstschaal (Nederlandse project-standaard, zie eerdere testsuites in deze app).
