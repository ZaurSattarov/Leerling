/// Leerling-side model van een Live Aankomst-sessie (Feature 2, Fase 2C).
///
/// Puur een leesmodel van een `arrival_sessions`-rij zoals de Leerling-app
/// die via RLS mag zien -- de Leerling-app schrijft hier NOOIT naar (geen
/// insert/update/delete, geen RPC-aanroepen). Server/RLS blijft altijd de
/// autoriteit over welke sessie zichtbaar is; dit model interpreteert enkel
/// wat al is teruggekomen.
class ArrivalSession {
  final String id;
  final String lessonId;
  final String status;
  final DateTime endsAt;
  final String locationVisibility;

  const ArrivalSession({
    required this.id,
    required this.lessonId,
    required this.status,
    required this.endsAt,
    required this.locationVisibility,
  });

  /// UX-only afgeleide: server (RLS) is de echte autoriteit -- deze getter
  /// voorkomt alleen dat de UI tussen twee verse SELECT's in een sessie
  /// als "actief" blijft tonen die het client-device al weet te zijn
  /// verlopen (ends_at gepasseerd).
  bool isActive({DateTime? nu}) {
    final referentie = nu ?? DateTime.now();
    return status == 'active' && referentie.isBefore(endsAt);
  }

  bool get isVisible => locationVisibility == 'visible';

  static ArrivalSession? fromRow(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['id'] as String?;
    final lessonId = json['lesson_id'] as String?;
    final endsAtRaw = json['ends_at'] as String?;
    if (id == null || id.isEmpty) return null;
    if (lessonId == null || lessonId.isEmpty) return null;
    final endsAt = endsAtRaw != null ? DateTime.tryParse(endsAtRaw) : null;
    if (endsAt == null) return null;

    return ArrivalSession(
      id: id,
      lessonId: lessonId,
      status: (json['status'] as String?) ?? 'active',
      endsAt: endsAt,
      locationVisibility: (json['location_visibility'] as String?) ?? 'hidden',
    );
  }
}
