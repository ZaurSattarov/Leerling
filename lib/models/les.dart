// ignore_for_file: constant_identifier_names

enum LesStatus { gepland, afgerond, geannuleerd, verzet, geen_toon }

extension LesStatusLabel on LesStatus {
  String get label {
    switch (this) {
      case LesStatus.gepland:
        return 'Gepland';
      case LesStatus.afgerond:
        return 'Afgerond';
      case LesStatus.geannuleerd:
        return 'Geannuleerd';
      case LesStatus.verzet:
        return 'Verzet';
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
  final List<String> geoefendeOnderwerpen;
  final String? instructeurFeedback;
  final String? leerlingNotitie;
  final Map<String, dynamic>? competentieScores;
  final String? beoordeling;
  final bool zichtbaarVoorLeerling;
  final String aangemaaktOp;
  final String bijgewerktOp;

  // Joined: instructor name/contact from instructeur_profielen
  final String? instructeurNaam;
  final String? instructeurTelefoon;
  final String? instructeurEmail;

  // Lesson type
  final String? lesType;

  // Vehicle info (from student_lessen_view if available)
  final String? voertuigMerk;
  final String? voertuigModel;
  final String? voertuigKenteken;
  final String? voertuigTransmissie;

  // Student license category
  final String? rijbewijsSoort;

  // From lessen table (only for afgerond + zichtbaar)
  final List<String> focusPunten;
  final String? ingrepenCount;
  final String? volgendeLesAdvies;

  // Instructor logo (from view join)
  final String? instructeurLogoUrl;

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
    this.geoefendeOnderwerpen = const [],
    this.instructeurFeedback,
    this.leerlingNotitie,
    this.competentieScores,
    this.beoordeling,
    this.zichtbaarVoorLeerling = false,
    required this.aangemaaktOp,
    required this.bijgewerktOp,
    this.instructeurNaam,
    this.instructeurTelefoon,
    this.instructeurEmail,
    this.lesType,
    this.voertuigMerk,
    this.voertuigModel,
    this.voertuigKenteken,
    this.voertuigTransmissie,
    this.rijbewijsSoort,
    this.focusPunten = const [],
    this.ingrepenCount,
    this.volgendeLesAdvies,
    this.instructeurLogoUrl,
  });

  static String _kortTijd(String t) => t.length > 5 ? t.substring(0, 5) : t;

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static Map<String, dynamic>? _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  factory Les.fromJson(Map<String, dynamic> json) {
    final instrData = json['instructeur_profielen'] as Map<String, dynamic>?;
    final instructeurNaam =
        (instrData?['naam'] as String?) ?? json['instructeur_naam'] as String?;
    final instructeurTelefoon = (instrData?['telefoon'] as String?) ??
        json['instructeur_telefoon'] as String?;
    final instructeurEmail = (instrData?['email'] as String?) ??
        json['instructeur_email'] as String?;
    final lesTypeRaw = json['les_type'] as String?;
    final lesTypeLabel = _lesTypeLabel(lesTypeRaw);

    // Vehicle data — may come from student_lessen_view join
    final voertuigData = json['voertuig'] as Map<String, dynamic>?;
    final voertuigMerk = (voertuigData?['merk'] as String?) ??
        json['voertuig_merk'] as String?;
    final voertuigModel = (voertuigData?['model'] as String?) ??
        json['voertuig_model'] as String?;
    final voertuigKenteken = (voertuigData?['kenteken'] as String?) ??
        json['voertuig_kenteken'] as String?;
    final voertuigTransmissie = (voertuigData?['transmissie'] as String?) ??
        json['voertuig_transmissie'] as String?;

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
      geoefendeOnderwerpen: _stringList(json['geoefende_onderwerpen']),
      instructeurFeedback: json['instructeur_feedback'] as String?,
      leerlingNotitie: json['leerling_notitie'] as String?,
      competentieScores: _map(json['competentie_scores']),
      beoordeling: json['beoordeling'] as String?,
      zichtbaarVoorLeerling: json['zichtbaar_voor_leerling'] as bool? ?? false,
      aangemaaktOp: (json['aangemaakt_op'] as String?) ?? '',
      bijgewerktOp: (json['bijgewerkt_op'] as String?) ?? '',
      instructeurNaam: instructeurNaam,
      instructeurTelefoon: instructeurTelefoon,
      lesType: lesTypeLabel,
      voertuigMerk: voertuigMerk,
      voertuigModel: voertuigModel,
      voertuigKenteken: voertuigKenteken,
      voertuigTransmissie: voertuigTransmissie,
      rijbewijsSoort: json['rijbewijs_soort'] as String?,
      focusPunten: _stringList(json['focus_punten']),
      ingrepenCount: json['ingrepen_count'] as String?,
      volgendeLesAdvies: json['volgende_les_advies'] as String?,
      instructeurEmail: instructeurEmail,
      instructeurLogoUrl: (instrData?['logo_url'] as String?) ??
          json['instructeur_logo_url'] as String?,
    );
  }

  static String? _lesTypeLabel(String? raw) {
    return switch (raw) {
      'pakketles' => 'Pakketles',
      'losse_les' => 'Losse les',
      'examenrit' => 'Examenrit',
      'proefexamen' => 'Proefexamen',
      _ => null,
    };
  }
}
