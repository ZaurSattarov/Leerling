import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/core/routing/email_link_route.dart';

void main() {
  const id = '11111111-1111-4111-8111-111111111111';
  for (final client in ['instructeur', 'leerling']) {
    final route =
        client == 'instructeur' ? '/agenda/lessen/$id' : '/planning/$id';
    final scheme =
        client == 'instructeur' ? 'rijschoolplanner' : 'leerlingplanner';
    test('$client: both HTTPS and custom scheme select the same actual screen',
        () {
      for (final origin in [
        'https://app.klantio.com/open/$client',
        '$scheme://open'
      ]) {
        final uri =
            Uri.parse(origin).replace(queryParameters: {'route': route});
        expect(emailLinkRoute(uri, client: client), route);
      }
    });
    test(
        '$client: foreign hosts, client schemes and login actions are rejected',
        () {
      for (final raw in [
        'https://evil.example/open/$client?route=%2Fhome',
        'https://app.klantio.com:444/open/$client?route=%2Fhome',
        'https://user@app.klantio.com/open/$client?route=%2Fhome',
        '$scheme://auth?route=${Uri.encodeComponent(route)}',
        '$scheme://open?route=${Uri.encodeComponent(route)}&role=owner',
        '$scheme://open?route=${Uri.encodeComponent(route)}&route=%2Fprofiel',
      ]) {
        expect(emailLinkRoute(Uri.parse(raw), client: client), isNull,
            reason: raw);
      }
      for (final raw in [
        'https://evil.example/',
        '//evil.example/',
        '/login',
        '/reset-password',
        '/invite',
        '/planning/DEMO',
        '/home?role=owner'
      ]) {
        expect(safeEmailRoute(raw, client: client), isNull, reason: raw);
      }
    });
    test('$client: memory is one-time and logout-clearable', () {
      final memory = PendingEmailLink()..remember(route);
      expect(memory.take(), route);
      expect(memory.take(), isNull);
      memory.remember(route);
      expect(memory.take(), route);
      memory.remember(route);
      memory.clear();
      expect(memory.take(), isNull);
    });
  }
  test('calendar date and object parameters must be valid and unique', () {
    expect(
        safeEmailRoute('/agenda?date=2026-10-21&lesson=$id',
            client: 'instructeur'),
        isNotNull);
    for (final raw in [
      '/agenda?date=2026-02-31',
      '/agenda?lesson=DEMO',
      '/agenda?date=2026-10-21&date=2026-10-22',
      '/agenda?redirect=https://evil.example'
    ]) {
      expect(safeEmailRoute(raw, client: 'instructeur'), isNull, reason: raw);
    }
    expect(safeEmailRoute('/facturen/$id', client: 'leerling'), isNotNull);
    expect(
        safeEmailRoute('/facturen/DEMO-2026-42', client: 'leerling'), isNull);
  });
  test('platform billing, payment return and auth links stay out of mail routing',
      () {
    const blocked = [
      '/facturen/mijn-facturen',
      '/profiel/upgrade',
      '/profiel/membership',
      '/factuur/$id',
      '/abonnement',
    ];
    for (final raw in blocked) {
      expect(safeEmailRoute(raw, client: 'instructeur'), isNull, reason: raw);
    }
    expect(
        emailOpenLink(Uri.parse('https://app.klantio.com/auth/callback'),
            client: 'leerling'),
        isFalse);
    expect(
        emailOpenLink(Uri.parse('leerlingplanner://auth/reset-password'),
            client: 'leerling'),
        isFalse);
    expect(
        emailOpenLink(Uri.parse('leerlingplanner://factuur?id=$id'),
            client: 'leerling'),
        isFalse);
    expect(
        emailLinkRoute(
            Uri.parse('https://app.klantio.com/open/leerling?route=%2Fgeen'),
            client: 'leerling'),
        isNull);
  });
  test('the learner cannot receive instructor-only screen targets', () {
    expect(safeEmailRoute('/profiel/upgrade', client: 'leerling'), isNull);
    expect(
        emailLinkRoute(Uri.parse('rijschoolplanner://open?route=%2Fhome'),
            client: 'leerling'),
        isNull);
    expect(safeEmailRoute('/home', client: 'unknown'), isNull);
  });
}
