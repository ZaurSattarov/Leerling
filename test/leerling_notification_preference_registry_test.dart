import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:leerling_app/features/notificaties/leerling_notification_preference_registry.dart';
import 'package:leerling_app/models/leerling_notificatie_voorkeuren.dart';

void main() {
  group('ALL_VISIBLE_LEARNER_NOTIFICATION_TOGGLES', () {
    test('elke zichtbare toggle heeft db-key op model', () {
      final modelKeys = LeerlingNotificatieVoorkeuren(
        userId: 'test',
      ).toJson().keys.toSet();

      for (final toggle in leerlingOptionalPreferenceToggles) {
        expect(
          modelKeys,
          contains(toggle.dbKey),
          reason: '${toggle.uiLabel} mist db-key ${toggle.dbKey}',
        );
      }
    });

    test('elke toggle mapped minimaal één canonical type', () {
      for (final toggle in leerlingOptionalPreferenceToggles) {
        expect(
          toggle.canonicalTypes,
          isNotEmpty,
          reason: toggle.uiLabel,
        );
      }
    });

    test('push_logic optionele types hebben zichtbare toggle', () {
      final toggleDbKeys =
          leerlingOptionalPreferenceToggles.map((t) => t.dbKey).toSet();

      for (final entry in leerlingOptionalCanonicalTypes.entries) {
        expect(
          toggleDbKeys,
          contains(entry.value),
          reason:
              'Canonical type ${entry.key} mapped naar ${entry.value} zonder toggle',
        );
      }
    });

    test('geen dubbele db-keys tussen toggles', () {
      final keys =
          leerlingOptionalPreferenceToggles.map((t) => t.dbKey).toList();
      expect(keys.length, keys.toSet().length);
    });

    test('UI bron bevat alle registry labels en geen verwijderde nep-rijen', () {
      final source = File(
        'lib/features/notificaties/notificatie_instellingen_screen.dart',
      ).readAsStringSync();

      for (final toggle in leerlingOptionalPreferenceToggles) {
        expect(source, contains(toggle.uiLabel));
      }
      for (final locked in leerlingSystemLockedNotifications) {
        expect(source, contains(locked.uiLabel));
      }

      expect(source, isNot(contains('Account- en beveiligingsmeldingen')));
      expect(source, isNot(contains('Serviceberichten van Klantio')));
      expect(source, isNot(contains('Betaling ontvangen')));
    });

    test('systemNonOptional types staan niet als toggle in UI', () {
      final source = File(
        'lib/features/notificaties/notificatie_instellingen_screen.dart',
      ).readAsStringSync();

      for (final type in leerlingSystemNonOptionalTypes) {
        expect(
          source,
          isNot(contains("Key('toggle_$type')")),
          reason: '$type mag geen toggle zijn',
        );
      }
    });
  });

  group('Profiel notificatie-entry', () {
    test('Profiel bevat Notificaties item met directe route', () {
      final profile =
          File('lib/features/profiel/profiel_screen.dart').readAsStringSync();

      expect(profile, contains("label: 'Notificaties'"));
      expect(
        profile,
        contains('Beheer welke meldingen je ontvangt'),
      );
      expect(profile, contains("'/profiel/notificatie-instellingen'"));
    });

    test('App-instellingen bevat geen notification settings item meer', () {
      final settings = File('lib/features/profiel/app_instellingen_screen.dart')
          .readAsStringSync();

      expect(settings, isNot(contains("label: 'Notificatie-instellingen'")));
      expect(settings, isNot(contains("'/profiel/notificatie-instellingen'")));
      expect(settings, contains("label: 'App-machtigingen'"));
      expect(settings, contains("label: 'Beveiliging'"));
    });
  });
}
