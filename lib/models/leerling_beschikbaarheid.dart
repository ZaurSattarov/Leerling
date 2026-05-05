class LeerlingBeschikbaarheid {
  final String id;
  final String leerlingId;
  final String instructeurId;
  final int dagVanWeek; // 0 = maandag … 6 = zondag
  final String startTijd; // "HH:MM:SS" (Supabase TIME kolom)
  final String eindTijd;
  final int voorkeurScore; // 1–5

  static const List<String> dagNamen = [
    'Maandag',
    'Dinsdag',
    'Woensdag',
    'Donderdag',
    'Vrijdag',
    'Zaterdag',
    'Zondag',
  ];

  const LeerlingBeschikbaarheid({
    required this.id,
    required this.leerlingId,
    required this.instructeurId,
    required this.dagVanWeek,
    required this.startTijd,
    required this.eindTijd,
    required this.voorkeurScore,
  });

  String get dagNaam => dagNamen[dagVanWeek.clamp(0, 6)];

  String get startTijdKort =>
      startTijd.length >= 5 ? startTijd.substring(0, 5) : startTijd;

  String get eindTijdKort =>
      eindTijd.length >= 5 ? eindTijd.substring(0, 5) : eindTijd;

  factory LeerlingBeschikbaarheid.fromJson(Map<String, dynamic> json) {
    return LeerlingBeschikbaarheid(
      id: json['id'] as String,
      leerlingId: json['leerling_id'] as String,
      instructeurId: json['instructeur_id'] as String,
      dagVanWeek: (json['dag_van_week'] as num).toInt(),
      startTijd: json['start_tijd'] as String,
      eindTijd: json['eind_tijd'] as String,
      voorkeurScore: (json['voorkeur_score'] as num?)?.toInt() ?? 3,
    );
  }
}
