/// Canonical toegewezen/voorkeursvoertuig van de leerling
/// (`leerlingen.preferred_vehicle_id` → `vehicles.id`). Uitsluitend view-only
/// hier -- de leerling kan dit nergens wijzigen, dat gebeurt in de
/// Instructeur-app. Zelfde bron als Instrecteur/Admin, geen tweede relatie,
/// geen kentekenduplicatie.
class LeerlingVoertuig {
  final String id;
  final String? kenteken;
  final String? merk;
  final String? model;

  const LeerlingVoertuig({
    required this.id,
    this.kenteken,
    this.merk,
    this.model,
  });

  String? get naam {
    final parts = [merk, model]
        .where((s) => s != null && s.trim().isNotEmpty)
        .map((s) => s!.trim())
        .toList();
    return parts.isEmpty ? null : parts.join(' ');
  }

  factory LeerlingVoertuig.fromJson(Map<String, dynamic> json) {
    return LeerlingVoertuig(
      id: json['id'] as String,
      kenteken: json['kenteken'] as String?,
      merk: json['merk'] as String?,
      model: json['model'] as String?,
    );
  }
}
