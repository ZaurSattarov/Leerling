class Notificatie {
  final String id;
  final String leerlingId;
  final String instructeurId;
  final String titel;
  final String? bericht;
  final String? omschrijving;
  final String type; // les | factuur | voortgang | systeem
  final bool gelezen;
  final String aangemaaktOp;
  final String createdAt;
  final String? scheduledFor;
  final String targetRoute;
  final Map<String, dynamic> metadata;

  const Notificatie({
    required this.id,
    required this.leerlingId,
    required this.instructeurId,
    required this.titel,
    this.bericht,
    this.omschrijving,
    required this.type,
    required this.gelezen,
    required this.aangemaaktOp,
    String? createdAt,
    this.scheduledFor,
    required this.targetRoute,
    this.metadata = const <String, dynamic>{},
  }) : createdAt = createdAt ?? aangemaaktOp;

  bool get isMock => id.startsWith('mock-');
  String? get tekst => bericht ?? omschrijving;

  factory Notificatie.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] as String?) ?? 'systeem';
    final bericht =
        (json['bericht'] as String?) ?? (json['omschrijving'] as String?);
    final createdAt = (json['created_at'] as String?) ??
        (json['aangemaakt_op'] as String?) ??
        '';
    final metadata = json['metadata'];
    return Notificatie(
      id: (json['id'] as String?) ?? '',
      leerlingId: (json['leerling_id'] as String?) ?? '',
      instructeurId: (json['instructeur_id'] as String?) ?? '',
      titel: (json['titel'] as String?) ?? '',
      bericht: bericht,
      omschrijving: bericht,
      type: type,
      gelezen: json['gelezen'] as bool? ?? false,
      aangemaaktOp: createdAt,
      createdAt: createdAt,
      scheduledFor: json['scheduled_for'] as String?,
      targetRoute: (json['target_route'] as String?) ?? routeVoorType(type),
      metadata: metadata is Map<String, dynamic>
          ? metadata
          : const <String, dynamic>{},
    );
  }

  static String routeVoorType(String type) {
    return switch (type) {
      'les' || 'les_reminder' => '/planning',
      'voorbereiding' => '/lesvoorbereiding',
      'feedback' => '/les-logboek',
      'factuur' => '/facturen',
      'voortgang' || 'examenadvies' => '/examenadvies',
      _ => '/home',
    };
  }
}
