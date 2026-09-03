import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/support_service.dart';
import '../../models/support_thread.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_detail_header.dart';
import '../../shared/widgets/snackbar.dart';
import 'support_provider.dart';
import 'widgets/support_ui.dart';

/// Supportgesprek (chat) -- 1-op-1 poort van de Instructeur-app
/// (support_thread_screen.dart). RLS beperkt berichten/thread al tot de
/// eigen leerling (support_threads_select_own / support_messages_select_own).
class SupportThreadScreen extends ConsumerStatefulWidget {
  final String threadId;

  const SupportThreadScreen({super.key, required this.threadId});

  @override
  ConsumerState<SupportThreadScreen> createState() =>
      _SupportThreadScreenState();
}

class _SupportThreadScreenState extends ConsumerState<SupportThreadScreen> {
  final _bericht = TextEditingController();
  bool _bezig = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SupportService.markRead(widget.threadId).then((_) {
        if (!mounted) return;
        ref.invalidate(supportThreadsProvider);
        ref.invalidate(supportThreadProvider(widget.threadId));
      });
    });
  }

  @override
  void dispose() {
    _bericht.dispose();
    super.dispose();
  }

  Future<void> _verstuur() async {
    final body = _bericht.text.trim();
    if (body.isEmpty) return;
    setState(() => _bezig = true);
    try {
      final result = await SupportService.reply(
        threadId: widget.threadId,
        body: body,
      );
      if (!mounted) return;
      _bericht.clear();
      ref.invalidate(supportMessagesProvider(widget.threadId));
      ref.invalidate(supportThreadProvider(widget.threadId));
      ref.invalidate(supportThreadsProvider);
      if (!result.mailSent && result.mailError != null) {
        showAppSnackBar(context, result.mailError!, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, supportFoutmelding(e), isError: true);
    } finally {
      if (mounted) setState(() => _bezig = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final threadAsync = ref.watch(supportThreadProvider(widget.threadId));
    final messagesAsync = ref.watch(supportMessagesProvider(widget.threadId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          threadAsync.when(
            loading: () => const MainDetailHeader(
              title: 'Support',
              fallbackRoute: '/help/support',
            ),
            error: (_, __) => const MainDetailHeader(
              title: 'Support',
              fallbackRoute: '/help/support',
            ),
            data: (thread) => MainDetailHeader(
              title: thread.subject,
              fallbackRoute: '/help/support',
            ),
          ),
          if (threadAsync.hasValue)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  Text(
                    threadAsync.requireValue.ticketLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SupportStatusChip(status: threadAsync.requireValue.status),
                  const Spacer(),
                  if (threadAsync.requireValue.outboundMailStatus == 'failed')
                    TextButton(
                      onPressed: () async {
                        try {
                          await SupportService.retryMail(widget.threadId);
                          ref.invalidate(
                              supportThreadProvider(widget.threadId));
                          if (context.mounted) {
                            showAppSnackBar(
                                context, 'E-mail opnieuw verstuurd.',
                                isSuccess: true);
                          }
                        } catch (_) {
                          if (context.mounted) {
                            showAppSnackBar(
                                context, 'Opnieuw versturen is niet gelukt.',
                                isError: true);
                          }
                        }
                      },
                      child: const Text(
                        'E-mail opnieuw',
                        style: TextStyle(color: AppColors.textPrimary),
                      ),
                    ),
                ],
              ),
            ),
          Expanded(
            child: messagesAsync.when(
              loading: () => ListView(
                padding: const EdgeInsets.all(20),
                children: const [
                  SkeletonCard(),
                  SizedBox(height: 10),
                  SkeletonCard(),
                ],
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Berichten konden niet worden geladen.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              data: (messages) {
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(supportMessagesProvider(widget.threadId));
                    ref.invalidate(supportThreadProvider(widget.threadId));
                    await ref.read(
                      supportMessagesProvider(widget.threadId).future,
                    );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _BerichtKaart(message: messages[index]);
                    },
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: threadAsync.maybeWhen(
              data: (thread) {
                if (thread.status == SupportThreadStatus.closed) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Text(
                      'Dit gesprek is afgerond. Open een nieuw gesprek als je opnieuw hulp nodig hebt.',
                      style: TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  );
                }
                return _Composer(
                  controller: _bericht,
                  bezig: _bezig,
                  onSend: _verstuur,
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool bezig;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.bezig,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 5,
              enabled: !bezig,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Typ een bericht',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            height: 48,
            child: ElevatedButton(
              onPressed: bezig ? null : onSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: bezig
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _BerichtKaart extends StatelessWidget {
  final SupportMessage message;

  const _BerichtKaart({required this.message});

  @override
  Widget build(BuildContext context) {
    final vanGebruiker = message.isVanGebruiker;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        backgroundColor: vanGebruiker ? SupportUi.iconBg : AppColors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  vanGebruiker ? 'Jij' : 'Klantio Support',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  SupportUi.formatWhen(message.createdAt),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message.body,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
