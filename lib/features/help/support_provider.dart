import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/support_service.dart';
import '../../models/support_thread.dart';

final supportThreadsProvider =
    FutureProvider.autoDispose<List<SupportThread>>((ref) {
  return SupportService.listThreads();
});

final supportThreadProvider =
    FutureProvider.autoDispose.family<SupportThread, String>((ref, threadId) {
  return SupportService.getThread(threadId);
});

final supportMessagesProvider = FutureProvider.autoDispose
    .family<List<SupportMessage>, String>((ref, threadId) {
  return SupportService.listMessages(threadId);
});
