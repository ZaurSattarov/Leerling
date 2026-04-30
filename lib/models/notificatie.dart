class Notificatie {
  final String id;
  final String leerlingId;
  final String instructeurId;
  final String titel;
  final String? omschrijving;
  final String type; // les | factuur | voortgang | systeem
  final bool gelezen;
  final String aangemaaktOp;

  const Notificatie({
    required this.id,
    required this.leerlingId,
    required this.instructeurId,
    required this.titel,
    this.omschrijving,
    required this.type,
    required this.gelezen,
    required this.aangemaaktOp,
  });

  factory Notificatie.fromJson(Map<String, dynamic> json) {
    return Notificatie(
      id: (json['id'] as String?) ?? '',
      leerlingId: (json['leerling_id'] as String?) ?? '',
      instructeurId: (json['instructeur_id'] as String?) ?? '',
      titel: (json['titel'] as String?) ?? '',
      omschrijving: json['omschrijving'] as String?,
      type: (json['type'] as String?) ?? 'systeem',
      gelezen: json['gelezen'] as bool? ?? false,
      aangemaaktOp: (json['aangemaakt_op'] as String?) ?? '',
    );
  }
}
