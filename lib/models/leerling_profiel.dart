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
  final String? avatarId;
  final String? geboortedatum;
  final String? adres;
  // Canonical waarden 'man'/'vrouw' — zelfde representatie als de
  // Instructeur-app (AvatarService.genderValueForCategory daar).
  final String? geslacht;
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

  // ── Lespakket (Fase 4) ──────────────────────────────────────────────────
  // pakketId/rijbewijsSoort/transmissie/startdatum zijn "live" leerling-
  // velden (net als pakket/status hierboven) -- de overige pakket_*-velden
  // zijn een immutable snapshot, vastgelegd op het moment dat de instructeur
  // dit pakket toewees. Zie StudentService.getMijnPakketCatalogusItem() en
  // heeftPakketSnapshot hieronder voor hoe snapshot vs. catalogus wordt
  // opgelost -- exact het patroon dat de Instructeur-app zelf gebruikt.
  final String? pakketId;
  final String? pakketNaam;
  final int? pakketLessenSnapshot;
  final int? losseLessen;
  final int losseMinuten;
  final String saldoEenheid;
  final int? pakketMinutenTotaal;
  final int pakketMinutenVerbruikt;
  final int? pakketPrijsCents;
  final int? pakketLosseLesPrijsCents;
  final int? pakketLesduurMinuten;
  final bool? pakketPraktijkexamenInbegrepen;
  final bool? pakketTussentijdseToetsInbegrepen;
  final String? pakketSnapshotVastgelegdOp;
  final String? rijbewijsSoort;
  final String? transmissie;
  final String? startdatum;

  const LeerlingProfiel({
    required this.id,
    required this.instructeurId,
    required this.voornaam,
    required this.achternaam,
    this.email,
    this.telefoon,
    this.avatarUrl,
    this.avatarId,
    this.geboortedatum,
    this.adres,
    this.geslacht,
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
    this.pakketId,
    this.pakketNaam,
    this.pakketLessenSnapshot,
    this.losseLessen,
    this.losseMinuten = 0,
    this.saldoEenheid = 'lessen',
    this.pakketMinutenTotaal,
    this.pakketMinutenVerbruikt = 0,
    this.pakketPrijsCents,
    this.pakketLosseLesPrijsCents,
    this.pakketLesduurMinuten,
    this.pakketPraktijkexamenInbegrepen,
    this.pakketTussentijdseToetsInbegrepen,
    this.pakketSnapshotVastgelegdOp,
    this.rijbewijsSoort,
    this.transmissie,
    this.startdatum,
  });

  String get volledigeNaam => '$voornaam $achternaam'.trim();

  bool get isProfielCompleet =>
      achternaam.trim().isNotEmpty &&
      geboortedatum?.trim().isNotEmpty == true &&
      email?.trim().isNotEmpty == true &&
      (avatarId?.trim().isNotEmpty == true ||
          avatarUrl?.trim().isNotEmpty == true);

  double get voortgangPercent =>
      lessenTotaal > 0 ? (lessenGevolgd / lessenTotaal).clamp(0.0, 1.0) : 0.0;

  /// True zodra de instructeur dit pakket heeft toegewezen ná introductie
  /// van de snapshotfunctionaliteit -- pakket_prijs/-duur/-examens komen dan
  /// UITSLUITEND uit de snapshotvelden hierboven, nooit meer live uit de
  /// catalogus (zodat een latere catalogusprijswijziging een al toegewezen
  /// pakket niet met terugwerkende kracht verandert).
  bool get heeftPakketSnapshot =>
      pakketSnapshotVastgelegdOp != null &&
      pakketSnapshotVastgelegdOp!.trim().isNotEmpty;

  bool get gebruiktMinutenSaldo => saldoEenheid == 'minuten';

  factory LeerlingProfiel.fromJson(Map<String, dynamic> json) {
    return LeerlingProfiel(
      id: json['id'] as String,
      instructeurId: json['instructeur_id'] as String,
      voornaam: json['voornaam'] as String,
      achternaam: json['achternaam'] as String? ?? '',
      email: json['email'] as String?,
      telefoon: json['telefoon'] as String?,
      avatarUrl: (json['avatar_url'] ??
          json['profielfoto_url'] ??
          json['foto_url'] ??
          json['profile_image_url']) as String?,
      avatarId: json['avatar_id'] as String?,
      geboortedatum: json['geboortedatum'] as String?,
      adres: json['adres'] as String?,
      geslacht: json['geslacht'] as String?,
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
      pakketId: json['pakket_id'] as String?,
      pakketNaam: json['pakket_naam'] as String?,
      pakketLessenSnapshot: (json['pakket_lessen'] as num?)?.toInt(),
      losseLessen: (json['losse_lessen'] as num?)?.toInt(),
      losseMinuten: (json['losse_minuten'] as num?)?.toInt() ?? 0,
      saldoEenheid: (json['saldo_eenheid'] as String?) ?? 'lessen',
      pakketMinutenTotaal: (json['pakket_minuten_totaal'] as num?)?.toInt(),
      pakketMinutenVerbruikt:
          (json['pakket_minuten_verbruikt'] as num?)?.toInt() ?? 0,
      pakketPrijsCents: (json['pakket_prijs_cents'] as num?)?.toInt(),
      pakketLosseLesPrijsCents:
          (json['pakket_losse_les_prijs_cents'] as num?)?.toInt(),
      pakketLesduurMinuten: (json['pakket_lesduur_minuten'] as num?)?.toInt(),
      pakketPraktijkexamenInbegrepen:
          json['pakket_praktijkexamen_inbegrepen'] as bool?,
      pakketTussentijdseToetsInbegrepen:
          json['pakket_tussentijdse_toets_inbegrepen'] as bool?,
      pakketSnapshotVastgelegdOp:
          json['pakket_snapshot_vastgelegd_op'] as String?,
      rijbewijsSoort: json['rijbewijs_soort'] as String?,
      transmissie: json['transmissie'] as String?,
      startdatum: json['startdatum'] as String?,
    );
  }
}
