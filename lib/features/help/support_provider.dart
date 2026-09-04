import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/support_service.dart';
import '../../models/support_thread.dart';

final supportThreadsProvider =
    FutureProvider.autoDispose<List<SupportThread>>((ref) {
  return SupportService.listThreads();
});

/// Het gesprek dat de Help & Support-chat direct moet tonen: de meest
/// recente supportthread van de leerling, ongeacht status -- `null` wanneer
/// er nog nooit een gesprek is gestart. `SupportChatScreen` beslist zelf
/// hoe een afgeronde thread getoond wordt (afgesloten-banner + "Nieuwe chat
/// starten").
final activeSupportThreadProvider =
    FutureProvider.autoDispose<SupportThread?>((ref) async {
  final threads = await SupportService.listThreads();
  return threads.isEmpty ? null : threads.first;
});

final supportThreadProvider =
    FutureProvider.autoDispose.family<SupportThread, String>((ref, threadId) {
  return SupportService.getThread(threadId);
});

final supportMessagesProvider = FutureProvider.autoDispose
    .family<List<SupportMessage>, String>((ref, threadId) {
  return SupportService.listMessages(threadId);
});
