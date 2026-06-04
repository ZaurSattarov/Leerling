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

const emptyExamenadvies = ExamenadviesData(
  score: 0,
  status: 'Nog onvoldoende data',
  uitleg:
      'Er zijn nog geen afgeronde lessen met evaluatie. Volg meer lessen zodat je instructeur beoordelingen kan invullen.',
  sterkePunten: [],
  nogOefenen: [],
  resterendeLessen: 'Volg eerst meer lessen voor een advies',
  gebaseerdOp: [],
  scoreOnderdelen: [
    ScoreOnderdeel(
      naam: 'Gevolgde lessen',
      score: null,
      gewicht: 0.40,
      teltMee: false,
      scoreLabel: 'Nog onvoldoende data',
      uitleg: 'Aantal gevolgde lessen ten opzichte van je lespakket.',
    ),
    ScoreOnderdeel(
      naam: 'Vaardigheidsscores',
      score: null,
      gewicht: 0.30,
      teltMee: false,
      scoreLabel: 'Nog onvoldoende data',
      uitleg: 'Gemiddelde van beoordeelde vaardigheden per les.',
    ),
    ScoreOnderdeel(
      naam: 'Competenties per les',
      score: null,
      gewicht: 0.15,
      teltMee: false,
      scoreLabel: 'Nog onvoldoende data',
      uitleg: 'Competentiescores uit zichtbare afgeronde lessen.',
    ),
    ScoreOnderdeel(
      naam: 'Beoordelingen',
      score: null,
      gewicht: 0.15,
      teltMee: false,
      scoreLabel: 'Nog onvoldoende data',
      uitleg: 'Gemiddelde beoordeling van afgeronde lessen.',
    ),
  ],
);
