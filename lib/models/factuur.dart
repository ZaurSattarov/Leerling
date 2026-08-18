enum FactuurStatus {
  concept,
  verstuurd,
  open,
  betaald,
  verlopen,
  teLaat,
  geannuleerd
}

extension FactuurStatusLabel on FactuurStatus {
  String get label {
    switch (this) {
      case FactuurStatus.concept:
      case FactuurStatus.verstuurd:
      case FactuurStatus.open:
        return 'Nog niet betaald';
      case FactuurStatus.betaald:
        return 'Betaald';
      case FactuurStatus.verlopen:
      case FactuurStatus.teLaat:
        return 'Te laat';
      case FactuurStatus.geannuleerd:
        return 'Geannuleerd';
    }
  }
}

/// 1-op-1 met FactuurRegel (rijschool-planner-flutter/lib/models/factuur.dart)
/// -- zelfde JSONB-sleutels als geschreven door SupabaseService.maakFactuur/
/// Admin Web's maakFactuur, bewust niet zelf herberekend.
class FactuurRegel {
  final String omschrijving;
  final int aantal;
  final int prijsPerStukCents;
  final int totaalCents;
  final int btwCents;

  const FactuurRegel({
    required this.omschrijving,
    required this.aantal,
    required this.prijsPerStukCents,
    required this.totaalCents,
    required this.btwCents,
  });

  factory FactuurRegel.fromJson(Map<String, dynamic> json) {
    return FactuurRegel(
      omschrijving: (json['omschrijving'] as String?) ?? '',
      aantal: (json['aantal'] as num?)?.toInt() ?? 1,
      prijsPerStukCents: (json['prijs_per_stuk_cents'] as num?)?.toInt() ?? 0,
      totaalCents: (json['totaal_cents'] as num?)?.toInt() ?? 0,
      btwCents: (json['btw_cents'] as num?)?.toInt() ?? 0,
    );
  }
}

class Factuur {
  final String id;
  final String instructeurId;
  final String leerlingId;
  final String factuurnummer;
  final String beschrijving;
  final int bedragCents;
  final int? subtotaalCents;
  final int? btwCents;
  final List<FactuurRegel>? factuurregels;
  final FactuurStatus status;
  final String? betaalmethode;
  final String? betaalLinkUrl;
  final String? stripeCheckoutUrl;
  final String? mollieCheckoutUrl;
  final String? molliePaymentId;
  final String? mollieStatus;
  final String? paymentUrl;
  final String? invoicePdfUrl;
  final String? downloadUrl;
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
    this.subtotaalCents,
    this.btwCents,
    this.factuurregels,
    required this.status,
    this.betaalmethode,
    this.betaalLinkUrl,
    this.stripeCheckoutUrl,
    this.mollieCheckoutUrl,
    this.molliePaymentId,
    this.mollieStatus,
    this.paymentUrl,
    this.invoicePdfUrl,
    this.downloadUrl,
    this.ibanSnapshot,
    this.betalingskenmerk,
    this.notities,
    this.vervaldatum,
    this.betaaldOp,
    required this.aangemaaktOp,
    required this.bijgewerktOp,
  });

  String get bedragEuro =>
      'EUR ${(bedragCents / 100).toStringAsFixed(2).replaceAll('.', ',')}';

  bool get isOpen =>
      status == FactuurStatus.concept ||
      status == FactuurStatus.verstuurd ||
      status == FactuurStatus.open;

  bool get isVerlopen =>
      status == FactuurStatus.verlopen || status == FactuurStatus.teLaat;

  bool get isBetaalbaar => isOpen || isVerlopen;

  String? get effectieveBetaalUrl {
    for (final url in [
      mollieCheckoutUrl,
      stripeCheckoutUrl,
      betaalLinkUrl,
      paymentUrl,
    ]) {
      if (url?.trim().isNotEmpty == true) return url!.trim();
    }
    return null;
  }

  String? get effectieveDownloadUrl {
    for (final url in [invoicePdfUrl, downloadUrl]) {
      if (url?.trim().isNotEmpty == true) return url!.trim();
    }
    return null;
  }

  String get betaalmethodeLabel {
    switch (betaalmethode) {
      case 'ideal_tikkie':
        return 'iDEAL / Tikkie';
      case 'bankoverschrijving':
        return 'Bankoverschrijving';
      case 'contant':
        return 'Contant';
      default:
        return effectieveBetaalUrl == null
            ? 'Nog niet beschikbaar'
            : 'Betaallink';
    }
  }

  factory Factuur.fromJson(Map<String, dynamic> json) {
    return Factuur(
      id: (json['id'] as String?) ?? '',
      instructeurId: (json['instructeur_id'] as String?) ?? '',
      leerlingId: (json['leerling_id'] as String?) ?? '',
      factuurnummer: (json['factuurnummer'] as String?) ?? '',
      beschrijving: (json['beschrijving'] as String?) ?? '',
      bedragCents: (json['bedrag_cents'] as num?)?.toInt() ?? 0,
      subtotaalCents: (json['subtotaal_cents'] as num?)?.toInt(),
      btwCents: (json['btw_cents'] as num?)?.toInt(),
      factuurregels: (json['factuurregels'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map(FactuurRegel.fromJson)
          .toList(),
      status: _statusFromJson(json['status'] as String?),
      betaalmethode: json['betaalmethode'] as String?,
      betaalLinkUrl: json['betaal_link_url'] as String?,
      stripeCheckoutUrl: json['stripe_checkout_url'] as String?,
      mollieCheckoutUrl: json['mollie_checkout_url'] as String?,
      molliePaymentId: json['mollie_payment_id'] as String?,
      mollieStatus: json['mollie_status'] as String?,
      paymentUrl: json['payment_url'] as String?,
      invoicePdfUrl: (json['invoice_pdf_url'] ??
          json['factuur_pdf_url'] ??
          json['pdf_url']) as String?,
      downloadUrl: json['download_url'] as String?,
      ibanSnapshot: json['iban_snapshot'] as String?,
      betalingskenmerk: json['betalingskenmerk'] as String?,
      notities: json['notities'] as String?,
      vervaldatum: json['vervaldatum'] as String?,
      betaaldOp: json['betaald_op'] as String?,
      aangemaaktOp: (json['aangemaakt_op'] as String?) ?? '',
      bijgewerktOp: (json['bijgewerkt_op'] as String?) ?? '',
    );
  }

  static FactuurStatus _statusFromJson(String? value) {
    switch ((value ?? 'concept').trim().toLowerCase()) {
      case 'verstuurd':
      case 'sent':
        return FactuurStatus.verstuurd;
      case 'open':
      case 'openstaand':
        return FactuurStatus.open;
      case 'betaald':
      case 'paid':
        return FactuurStatus.betaald;
      case 'verlopen':
      case 'te_laat':
      case 'te-laat':
      case 'late':
      case 'overdue':
        return FactuurStatus.verlopen;
      case 'geannuleerd':
      case 'geannuleerd_door_instructeur':
      case 'canceled':
      case 'cancelled':
        return FactuurStatus.geannuleerd;
      case 'concept':
      default:
        return FactuurStatus.concept;
    }
  }
}
