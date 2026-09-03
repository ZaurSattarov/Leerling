import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../models/support_thread.dart';
import 'student_service.dart';

/// Canonical supportchat-service voor de Leerling-app -- 1-op-1 poort van
/// de Instructeur-app (rijschool-planner-flutter/lib/core/services/
/// support_service.dart). Zelfde backend/contract: alle schrijfacties lopen
/// via de bestaande Edge Function `support-chat`, nooit directe
/// table-writes vanuit de client. `product_context` wordt server-side
/// hardcoded bepaald door de aangeroepen actie (`create_leerling` ->
/// altijd 'leerling') -- nooit uit clientinput, en NIET meer door te kijken
/// welke tabel toevallig een rij heeft voor dit account (isolatiebug-fix
/// 2026-09-03: hetzelfde auth-account kan legitiem zowel een
/// instructeur- als een leerlingprofiel hebben).
///
/// LIST/GET filteren daarnaast expliciet op `product_context = 'leerling'`
/// (defense-in-depth, naast de user_id-isolatie via RLS) -- een leerling
/// mag nooit een instructeur-thread terugkrijgen, ook niet als dezelfde
/// user_id eigenaar is.
class SupportActionResult {
  final String threadId;
  final int? ticketNumber;
  final bool mailSent;
  final String? mailError;

  const SupportActionResult({
    required this.threadId,
    required this.mailSent,
    this.ticketNumber,
    this.mailError,
  });
}

class SupportService {
  SupportService._();

  static Future<List<SupportThread>> listThreads() async {
    final rows = await StudentService.client
        .from('support_threads_app')
        .select()
        .eq('user_id', StudentService.client.auth.currentUser?.id ?? '')
        .eq('product_context', 'leerling')
        .order('last_message_at', ascending: false);
    return (rows as List)
        .map((row) => SupportThread.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  static Future<SupportThread> getThread(String threadId) async {
    final row = await StudentService.client
        .from('support_threads_app')
        .select()
        .eq('id', threadId)
        .eq('user_id', StudentService.client.auth.currentUser?.id ?? '')
        .eq('product_context', 'leerling')
        .maybeSingle();
    if (row == null) {
      throw Exception('Dit gesprek is niet gevonden.');
    }
    return SupportThread.fromJson(row);
  }

  static Future<List<SupportMessage>> listMessages(String threadId) async {
    final rows = await StudentService.client
        .from('support_messages')
        .select()
        .eq('thread_id', threadId)
        .order('created_at', ascending: true);
    return (rows as List)
        .map((row) => SupportMessage.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> markRead(String threadId) async {
    try {
      await StudentService.client.rpc('fn_support_mark_read', params: {
        'p_thread_id': threadId,
      });
    } catch (e) {
      debugPrint('[SupportService] markRead fout: $e');
    }
  }

  static Future<SupportActionResult> createThread({
    required String subject,
    required String body,
    String? category,
    String? clientRequestId,
  }) {
    // create_leerling (niet het generieke 'create') -- de Edge Function zet
    // hierdoor server-side altijd product_context='leerling' en weigert
    // (403) als er geen leerlingen-rij bestaat voor dit account.
    return _invoke(
      action: 'create_leerling',
      body: {
        'subject': subject,
        'body': body,
        if (category != null) 'category': category,
        'client_request_id': clientRequestId ?? newSupportRequestId(),
      },
    );
  }

  static Future<SupportActionResult> reply({
    required String threadId,
    required String body,
    String? clientRequestId,
  }) {
    return _invoke(
      action: 'reply',
      body: {
        'thread_id': threadId,
        'body': body,
        'client_request_id': clientRequestId ?? newSupportRequestId(),
      },
    );
  }

  static Future<SupportActionResult> retryMail(String threadId) {
    return _invoke(
      action: 'retry_mail',
      body: {'thread_id': threadId},
    );
  }

  static Future<SupportActionResult> _invoke({
    required String action,
    required Map<String, dynamic> body,
  }) async {
    final result = await StudentService.client.functions.invoke(
      'support-chat',
      body: {'action': action, ...body},
    );
    final data = result.data;
    if (data is! Map) {
      throw Exception('Support is tijdelijk niet bereikbaar. Probeer opnieuw.');
    }
    final map = Map<String, dynamic>.from(data);
    final threadId = map['thread_id'] as String?;
    if (threadId == null || threadId.isEmpty) {
      throw Exception(
        (map['error'] as String?) ??
            'Je bericht is niet verzonden. Probeer opnieuw.',
      );
    }
    return SupportActionResult(
      threadId: threadId,
      ticketNumber: (map['ticket_number'] as num?)?.toInt(),
      mailSent: map['mail_sent'] != false,
      mailError: map['mail_error'] as String?,
    );
  }
}

String newSupportRequestId() {
  final n = Random.secure().nextInt(1 << 32);
  return '${DateTime.now().microsecondsSinceEpoch}-$n';
}

String supportFoutmelding(Object error) {
  final raw = error.toString().replaceFirst('Exception: ', '');
  const hints = [
    'Onderwerp',
    'Bericht',
    'niet gevonden',
    'afgerond',
    'niet verzonden',
    'Ongeldige',
    'Niet geautoriseerd',
    'niet gelukt',
    'niet opgeslagen',
    'verplicht',
    'leerlingprofiel',
  ];
  for (final hint in hints) {
    if (raw.toLowerCase().contains(hint.toLowerCase())) {
      return raw;
    }
  }
  return 'Versturen is niet gelukt. Probeer het later opnieuw.';
}
