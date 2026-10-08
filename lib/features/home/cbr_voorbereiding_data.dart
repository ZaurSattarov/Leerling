/// Statische examen-voorbereidingsinhoud (CBR "voorbereidings- en
/// controlehandelingen", Rijbewijs B) voor de Home-carousel. Puur
/// leerinhoud: geen databron, geen rechten, geen Solo/Team-afhankelijkheid.
library;

class CbrVraag {
  final String vraag;
  final String antwoord;

  const CbrVraag(this.vraag, this.antwoord);
}

class CbrCategorie {
  final String titel;

  /// Asset-pad van de achtergrondfoto (Nederlandse locatie).
  final String foto;
  final List<CbrVraag> vragen;

  const CbrCategorie({
    required this.titel,
    required this.foto,
    required this.vragen,
  });
}

const _banden = 'assets/images/home_carousel/banden.jpg';
const _motorkap = 'assets/images/home_carousel/motorkap.jpg';
const _verlichting = 'assets/images/home_carousel/verlichting.jpg';
const _dashboard = 'assets/images/home_carousel/dashboard.jpg';
const _spiegels = 'assets/images/home_carousel/spiegels.jpg';

const _rijbewijs = 'assets/images/home_carousel/rijbewijs.jpg';

const cbrCategorieen = <CbrCategorie>[
  CbrCategorie(
    titel: 'Banden en wielen',
    foto: _banden,
    vragen: [
      CbrVraag(
        'Wat is de minimale wettelijke profieldiepte van een autoband?',
        '1,6 millimeter. Voor winterbanden en een veilig advies bij '
            'vervanging wordt minimaal 4,0 millimeter aangeraden.',
      ),
      CbrVraag(
        'Hoe controleer je de profieldiepte zonder meetlint?',
        'Via de slijtage-indicatoren (TWI-blokjes) in de hoofdgroeven van de '
            'band. Ligt het loopvlak gelijk met deze blokjes, dan is de band '
            'versleten.',
      ),
      CbrVraag(
        'Hoe controleer je de bandenspanning en waar vind je de juiste waarde?',
        'Meet met een bandenspanningsmeter bij koude banden. De juiste '
            'waarde staat in het instructieboekje, op een sticker in de '
            'deurstijl van de bestuurder of aan de binnenkant van het '
            'tankklepje.',
      ),
      CbrVraag(
        'Wat zijn de risico\'s van een te lage bandenspanning?',
        'Een langere remweg, slechtere wegligging en stuurgedrag, hoger '
            'brandstofverbruik en meer kans op een klapband door '
            'oververhitting.',
      ),
      CbrVraag(
        'Waar let je nog meer op bij de controle van de banden?',
        'Op beschadigingen aan de wang (scheuren of bulten), ingereden '
            'spijkers of steentjes, een gelijkmatig slijtagepatroon en het '
            'ventieldopje (houdt vuil en vocht buiten).',
      ),
      CbrVraag(
        'Wat doe je bij een lekke band en wat vind je in de auto?',
        'Afhankelijk van de auto: een reservewiel (thuiskomer of volwaardig) '
            'met krik en wielmoersleutel, of een bandenreparatieset '
            '(afdichtmiddel en compressor).',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Onder de motorkap',
    foto: _motorkap,
    vragen: [
      CbrVraag(
        'Hoe controleer en peil je de motorolie?',
        'Zet de auto waterpas, met een koude motor (of minstens 10 minuten '
            'uit). Trek de peilstok eruit en veeg hem schoon. Duw hem '
            'volledig terug en trek hem er weer uit. Het oliepeil moet '
            'tussen MIN en MAX staan.',
      ),
      CbrVraag(
        'Waar vul je motorolie bij en welke olie moet erin?',
        'Bij de vuldop bovenop het motorblok. Welke olie (bijv. 5W-30) staat '
            'in het onderhoudsboekje. Altijd in kleine porties bijvullen.',
      ),
      CbrVraag(
        'Waar zit het koelvloeistofreservoir en hoe controleer je dit?',
        'Het doorschijnende expansievat met een waarschuwingssymbool. Het '
            'niveau moet tussen MIN en MAX staan. Nooit opendraaien bij een '
            'warme motor: er staat hoge druk op en de vloeistof is kokend '
            'heet.',
      ),
      CbrVraag(
        'Waar zit het ruitensproeiervloeistofreservoir?',
        'Onder de dop met het ruitenwisser-icoontje (vaak blauw of zwart). '
            'Het reservoir heeft geen strikt maximum en mag tot de rand '
            'worden bijgevuld (in de winter met antivries).',
      ),
      CbrVraag(
        'Waar zit de remvloeistof en wat betekent een laag peil?',
        'Een doorschijnend reservoir (vaak met een geel rond symbool) tegen '
            'het schutbord. Het niveau moet tussen MIN en MAX staan. Een '
            'daling duidt op versleten remblokken of een lekkage. Niet '
            'zomaar bijvullen zonder de oorzaak te controleren.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Verlichting en buitenkant',
    foto: _verlichting,
    vragen: [
      CbrVraag(
        'Wanneer mag je het mistachterlicht aanzetten?',
        'Alleen bij mist of sneeuwval met minder dan 50 meter zicht. Bij '
            'zware regen nooit: het felle rode licht verblindt achterliggers '
            'door reflectie op het natte wegdek.',
      ),
      CbrVraag(
        'Wanneer mag je de mistlampen aan de voorzijde gebruiken?',
        'Bij mist, sneeuw of zware regenval waardoor het zicht ernstig '
            'wordt belemmerd (minder dan 200 meter).',
      ),
      CbrVraag(
        'Wat controleer je aan de verlichting rondom?',
        'Of de glazen schoon, heel en niet beslagen zijn en of alles '
            'werkt: dagrijverlichting, dimlicht, groot licht, '
            'richtingaanwijzers, remlichten en kentekenverlichting.',
      ),
      CbrVraag(
        'Wat controleer je aan de ruitenwissers?',
        'Of het rubber soepel is, niet gescheurd of uitgedroogd, en of ze '
            'de ruit streeploos en geruisloos schoonvegen.',
      ),
      CbrVraag(
        'Wat controleer je aan de kentekenplaten?',
        'Of ze schoon, goed leesbaar en stevig bevestigd zijn, zowel voor '
            'als achter.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Dashboard en controlelampjes',
    foto: _dashboard,
    vragen: [
      CbrVraag(
        'Wat is het verschil tussen een rood en een oranje dashboardlampje?',
        'Rood: direct actie nodig. Zo snel mogelijk veilig stoppen, motor '
            'uit en hulp inschakelen. Oranje of geel: waarschuwing, er is '
            'een storing die aandacht nodig heeft. Je kunt meestal '
            'doorrijden naar een veilige plek of garage.',
      ),
      CbrVraag(
        'Welke rode waarschuwingslampjes moet je kennen?',
        'Oliedruk (direct stoppen), koelvloeistoftemperatuur (oververhit), '
            'remsysteem of handrem, accu of dynamo (laadt niet bij) en '
            'veiligheidsgordel of portieren open.',
      ),
      CbrVraag(
        'Wat betekent het blauwe controlelampje?',
        'Het grote licht staat ingeschakeld.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Zicht en afstelling',
    foto: _spiegels,
    vragen: [
      CbrVraag(
        'Hoe stel je de binnenspiegel correct af?',
        'Met je rechterhand aan de spiegel, in je normale zithouding. Je '
            'moet de hele achterruit kunnen overzien zonder je hoofd te '
            'draaien of te buigen.',
      ),
      CbrVraag(
        'Hoe stel je de buitenspiegels correct af?',
        'De horizon ligt op ongeveer de helft van de spiegel. Aan de '
            'binnenzijde zie je net een klein stukje van je eigen auto.',
      ),
      CbrVraag(
        'Hoe ontwasem je zo snel mogelijk een beslagen voorruit?',
        'Ventilator op de hoogste stand, luchtstroom volledig op de '
            'voorruit, airco aan, temperatuur warm en de recirculatiestand '
            'uit (verse buitenlucht naar binnen).',
      ),
      CbrVraag(
        'Hoe ontwasem je de achterruit?',
        'Met de knop van de achterruitverwarming (verwarmingsdraden in het '
            'glas).',
      ),
      CbrVraag(
        'Wat is het gevaar van de recirculatiestand te lang aan laten staan?',
        'Er komt geen verse zuurstof binnen, de ruiten beslaan snel door '
            'ademvocht en de bestuurder kan slaperig of vermoeid raken.',
      ),
      CbrVraag(
        'Wat moet er verplicht aanwezig zijn bij een pechsituatie?',
        'Een gevarendriehoek. Veiligheidshesjes voor alle inzittenden zijn '
            'zeer aangeraden en in het buitenland verplicht.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Documenten en kentekenbewijs',
    foto: _rijbewijs,
    vragen: [
      CbrVraag(
        'Welke documenten moet je kunnen tonen als bestuurder?',
        'Een geldig rijbewijs en het kentekenbewijs (kentekencard of '
            'deel IA/IB).',
      ),
      CbrVraag(
        'Wat betekenen de massa-aanduidingen op het kentekenbewijs?',
        'Massa rijklaar: het gewicht van de auto inclusief vloeistoffen, '
            'volle tank en bestuurder (75 kg). Toegestane maximummassa: het '
            'maximumgewicht inclusief bagage en passagiers, dat niet '
            'overschreden mag worden.',
      ),
    ],
  ),
];

/// Motor (rijbewijs A, A1, A2): controle volgens het ezelsbruggetje BRAVOK.
const _mBanden = 'assets/images/home_carousel/m_banden.jpg';
const _mBrandstof = 'assets/images/home_carousel/m_brandstof.jpg';
const _mRemmen = 'assets/images/home_carousel/m_remmen.jpg';
const _mAandrijving = 'assets/images/home_carousel/m_aandrijving.jpg';
const _mVering = 'assets/images/home_carousel/m_vering.jpg';
const _mOlie = 'assets/images/home_carousel/m_olie.jpg';
const _mKoeling = 'assets/images/home_carousel/m_koeling.jpg';
const _mKleding = 'assets/images/home_carousel/m_kleding.jpg';

const cbrMotorCategorieen = <CbrCategorie>[
  CbrCategorie(
    titel: 'Banden',
    foto: _mBanden,
    vragen: [
      CbrVraag(
        'Wat is de minimale wettelijke profieldiepte voor een motorband?',
        '1,0 millimeter (wettelijk minimum in Nederland). Het veilige advies '
            'voor vervanging is minimaal 2,0 mm.',
      ),
      CbrVraag(
        'Hoe controleer je de bandenspanning?',
        'Met een spanningsmeter bij koude banden. De juiste spanning staat in '
            'de handleiding, op een sticker op de achterbrug of onder het '
            'zadel. Die verschilt vaak tussen solo rijden en met '
            'duopassagier of bagage.',
      ),
      CbrVraag(
        'Waar let je nog meer op bij de banden?',
        'Beschadigingen aan het karkas of de wang (scheurtjes, uitdroging, '
            'bulten), ingereden voorwerpen, een gelijkmatig slijtagepatroon '
            '(vierkant afslijten) en het ventieldopje, dat het ventiel '
            'beschermt tegen vuil en centrifugaalkracht bij hoge snelheden.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Brandstof',
    foto: _mBrandstof,
    vragen: [
      CbrVraag(
        'Hoe controleer je de brandstof?',
        'Via de brandstofmeter op het dashboard, het waarschuwingslampje '
            'voor reserve, of visueel in de tank kijken. Bij oudere motoren: '
            'de stand van de benzinekraan (ON, RES, PRI).',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Remmen',
    foto: _mRemmen,
    vragen: [
      CbrVraag(
        'Hoe controleer je de remmen vóór vertrek?',
        'Druktest: knijp de voorremhendel in en trap het achterrempedaal '
            'in. Ze moeten direct stevige weerstand bieden, niet sponsig '
            'aanvoelen en de hendel mag niet tot het stuur in te knijpen '
            'zijn. Test bij het wegrijden kort beide remmen apart.',
      ),
      CbrVraag(
        'Hoe controleer je de remvloeistof?',
        'Via de peilglazen op het stuur (voorrem) en bij het frame of de '
            'achterbrug (achterrem). De motor staat rechtop en het stuur '
            'recht. Het niveau moet tussen LOWER/MIN en UPPER/MAX staan.',
      ),
      CbrVraag(
        'Hoe controleer je de remblokken en remschijven?',
        'Kijk in de remklauw of de slijtagegroeven in de blokken nog '
            'zichtbaar zijn (minimaal 1 à 2 mm remvoering). Controleer de '
            'remschijven op diepe groeven, scheuren of een opstaande '
            'slijtagerand.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Aandrijving',
    foto: _mAandrijving,
    vragen: [
      CbrVraag(
        'Hoe controleer je de kettingspanning?',
        'Duw de ketting in het midden aan de onderkant (tussen voor- en '
            'achtertandwiel) omhoog. De speling moet meestal circa 2 tot 3 '
            'centimeter zijn. De exacte maat staat in het instructieboekje '
            'of op de achterbrug.',
      ),
      CbrVraag(
        'Hoe controleer je de kettingsmering en conditie?',
        'De rollen moeten vettig glanzen (regelmatig insmeren met '
            'kettingspray, bij voorkeur na een rit als de ketting warm is). '
            'Controleer op roest, strakke schakels (knikken) en haaitanden '
            'op het achtertandwiel.',
      ),
      CbrVraag(
        'Wat controleer je bij cardan- of riemaandrijving?',
        'Cardan: olielekkage bij de eindaandrijving. Tandriem: spanning en '
            'scheurtjes, steentjes of ontbrekende tanden.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Vering en vork',
    foto: _mVering,
    vragen: [
      CbrVraag(
        'Hoe controleer je de voorvorkvering?',
        'Knijp de voorrem in en duw de motor een paar keer krachtig in de '
            'voorvork. De vork moet soepel inveren en zonder naschommelen '
            'gedempt terugkomen.',
      ),
      CbrVraag(
        'Waar let je op bij de voorvorkpoten?',
        'De binnenpoten moeten schoon, krasvrij en droog zijn. Er mag geen '
            'olie langs de keerringen lekken: olie kan op de remschijven '
            'terechtkomen, wat levensgevaarlijk is.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Olie en smering',
    foto: _mOlie,
    vragen: [
      CbrVraag(
        'Hoe controleer je de motorolie?',
        'Zet de motor rechtop (waterpas), koud of enkele minuten na het '
            'uitzetten. Lees af via het peilglas onderaan het motorblok of '
            'met de peilstok (uitschroeven, schoonvegen, erin steken zonder '
            'vast te draaien) tussen MIN en MAX.',
      ),
      CbrVraag(
        'Waarom is het oliepeil bij een motor extra kritisch?',
        'Bij de meeste motoren smeert de motorolie niet alleen het '
            'motorblok, maar ook de versnellingsbak en de natte koppeling. '
            'Te weinig olie leidt direct tot ernstige mechanische schade.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Koeling en elektronica',
    foto: _mKoeling,
    vragen: [
      CbrVraag(
        'Hoe controleer je de koelvloeistof?',
        'Controleer het niveau in het expansiereservoir tussen MIN en MAX. '
            'Draai de radiatordop nooit los bij een warme motor: kokende '
            'vloeistof onder druk.',
      ),
      CbrVraag(
        'Wat is het verschil tussen lucht- en vloeistofkoeling?',
        'Vloeistofgekoeld: controleer de radiatorlamellen op vuil, '
            'insecten, steenslag en lekkage. Luchtgekoeld: de koelribben op '
            'de cilinders moeten schoon zijn voor voldoende warmteafvoer.',
      ),
      CbrVraag(
        'Wat controleer je aan de verlichting en signalen?',
        'Dimlicht, groot licht (met het blauwe lampje en de '
            'passeerschakelaar), richtingaanwijzers voor en achter, '
            'kentekenverlichting, claxon en of het remlicht werkt op zowel '
            'de voorremhendel als het achterrempedaal.',
      ),
      CbrVraag(
        'Wat is de dodemansknop (kill switch)?',
        'De rode schakelaar op het stuur om in een noodsituatie de motor '
            'direct uit te schakelen zonder het stuur los te hoeven laten.',
      ),
      CbrVraag(
        'Wat controleer je aan de zijstandaard-beveiliging?',
        'Als de motor in de versnelling wordt gezet terwijl de zijstandaard '
            'nog uitstaat, moet de motor automatisch direct afslaan.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Veiligheidskleding',
    foto: _mKleding,
    vragen: [
      CbrVraag(
        'Waar moet goedgekeurde motorkleding aan voldoen?',
        'Helm: goedgekeurd (ECE-keurmerk, bijv. ECE 22.06), goed passend, '
            'vizier schoon en krasvrij. Jas en broek: slijtvast motorleer of '
            'textiel met CE-protectoren op schouders, ellebogen, rug en '
            'knieën. Handschoenen en laarzen: stevige motorhandschoenen die '
            'de pols bedekken en motorlaarzen of schoenen die de enkels '
            'beschermen.',
      ),
    ],
  ),
];

/// A, A1, A2 = motor; AM = scooter; C/C1(E) = vrachtwagen; D/D1(E) = bus; BE = auto+aanhanger; T = trekker; alles anders (B, ...) = auto.
List<CbrCategorie> cbrCategorieenVoor(String? rijbewijsSoort) {
  switch (rijbewijsSoort?.trim().toUpperCase()) {
    case 'A':
    case 'A1':
    case 'A2':
      return cbrMotorCategorieen;
    case 'AM':
      return cbrScooterCategorieen;
    case 'BE':
      return cbrBeCategorieen;
    case 'T':
      return cbrTrekkerCategorieen;
    case 'C':
    case 'C1':
    case 'CE':
    case 'C1E':
      return cbrVrachtwagenCategorieen;
    case 'D':
    case 'D1':
    case 'DE':
    case 'D1E':
      return cbrBusCategorieen;
    default:
      return cbrCategorieen;
  }
}

/// Scooter / bromfiets (rijbewijs AM): BRAVOK, aangepast voor scooters.
const _sBanden = 'assets/images/home_carousel/s_banden.jpg';
const _sAandrijving = 'assets/images/home_carousel/s_aandrijving.jpg';
const _sVering = 'assets/images/home_carousel/s_vering.jpg';
const _sOlie = 'assets/images/home_carousel/s_olie.jpg';
const _sKoeling = 'assets/images/home_carousel/s_koeling.jpg';
const _sKleding = 'assets/images/home_carousel/s_kleding.jpg';

const cbrScooterCategorieen = <CbrCategorie>[
  CbrCategorie(
    titel: 'Banden en brandstof',
    foto: _sBanden,
    vragen: [
      CbrVraag(
        'Wat is de minimale wettelijke profieldiepte voor een scooterband?',
        '1,0 millimeter. Veilig advies is minimaal 2,0 mm voor voldoende '
            'waterafvoer.',
      ),
      CbrVraag(
        'Hoe controleer je de bandenspanning?',
        'Met een spanningsmeter bij koude banden. De juiste spanning staat '
            'in het instructieboekje of op een sticker onder de buddyseat '
            '(meestal rond 2,0 bar voor en 2,2 bar achter).',
      ),
      CbrVraag(
        'Waar let je nog meer op bij de banden?',
        'Beschadigingen aan de wangen (scheurtjes, bulten), ingereden glas '
            'of spijkers, slijtage-indicatoren (TWI-blokjes) en het '
            'ventieldopje, dat vuil buiten houdt.',
      ),
      CbrVraag(
        'Hoe controleer je het brandstofpeil of de accustatus?',
        'Via de brandstofmeter of het accudisplay op het dashboard vóór het '
            'starten. Bij tweetaktscooters (oudere modellen) controleer je '
            'ook het aparte 2-takt oliepeil.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Remmen en aandrijving',
    foto: _sAandrijving,
    vragen: [
      CbrVraag(
        'Hoe controleer je de werking van de remmen vóór vertrek?',
        'Druktest: knijp de linker remhendel (achterrem) en de rechter '
            'remhendel (voorrem) in. Ze moeten stevig aanvoelen, mogen niet '
            'tot het handvat worden ingeknepen en niet verend of sponsig '
            'zijn. Probeer direct na het wegrijden beide remmen kort '
            'afzonderlijk.',
      ),
      CbrVraag(
        'Hoe controleer je de remvloeistof (bij schijfremmen)?',
        'Via het peilglas op het stuur of rempotje. Het stuur staat recht '
            'en de vloeistof moet boven het minimumpeil staan.',
      ),
      CbrVraag(
        'Hoe controleer je een trommelrem (op het achterwiel)?',
        'Controleer of er voldoende stelruimte over is bij de stelbout of '
            'kabel bij het achterwiel en of de rem niet te diep doortrekt.',
      ),
      CbrVraag(
        'Hoe zit de aandrijving bij een scooter en wat controleer je?',
        'Een scooter heeft een automatische transmissie (variateur en '
            'V-snaar in de carterkap). Controleer visueel of het carterdeksel '
            'heel en droog is (geen olielekkage bij de vertanding of '
            'achteras) en of het achterwiel soepel en spelingsvrij draait.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Vering en vork',
    foto: _sVering,
    vragen: [
      CbrVraag(
        'Hoe controleer je de voorvorkvering?',
        'Knijp de voorrem in en duw het stuur een paar keer stevig naar '
            'beneden. De vork moet soepel inveren en zonder te stuiteren '
            'terugkomen.',
      ),
      CbrVraag(
        'Waar let je op bij de voorvorkpoten?',
        'Controleer of de poten schoon zijn en of er geen olie langs de '
            'vorkkeerringen lekt. Lekkende vorkolie kan op de remschijf '
            'komen.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Olie en onderhoud',
    foto: _sOlie,
    vragen: [
      CbrVraag(
        'Hoe controleer je de motorolie (bij 4-takt)?',
        'Zet de scooter op de middenbok op een vlakke ondergrond. Schroef '
            'de oliepeilstok bij het carter uit, veeg hem schoon, steek hem '
            'erin (bij de meeste modellen zonder vast te draaien) en lees af '
            'tussen MIN en MAX.',
      ),
      CbrVraag(
        'Wat is het verschil tussen olie bij 2-takt en 4-takt?',
        'Bij 4-takt zit de olie in het carter en moet je regelmatig peilen. '
            'Bij 2-takt wordt olie gemengd met benzine: vul het '
            '2-takt oliereservoir regelmatig bij. Een rood olielampje op '
            'het dashboard waarschuwt als het bijna leeg is.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Koelvloeistof',
    foto: _sKoeling,
    vragen: [
      CbrVraag(
        'Hoe controleer je de koelvloeistof (bij watergekoelde scooters)?',
        'Controleer het niveau in het expansievaatje (vaak zichtbaar achter '
            'een kapje of onder het zadel). Open het nooit als de motor '
            'warm is.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Verlichting, kenteken en helm',
    foto: _sKleding,
    vragen: [
      CbrVraag(
        'Wat controleer je aan de verlichting?',
        'Dimlicht, groot licht (indien aanwezig), achterlicht, '
            'richtingaanwijzers voor en achter, claxon en of het remlicht '
            'brandt bij zowel de linker- als de rechterremhendel.',
      ),
      CbrVraag(
        'Waar let je op bij de spiegels?',
        'De linker buitenspiegel (en eventueel de rechter) moet schoon zijn '
            'en zo afgesteld dat je rechtop zittend goed naar achteren kunt '
            'kijken zonder je schouder mee te draaien.',
      ),
      CbrVraag(
        'Wat moet je weten over de kentekenplaat en constructiesnelheid?',
        'De gele kentekenplaat (45 km/u brommer) of blauwe (25 km/u '
            'snorfiets) moet schoon, heel en goed leesbaar zijn. De scooter '
            'mag de constructiesnelheid niet overschrijden: opvoeren geeft '
            'WOK-risico.',
      ),
      CbrVraag(
        'Wat zijn de eisen voor de helm?',
        'Verplicht een goedgekeurde helm met ECE-keurmerk (herkenbaar aan '
            'de E-cirkel op het label aan de binnenkant), een goed passende '
            'maat en een stevig vastgeklikte kinband. Handschoenen en '
            'oogbescherming worden sterk aanbevolen.',
      ),
    ],
  ),
];

/// Vrachtwagen (rijbewijs C, C1, CE, C1E).
const cbrVrachtwagenCategorieen = <CbrCategorie>[
  CbrCategorie(
    titel: 'Banden, velgen en assen',
    foto: 'assets/images/home_carousel/v_banden.jpg',
    vragen: [
      CbrVraag(
        'Wat is de minimale wettelijke profieldiepte voor '
            'vrachtwagenbanden?',
        '1,6 millimeter over de gehele omtrek in de hoofdgroeven (net als '
            'bij personenauto\'s).',
      ),
      CbrVraag(
        'Wat controleer je bij dubbellucht (dubbele achterbanden)?',
        'Er mogen geen stenen of voorwerpen klem zitten tussen de twee '
            'banden (gevaar voor losschieten of een klapband). De banden '
            'mogen elkaar niet raken: dat duidt op ernstige onderspanning of '
            'overbelasting.',
      ),
      CbrVraag(
        'Wat controleer je aan de wielbouten en wielmoeren?',
        'Of alle moeren aanwezig zijn en vastzitten. Let op roestsporen die '
            'straalsgewijs vanaf de moer lopen (loszittende wielmoeren) of op '
            'de stand van eventuele wielmoerindicatoren (pijltjes).',
      ),
      CbrVraag(
        'Wat zijn de gevaren van een verkeerde bandenspanning bij een '
            'vrachtwagen?',
        'Oververhitting met direct risico op een klapband of bandenbrand, '
            'aanzienlijk hoger brandstofverbruik, ongelijkmatige '
            'bandenslijtage en een langere remweg met zware lading.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Luchtveer- en remsysteem',
    foto: 'assets/images/home_carousel/v_lucht.jpg',
    vragen: [
      CbrVraag(
        'Hoe werkt het remsysteem van een vrachtwagen?',
        'Het is een pneumatisch remsysteem (luchtdrukremsysteem) met '
            'veerremcilinders voor de parkeerrem.',
      ),
      CbrVraag(
        'Hoe controleer je het luchtdruksysteem vóór vertrek?',
        'Zet het contact aan en lees de manometers op het dashboard af '
            '(meestal circuit 1 en 2). De bedrijfsdruk ligt tussen circa 8 en '
            '12 bar. Het lage-druk waarschuwingslampje of geluidssignaal moet '
            'uitgaan zodra de druk boven circa 5 à 6 bar komt.',
      ),
      CbrVraag(
        'Hoe doe je een lektest (drukverliestest)?',
        'Zet de motor af, handrem los (met wielkeggen indien nodig) en houd '
            'het rempedaal stevig ingetrapt. De druk mag binnen 1 minuut niet '
            'merkbaar dalen (maximaal toelaatbaar drukverlies volgens de '
            'fabrieksopgave).',
      ),
      CbrVraag(
        'Wat is de functie van de luchtdroger en het vloeistofaftappen?',
        'De luchtdroger haalt condensvocht uit de samengeperste lucht, '
            'zodat leidingen en ventielen in de winter niet bevriezen of '
            'gaan roesten.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Cabine, zicht en spiegels',
    foto: 'assets/images/home_carousel/v_cabine.jpg',
    vragen: [
      CbrVraag(
        'Welke spiegels of camerasystemen zijn verplicht en hoe moeten ze '
            'staan?',
        'Klasse I: binnenspiegel (indien doorkijk mogelijk). Klasse II: '
            'hoofdbuitenspiegels links en rechts (zicht naar achteren langs '
            'de opbouw). Klasse III: breedtehoekspiegels links en rechts '
            '(zicht op de rijstrook ernaast). Klasse IV en V: trottoirspiegel '
            'en frontspiegel (of een goedgekeurd camerasysteem) om '
            'voetgangers en fietsers direct voor en rechts naast de cabine '
            'te zien.',
      ),
      CbrVraag(
        'Hoe controleer je de cabinevergrendeling?',
        'Controleer of de kantelbare cabine mechanisch vergrendeld is en of '
            'het waarschuwingslampje van de cabinevergrendeling op het '
            'dashboard uit is.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Onder de motorkap',
    foto: 'assets/images/home_carousel/v_motorkap.jpg',
    vragen: [
      CbrVraag(
        'Hoe controleer je vloeistoffen bij een moderne vrachtwagen?',
        'Veel moderne trucks tonen het motoroliepeil en het '
            'koelvloeistofniveau digitaal in het boordcomputermenu. '
            'Handmatig: peilstok en vulopeningen achter de grille aan de '
            'voorkant (zonder de cabine te kantelen).',
      ),
      CbrVraag(
        'Wat is AdBlue en hoe controleer je het?',
        'Een ureumoplossing die in de uitlaatgassen wordt gespoten om '
            'stikstofoxiden (NOx) af te breken tot stikstof en water. Je leest '
            'het niveau af op de AdBlue-meter op het dashboard. Zonder AdBlue '
            'verlaagt het motormanagement het motorvermogen drastisch.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Carrosserie en lading',
    foto: 'assets/images/home_carousel/v_lading.jpg',
    vragen: [
      CbrVraag(
        'Wat controleer je aan de ladingzekering en opbouw?',
        'Zijn de laaddeuren, laadklep of schuifzeilen goed afgesloten en '
            'vergrendeld? Is de lading vormsluitend geladen of gezekerd met '
            'spanbanden of stuwbalken? Zitten de zijafscherming '
            '(fietsenvangers) en de stootbalk aan de achterzijde deugdelijk '
            'vast?',
      ),
      CbrVraag(
        'Welke maten moet je als chauffeur paraat hebben vóór vertrek?',
        'De hoogte (cruciaal voor viaducten en tunnels, vaak aangegeven met '
            'een sticker in de cabine), breedte, lengte en het totaalgewicht '
            'van de combinatie.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Documenten en tachograaf',
    foto: 'assets/images/home_carousel/v_documenten.jpg',
    vragen: [
      CbrVraag(
        'Welke documenten moet je kunnen overhandigen?',
        'Rijbewijs C met Code 95 (vakbekwaamheid), het kentekenbewijs van '
            'het voertuig, het APK-keuringsrapport en bij goederenvervoer '
            'de vrachtbrief (CMR of AVC).',
      ),
      CbrVraag(
        'Wat moet je weten over de digitale tachograaf?',
        'De bestuurderskaart moet vóór het rijden in sleuf 1 geplaatst '
            'worden en je moet handmatige invoer kunnen doen (bijv. '
            'rusttijd). Rij- en rusttijden: maximaal 4,5 uur rijden, daarna '
            'minimaal 45 minuten pauze (of 15 minuten gevolgd door 30 '
            'minuten).',
      ),
    ],
  ),
];

/// Bus (rijbewijs D, D1, DE, D1E).
const cbrBusCategorieen = <CbrCategorie>[
  CbrCategorie(
    titel: 'Passagiersveiligheid en nooduitgangen',
    foto: 'assets/images/home_carousel/b_veiligheid.jpg',
    vragen: [
      CbrVraag(
        'Waar bevinden zich de nooduitgangen en hoe werken ze?',
        'Nooddeuren ontgrendel je met de rode noodknoppen of hendels bij '
            'de deuren (binnen en buiten). Noodramen en dakluiken open je via '
            'ontgrendelingshendels of sla je in met de noodhamers. Controleer '
            'of alle noodhamers op hun vaste houders aanwezig zijn.',
      ),
      CbrVraag(
        'Wat controleer je aan de veiligheidsuitrusting?',
        'Brandblussers: aanwezig, verzegeld, geldige keuringsdatum en de '
            'drukmeter staat in het groene vlak. Verbandtrommel: aanwezig, '
            'verzegeld of compleet en bereikbaar. Gevarendriehoek en '
            'veiligheidshesjes: aanwezig in het chauffeurscompartiment.',
      ),
      CbrVraag(
        'Wat controleer je bij de passagiersstoelen?',
        'De werking van de veiligheidsgordels (indien aanwezig of '
            'verplicht), of de stoelen stevig verankerd zijn en of het '
            'gangpad vrij is van obstakels.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Deuren en instapsystemen',
    foto: 'assets/images/home_carousel/b_deuren.jpg',
    vragen: [
      CbrVraag(
        'Hoe controleer je de automatische deuren vóór vertrek?',
        'Klembeveiliging: test of de deuren automatisch weer openen zodra '
            'ze weerstand voelen bij het sluiten. Wegrijblokkering: de bus '
            'mag niet kunnen wegrijden zolang een passagiersdeur open is. '
            'Noodbediening: weet waar de noodkranen of ontluchtingsventielen '
            'zitten om de deuren bij stroom- of luchtdrukuitval handmatig '
            'open te duwen.',
      ),
      CbrVraag(
        'Wat controleer je bij de rolstoellift of oprijplaat?',
        'Of de plaat of lift soepel uitschuift en vergrendelt, en of het '
            'signaleringslampje op het dashboard aangeeft dat hij weer veilig '
            'is ingeklapt.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Luchtdruk, remmen en vering',
    foto: 'assets/images/home_carousel/b_lucht.jpg',
    vragen: [
      CbrVraag(
        'Hoe controleer je het luchtdrukremsysteem?',
        'Zet het contact aan en lees de manometers af (circuit 1 en 2; '
            'bedrijfsdruk tussen 8 en 12 bar). Het waarschuwingslampje of de '
            'zoemer voor lage luchtdruk moet uitgaan boven circa 5 à 6 bar. '
            'Lektest: motor uit, parkeerrem los (wielkeggen indien nodig) en '
            'het rempedaal stevig ingetrapt houden om drukverlies te '
            'controleren.',
      ),
      CbrVraag(
        'Wat controleer je aan het niveauregelsysteem (luchtvering en '
            'knielsysteem)?',
        'De bus moet voor het wegrijden op normale rijhoogte staan '
            '(controle via de dashboardindicatie). Controleer ook de '
            'knielfunctie: het laten zakken van de rechterzijde aan de halte '
            'om instappen te vergemakkelijken.',
      ),
      CbrVraag(
        'Wat is de functie van de retarder (hulprem)?',
        'Een slijtagevrije hydrodynamische of elektromagnetische rem op de '
            'aandrijflijn om langdurig af te remmen (bijv. op hellingen of '
            'voor haltes) zonder de bedrijfsremmen te oververhitten.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Spiegels, zicht en interieur',
    foto: 'assets/images/home_carousel/b_spiegels.jpg',
    vragen: [
      CbrVraag(
        'Welke spiegels controleer je en hoe moeten ze staan?',
        'Hoofdbuitenspiegels en breedtehoekspiegels: zicht naar achteren '
            'langs de hele busflank. Trottoir- en vooruitkijkspiegel (of '
            'camerasysteem): zicht op voetgangers en objecten direct voor en '
            'rechts naast het voertuig. Interieurspiegels of -camera\'s: '
            'zicht op het gangpad, de achterbank en de in- en uitstapdeuren, '
            'om te controleren of alle passagiers veilig zitten of staan voor '
            'vertrek.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Banden, velgen en onderstel',
    foto: 'assets/images/home_carousel/b_banden.jpg',
    vragen: [
      CbrVraag(
        'Wat is de minimale wettelijke profieldiepte?',
        '1,6 millimeter over de gehele omtrek in de hoofdgroeven. Het '
            'veiligheidsadvies is aanzienlijk hoger voor passagiersvervoer.',
      ),
      CbrVraag(
        'Wat controleer je aan wielen en dubbellucht?',
        'Geen ingeklemde stenen tussen de dubbele achterwielen. Controleer '
            'de wielmoeren op vaste montage en roestsporen (of de '
            'wielmoerindicatoren) en de wangen op scheuren, bulten en de '
            'juiste bandenspanning (geen overmatige invering).',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Documenten, tachograaf en Code 95',
    foto: 'assets/images/home_carousel/b_documenten.jpg',
    vragen: [
      CbrVraag(
        'Welke documenten moet je als buschauffeur tonen?',
        'Rijbewijs D met geldige Code 95, het kentekenbewijs en APK-rapport '
            'en de vervoersvergunning (bijv. een communautaire vergunning '
            'voor openbaar vervoer of besloten busvervoer).',
      ),
      CbrVraag(
        'Wat moet je weten over de tachograaf en de rijtijden?',
        'Plaats de bestuurderskaart in sleuf 1. Maximaal 4,5 uur '
            'onafgebroken rijden, gevolgd door een onderbreking van minimaal '
            '45 minuten (of een opdeling van 15 minuten gevolgd door '
            'minimaal 30 minuten).',
      ),
    ],
  ),
];

/// Auto met aanhangwagen (rijbewijs BE).
const cbrBeCategorieen = <CbrCategorie>[
  CbrCategorie(
    titel: 'Koppeling, breekkabel en neuswiel',
    foto: 'assets/images/home_carousel/be_koppeling.jpg',
    vragen: [
      CbrVraag(
        'Hoe controleer je of de aanhangwagen correct is aangekoppeld?',
        'De koppelingshendel moet volledig vergrendeld zijn (groene '
            'indicator zichtbaar of klikvergrendeling geborgd). Treftest: '
            'draai met het neuswiel de dissel omhoog. De achterkant van de '
            'trekkende auto moet meeliften; dat bewijst dat de koppeling vast '
            'om de kogel zit en er niet los bovenop rust.',
      ),
      CbrVraag(
        'Wat is de functie van de losbreekreminrichting (breekkabel) en '
            'hoe bevestig je die?',
        'Schiet de aanhangwagen los van de trekhaakkogel, dan trekt deze '
            'staalkabel eerst de handrem van de aanhangwagen maximaal aan en '
            'breekt daarna. Bevestig de kabel rechtstreeks aan een vast oog '
            'of hulpkoppeling aan het chassis of de trekhaakconstructie, '
            'nooit als losse lus alleen om de kogel.',
      ),
      CbrVraag(
        'Wat is het verschil met een ongeremde aanhanger (onder 750 kg)?',
        'Lichte aanhangers zonder eigen rem hebben een hulpkoppeling '
            '(staalkabel of ketting), zodat de aanhangwagen bij losschieten '
            'achter de auto blijft hangen.',
      ),
      CbrVraag(
        'Wat doe je met het neuswiel na het aankoppelen?',
        'Volledig indraaien, de buis maximaal omhoog trekken in de klem, '
            'goed vastdraaien en borgen in de uitsparing, zodat hij tijdens '
            'het rijden niet naar beneden trilt.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Banden, wielen en onderstel',
    foto: 'assets/images/home_carousel/be_banden.jpg',
    vragen: [
      CbrVraag(
        'Wat is de minimale wettelijke profieldiepte voor de '
            'aanhangwagenbanden?',
        '1,6 millimeter over de gehele omtrek in de hoofdgroeven.',
      ),
      CbrVraag(
        'Waar let je specifiek op bij aanhangerbanden?',
        'Droogtescheurtjes en veroudering: aanhangwagens staan vaak lang '
            'stil, dus controleer op uitdroging en de DOT-code (leeftijd van '
            'de band). Bandenspanning: vaak aanzienlijk hoger dan bij de auto '
            '(3,0 tot 4,5 bar bij versterkte C-banden); de juiste spanning '
            'staat op de wang van de band of het typeplaatje. Wielbouten en '
            'lagers: spelingsvrij draaien en geen sporen van loszittende '
            'wielbouten.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Belading, gewichten en kogeldruk',
    foto: 'assets/images/home_carousel/be_belading.jpg',
    vragen: [
      CbrVraag(
        'Wat is kogeldruk en hoe controleer je die?',
        'De neerwaartse kracht die de dissel van de aanhangwagen op de '
            'trekhaakkogel uitoefent. Controleer met een kogeldrukmeter of '
            'een personenweegschaal onder de dissel.',
      ),
      CbrVraag(
        'Wat zijn de risico\'s van een verkeerde kogeldruk?',
        'Te lage (of negatieve) kogeldruk: de achterkant van de auto wordt '
            'opgetild en de aanhangwagen gaat extreem snel slingeren en '
            'scharen (levensgevaarlijk). Te hoge kogeldruk: de achterkant van '
            'de auto zakt te ver door, de voorwielen hebben minder grip '
            '(minder stuur- en remkracht) en de trekhaakconstructie raakt '
            'overbelast.',
      ),
      CbrVraag(
        'Hoe verdeel je de lading in de aanhangwagen?',
        'Het zwaartepunt moet zo laag mogelijk liggen en vlak voor of boven '
            'de as(sen), gelijkmatig verdeeld over links en rechts.',
      ),
      CbrVraag(
        'Hoe zeker je de lading?',
        'Vormsluitend laden, vastzetten met goedgekeurde spanbanden aan de '
            'sjorogen in de bak, of afdekken met een ladingnet of dekzeil '
            'tegen het afwaaien van losse delen.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Kenteken, massa\'s en regels',
    foto: 'assets/images/home_carousel/be_kenteken.jpg',
    vragen: [
      CbrVraag(
        'Welke kentekenplaat hoort op de aanhangwagen?',
        'Boven 750 kg (toegestane maximummassa): een eigen geel kenteken '
            'met een eigen kentekenbewijs. Tot en met 750 kg: een witte '
            'kentekenplaat met exact hetzelfde kenteken als de trekkende '
            'auto.',
      ),
      CbrVraag(
        'Wat betekenen de gegevens op het typeplaatje (dissel of chassis)?',
        'Het chassisnummer (VIN), de toegestane maximummassa van de '
            'aanhanger en de maximale aslasten.',
      ),
      CbrVraag(
        'Wanneer heb je rijbewijs BE nodig in plaats van alleen B?',
        'Zodra de aanhanger een toegestane maximummassa heeft van meer dan '
            '750 kg én het totale maximumgewicht van auto en aanhanger samen '
            'boven 3.500 kg uitkomt (tot maximaal 7.000 kg treingewicht).',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Verlichting en buitenkant',
    foto: 'assets/images/home_carousel/be_verlichting.jpg',
    vragen: [
      CbrVraag(
        'Wat controleer je aan de stekkerverbinding?',
        'Sluit de 7-polige of 13-polige stekker aan, vergrendel de '
            'bajonetsluiting en controleer dat de kabel niet over het wegdek '
            'sleept.',
      ),
      CbrVraag(
        'Welke verlichting en reflectoren zijn verplicht op de aanhanger?',
        'Achterzijde: twee rode driehoekige reflectoren, achterlichten, '
            'remlichten, richtingaanwijzers, kentekenverlichting en '
            'minimaal één mistachterlicht. Zijkanten: ambergele '
            'zijreflectoren en zijmarkeringslichten (bij langere '
            'aanhangers). Voorzijde: twee witte reflectoren (en witte '
            'markeringslichten als de aanhanger breder is dan 2,10 meter).',
      ),
      CbrVraag(
        'Waar let je op bij de buitenspiegels van de auto?',
        'Is de aanhanger breder dan de auto, dan zijn opzetspiegels '
            '(caravanspiegels) verplicht. Je moet langs beide zijden van de '
            'aanhanger naar achteren kunnen kijken en de horizon op de helft '
            'van de spiegel zien.',
      ),
    ],
  ),
];

/// Trekker (rijbewijs T).
const cbrTrekkerCategorieen = <CbrCategorie>[
  CbrCategorie(
    titel: 'Koppeling en werktuigbeveiliging',
    foto: 'assets/images/home_carousel/t_koppeling.jpg',
    vragen: [
      CbrVraag(
        'Hoe controleer je de koppeling en beveiliging vóór vertrek?',
        'Trekhaak of trekoog: controleer of de koppelpen volledig door het '
            'trekoog zit en mechanisch geborgd is met een borgpen (klapspie '
            'of veerstift), zodat de dissel er nooit uit kan springen. '
            'Aftakas (PTO): de beschermkap en beschermbuis moeten heel zijn '
            'en met de borgketting vastzitten aan de trekker of het '
            'werktuig, zodat de beschermhoes niet meedraait. Remleidingen en '
            'verlichting: sluit lucht- of hydraulische remslangen en de '
            'verlichtingskabel aan zonder dat ze over de grond slepen.',
      ),
    ],
  ),
  CbrCategorie(
    titel: 'Banden en breedtemarkering',
    foto: 'assets/images/home_carousel/t_banden.jpg',
    vragen: [
      CbrVraag(
        'Wat zijn de eisen voor spanning en borden op de openbare weg?',
        'Bandenspanning: stem af op de openbare weg (hogere spanning dan op '
            'het land) om oververhitting en slijtage te voorkomen en '
            'controleer op insnijdingen en karkasbeschadigingen. Breedte en '
            'markering: de maximale breedte op de weg is doorgaans 2,55 meter '
            '(tot 3,00 meter voor specifieke landbouwvoertuigen). Steekt het '
            'werktuig zijdelings uit, dan zijn rood-wit gestreepte '
            'breedtemarkeringsborden en breedtelichten verplicht. '
            'Zwaailicht en afgeknotte driehoek: een rood-oranje afgeknotte '
            'driehoek is verplicht achterop; een oranje zwaailamp is '
            'verplicht bij werkzaamheden of bij een breedte van meer dan '
            '2,60 meter.',
      ),
    ],
  ),
];
