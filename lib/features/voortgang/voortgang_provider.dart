export '../../shared/providers/auth_provider.dart' show mijnProfielProvider;

const Map<String, List<String>> vaardighedenCategorieen = {
  'Voertuigbeheersing': [
    'stuurcontrole',
    'gas_rem_koppeling',
    'schakelen',
    'optrekken_remmen',
    'voertuig_controle',
  ],
  'Observatie': [
    'spiegelgebruik',
    'dode_hoek',
    'reactie_omgeving',
    'volgafstand',
    'signalen',
  ],
  'Manoeuvres': [
    'keren',
    'achteruit_inparkeren',
    'parallel_parkeren',
    'invoegen_uitvoegen',
    'bochten',
  ],
  'Verkeer': [
    'voorrang',
    'kruispunten',
    'rotondes',
    'bebording',
    'rijstroken',
  ],
  'Wegpositie': [
    'rijbaan_positie',
    'snelheidsaanpassing',
    'inhalen',
    'rechts_houden',
    'zijdelingse_afstand',
  ],
  'Gedrag': [
    'zelfstandig_rijden',
    'stressbeheersing',
    'anticiperen',
    'richtingaanwijzer',
    'algehele_ervaring',
  ],
};

class CbrCompetentie {
  final String naam;
  final List<String> vaardigheidKeys;
  final String uitlegSterk;
  final String uitlegGoedOpWeg;
  final String uitlegNogOefenen;

  const CbrCompetentie({
    required this.naam,
    required this.vaardigheidKeys,
    required this.uitlegSterk,
    required this.uitlegGoedOpWeg,
    required this.uitlegNogOefenen,
  });

  String uitlegVoor(double percentage) {
    if (percentage >= 0.8) return uitlegSterk;
    if (percentage >= 0.5) return uitlegGoedOpWeg;
    return uitlegNogOefenen;
  }

  String statusVoor(double percentage) {
    if (percentage >= 0.8) return 'Sterk';
    if (percentage >= 0.5) return 'Goed op weg';
    return 'Nog oefenen';
  }
}

const List<CbrCompetentie> cbrCompetenties = [
  CbrCompetentie(
    naam: 'Voertuigbeheersing',
    vaardigheidKeys: [
      'stuurcontrole',
      'gas_rem_koppeling',
      'schakelen',
      'optrekken_remmen',
      'voertuig_controle',
    ],
    uitlegSterk: 'Je bedient de auto rustig en gecontroleerd.',
    uitlegGoedOpWeg: 'Je basis is stabiel, blijf werken aan soepel tempo.',
    uitlegNogOefenen: 'Focus op controle over sturen, remmen en schakelen.',
  ),
  CbrCompetentie(
    naam: 'Kijkgedrag',
    vaardigheidKeys: [
      'spiegelgebruik',
      'dode_hoek',
      'reactie_omgeving',
      'volgafstand',
      'signalen',
    ],
    uitlegSterk: 'Je kijkt actief vooruit en gebruikt spiegels consequent.',
    uitlegGoedOpWeg: 'Je kijkt steeds beter, maar nog niet altijd vroeg genoeg.',
    uitlegNogOefenen: 'Oefen vooruit kijken, spiegels en dode hoek als vaste routine.',
  ),
  CbrCompetentie(
    naam: 'Verkeersinzicht',
    vaardigheidKeys: [
      'voorrang',
      'kruispunten',
      'rotondes',
      'bebording',
      'rijstroken',
      'anticiperen',
    ],
    uitlegSterk: 'Je leest verkeerssituaties goed en anticipeert op tijd.',
    uitlegGoedOpWeg: 'Je begrijpt situaties beter, blijf keuzes eerder maken.',
    uitlegNogOefenen: 'Werk aan voorrang, borden en drukke kruispunten.',
  ),
  CbrCompetentie(
    naam: 'Bijzondere verrichtingen',
    vaardigheidKeys: [
      'keren',
      'achteruit_inparkeren',
      'parallel_parkeren',
      'invoegen_uitvoegen',
      'bochten',
    ],
    uitlegSterk: 'Je voert verrichtingen beheerst en overzichtelijk uit.',
    uitlegGoedOpWeg: 'De stappen zitten erin, oefen nog op rust en precisie.',
    uitlegNogOefenen: 'Oefen parkeren, keren en controle rondom de auto.',
  ),
  CbrCompetentie(
    naam: 'Zelfstandig rijden',
    vaardigheidKeys: [
      'zelfstandig_rijden',
      'rijbaan_positie',
      'snelheidsaanpassing',
      'inhalen',
      'rechts_houden',
      'zijdelingse_afstand',
    ],
    uitlegSterk: 'Je rijdt zelfstandig met duidelijke positie en tempo.',
    uitlegGoedOpWeg: 'Je wordt zelfstandiger, maar hebt soms nog bevestiging nodig.',
    uitlegNogOefenen: 'Focus op zelf keuzes maken, positie en snelheid.',
  ),
  CbrCompetentie(
    naam: 'Examenvoorbereiding',
    vaardigheidKeys: [
      'stressbeheersing',
      'richtingaanwijzer',
      'algehele_ervaring',
      'anticiperen',
      'zelfstandig_rijden',
    ],
    uitlegSterk: 'Je rijdt consistent genoeg voor examenvoorbereiding.',
    uitlegGoedOpWeg: 'Je komt dichterbij, blijf werken aan rust en consistentie.',
    uitlegNogOefenen: 'Werk aan stress, zelfstandigheid en vaste routines.',
  ),
];

const Map<String, String> vaardighedenLabels = {
  'stuurcontrole': 'Stuurcontrole',
  'gas_rem_koppeling': 'Gas / rem / koppeling',
  'schakelen': 'Schakelen',
  'optrekken_remmen': 'Optrekken & remmen',
  'voertuig_controle': 'Voertuig controle',
  'spiegelgebruik': 'Spiegelgebruik',
  'dode_hoek': 'Dode hoek',
  'reactie_omgeving': 'Reactie op omgeving',
  'volgafstand': 'Volgafstand',
  'signalen': 'Signalen',
  'keren': 'Keren',
  'achteruit_inparkeren': 'Achteruit inparkeren',
  'parallel_parkeren': 'Parallel parkeren',
  'invoegen_uitvoegen': 'Invoegen / uitvoegen',
  'bochten': 'Bochten',
  'voorrang': 'Voorrang',
  'kruispunten': 'Kruispunten',
  'rotondes': 'Rotondes',
  'bebording': 'Bebording',
  'rijstroken': 'Rijstroken',
  'rijbaan_positie': 'Rijbaan positie',
  'snelheidsaanpassing': 'Snelheidsaanpassing',
  'inhalen': 'Inhalen',
  'rechts_houden': 'Rechts houden',
  'zijdelingse_afstand': 'Zijdelingse afstand',
  'zelfstandig_rijden': 'Zelfstandig rijden',
  'stressbeheersing': 'Stressbeheersing',
  'anticiperen': 'Anticiperen',
  'richtingaanwijzer': 'Richtingaanwijzer',
  'algehele_ervaring': 'Algehele ervaring',
};
