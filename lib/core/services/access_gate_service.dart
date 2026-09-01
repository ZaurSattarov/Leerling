import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Klantio Intern Beheerplatform — accountblokkade (Optie B, 2026-09-01).
///
/// Controleert de canonical `access_status` (los van `leerlingen.status`/
/// `actief`) via de gedeelde SECURITY DEFINER-RPC `get_my_access_status()`
/// — dezelfde RPC als de Instructeur-app, precies één canonical checkpoint
/// voor "mag deze gebruiker normaal verder?". Bypassed bewust de
/// RESTRICTIVE RLS-policies zodat een geblokkeerde gebruiker alsnog de
/// juiste melding kan krijgen i.p.v. een kale foutmelding.
///
/// Wijzigt NOOIT `leerlingen.status`/`actief` — puur een read-only check.
class AccessGateService {
  const AccessGateService._();

  /// Retourneert 'active' | 'blocked' | 'suspended'. Bij een fout (bv. geen
  /// netwerk) wordt 'active' teruggegeven — fail-open op deze check; de
  /// RESTRICTIVE RLS-policies op leerlingen blijven de daadwerkelijke,
  /// server-side afdwinging voor echte databasetoegang.
  static Future<String> currentAccessStatus() async {
    try {
      final result = await Supabase.instance.client.rpc(
        'get_my_access_status',
      );
      if (result is String && result.isNotEmpty) return result;
      return 'active';
    } catch (e) {
      debugPrint('[access-gate] status check mislukt (fail-open): $e');
      return 'active';
    }
  }
}
