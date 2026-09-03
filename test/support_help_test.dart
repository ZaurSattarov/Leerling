import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guardtests voor de Help & Support-poort (Punt 11 + 12): dezelfde
/// bron-string-aanpak als de overige *_test.dart-bestanden in deze map.
/// Draait geen live Supabase-calls (die vereisen een echte sessie) --
/// verifieert dat de juiste bestanden/routes/aanroepen bestaan en dat de
/// canonical backend-contracten (Edge Function `support-chat`,
/// `support_threads_app`, RLS) worden gebruikt zoals bedoeld.
void main() {
  String read(String path) => File(path).readAsStringSync();

  group('Help & Support (leerling-poort)', () {
    test('A. Help & Support is bereikbaar vanuit Profiel', () {
      final profiel = read('lib/features/profiel/profiel_screen.dart');
      expect(profiel, contains("context.push('/help')"));
      expect(profiel, contains('Help & Support'));
    });

    test(
        'B. Alle nieuwe supportschermen gebruiken MainDetailHeader '
        '(terugpijl, geen navbar)', () {
      for (final path in [
        'lib/features/help/help_screen.dart',
        'lib/features/help/help_faq_screen.dart',
        'lib/features/help/support_inbox_screen.dart',
        'lib/features/help/support_new_thread_screen.dart',
        'lib/features/help/support_thread_screen.dart',
      ]) {
        final source = read(path);
        expect(source, contains('MainDetailHeader'), reason: path);
      }
    });

    test('C. Help-hub linkt naar Chat met support en Help & FAQ', () {
      final source = read('lib/features/help/help_screen.dart');
      expect(source, contains("context.push('/help/support')"));
      expect(source, contains("context.push('/help/faq')"));
    });

    test(
        'D. Nieuw-gesprekscherm heeft categorie, onderwerp en bericht, en '
        'gebruikt de leerlinggerichte categorielijst', () {
      final source = read('lib/features/help/support_new_thread_screen.dart');
      expect(source, contains('supportCategorieen'));
      expect(source, contains('_onderwerp'));
      expect(source, contains('_bericht'));
      expect(source, contains('SupportService.createThread'));
    });

    test(
        'E/H. SupportService maakt threads aan en verstuurt replies via de '
        'bestaande Edge Function `support-chat` -- geen directe '
        'insert/update op support_threads of support_messages', () {
      final source = read('lib/core/services/support_service.dart');
      expect(source, contains("'support-chat'"));
      expect(source, contains("action: 'create_leerling'"));
      expect(source, contains("action: 'reply'"));
      // Alleen leesqueries (select) op support_messages zijn toegestaan
      // (listMessages, RLS-gescoped) -- schrijven gaat altijd via de Edge
      // Function (service_role), nooit via .insert()/.update() vanuit de
      // client.
      expect(source, isNot(contains('.insert(')));
      expect(source, isNot(contains('.update(')));
    });

    test(
        'F/I. product_context wordt NOOIT als request-body-sleutel vanuit de '
        'Leerling-client verstuurd -- alleen als leesfilter gebruikt, nooit '
        'als request-body-key (`\'product_context\':`)', () {
      final service = read('lib/core/services/support_service.dart');
      // Wél toegestaan: .eq('product_context', ...) als LEESFILTER (de
      // isolatiefix zelf). NIET toegestaan: 'product_context': ... als
      // sleutel in een request-body die naar de Edge Function gaat -- dat
      // veld bepaalt de server uitsluitend zelf, per aangeroepen actie.
      expect(service, isNot(contains("'product_context':")));
      final newThreadScreen =
          read('lib/features/help/support_new_thread_screen.dart');
      expect(newThreadScreen, isNot(contains("'product_context':")));
    });

    test(
        'G. Threads/messages worden gelezen via de RLS-gescoped view/tabel '
        '(support_threads_app), niet rechtstreeks support_threads', () {
      final source = read('lib/core/services/support_service.dart');
      expect(source, contains("from('support_threads_app')"));
      expect(source, isNot(contains("from('support_threads')")));
    });

    test('I. Een bestaand gesprek laadt thread + berichten via providers', () {
      final provider = read('lib/features/help/support_provider.dart');
      expect(provider, contains('supportThreadProvider'));
      expect(provider, contains('supportMessagesProvider'));
      final screen = read('lib/features/help/support_thread_screen.dart');
      expect(screen, contains('supportThreadProvider(widget.threadId)'));
      expect(screen, contains('supportMessagesProvider(widget.threadId)'));
    });

    test('J/K. Help & FAQ bevat alleen leerlinggerichte categorieën', () {
      final source = read('lib/features/help/help_faq_screen.dart');
      for (final categorie in [
        'Account & profiel',
        'Planning & lessen',
        'Lespakket & voortgang',
        'Live Aankomst',
        'Facturen & betalingen',
        'Notificaties',
        'Rijschool & instructeur',
        'Privacy & gegevens',
        'Support',
      ]) {
        expect(source, contains(categorie), reason: categorie);
      }
      // Geen instructeur-specifieke content (leerlingen hebben geen
      // rijschool/leerlingenbeheer).
      expect(source, isNot(contains('Hoe voeg ik een leerling toe')));
      expect(source, isNot(contains('Hoe beheer ik mijn rijschool')));
    });

    test('Alle vijf supportroutes zijn geregistreerd in app.dart', () {
      final app = read('lib/app.dart');
      for (final route in [
        "path: '/help'",
        "path: '/help/faq'",
        "path: '/help/support'",
        "path: '/help/support/nieuw'",
        "path: '/help/support/:id'",
      ]) {
        expect(app, contains(route), reason: route);
      }
    });

    test('Notificatie-routewhitelist staat /help toe (supportantwoorden)', () {
      final source = read('lib/models/notificatie.dart');
      expect(source, contains("'/help'"));
    });
  });

  group(
      'Isolatiebug-fix: leerling- en instructeur-tickets nooit gemengd '
      '(2026-09-03)', () {
    test(
        'A. CREATE gebruikt de aparte create_leerling-actie, niet de '
        'generieke create (die is voor Instructeur)', () {
      final source = read('lib/core/services/support_service.dart');
      expect(source, contains("action: 'create_leerling'"));
      expect(source, isNot(contains("action: 'create',")));
    });

    test(
        'D. listThreads/getThread filteren expliciet op '
        "product_context = 'leerling' (naast de bestaande user_id-isolatie)",
        () {
      final source = read('lib/core/services/support_service.dart');
      final matches =
          "eq('product_context', 'leerling')".allMatches(source).length;
      expect(matches, 2,
          reason: 'listThreads en getThread moeten allebei filteren');
    });
  });
}
