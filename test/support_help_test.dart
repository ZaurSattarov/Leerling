import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guardtests voor de Help & Support-redesign (2026-09-04): directe chat,
/// geen hub/FAQ-tegels, geen apart onderwerp-/categorieformulier, foto-
/// bijlagen, realtime, Klantio-primary i.p.v. blauw uit de Figma-referentie.
/// 1-op-1 poort van de Instructeur-app
/// (test/support_chat_redesign_test.dart). Draait geen live Supabase-calls
/// (die vereisen een echte sessie) -- verifieert dat de juiste
/// bestanden/routes/aanroepen bestaan en dat de canonical backend-contracten
/// (Edge Function support-chat, support_threads_app, RLS) gebruikt worden
/// zoals bedoeld.
void main() {
  String read(String path) => File(path).readAsStringSync();

  group('Help & Support-redesign (leerling-poort)', () {
    test('A. Help & Support is bereikbaar vanuit Profiel', () {
      final profiel = read('lib/features/profiel/profiel_screen.dart');
      expect(profiel, contains("context.push('/help')"));
      expect(profiel, contains('Help & Support'));
    });

    test('B. De oude hub/FAQ/nieuw-gesprek-schermen bestaan niet meer', () {
      for (final path in [
        'lib/features/help/help_screen.dart',
        'lib/features/help/help_faq_screen.dart',
        'lib/features/help/support_new_thread_screen.dart',
        'lib/features/help/support_thread_screen.dart',
      ]) {
        expect(File(path).existsSync(), isFalse, reason: path);
      }
    });

    test(
        'C. app.dart opent /help en /help/support direct via '
        'SupportChatScreen -- geen HelpScreen/HelpFaqScreen/'
        'SupportNewThreadScreen meer', () {
      final app = read('lib/app.dart');
      expect(app, contains("import 'features/help/support_chat_screen.dart';"));
      expect(app, isNot(contains('HelpScreen(')));
      expect(app, isNot(contains('HelpFaqScreen')));
      expect(app, isNot(contains('SupportNewThreadScreen')));
      expect(app, contains("path: '/help',"));
      expect(app, contains('SupportChatScreen(),'));
      expect(app, contains("threadId: state.pathParameters['id']!"));
      // Bestaande notificatie-fallback ('/help/support', zonder id) blijft
      // geregistreerd en wijst naar hetzelfde directe-chatscherm.
      expect(app, contains("path: '/help/support',"));
    });

    test(
        'D. SupportChatScreen gebruikt MainDetailHeader (consistent met de '
        'rest van de app, geen aparte navbar)', () {
      final source = read('lib/features/help/support_chat_screen.dart');
      expect(source, contains('MainDetailHeader'));
    });

    test(
        'E. Nieuw gesprek aanmaken vereist geen onderwerp/categorie meer van '
        'de leerling', () {
      final service = read('lib/core/services/support_service.dart');
      expect(service, isNot(contains('required String subject')));
      final screen = read('lib/features/help/support_chat_screen.dart');
      expect(screen, contains('SupportService.createThread(body: body'));
    });

    test(
        'F. SupportService maakt threads aan en verstuurt replies via de '
        'bestaande Edge Function `support-chat` -- geen directe '
        'insert/update op support_threads of support_messages (Storage-'
        'upload voor bijlagen is geen table-write)', () {
      final source = read('lib/core/services/support_service.dart');
      expect(source, contains("'support-chat'"));
      expect(source, contains("action: 'create_leerling'"));
      expect(source, contains("action: 'reply'"));
      expect(source, isNot(contains('.insert(')));
      expect(source, isNot(contains('.update(')));
    });

    test(
        'G. Foto-bijlagen gaan naar de private support-attachments-bucket, '
        'nooit als base64 in de database', () {
      final service = read('lib/core/services/support_service.dart');
      expect(service, contains("storage.from('support-attachments')"));
      expect(service, contains('uploadBinary'));
      expect(service, contains('createSignedUrl'));
    });

    test(
        'H. product_context wordt NOOIT als request-body-sleutel vanuit de '
        'Leerling-client verstuurd -- alleen als leesfilter gebruikt', () {
      final service = read('lib/core/services/support_service.dart');
      expect(service, isNot(contains("'product_context':")));
      final screen = read('lib/features/help/support_chat_screen.dart');
      expect(screen, isNot(contains("'product_context':")));
    });

    test(
        'I. Threads/messages worden gelezen via de RLS-gescoped view/tabel '
        '(support_threads_app), niet rechtstreeks support_threads', () {
      final source = read('lib/core/services/support_service.dart');
      expect(source, contains("from('support_threads_app')"));
      expect(source, isNot(contains("from('support_threads')")));
    });

    test(
        'J. Realtime: de chat abonneert op support_messages/support_threads '
        'i.p.v. uitsluitend handmatig verversen', () {
      final source = read('lib/features/help/support_chat_screen.dart');
      expect(source, contains('.onPostgresChanges('));
      expect(source, contains("table: 'support_messages'"));
      expect(source, contains("table: 'support_threads'"));
    });

    test(
        'K. Klantio-primary komt terug in verzendknop/eigen berichten/'
        'attachment-knop -- geen blauw uit de Figma-referentie', () {
      final source = read('lib/features/help/support_chat_screen.dart');
      expect(source, contains('AppColors.primary'));
      expect(source, isNot(contains('Colors.blue')));
    });

    test(
        'L. Afgesloten gesprek toont een afsluit-melding met een "Nieuwe '
        'chat starten"-actie', () {
      final source = read('lib/features/help/support_chat_screen.dart');
      expect(source, contains('Je vorige gesprek is afgesloten.'));
      expect(source, contains('Nieuwe chat starten'));
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
