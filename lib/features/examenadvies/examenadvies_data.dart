class ExamenadviesData {
  final int score;
  final String status;
  final String uitleg;
  final List<String> sterkePunten;
  final List<String> nogOefenen;
  final String resterendeLessen;
  final List<String> gebaseerdOp;
  final List<ScoreOnderdeel> scoreOnderdelen;

  const ExamenadviesData({
    required this.score,
    required this.status,
    required this.uitleg,
    required this.sterkePunten,
    required this.nogOefenen,
    required this.resterendeLessen,
    required this.gebaseerdOp,
    required this.scoreOnderdelen,
  });
}

class ScoreOnderdeel {
  final String naam;
  final double? score;
  final double gewicht;
  final bool teltMee;
  final String uitleg;
  final String scoreLabel;

  const ScoreOnderdeel({
    required this.naam,
    required this.score,
    required this.gewicht,
    required this.teltMee,
    required this.uitleg,
    required this.scoreLabel,
  });
}

const mockExamenadvies = ExamenadviesData(
  score: 68,
  status: 'Goed op weg',
  uitleg:
      'Je basisvaardigheden worden steeds stabieler. De score is nog geen examenadvies omdat zelfstandig rijden, kijkgedrag en rust bij drukke kruispunten nog wisselend zijn.',
  sterkePunten: [
    'Je voertuigbeheersing wordt soepeler.',
    'Rotondes gaan duidelijk beter dan vorige maand.',
    'Je herstelt sneller na kleine fouten.',
  ],
  nogOefenen: [
    'Zelfstandig routekeuzes maken zonder hulp.',
    'Vaker vooruit kijken bij kruispunten.',
    'Dode hoek consequent controleren.',
    'Rust bewaren bij druk verkeer.',
  ],
  resterendeLessen: 'Nog ongeveer 8-10 lessen tot examenadvies',
  gebaseerdOp: [
    'Gevolgde lessen',
    'Vaardigheidsscores',
    'Instructeur feedback',
    'Consistentie',
  ],
  scoreOnderdelen: [
    ScoreOnderdeel(
      naam: 'Gevolgde lessen',
      score: 68,
      gewicht: 0.40,
      teltMee: true,
      scoreLabel: '68% voortgang',
      uitleg: 'Aantal gevolgde lessen ten opzichte van je lespakket.',
    ),
    ScoreOnderdeel(
      naam: 'Vaardigheidsscores',
      score: 62,
      gewicht: 0.30,
      teltMee: true,
      scoreLabel: '62% gemiddeld',
      uitleg: 'Gemiddelde van beoordeelde CBR-achtige vaardigheden.',
    ),
    ScoreOnderdeel(
      naam: 'Competenties per les',
      score: null,
      gewicht: 0.15,
      teltMee: false,
      scoreLabel: 'Nog onvoldoende data',
      uitleg: 'Beschikbare onderdelen tellen tijdelijk zwaarder mee.',
    ),
    ScoreOnderdeel(
      naam: 'Beoordelingen',
      score: 80,
      gewicht: 0.15,
      teltMee: true,
      scoreLabel: '80% gemiddeld',
      uitleg: 'Gemiddelde beoordeling van zichtbare afgeronde lessen.',
    ),
  ],
);
