# Actuele releasepoort — backend v2 geïnstalleerd

Het installatiebewijs van MAIL is gelezen:
`Instrecteur/Klantio-emailbibliotheek/qa/master76-2026-10-25/preferences-v2-execution/VERIFIED.json`.

MAIL registreert geslaagde installatie van migratie 20261025221500, zes
gecontroleerde functiebody's, de eigen RPC uitsluitend voor authenticated,
15 bestaande actieve ketens en 13 optionele ketens UIT, zonder optionele
activiteit of wijzigingen aan push/RLS/runtime/cron. Dit is controle van het
vastgelegde installatiebewijs, geen door Agent 2 herhaalde live databasecontrole.

De backendinstallatiepoort uit RELEASEPLAN stap 1 is daarmee volgens het bewijs
gepasseerd. De gezamenlijke eigen-accountintegratie uit stap 2 is nog NIET gedaan.
De 54 Flutter-tests blijven lokaal bewijs en vervangen die controle niet.

Voor de SDK/appcontrole zijn bestaande eigen Solo- en Team-leerlingaccounts met
hun echte ingelogde sessie en eventuele persoonlijke MFA nodig. In deze chat is
nog geen dergelijke testsessie beschikbaar gesteld of geselecteerd. Geen account
maken, credentials uit lokale bestanden halen, impersonatie of service-role
gebruiken. De gebruiker voert de persoonlijke login/MFA uit; daarna kan de
begeleide controle volgens RELEASEPLAN plaatsvinden binnen de afgesproken
scope. Een integratiecontrole met opslaan wijzigt echte eigen voorkeuren: leg de
beginstand vast en herstel die na afloop.

De eerstvolgende handeling is de eigen-accountintegratie. Het eerstvolgende
publicatie-GO kan pas NA geslaagde integratie en normale build/signingcontrole.
De 13 optionele ketens blijven ook dan UIT tot hun afzonderlijke activerings-GO.
Geen appcode, backend of gepubliceerde app gewijzigd door deze statusupdate.
