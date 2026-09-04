import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/support_thread.dart';
import 'student_service.dart';

class SupportAttachment {
  final String path;
  final String mime;
  final int sizeBytes;

  const SupportAttachment({
    required this.path,
    required this.mime,
    required this.sizeBytes,
  });
}

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

  // subject/category zijn bewust optioneel: de Help & Support-chat opent
  // direct (geen apart onderwerp-/categorieformulier meer); de Edge
  // Function vult server-side een default-onderwerp in ('Nieuw gesprek')
  // wanneer dit veld leeg blijft.
  static Future<SupportActionResult> createThread({
    String? subject,
    required String body,
    String? category,
    String? clientRequestId,
    SupportAttachment? attachment,
  }) {
    // create_leerling (niet het generieke 'create') -- de Edge Function zet
    // hierdoor server-side altijd product_context='leerling' en weigert
    // (403) als er geen leerlingen-rij bestaat voor dit account.
    return _invoke(
      action: 'create_leerling',
      body: {
        if (subject != null && subject.isNotEmpty) 'subject': subject,
        'body': body,
        if (category != null) 'category': category,
        'client_request_id': clientRequestId ?? newSupportRequestId(),
        ..._attachmentBody(attachment),
      },
    );
  }

  static Future<SupportActionResult> reply({
    required String threadId,
    required String body,
    String? clientRequestId,
    SupportAttachment? attachment,
  }) {
    return _invoke(
      action: 'reply',
      body: {
        'thread_id': threadId,
        'body': body,
        'client_request_id': clientRequestId ?? newSupportRequestId(),
        ..._attachmentBody(attachment),
      },
    );
  }

  static Map<String, dynamic> _attachmentBody(SupportAttachment? attachment) {
    if (attachment == null) return const {};
    return {
      'attachment_path': attachment.path,
      'attachment_mime': attachment.mime,
      'attachment_size_bytes': attachment.sizeBytes,
    };
  }

  /// Uploadt een foto naar de private bucket `support-attachments` op het
  /// pad `{auth.uid()}/{uuid}.{ext}` (Storage-RLS staat alleen de eigen map
  /// + actieve platform_staff toe). Het supportbericht zelf met de
  /// verwijzing naar dit pad wordt pas daarna, via de Edge Function
  /// (service_role), weggeschreven -- nooit een directe insert hier.
  static Future<SupportAttachment> uploadAttachment({
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final uid = StudentService.client.auth.currentUser?.id ?? '';
    final ext = _extensionFor(mimeType);
    final path = '$uid/${DateTime.now().microsecondsSinceEpoch}_'
        '${Random.secure().nextInt(1 << 32)}$ext';
    await StudentService.client.storage.from('support-attachments').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType),
        );
    return SupportAttachment(path: path, mime: mimeType, sizeBytes: bytes.length);
  }

  /// Signed URL (1 uur geldig) om een bijlage te tonen -- bucket is privé,
  /// geen publieke URL.
  static Future<String> signedAttachmentUrl(String path) {
    return StudentService.client.storage
        .from('support-attachments')
        .createSignedUrl(path, 3600);
  }

  static String _extensionFor(String mimeType) {
    switch (mimeType) {
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      case 'image/heic':
        return '.heic';
      case 'image/heif':
        return '.heif';
      default:
        return '.jpg';
    }
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
