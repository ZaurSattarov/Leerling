/// Of deze URI een e-mailopenpoging is. Auth, uitnodiging en betaalcallbacks
/// vallen hier buiten en blijven hun bestaande afhandeling houden.
bool emailOpenLink(Uri uri, {required String client}) {
  final scheme =
      client == 'instructeur' ? 'rijschoolplanner' : 'leerlingplanner';
  if (!['instructeur', 'leerling'].contains(client) ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment) {
    return false;
  }
  final https = uri.scheme == 'https' &&
      uri.host == 'app.klantio.com' &&
      (!uri.hasPort || uri.port == 443) &&
      uri.path == '/open/$client';
  final custom = uri.scheme == scheme &&
      uri.host == 'open' &&
      (uri.path.isEmpty || uri.path == '/') &&
      !uri.hasPort;
  return https || custom;
}

/// Presentatierouting voor e-maillinks. Geen accountactie of toegangsverlening.
String? emailLinkRoute(Uri uri, {required String client}) {
  if (!emailOpenLink(uri, client: client)) return null;
  if (uri.queryParameters.keys.any((key) => key != 'route') ||
      uri.queryParametersAll['route']?.length != 1) {
    return null;
  }
  return safeEmailRoute(uri.queryParameters['route'], client: client);
}

String? safeEmailRoute(String? value, {required String client}) {
  if (value == null ||
      value.length > 500 ||
      RegExp(r'[\\\x00-\x20\x7f]').hasMatch(value)) {
    return null;
  }
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.hasScheme ||
      uri.hasAuthority ||
      uri.hasFragment ||
      !value.startsWith('/') ||
      value.startsWith('//')) {
    return null;
  }
  const instructor = {
    '/dashboard',
    '/agenda',
    '/leerlingen',
    '/facturen',
    '/statistieken',
    '/profiel',
    '/profiel/team',
    '/profiel/teamagenda',
    '/profiel/support',
    '/ritten',
    '/meldingen',
  };
  const student = {
    '/home',
    '/planning',
    '/voortgang',
    '/voortgang/tijdlijn',
    '/voortgang/lespakket',
    '/profiel/lespakket',
    '/profiel',
    '/profiel/beveiliging',
    '/profiel/persoonlijke-gegevens',
    '/profiel/mijn-rijschool',
    '/profiel/notificatie-instellingen',
    '/beschikbaarheid',
    '/examens',
    '/facturen',
    '/help',
    '/help/support',
    '/notificaties',
  };
  if (!['instructeur', 'leerling'].contains(client)) {
    return null;
  }
  const uuid =
      r'[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}';
  final pattern = client == 'instructeur'
      ? '^/(agenda/lessen|leerlingen|facturen|examens)/($uuid)\$'
      : '^/(planning|facturen)/($uuid)\$';
  if (!(client == 'instructeur' ? instructor : student).contains(uri.path) &&
      !RegExp(pattern).hasMatch(uri.path)) {
    return null;
  }
  for (final entry in uri.queryParametersAll.entries) {
    if (entry.value.length != 1) {
      return null;
    }
    final v = entry.value.single;
    if (client == 'instructeur' && uri.path == '/agenda') {
      if (entry.key == 'date') {
        final d = DateTime.tryParse(v);
        if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v) ||
            d == null ||
            d.toIso8601String().substring(0, 10) != v) {
          return null;
        }
      } else if (!['lesson', 'request'].contains(entry.key) ||
          !RegExp('^$uuid\$').hasMatch(v)) {
        return null;
      }
    } else if (client == 'instructeur' &&
        uri.path.startsWith('/leerlingen/') &&
        entry.key == 'tab' &&
        v == 'examens') {
      // Bestaand examenselectiepad in app.dart.
    } else {
      return null;
    }
  }
  return uri.toString();
}

/// Alleen een tijdelijk navigatiedoel. De bestaande login-/MFA-/RLS-poorten
/// beslissen over toegang; deze klasse bewaart geen sessie of identiteit.
class PendingEmailLink {
  String? _route;
  void remember(String route) => _route = route;
  String? take() {
    final route = _route;
    _route = null;
    return route;
  }

  void clear() => _route = null;
}
