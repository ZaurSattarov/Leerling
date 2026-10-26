import 'package:flutter/foundation.dart';

/// Vertaalt fouten naar tekst die een leerling mag zien.
/// Hosts, URL's, tabelnamen en id's blijven in de debuglog.
class AppErrorFormatter {
  AppErrorFormatter._();

  static const String netwerkFoutMelding =
      'Geen internetverbinding. Controleer je verbinding en probeer het opnieuw.';

  static const String algemeen =
      'Er is iets misgegaan. Probeer het later opnieuw.';

  static final RegExp _technisch = RegExp(
    r'https?://|socketexception|clientexception|failed host lookup|'
    r'rest/v1|supabase|postgrest|jwt|uri=|select=\*|leerling_id|'
    r'instructeur_id|[0-9a-f]{8}-[0-9a-f]{4}-|\.invalid\b|stack trace',
    caseSensitive: false,
  );

  static bool isNetwerkFout(Object? error) {
    final lower = (error ?? '').toString().toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('connection closed') ||
        lower.contains('clientexception') ||
        lower.contains('handshake') ||
        lower.contains('timeoutexception') ||
        lower.contains('timeout');
  }

  static String toFriendlyDutch(
    Object? error, {
    String? fallback,
    String? contextMessage,
  }) {
    if (kDebugMode) {
      debugPrint(
          '[AppErrorFormatter] Originele fout ($contextMessage): $error');
    }
    if (error == null) return fallback ?? algemeen;

    final raw = error.toString();
    final lower = raw.toLowerCase();
    if (lower.contains('geen_actief_schoollid')) {
      return 'Je rijschool kan op dit moment niet gekoppeld worden. Neem contact op met je rijinstructeur.';
    }
    if (lower.contains('mfa_required') || lower.contains('mfa required')) {
      return 'Bevestig eerst de extra beveiliging van je account en probeer het daarna opnieuw.';
    }
    if (isNetwerkFout(error)) return fallback ?? netwerkFoutMelding;
    if (_technisch.hasMatch(lower)) {
      return fallback ?? _metContext(contextMessage);
    }

    final schoon = raw
        .replaceFirst(
            RegExp(r'^(Exception|StateError|ClientException):\s*'), '')
        .trim();
    if (schoon.isEmpty || _technisch.hasMatch(schoon.toLowerCase())) {
      return fallback ?? _metContext(contextMessage);
    }
    return schoon;
  }

  static String _metContext(String? contextMessage) {
    if (contextMessage != null && contextMessage.isNotEmpty) {
      return '$contextMessage. Probeer het opnieuw.';
    }
    return algemeen;
  }
}
