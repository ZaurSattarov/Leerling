import 'legal_document_content.dart';

// Juridisch concept — vóór publicatie juridisch laten controleren.
const termsConditionsNl = LegalDocumentContent(
  eyebrow: 'JURIDISCH',
  title: 'Algemene voorwaarden',
  version: '1.0',
  effectiveDate: 'Nog vast te stellen',
  sections: [
    LegalSectionContent(
      title: 'Belangrijke scheiding',
      body:
          'Dit document is een conceptstructuur. De definitieve rolverdeling tussen softwareplatform, rijschool en eventuele betaaldienstverlener moet juridisch worden vastgesteld.',
    ),
    LegalSectionContent(
      title: 'Rol van de app',
      body:
          'Nog juridisch te bevestigen. Functioneel biedt de app een platform voor leerlinggegevens, planning, voortgang, facturen, meldingen en communicatie met de gekoppelde rijschool.',
    ),
    LegalSectionContent(
      title: 'Rol van de rijschool',
      body:
          'Nog juridisch te bevestigen. De rijschool levert en beheert de rijschoolinhoudelijke gegevens die in de app worden getoond.',
    ),
    LegalSectionContent(
      title: 'Account en beveiliging',
      body:
          'Nog aan te vullen: regels voor veilig accountgebruik, wachtwoordreset, toegang en misbruik.',
    ),
    LegalSectionContent(
      title: 'Facturen en betalingen',
      body:
          'Nog aan te vullen: betaalproces, eventuele betaaldienstverlener en verantwoordelijkheden rond facturen.',
    ),
    LegalSectionContent(
      title: 'Onderhoud en beschikbaarheid',
      body:
          'Nog aan te vullen: onderhoud, storingen, wijzigingen en communicatie daarover.',
    ),
    LegalSectionContent(
      title: 'Klachten en contact',
      body:
          'Nog aan te vullen: contactgegevens, klachtenroute, toepasselijk recht en versiebeheer.',
    ),
  ],
);
