enum ExamenType { praktijk, theorie, ttt }

extension ExamenTypeLabel on ExamenType {
  String get label {
    switch (this) {
      case ExamenType.praktijk:
        return 'Praktijkexamen';
      case ExamenType.theorie:
        return 'Theorie-examen';
      case ExamenType.ttt:
        return 'Tussentijdse Toets (TTT)';
    }
  }
}

enum ExamenStatus { gepland, geslaagd, gezakt }

extension ExamenStatusLabel on ExamenStatus {
  String get label {
    switch (this) {
      case ExamenStatus.gepland:
        return 'Gepland';
      case ExamenStatus.geslaagd:
        return 'Geslaagd';
      case ExamenStatus.gezakt:
        return 'Gezakt';
    }
  }
}

class Examen {
  final String id;
  final String leerlingId;
  final String instructeurId;
  final String datum;
  final String? tijdstip;
  final ExamenType type;
  final ExamenStatus status;
  final String? uitslag;
  final String? cbrVestiging;
  final String? cbrLocatie;
  final int pogingNummer;
  final int? foutpunten;
  final String? notities;
  final String aangemaaktOp;

  const Examen({
    required this.id,
    required this.leerlingId,
    required this.instructeurId,
    required this.datum,
    this.tijdstip,
    required this.type,
    required this.status,
    this.uitslag,
    this.cbrVestiging,
    this.cbrLocatie,
    required this.pogingNummer,
    this.foutpunten,
    this.notities,
    required this.aangemaaktOp,
  });

  String? get locatie => cbrLocatie ?? cbrVestiging;

  factory Examen.fromJson(Map<String, dynamic> json) {
    return Examen(
      id: (json['id'] as String?) ?? '',
      leerlingId: (json['leerling_id'] as String?) ?? '',
      instructeurId: (json['instructeur_id'] as String?) ?? '',
      datum: (json['datum'] as String?) ?? '',
      tijdstip: json['tijdstip'] as String?,
      type: _parseType(json['type'] as String?),
      status: ExamenStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'gepland'),
        orElse: () => ExamenStatus.gepland,
      ),
      uitslag: json['uitslag'] as String?,
      cbrVestiging: json['cbr_vestiging'] as String?,
      cbrLocatie: json['cbr_locatie'] as String?,
      pogingNummer: (json['poging_nummer'] as num? ?? 1).toInt(),
      foutpunten: (json['foutpunten'] as num?)?.toInt(),
      notities: (json['notities'] ?? json['notitie']) as String?,
      aangemaaktOp: (json['aangemaakt_op'] as String?) ?? '',
    );
  }

  static ExamenType _parseType(String? raw) {
    if (raw == null) return ExamenType.praktijk;
    final lower = raw.toLowerCase();
    if (lower.contains('theorie')) return ExamenType.theorie;
    if (lower.contains('ttt') || lower.contains('tussentijds')) {
      return ExamenType.ttt;
    }
    return ExamenType.praktijk;
  }
}
