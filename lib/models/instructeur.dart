class Instructeur {
  final String id;
  final String? rijschoolNaam;
  final String? naam;
  final String? telefoon;
  final String? email;
  final String? adres;
  final String? postcode;
  final String? stad;
  final String? logoUrl;
  final String? whatsappNummer;
  final String? website;
  final String? kvkNummer;

  const Instructeur({
    required this.id,
    this.rijschoolNaam,
    this.naam,
    this.telefoon,
    this.email,
    this.adres,
    this.postcode,
    this.stad,
    this.logoUrl,
    this.whatsappNummer,
    this.website,
    this.kvkNummer,
  });

  String get weergaveNaam =>
      (rijschoolNaam?.isNotEmpty == true) ? rijschoolNaam! : (naam ?? 'Rijschool');

  String? get volledigAdres {
    if (adres == null && stad == null) return null;
    final parts = [adres, postcode, stad].where((e) => e?.isNotEmpty == true);
    return parts.join(', ');
  }

  factory Instructeur.fromJson(Map<String, dynamic> json) {
    return Instructeur(
      id: (json['id'] as String?) ?? '',
      rijschoolNaam: json['rijschool_naam'] as String?,
      naam: json['naam'] as String?,
      telefoon: json['telefoon'] as String?,
      email: json['email'] as String?,
      adres: json['adres'] as String?,
      postcode: json['postcode'] as String?,
      stad: json['stad'] as String?,
      logoUrl: json['logo_url'] as String?,
      whatsappNummer: json['whatsapp_nummer'] as String?,
      website: json['website'] as String?,
      kvkNummer: json['kvk_nummer'] as String?,
    );
  }
}
