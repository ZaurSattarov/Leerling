/// Onderwerpen uit het centrale voorkeurencontract v2. Codes zijn uitsluitend
/// opslagkeys; de interface toont Nederlandse titels en omschrijvingen.
class LeerlingEmailPreferenceToggle {
  final String topicKey;
  final String group;
  final String title;
  final String subtitle;

  const LeerlingEmailPreferenceToggle(
    this.topicKey,
    this.group,
    this.title,
    this.subtitle,
  );
}

const leerlingEmailPreferenceToggles = <LeerlingEmailPreferenceToggle>[
  LeerlingEmailPreferenceToggle('L07', 'Rijlessen', 'Rijles ingepland',
      'Als je instructeur een rijles voor je inplant.'),
  LeerlingEmailPreferenceToggle('L08', 'Rijlessen', 'Rijles verplaatst',
      'Als de datum of tijd van je rijles verandert.'),
  LeerlingEmailPreferenceToggle('L09', 'Rijlessen', 'Rijleslocatie gewijzigd',
      'Als de ophaallocatie van je rijles verandert.'),
  LeerlingEmailPreferenceToggle('L10', 'Rijlessen', 'Rijles geannuleerd',
      'Als een geplande rijles niet doorgaat.'),
  LeerlingEmailPreferenceToggle(
      'L13',
      'Rijlessen',
      'Andere instructeur toegewezen',
      'Als je rijles door een andere instructeur wordt gegeven.'),
  LeerlingEmailPreferenceToggle('L14', 'Rijlessen', 'Rijles afgerond',
      'Als je instructeur je rijles als afgerond registreert.'),
  LeerlingEmailPreferenceToggle('L19', 'Lespakketten', 'Lespakket bijna op',
      'Als je lespakket bijna is verbruikt.'),
  LeerlingEmailPreferenceToggle('L20', 'Lespakketten', 'Lespakket op',
      'Als je geen tegoed meer hebt in je lespakket.'),
  LeerlingEmailPreferenceToggle(
      'L16',
      'Voortgang',
      'Nieuwe lesevaluatie beschikbaar',
      'Als je instructeur een nieuwe evaluatie met je deelt.'),
  LeerlingEmailPreferenceToggle('L22', 'Examens', 'Praktijkexamen ingepland',
      'Als je instructeur je praktijkexamen inplant.'),
  LeerlingEmailPreferenceToggle('L23', 'Examens', 'Praktijkexamen gewijzigd',
      'Als de planning of locatie van je praktijkexamen verandert.'),
  LeerlingEmailPreferenceToggle('L25', 'Examens', 'Examenresultaat beschikbaar',
      'Als je instructeur je examenresultaat publiceert.'),
  LeerlingEmailPreferenceToggle(
      'L26',
      'Examens',
      'Geslaagd voor praktijkexamen',
      'Een felicitatie als je geslaagd bent voor je praktijkexamen.'),
];
