/// Canonical supportthread-modellen -- 1-op-1 poort van de Instructeur-app
/// (rijschool-planner-flutter/lib/models/support_thread.dart). Zelfde
/// backend (support_threads/support_messages via de Edge Function
/// `support-chat`), zelfde velden/logica. Tickets die vanuit de Leerling-app
/// worden aangemaakt krijgen server-side (niet client-side, dus niet
/// spoofbaar) `product_context = 'leerling'`.
enum SupportThreadStatus {
  open,
  waitingForSupport,
  waitingForUser,
  closed;

  static SupportThreadStatus fromDb(String? value) {
    return switch (value) {
      'waiting_for_support' => SupportThreadStatus.waitingForSupport,
      'waiting_for_user' => SupportThreadStatus.waitingForUser,
      'closed' => SupportThreadStatus.closed,
      _ => SupportThreadStatus.open,
    };
  }

  String get dbValue => switch (this) {
        SupportThreadStatus.open => 'open',
        SupportThreadStatus.waitingForSupport => 'waiting_for_support',
        SupportThreadStatus.waitingForUser => 'waiting_for_user',
        SupportThreadStatus.closed => 'closed',
      };

  String get label => switch (this) {
        SupportThreadStatus.open => 'Wacht op antwoord',
        SupportThreadStatus.waitingForSupport => 'Wacht op antwoord',
        SupportThreadStatus.waitingForUser => 'Klantio heeft gereageerd',
        SupportThreadStatus.closed => 'Afgerond',
      };
}

class SupportThread {
  final String id;
  final int ticketNumber;
  final String subject;
  final SupportThreadStatus status;
  final DateTime lastMessageAt;
  final String lastMessagePreview;
  final DateTime? userLastReadAt;
  final String outboundMailStatus;
  final DateTime createdAt;
  final String? category;
  final String? lastSenderType;

  const SupportThread({
    required this.id,
    required this.ticketNumber,
    required this.subject,
    required this.status,
    required this.lastMessageAt,
    required this.lastMessagePreview,
    required this.outboundMailStatus,
    required this.createdAt,
    this.userLastReadAt,
    this.category,
    this.lastSenderType,
  });

  String get ticketLabel => 'KLT-$ticketNumber';

  bool get heeftOngelezen {
    if (status == SupportThreadStatus.closed) return false;
    if (lastSenderType == 'user') return false;
    if (userLastReadAt == null) {
      return status == SupportThreadStatus.waitingForUser;
    }
    return lastMessageAt.isAfter(userLastReadAt!) &&
        (lastSenderType == 'support' ||
            status == SupportThreadStatus.waitingForUser);
  }

  factory SupportThread.fromJson(Map<String, dynamic> json) {
    return SupportThread(
      id: json['id'] as String,
      ticketNumber: (json['ticket_number'] as num).toInt(),
      subject: (json['subject'] as String?) ?? '',
      status: SupportThreadStatus.fromDb(json['status'] as String?),
      lastMessageAt: DateTime.parse(json['last_message_at'] as String),
      lastMessagePreview: (json['last_message_preview'] as String?) ?? '',
      userLastReadAt: json['user_last_read_at'] == null
          ? null
          : DateTime.tryParse(json['user_last_read_at'] as String),
      outboundMailStatus: (json['outbound_mail_status'] as String?) ?? 'sent',
      createdAt: DateTime.parse(json['created_at'] as String),
      category: json['category'] as String?,
      lastSenderType: json['last_sender_type'] as String?,
    );
  }
}

class SupportMessage {
  final String id;
  final String threadId;
  final String senderType;
  final String body;
  final String source;
  final DateTime createdAt;

  const SupportMessage({
    required this.id,
    required this.threadId,
    required this.senderType,
    required this.body,
    required this.source,
    required this.createdAt,
  });

  bool get isVanGebruiker => senderType == 'user';

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'] as String,
      threadId: json['thread_id'] as String,
      senderType: (json['sender_type'] as String?) ?? 'user',
      body: (json['body'] as String?) ?? '',
      source: (json['source'] as String?) ?? 'app',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Leerlinggerichte supportcategorieën. De eerste 5 waarden zijn identiek
/// aan de Instructeur-app (gedeelde Edge Function-validatie); de laatste 3
/// zijn additief toegevoegd voor de Leerling-app (support-chat/index.ts,
/// CATEGORIES-set, 2026-09-03) en breken de Instructeur-categorieën niet.
const supportCategorieen = <(String, String)>[
  ('account', 'Account & profiel'),
  ('facturen', 'Facturen & betalingen'),
  ('planning', 'Planning & lessen'),
  ('lespakket_voortgang', 'Lespakket & voortgang'),
  ('live_aankomst', 'Live Aankomst'),
  ('rijschool_instructeur', 'Rijschool & instructeur'),
  ('technisch', 'Technisch probleem'),
  ('privacy', 'Privacy & gegevens'),
  ('overig', 'Overig'),
];
