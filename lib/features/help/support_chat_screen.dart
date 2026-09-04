import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';
import '../../core/services/support_service.dart';
import '../../models/support_thread.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_detail_header.dart';
import '../../shared/widgets/snackbar.dart';
import 'support_provider.dart';
import 'widgets/support_ui.dart';

/// Help & Support -- opent altijd direct de chat, geen tussenliggende
/// hub/FAQ-keuze en geen apart onderwerp-/categorieformulier meer (redesign
/// 2026-09-04). 1-op-1 poort van de Instructeur-app
/// (support_chat_screen.dart) -- zelfde drie situaties, zelfde backend
/// (support-chat, support_threads_app, RLS), leerlinggerichte navigatie.
class SupportChatScreen extends ConsumerStatefulWidget {
  final String? threadId;

  const SupportChatScreen({super.key, this.threadId});

  @override
  ConsumerState<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends ConsumerState<SupportChatScreen> {
  bool _forceNewChat = false;

  @override
  Widget build(BuildContext context) {
    if (widget.threadId != null) {
      return _ThreadView(threadId: widget.threadId!, isExplicitRoute: true);
    }
    if (_forceNewChat) {
      return _EmptyComposerView(
        onCreated: () {
          if (!mounted) return;
          setState(() => _forceNewChat = false);
          ref.invalidate(activeSupportThreadProvider);
        },
      );
    }

    final activeAsync = ref.watch(activeSupportThreadProvider);
    return activeAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(
          children: [
            const MainDetailHeader(title: 'Support', fallbackRoute: '/home'),
            const Expanded(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    SkeletonCard(),
                    SizedBox(height: 10),
                    SkeletonCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(
          children: [
            const MainDetailHeader(title: 'Support', fallbackRoute: '/home'),
            Expanded(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  EmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: 'Support kon niet worden geladen',
                    subtitle: e.toString(),
                  ),
                  const SizedBox(height: 16),
                  SupportPrimaryButton(
                    label: 'Opnieuw proberen',
                    onPressed: () => ref.invalidate(activeSupportThreadProvider),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      data: (thread) {
        if (thread == null) {
          return const _EmptyComposerView();
        }
        if (thread.status == SupportThreadStatus.closed) {
          return _ClosedView(
            onStartNew: () => setState(() => _forceNewChat = true),
          );
        }
        return _ThreadView(threadId: thread.id, isExplicitRoute: false);
      },
    );
  }
}

class _ClosedView extends StatelessWidget {
  final VoidCallback onStartNew;
  const _ClosedView({required this.onStartNew});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          MainDetailHeader(
            title: 'Support',
            fallbackRoute: '/home',
            actions: [
              IconButton(
                onPressed: () => context.push('/help/gesprekken'),
                tooltip: 'Eerdere gesprekken',
                icon: const Icon(Icons.history_rounded, color: Colors.white),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const IconBadge(
                      icon: Icons.check_circle_outline_rounded,
                      color: SupportUi.accent,
                      size: 56,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Je vorige gesprek is afgesloten.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Heb je nog hulp nodig? Start een nieuw gesprek.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SupportPrimaryButton(
                      label: 'Nieuwe chat starten',
                      onPressed: onStartNew,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lege staat: nog geen gesprek (of expliciet "nieuwe chat starten" na een
/// afgesloten gesprek). Toont direct een composer.
class _EmptyComposerView extends ConsumerStatefulWidget {
  final VoidCallback? onCreated;
  const _EmptyComposerView({this.onCreated});

  @override
  ConsumerState<_EmptyComposerView> createState() =>
      _EmptyComposerViewState();
}

class _EmptyComposerViewState extends ConsumerState<_EmptyComposerView> {
  final _bericht = TextEditingController();
  _PickedImage? _picked;
  bool _bezig = false;

  @override
  void dispose() {
    _bericht.dispose();
    super.dispose();
  }

  Future<void> _verstuur() async {
    final body = _bericht.text.trim();
    if (body.isEmpty && _picked == null) return;
    setState(() => _bezig = true);
    try {
      SupportAttachment? attachment;
      if (_picked != null) {
        attachment = await SupportService.uploadAttachment(
          bytes: _picked!.bytes,
          mimeType: _picked!.mime,
        );
      }
      await SupportService.createThread(body: body, attachment: attachment);
      if (!mounted) return;
      _bericht.clear();
      setState(() => _picked = null);
      ref.invalidate(supportThreadsProvider);
      widget.onCreated?.call();
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, supportFoutmelding(e), isError: true);
    } finally {
      if (mounted) setState(() => _bezig = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          MainDetailHeader(
            title: 'Support',
            fallbackRoute: '/home',
            actions: [
              IconButton(
                onPressed: () => context.push('/help/gesprekken'),
                tooltip: 'Eerdere gesprekken',
                icon: const Icon(Icons.history_rounded, color: Colors.white),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Waarmee kunnen we je helpen?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Stuur ons je vraag. We reageren zo snel mogelijk in dit gesprek.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: _Composer(
              controller: _bericht,
              bezig: _bezig,
              picked: _picked,
              onPickedChanged: (p) => setState(() => _picked = p),
              onSend: _verstuur,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bestaand gesprek (elke status). Houdt een realtime-kanaal open op
/// support_messages/support_threads voor dit gesprek (Punt 7).
class _ThreadView extends ConsumerStatefulWidget {
  final String threadId;
  final bool isExplicitRoute;

  const _ThreadView({required this.threadId, required this.isExplicitRoute});

  @override
  ConsumerState<_ThreadView> createState() => _ThreadViewState();
}

class _ThreadViewState extends ConsumerState<_ThreadView> {
  final _bericht = TextEditingController();
  _PickedImage? _picked;
  bool _bezig = false;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SupportService.markRead(widget.threadId).then((_) {
        if (!mounted) return;
        ref.invalidate(supportThreadsProvider);
        ref.invalidate(supportThreadProvider(widget.threadId));
        ref.invalidate(activeSupportThreadProvider);
      });
    });
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    final client = StudentService.client;
    _channel = client
        .channel('support_thread_${widget.threadId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'support_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'thread_id',
            value: widget.threadId,
          ),
          callback: (_) {
            if (!mounted) return;
            ref.invalidate(supportMessagesProvider(widget.threadId));
            ref.invalidate(supportThreadProvider(widget.threadId));
            ref.invalidate(supportThreadsProvider);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'support_threads',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.threadId,
          ),
          callback: (_) {
            if (!mounted) return;
            ref.invalidate(supportThreadProvider(widget.threadId));
            ref.invalidate(activeSupportThreadProvider);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    final channel = _channel;
    if (channel != null) {
      StudentService.client.removeChannel(channel);
    }
    _bericht.dispose();
    super.dispose();
  }

  void _goBack(BuildContext context) {
    if (widget.isExplicitRoute) {
      context.go('/help');
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _verstuur() async {
    final body = _bericht.text.trim();
    if (body.isEmpty && _picked == null) return;
    setState(() => _bezig = true);
    try {
      SupportAttachment? attachment;
      if (_picked != null) {
        attachment = await SupportService.uploadAttachment(
          bytes: _picked!.bytes,
          mimeType: _picked!.mime,
        );
      }
      final result = await SupportService.reply(
        threadId: widget.threadId,
        body: body,
        attachment: attachment,
      );
      if (!mounted) return;
      _bericht.clear();
      setState(() => _picked = null);
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
            loading: () => MainDetailHeader(
              title: 'Support',
              fallbackRoute: '/home',
              onBack: () => _goBack(context),
            ),
            error: (_, __) => MainDetailHeader(
              title: 'Support',
              fallbackRoute: '/home',
              onBack: () => _goBack(context),
            ),
            data: (thread) => MainDetailHeader(
              title: thread.subject,
              fallbackRoute: '/home',
              onBack: () => _goBack(context),
              actions: [
                IconButton(
                  onPressed: () => context.push('/help/gesprekken'),
                  tooltip: 'Eerdere gesprekken',
                  icon: const Icon(Icons.history_rounded, color: Colors.white),
                ),
              ],
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
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _BerichtKaart(message: messages[index]);
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: threadAsync.maybeWhen(
              data: (thread) {
                if (thread.status == SupportThreadStatus.closed) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Dit gesprek is afgerond. Open een nieuw gesprek als je opnieuw hulp nodig hebt.',
                          style: TextStyle(
                              fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                        if (!widget.isExplicitRoute) ...[
                          const SizedBox(height: 10),
                          SupportPrimaryButton(
                            label: 'Nieuwe chat starten',
                            onPressed: () => context.go('/help'),
                          ),
                        ],
                      ],
                    ),
                  );
                }
                return _Composer(
                  controller: _bericht,
                  bezig: _bezig,
                  picked: _picked,
                  onPickedChanged: (p) => setState(() => _picked = p),
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

class _PickedImage {
  final Uint8List bytes;
  final String mime;
  const _PickedImage({required this.bytes, required this.mime});
}

Future<_PickedImage?> _pickImage(BuildContext context, ImageSource source) async {
  final file = await ImagePicker().pickImage(
    source: source,
    imageQuality: 82,
    maxWidth: 2000,
  );
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  final name = file.name.toLowerCase();
  final mime = name.endsWith('.png')
      ? 'image/png'
      : name.endsWith('.webp')
          ? 'image/webp'
          : name.endsWith('.heic')
              ? 'image/heic'
              : name.endsWith('.heif')
                  ? 'image/heif'
                  : 'image/jpeg';
  return _PickedImage(bytes: bytes, mime: mime);
}

Future<void> _showAttachmentSheet(
  BuildContext context,
  ValueChanged<_PickedImage> onPicked,
) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.primary),
              title: const Text('Maak een foto'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final picked = await _pickImage(context, ImageSource.camera);
                if (picked != null) onPicked(picked);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: const Text('Kies uit galerij'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                final picked = await _pickImage(context, ImageSource.gallery);
                if (picked != null) onPicked(picked);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool bezig;
  final _PickedImage? picked;
  final ValueChanged<_PickedImage?> onPickedChanged;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.bezig,
    required this.picked,
    required this.onPickedChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (picked != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        picked!.bytes,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: -8,
                      right: -8,
                      child: GestureDetector(
                        onTap: () => onPickedChanged(null),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.textPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: IconButton(
                  onPressed: bezig
                      ? null
                      : () => _showAttachmentSheet(
                            context,
                            (p) => onPickedChanged(p),
                          ),
                  tooltip: 'Foto toevoegen',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.camera_alt_outlined,
                      color: AppColors.primary, size: 20),
                ),
              ),
              const SizedBox(width: 8),
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
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          const BorderSide(color: AppColors.primary, width: 1.15),
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
      child: Align(
        alignment: vanGebruiker ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: vanGebruiker ? AppColors.primary : AppColors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(vanGebruiker ? 16 : 4),
                bottomRight: Radius.circular(vanGebruiker ? 4 : 16),
              ),
              border: vanGebruiker ? null : Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vanGebruiker ? 'Jij' : 'Klantio Support',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: vanGebruiker
                        ? Colors.white.withValues(alpha: 0.85)
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                if (message.heeftBijlage) ...[
                  _AttachmentPreview(
                    path: message.attachmentPath!,
                    vanGebruiker: vanGebruiker,
                  ),
                  const SizedBox(height: 6),
                ],
                if (message.body.isNotEmpty && message.body != '📷 Foto')
                  Text(
                    message.body,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: vanGebruiker ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    SupportUi.formatWhen(message.createdAt),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: vanGebruiker
                          ? Colors.white.withValues(alpha: 0.75)
                          : AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  final String path;
  final bool vanGebruiker;

  const _AttachmentPreview({required this.path, required this.vanGebruiker});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: SupportService.signedAttachmentUrl(path),
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null) {
          return Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: vanGebruiker
                  ? Colors.white.withValues(alpha: 0.15)
                  : SupportUi.iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return GestureDetector(
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.black,
              insetPadding: const EdgeInsets.all(12),
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              width: 180,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 180,
                height: 180,
                color: SupportUi.iconBg,
                child: const Icon(Icons.broken_image_outlined,
                    color: AppColors.textHint),
              ),
            ),
          ),
        );
      },
    );
  }
}
