/// Leerling-side leesmodel van de Live Aankomst-eligibility voor één les
/// (Feature 2, Lesdetails-banner, 2026-09-03).
///
/// Komt UITSLUITEND van `fn_leerling_arrival_settings` (SECURITY DEFINER
/// RPC, migratie `20260903090000_live_aankomst_leerling_settings_rpc.sql`)
/// -- de Leerling-app heeft geen enkele directe SELECT-toegang tot
/// `instructor_arrival_settings` (die tabel heeft uitsluitend een
/// instructeur-eigen leespolicy). Deze RPC combineert EXACT dezelfde
/// eligibility-voorwaarden als `fn_arrival_start` (les.status='gepland',
/// les_type-whitelist, settings.enabled) -- geen tweede/afwijkende
/// eligibility-definitie hier in de client.
///
/// [eligible] = false betekent consequent "Live Aankomst is voor deze les
/// niet beschikbaar" -- dit dekt zowel "instructeur heeft het uitstaan" als
/// "les is geannuleerd/afgerond" als "lestype niet toegestaan" als "geen
/// toegang" in één, voor de UI identieke, niet-foutieve staat. Een echte
/// technische fout (netwerk/RPC-fout) geeft GEEN [ArrivalSettingsInfo]
/// terug (zie [ArrivalRepository.fetchArrivalSettings]) -- dat is een apart
/// geval ("nog niet geladen"), nooit hetzelfde als eligible=false.
class ArrivalSettingsInfo {
  final bool eligible;
  final int? visibleFromMinutes;

  const ArrivalSettingsInfo({
    required this.eligible,
    required this.visibleFromMinutes,
  });

  static const ArrivalSettingsInfo nietBeschikbaar =
      ArrivalSettingsInfo(eligible: false, visibleFromMinutes: null);

  /// Geeft nooit `eligible: true` terug zonder een geldig
  /// [visibleFromMinutes] -- een inconsistente serverrespons wordt hier
  /// defensief behandeld als "niet beschikbaar" (fail-safe, geen crash, geen
  /// misleidende banner).
  static ArrivalSettingsInfo fromRpcResult(dynamic json) {
    if (json is! Map) return nietBeschikbaar;
    final eligible = json['eligible'] == true;
    final minutenRaw = json['visible_from_minutes'];
    final minuten = minutenRaw is num ? minutenRaw.toInt() : null;
    if (!eligible || minuten == null) return nietBeschikbaar;
    return ArrivalSettingsInfo(eligible: true, visibleFromMinutes: minuten);
  }
}
