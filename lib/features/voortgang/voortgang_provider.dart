export '../../shared/providers/auth_provider.dart' show mijnProfielProvider;

// Historische lokale groepering van skill-keys.
//
// LET OP: deze constanten worden NIET meer gebruikt om Examenadvies of de
// CBR-radar op "Mijn voortgang" te voeden. Dat gebeurt sinds de canonical-
// refactor uitsluitend via `examenadviesProvider` →
// `ExamenadviesData.categorieen` (Postgres RPC `rpc_get_examenadvies`).
//
// Ze blijven staan als:
//  - Referentie voor code die skill-key labels wil tonen zonder een
//    RPC-aanroep (bv. losse skill-key in de tijdlijn).
//  - Documentatie van de historische 6 categorienamen (parallel aan de
//    canonieke lijst in `examenVaardigheidCategorieen`).
//
// Geen nieuwe consumer mag hierop een parallelle examenadvies-formule
// bouwen. Zie `Klantio-Knowledge/02 - FEATURES/Examenadvies.md`.

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
