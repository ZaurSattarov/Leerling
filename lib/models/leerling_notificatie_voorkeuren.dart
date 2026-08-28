class LeerlingNotificatieVoorkeuren {
  final String userId;
  final bool nieuweLes;
  final bool lesVerplaatst;
  final bool lesHerinnering;
  final bool nieuweFactuur;
  final bool betalingOntvangen;
  final bool factuurHerinnering;
  final bool nieuweEvaluatie;
  final bool lespakketBijnaOp;
  final bool examenGepland;
  final bool examenHerinnering;
  final bool examenResultaat;
  final bool examenadvies;
  final String? createdAt;
  final String? updatedAt;

  const LeerlingNotificatieVoorkeuren({
    required this.userId,
    this.nieuweLes = true,
    this.lesVerplaatst = true,
    this.lesHerinnering = true,
    this.nieuweFactuur = true,
    this.betalingOntvangen = true,
    this.factuurHerinnering = true,
    this.nieuweEvaluatie = true,
    this.lespakketBijnaOp = true,
    this.examenGepland = true,
    this.examenHerinnering = true,
    this.examenResultaat = true,
    this.examenadvies = true,
    this.createdAt,
    this.updatedAt,
  });

  factory LeerlingNotificatieVoorkeuren.fromJson(Map<String, dynamic> json) {
    return LeerlingNotificatieVoorkeuren(
      userId: json['user_id'] as String,
      nieuweLes: json['nieuwe_les'] as bool? ?? true,
      lesVerplaatst: json['les_verplaatst'] as bool? ?? true,
      lesHerinnering: json['les_herinnering'] as bool? ?? true,
      nieuweFactuur: json['nieuwe_factuur'] as bool? ?? true,
      betalingOntvangen: json['betaling_ontvangen'] as bool? ?? true,
      factuurHerinnering: json['factuur_herinnering'] as bool? ?? true,
      nieuweEvaluatie: json['nieuwe_evaluatie'] as bool? ?? true,
      lespakketBijnaOp: json['lespakket_bijna_op'] as bool? ?? true,
      examenGepland: json['examen_gepland'] as bool? ?? true,
      examenHerinnering: json['examen_herinnering'] as bool? ?? true,
      examenResultaat: json['examen_resultaat'] as bool? ?? true,
      examenadvies: json['examenadvies'] as bool? ?? true,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'nieuwe_les': nieuweLes,
      'les_verplaatst': lesVerplaatst,
      'les_herinnering': lesHerinnering,
      'nieuwe_factuur': nieuweFactuur,
      'betaling_ontvangen': betalingOntvangen,
      'factuur_herinnering': factuurHerinnering,
      'nieuwe_evaluatie': nieuweEvaluatie,
      'lespakket_bijna_op': lespakketBijnaOp,
      'examen_gepland': examenGepland,
      'examen_herinnering': examenHerinnering,
      'examen_resultaat': examenResultaat,
      'examenadvies': examenadvies,
    };
  }

  LeerlingNotificatieVoorkeuren copyWith({
    bool? nieuweLes,
    bool? lesVerplaatst,
    bool? lesHerinnering,
    bool? nieuweFactuur,
    bool? betalingOntvangen,
    bool? factuurHerinnering,
    bool? nieuweEvaluatie,
    bool? lespakketBijnaOp,
    bool? examenGepland,
    bool? examenHerinnering,
    bool? examenResultaat,
    bool? examenadvies,
    String? updatedAt,
  }) {
    return LeerlingNotificatieVoorkeuren(
      userId: userId,
      nieuweLes: nieuweLes ?? this.nieuweLes,
      lesVerplaatst: lesVerplaatst ?? this.lesVerplaatst,
      lesHerinnering: lesHerinnering ?? this.lesHerinnering,
      nieuweFactuur: nieuweFactuur ?? this.nieuweFactuur,
      betalingOntvangen: betalingOntvangen ?? this.betalingOntvangen,
      factuurHerinnering: factuurHerinnering ?? this.factuurHerinnering,
      nieuweEvaluatie: nieuweEvaluatie ?? this.nieuweEvaluatie,
      lespakketBijnaOp: lespakketBijnaOp ?? this.lespakketBijnaOp,
      examenGepland: examenGepland ?? this.examenGepland,
      examenHerinnering: examenHerinnering ?? this.examenHerinnering,
      examenResultaat: examenResultaat ?? this.examenResultaat,
      examenadvies: examenadvies ?? this.examenadvies,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
