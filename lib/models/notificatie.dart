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

  /// Valideert een ruwe push-route (canonical FCM `target_route` veld).
  static String sanitizePushRoute(String route, String type) {
    return _veiligeRoute(route, type);
  }

  /// Minimale notificatie uit FCM data-payload (fallback wanneer DB-fetch
  /// faalt of nog niet klaar is). Route wordt via [_veiligeRoute] gevalideerd.
  factory Notificatie.fromPushData(Map<String, dynamic> data) {
    final type = (data['type'] as String?) ?? 'systeem';
    final rawRoute = (data['target_route'] as String?) ?? '';
    return Notificatie.fromJson({
      'id': data['notification_id'],
      'type': type,
      'target_route': rawRoute.isNotEmpty ? rawRoute : routeVoorType(type),
    });
  }

  factory Notificatie.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] as String?) ?? 'systeem';
    final bericht = (json['body'] as String?) ??
        (json['bericht'] as String?) ??
        (json['omschrijving'] as String?);
    final createdAt = (json['created_at'] as String?) ??
        (json['aangemaakt_op'] as String?) ??
        '';
    final metadata = json['metadata'];
    final targetRoute =
        (json['target_route'] as String?) ?? routeVoorType(type);
    return Notificatie(
      id: (json['id'] as String?) ?? '',
      leerlingId: (json['leerling_id'] as String?) ?? '',
      instructeurId: (json['instructeur_id'] as String?) ?? '',
      titel: (json['title'] as String?) ?? (json['titel'] as String?) ?? '',
      bericht: bericht,
      omschrijving: bericht,
      type: type,
      gelezen:
          (json['is_read'] as bool?) ?? (json['gelezen'] as bool? ?? false),
      aangemaaktOp: createdAt,
      createdAt: createdAt,
      scheduledFor: json['scheduled_for'] as String?,
      targetRoute: _veiligeRoute(targetRoute, type),
      metadata: metadata is Map<String, dynamic>
          ? metadata
          : const <String, dynamic>{},
    );
  }

  static String routeVoorType(String type) {
    return switch (type) {
      'les' ||
      'les_reminder' ||
      'lesson_planned' ||
      'lesson_changed' ||
      'lesson_cancelled' =>
        '/planning',
      'voorbereiding' => '/lesvoorbereiding',
      // 'les_feedback' is de legacy-alias die rpc_les_afronden tot de
      // contractmigratie van 2026-08-28 schreef; historische rijen moeten hun
      // deeplink houden. Canonical is 'lesson_feedback'.
      'feedback' || 'les_feedback' || 'lesson_feedback' => '/planning',
      // Idem: 'factuur' en 'betalingsherinnering' zijn legacy-aliassen van
      // het canonical 'invoice_reminder'.
      'factuur' ||
      'betalingsherinnering' ||
      'invoice_reminder' ||
      'invoice_created' ||
      'invoice_paid' =>
        '/facturen',
      'package_almost_empty' => '/voortgang/lespakket',
      'arrival_started' || 'arrival_available' => '/planning',
      'exam_scheduled' => '/examens',
      'exam_result' => '/examens',
      'voortgang' || 'examenadvies' => '/examenadvies',
      'admin_message' => '/notificaties',
      'support_antwoord' => '/help/support',
      _ => '/home',
    };
  }

  static String _veiligeRoute(String route, String type) {
    if (route.isEmpty || !route.startsWith('/')) return routeVoorType(type);
    const toegestanePrefixes = [
      '/home',
      '/planning',
      '/les-logboek',
      '/lesvoorbereiding',
      '/examens',
      '/examenadvies',
      '/voortgang',
      '/facturen',
      '/profiel',
      '/notificaties',
      '/beschikbaarheid',
      // Supportantwoord-notificaties (Help & Support, 2026-09-03) linken
      // naar het eigen supportgesprek.
      '/help',
    ];
    return toegestanePrefixes.any(route.startsWith)
        ? route
        : routeVoorType(type);
  }
}
