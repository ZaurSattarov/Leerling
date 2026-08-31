/// Leerling-side model van de meest actuele instructeur-positie
/// (`current_arrival_location`, Feature 2, Fase 2C).
///
/// Puur een leesmodel -- de Leerling-app schrijft hier nooit naar. Als deze
/// rij niet via RLS wordt teruggegeven (sessie niet actief / locatie nog
/// verborgen) bestaat dit object simpelweg niet -- er is bewust geen "vorige
/// locatie" fallback: [fromRow] geeft dan `null`, nooit een leeg/placeholder
/// object dat per ongeluk als "actuele positie" gelezen zou kunnen worden.
class ArrivalLocation {
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final double? speedKmh;
  final double? headingDegrees;
  final DateTime recordedAt;

  const ArrivalLocation({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.speedKmh,
    this.headingDegrees,
    required this.recordedAt,
  });

  /// V1-drempel voor "verouderd": 90 seconden. De instructeur publiceert
  /// event-gedreven (bij >=10m beweging, zie Instructeur-app
  /// GeolocatorArrivalGps), niet op een vaste interval -- bij stilstand
  /// (verkeerslicht, file) kan een publish geruime tijd uitblijven zonder
  /// dat er iets mis is. 60s bleek in die situaties te agressief (privacy-
  /// notitie 30s+300m is een heel ander mechanisme, dit is puur UX-staleness);
  /// 90s balanceert "toon geen echt verouderde marker als actueel" tegen
  /// valse "niet bijgewerkt"-meldingen tijdens een normale korte stop.
  static const Duration staleThreshold = Duration(seconds: 90);

  bool isStale({DateTime? nu, Duration? threshold}) {
    final referentie = nu ?? DateTime.now();
    final grens = threshold ?? staleThreshold;
    return referentie.difference(recordedAt) > grens;
  }

  /// Geeft `null` bij ontbrekende/ongeldige velden -- nooit een gedeeltelijk
  /// geparste locatie tonen. Coördinaten worden defensief gevalideerd op de
  /// client, ook al garandeert de server-side CHECK constraint al geldige
  /// waarden: fail-closed als extra laag, nooit als vervanging voor de
  /// server-validatie.
  static ArrivalLocation? fromRow(Map<String, dynamic>? json) {
    if (json == null) return null;

    final lat = _num(json['latitude']);
    final lon = _num(json['longitude']);
    final recordedAtRaw = json['recorded_at'] as String?;
    final recordedAt =
        recordedAtRaw != null ? DateTime.tryParse(recordedAtRaw) : null;

    if (lat == null || lat < -90 || lat > 90) return null;
    if (lon == null || lon < -180 || lon > 180) return null;
    if (recordedAt == null) return null;

    return ArrivalLocation(
      latitude: lat,
      longitude: lon,
      accuracyMeters: _num(json['accuracy_meters']),
      speedKmh: _num(json['speed_kmh']),
      headingDegrees: _num(json['heading_degrees']),
      recordedAt: recordedAt,
    );
  }

  /// Veilige `num?`-cast: geeft `null` terug voor elke waarde die geen
  /// getal is, i.p.v. een `TypeError` te gooien op malformed data.
  static double? _num(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }
}
