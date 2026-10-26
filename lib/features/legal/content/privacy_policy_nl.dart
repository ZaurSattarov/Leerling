import 'legal_document_content.dart';

const privacyPolicyNl = LegalDocumentContent(
  eyebrow: 'JURIDISCH',
  title: 'Privacybeleid',
  version: '1.0',
  effectiveDate: '21 oktober 2026',
  sections: [
    LegalSectionContent(
      title: 'Wie is verantwoordelijk voor je gegevens?',
      body:
          'In de Leerlingenapp (Klantio L) verwerken twee partijen persoonsgegevens, elk met een eigen rol en verantwoordelijkheid:\n\n'
          '1. Klantio (EazyPeazy) als verwerkingsverantwoordelijke:\n'
          'Voor jouw app-account, inloggegevens en authenticatie, beveiliging en misbruikpreventie, pushnotificatietokens en supportcontact met Klantio bepaalt Klantio het doel en de middelen. Klantio is een softwaredienst van EazyPeazy, eenmanszaak ingeschreven bij de Kamer van Koophandel onder nummer 74389734 (btw-id NL002505494B23), gevestigd te Pleinweg 98 C, 3083 EK Rotterdam (contact: info@klantio.com).\n\n'
          '2. Jouw rijschool als verwerkingsverantwoordelijke:\n'
          'Voor al jouw rijlesgegevens, lesplanning, ophaaladressen, lespakketten, competenties, voortgang, lesobservaties, examens en facturen die door de rijschool aan jou worden uitgereikt, is jouw rijschool de verwerkingsverantwoordelijke. Klantio verwerkt deze opleidingsgegevens uitsluitend als verwerker in opdracht van jouw rijschool.\n\n'
          'Heb je inhoudelijke vragen over je lessen, vorderingen of facturen? Richt je dan in eerste instantie tot je rijschool of rijinstructeur. Klantio ondersteunt de rijschool bij het uitoefenen van jouw privacyrechten.',
    ),
    LegalSectionContent(
      title: 'Welke gegevens verwerken wij?',
      body:
          'De Leerlingenapp verwerkt alleen de gegevens die nodig zijn om jou inzicht te geven in je rijopleiding en de communicatie met je rijschool te ondersteunen:\n\n'
          '• Account- en profielgegevens: je voor- en achternaam, e-mailadres, telefoonnummer, inloggegevens, eventueel door jou geüploade profielfoto en app-instellingen.\n\n'
          '• Rijschoolkoppeling: de koppeling met je rijschool en toegewezen instructeur(s) via koppelcode of QR-code.\n\n'
          '• Lesplanning en beschikbaarheid: data en tijdstippen van geplande en afgeronde rijlessen, ophaal- en afzetlocaties, lesstatus en jouw opgegeven beschikbaarheid en tijdvoorkeuren.\n\n'
          '• Voortgang en evaluaties: voortgang binnen je lespakket, competenties en vorderingenkaart, indicatief examenadvies, en evaluaties of lesnotities die je instructeur met jou deelt.\n\n'
          '• Facturen en betalingen: factuurnummers, openstaande en voldane bedragen, vervaldatums en betalingsreferenties (wanneer je facturen via iDEAL/Mollie betaalt).\n\n'
          '• Live aankomst & navigatie: wanneer je instructeur onderweg is naar jouw ophaallocatie, kan de app een geschatte aankomsttijd (ETA) en afstand tonen om je tijdig te informeren.\n\n'
          '• Communicatie en pushmeldingen: apparaattokens (FCM/APNs) om herinneringen voor je lessen en belangrijke wijzigingen als pushbericht op je telefoon te bezorgen, en berichten aan onze helpdesk.\n\n'
          '• Technische gegevens: IP-adres, apparaattype, besturingssysteem, app-versie en diagnostische storingslogs om de app veilig en stabiel te houden.',
    ),
    LegalSectionContent(
      title: 'Waarom verwerken wij deze gegevens en op welke grondslag?',
      body:
          'Wij verwerken persoonsgegevens uitsluitend op basis van de wettelijke grondslagen van de AVG:\n\n'
          '1. Uitvoering van de overeenkomst (art. 6 lid 1 sub b AVG):\n'
          'Noodzakelijk voor het functioneren van de app, zoals het inzien van je lesrooster, doorgeven van beschikbaarheid, volgen van je lesvoortgang, downloaden en betalen van facturen en communicatie met je rijschool.\n\n'
          '2. Wettelijke verplichting (art. 6 lid 1 sub c AVG):\n'
          'Noodzakelijk om te voldoen aan administratieve en fiscale verplichtingen rond facturen en betalingen.\n\n'
          '3. Gerechtvaardigd belang (art. 6 lid 1 sub f AVG):\n'
          'Het beveiligen van jouw account, voorkomen van fraude of misbruik, en het technisch onderhouden en optimaliseren van de stabiliteit van de app.\n\n'
          '4. Toestemming (art. 6 lid 1 sub a AVG):\n'
          'Voor het sturen van pushmeldingen naar je telefoon en voor toegang tot je fotobibliotheek/camera als je een profielfoto instelt. Je kunt deze toestemming op ieder moment intrekken via de instellingen van je toestel.',
    ),
    LegalSectionContent(
      title: 'Toegang en strikte gegevensscheiding',
      body:
          'Gegevens van verschillende rijscholen en leerlingen zijn strikt van elkaar gescheiden.\n\n'
          'Via geavanceerde server-side autorisatieregels (Row Level Security) is gegarandeerd dat jij uitsluitend toegang hebt tot jouw eigen persoonlijke gegevens, lesplanning en facturen. Andere leerlingen hebben onder geen beding toegang tot jouw voortgang of gegevens.\n\n'
          'Binnen jouw rijschool hebben alleen de geautoriseerde instructeur(s) en administratie toegang tot jouw opleidingsdossier.',
    ),
    LegalSectionContent(
      title: 'Met wie delen wij gegevens? (Verwerkers)',
      body:
          'Klantio verkoopt jouw gegevens nooit aan derden. Gegevens worden uitsluitend gedeeld met betrouwbare technische dienstverleners die namens ons handelen en met wie strikte verwerkersafspraken zijn gemaakt:\n\n'
          '• Supabase: veilige database, gebruikersauthenticatie en bestandsopslag, gehost binnen de Europese Economische Ruimte (regio West-Europa / Ierland).\n\n'
          '• Mollie B.V.: veilige verwerking van online betalingen (zoals iDEAL) voor facturen die je via de app aan je rijschool betaalt.\n\n'
          '• Apple (APNs) en Google (Firebase Cloud Messaging): het veilig afleveren van pushnotificaties op jouw telefoon.\n\n'
          '• Resend: het versturen van transactionele e-mails zoals inloglinks, verificaties en accountmeldingen.\n\n'
          '• Cloudflare: beveiliging van het netwerkverkeer en api-infrastructuur.',
    ),
    LegalSectionContent(
      title: 'Hoe lang bewaren wij jouw gegevens?',
      body:
          'Wij bewaren persoonsgegevens niet langer dan strikt noodzakelijk:\n\n'
          '• Account- en opleidingsgegevens: zolang jouw leerlingaccount actief is en je rijles volgt bij je rijschool. Na beëindiging van je opleiding bewaart de rijschool het dossier conform haar eigen bewaarbeleid en wettelijke verplichtingen.\n\n'
          '• Financiële gegevens en facturen: minimaal 7 jaar volgens de wettelijke fiscale bewaarplicht voor de Belastingdienst.\n\n'
          '• Technische logbestanden en tokens: tijdelijke logs voor foutopsporing en apparaattokens worden periodiek opgeschoond en niet langer bewaard dan nodig voor beveiliging en werking.',
    ),
    LegalSectionContent(
      title: 'Beveiliging van persoonsgegevens',
      body:
          'Klantio neemt passende technische en organisatorische maatregelen om jouw gegevens te beschermen tegen verlies, diefstal of onbevoegde toegang.\n\n'
          'Alle gegevensuitwisseling tussen de Leerlingenapp en onze servers verloopt via sterke versleuteling (TLS/HTTPS). Toegang tot databases is beveiligd met strikte autorisatiemechanismen op serverniveau.\n\n'
          'Mocht je onverhoopt een kwetsbaarheid of beveiligingsprobleem ontdekken, meld dit dan direct via info@klantio.com.',
    ),
    LegalSectionContent(
      title: 'Jouw rechten onder de AVG',
      body:
          'Als betrokkene heb je op grond van de Algemene Verordening Gegevensbescherming (AVG) duidelijke rechten:\n\n'
          '• Recht op inzage: je kunt inzien welke persoonsgegevens over jou worden verwerkt (het merendeel zie je direct in de app).\n'
          '• Recht op rectificatie: je kunt onjuiste profiel- of contactgegevens laten aanpassen.\n'
          '• Recht op gegevenswissing: je kunt verzoeken om verwijdering van je gegevens, voor zover geen wettelijke bewaarplicht van toepassing is.\n'
          '• Recht op beperking en bezwaar: je kunt bezwaar maken tegen bepaalde verwerkingen of verzoeken de verwerking tijdelijk te beperken.\n'
          '• Recht op dataportabiliteit: je hebt het recht om je gegevens in een gestructureerd, gangbaar formaat te ontvangen.\n\n'
          'Wil je gebruikmaken van je rechten met betrekking tot lesgegevens, voortgang of facturen? Neem dan contact op met jouw rijschool. Voor account- en appbrede verzoeken kun je contact opnemen met Klantio via info@klantio.com.',
    ),
    LegalSectionContent(
      title: 'Account beëindigen en verwijderen',
      body:
          'Wil je stoppen met het gebruik van de Leerlingenapp en je account laten verwijderen? Je kunt een verzoek tot accountverwijdering indienen via de app of via info@klantio.com.\n\n'
          'Let op: facturen en reeds afgeronde administratieve transacties moeten door de rijschool en Klantio worden bewaard zolang de fiscale bewaarplicht dat vereist.',
    ),
    LegalSectionContent(
      title: 'Contact en klachten',
      body:
          'Heb je vragen of opmerkingen over dit privacybeleid of de manier waarop wij met jouw privacy omgaan? Neem gerust contact op met Klantio:\n\n'
          'EazyPeazy (Klantio)\n'
          'Pleinweg 98 C\n'
          '3083 EK Rotterdam\n'
          'KvK: 74389734\n'
          'E-mail: info@klantio.com\n\n'
          'Komen we er samen niet uit? Dan heb je altijd het recht om een klacht in te dienen bij de toezichthouder: de Autoriteit Persoonsgegevens (www.autoriteitpersoonsgegevens.nl).',
    ),
  ],
);
