// ignore_for_file: constant_identifier_names

enum LeerlingStatus { actief, geslaagd, gestopt, wachtlijst }

enum PakketType { basis, standaard, intensief, los_rijles }

extension LeerlingStatusLabel on LeerlingStatus {
  String get label {
    switch (this) {
      case LeerlingStatus.actief:
        return 'Actief';
      case LeerlingStatus.geslaagd:
        return 'Geslaagd';
      case LeerlingStatus.gestopt:
        return 'Gestopt';
      case LeerlingStatus.wachtlijst:
        return 'Wachtlijst';
    }
  }
}

extension PakketTypeLabel on PakketType {
  String get label {
    switch (this) {
      case PakketType.basis:
        return 'Basis';
      case PakketType.standaard:
        return 'Standaard';
      case PakketType.intensief:
        return 'Intensief';
      case PakketType.los_rijles:
        return 'Los rijles';
    }
  }
}

class LeerlingProfiel {
  final String id;
  final String instructeurId;
  final String voornaam;
  final String achternaam;
  final String? email;
  final String? telefoon;
  final String? avatarUrl;
  final String? geboortedatum;
  final PakketType pakket;
  final LeerlingStatus status;
  final int lessenTotaal;
  final int lessenGevolgd;
  final String? notities;
  final Map<String, dynamic>? vaardigheden;
  final String? userId;
  final String? gekoppeldOp;
  final String aangemaaktOp;
  final String bijgewerktOp;

  const LeerlingProfiel({
    required this.id,
    required this.instructeurId,
    required this.voornaam,
    required this.achternaam,
    this.email,
    this.telefoon,
    this.avatarUrl,
    this.geboortedatum,
    required this.pakket,
    required this.status,
    required this.lessenTotaal,
    required this.lessenGevolgd,
    this.notities,
    this.vaardigheden,
    this.userId,
    this.gekoppeldOp,
    required this.aangemaaktOp,
    required this.bijgewerktOp,
  });

  String get volledigeNaam => '$voornaam $achternaam';

  double get voortgangPercent =>
      lessenTotaal > 0 ? (lessenGevolgd / lessenTotaal).clamp(0.0, 1.0) : 0.0;

  factory LeerlingProfiel.fromJson(Map<String, dynamic> json) {
    return LeerlingProfiel(
      id: json['id'] as String,
      instructeurId: json['instructeur_id'] as String,
      voornaam: json['voornaam'] as String,
      achternaam: json['achternaam'] as String,
      email: json['email'] as String?,
      telefoon: json['telefoon'] as String?,
      avatarUrl: (json['avatar_url'] ??
          json['profielfoto_url'] ??
          json['foto_url'] ??
          json['profile_image_url']) as String?,
      geboortedatum: json['geboortedatum'] as String?,
      pakket: PakketType.values.firstWhere(
        (e) => e.name == (json['pakket'] as String?),
        orElse: () => PakketType.standaard,
      ),
      status: LeerlingStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String?),
        orElse: () => LeerlingStatus.actief,
      ),
      lessenTotaal: (json['lessen_totaal'] as num?)?.toInt() ?? 0,
      lessenGevolgd: (json['lessen_gevolgd'] as num?)?.toInt() ?? 0,
      notities: json['notities'] as String?,
      vaardigheden: json['vaardigheden'] as Map<String, dynamic>?,
      userId: json['user_id'] as String?,
      gekoppeldOp: json['gekoppeld_op'] as String?,
      aangemaaktOp: json['aangemaakt_op'] as String? ?? '',
      bijgewerktOp: json['bijgewerkt_op'] as String? ?? '',
    );
  }
}
