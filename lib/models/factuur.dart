enum FactuurStatus { concept, verstuurd, betaald, verlopen }

extension FactuurStatusLabel on FactuurStatus {
  String get label {
    switch (this) {
      case FactuurStatus.concept:
        return 'Concept';
      case FactuurStatus.verstuurd:
        return 'Verstuurd';
      case FactuurStatus.betaald:
        return 'Betaald';
      case FactuurStatus.verlopen:
        return 'Verlopen';
    }
  }
}

class Factuur {
  final String id;
  final String instructeurId;
  final String leerlingId;
  final String factuurnummer;
  final String beschrijving;
  final int bedragCents;
  final FactuurStatus status;
  final String? betaalLinkUrl;
  final String? ibanSnapshot;
  final String? betalingskenmerk;
  final String? notities;
  final String? vervaldatum;
  final String? betaaldOp;
  final String aangemaaktOp;
  final String bijgewerktOp;

  const Factuur({
    required this.id,
    required this.instructeurId,
    required this.leerlingId,
    required this.factuurnummer,
    required this.beschrijving,
    required this.bedragCents,
    required this.status,
    this.betaalLinkUrl,
    this.ibanSnapshot,
    this.betalingskenmerk,
    this.notities,
    this.vervaldatum,
    this.betaaldOp,
    required this.aangemaaktOp,
    required this.bijgewerktOp,
  });

  String get bedragEuro =>
      '€${(bedragCents / 100).toStringAsFixed(2).replaceAll('.', ',')}';

  bool get isOpen =>
      status == FactuurStatus.concept || status == FactuurStatus.verstuurd;

  bool get isVerlopen => status == FactuurStatus.verlopen;

  factory Factuur.fromJson(Map<String, dynamic> json) {
    return Factuur(
      id: (json['id'] as String?) ?? '',
      instructeurId: (json['instructeur_id'] as String?) ?? '',
      leerlingId: (json['leerling_id'] as String?) ?? '',
      factuurnummer: (json['factuurnummer'] as String?) ?? '',
      beschrijving: (json['beschrijving'] as String?) ?? '',
      bedragCents: (json['bedrag_cents'] as num?)?.toInt() ?? 0,
      status: FactuurStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'concept'),
        orElse: () => FactuurStatus.concept,
      ),
      betaalLinkUrl: json['betaal_link_url'] as String?,
      ibanSnapshot: json['iban_snapshot'] as String?,
      betalingskenmerk: json['betalingskenmerk'] as String?,
      notities: json['notities'] as String?,
      vervaldatum: json['vervaldatum'] as String?,
      betaaldOp: json['betaald_op'] as String?,
      aangemaaktOp: (json['aangemaakt_op'] as String?) ?? '',
      bijgewerktOp: (json['bijgewerkt_op'] as String?) ?? '',
    );
  }
}
