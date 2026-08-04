import 'legal_document_content.dart';

// Juridisch concept — vóór publicatie juridisch laten controleren.
const privacyPolicyNl = LegalDocumentContent(
  eyebrow: 'JURIDISCH',
  title: 'Privacybeleid',
  version: '1.0',
  effectiveDate: 'Nog vast te stellen',
  sections: [
    LegalSectionContent(
      title: 'Belangrijk juridisch kader',
      body:
          'Dit in-app document is voorbereid als structuur. De definitieve bedrijfsgegevens, bewaartermijnen, contactgegevens en verwerkers moeten nog worden vastgesteld.',
    ),
    LegalSectionContent(
      title: 'Wie is verantwoordelijk?',
      body:
          'Nog aan te vullen: verantwoordelijke rechtspersoon, vestigingsadres, KvK-nummer en privacycontact.',
    ),
    LegalSectionContent(
      title: 'Welke persoonsgegevens verwerken we?',
      body:
          'De app toont leerlingaccountgegevens, koppeling met de rijschool, naam en contactgegevens, lesplanning, beschikbaarheid, voortgang, examens, facturen, meldingen en profielfoto wanneer die gegevens in de bestaande appbronnen aanwezig zijn.',
    ),
    LegalSectionContent(
      title: 'Waarvoor gebruiken we gegevens?',
      body:
          'Nog juridisch te bevestigen. Functioneel ondersteunt de app rijlesplanning, communicatie met de rijschool, voortgangsinzicht, facturen, meldingen en accountbeheer.',
    ),
    LegalSectionContent(
      title: 'Delen met dienstverleners',
      body:
          'Nog aan te vullen: definitieve lijst van technische dienstverleners en betaal- of notificatiediensten die werkelijk worden gebruikt.',
    ),
    LegalSectionContent(
      title: 'Bewaartermijnen',
      body:
          'Nog aan te vullen: er is in deze fase geen vastgesteld bewaarbeleid aangetroffen.',
    ),
    LegalSectionContent(
      title: 'Rechten en contact',
      body:
          'Nog aan te vullen: proces voor inzage, correctie, verwijdering, klachten en contact met de verantwoordelijke partij.',
    ),
  ],
);
