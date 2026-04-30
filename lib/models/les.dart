enum LesStatus { gepland, afgerond, geannuleerd, geen_toon }

extension LesStatusLabel on LesStatus {
  String get label {
    switch (this) {
      case LesStatus.gepland:
        return 'Gepland';
      case LesStatus.afgerond:
        return 'Afgerond';
      case LesStatus.geannuleerd:
        return 'Geannuleerd';
      case LesStatus.geen_toon:
        return 'Geen toon';
    }
  }
}

class Les {
  final String id;
  final String instructeurId;
  final String leerlingId;
  final String datum;
  final String starttijd;
  final String eindtijd;
  final int duurMinuten;
  final LesStatus status;
  final String? notities;
  final String? locatie;
  final String aangemaaktOp;
  final String bijgewerktOp;

  // Joined: instructor name from instructeur_profielen
  final String? instructeurNaam;
  final String? instructeurTelefoon;

  const Les({
    required this.id,
    required this.instructeurId,
    required this.leerlingId,
    required this.datum,
    required this.starttijd,
    required this.eindtijd,
    required this.duurMinuten,
    required this.status,
    this.notities,
    this.locatie,
    required this.aangemaaktOp,
    required this.bijgewerktOp,
    this.instructeurNaam,
    this.instructeurTelefoon,
  });

  static String _kortTijd(String t) => t.length > 5 ? t.substring(0, 5) : t;

  factory Les.fromJson(Map<String, dynamic> json) {
    final instrData = json['instructeur_profielen'] as Map<String, dynamic>?;
    return Les(
      id: (json['id'] as String?) ?? '',
      instructeurId: (json['instructeur_id'] as String?) ?? '',
      leerlingId: (json['leerling_id'] as String?) ?? '',
      datum: (json['datum'] as String?) ?? '',
      starttijd: _kortTijd((json['starttijd'] as String?) ?? ''),
      eindtijd: _kortTijd((json['eindtijd'] as String?) ?? ''),
      duurMinuten: (json['duur_minuten'] as num?)?.toInt() ?? 60,
      status: LesStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'gepland'),
        orElse: () => LesStatus.gepland,
      ),
      notities: json['notities'] as String?,
      locatie: json['locatie'] as String?,
      aangemaaktOp: (json['aangemaakt_op'] as String?) ?? '',
      bijgewerktOp: (json['bijgewerkt_op'] as String?) ?? '',
      instructeurNaam: instrData?['naam'] as String?,
      instructeurTelefoon: instrData?['telefoon'] as String?,
    );
  }
}
