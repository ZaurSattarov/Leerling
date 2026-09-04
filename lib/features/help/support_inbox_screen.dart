import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../models/support_thread.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_detail_header.dart';
import 'support_provider.dart';
import 'widgets/support_ui.dart';

/// "Mijn supportvragen" -- 1-op-1 poort van de Instructeur-app
/// (support_inbox_screen.dart). Toont de eigen supportgesprekken van de
/// ingelogde leerling (RLS: `support_threads_select_own`, alleen eigen
/// threads).
class SupportInboxScreen extends ConsumerWidget {
  const SupportInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(supportThreadsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          MainDetailHeader(
            title: 'Eerdere gesprekken',
            fallbackRoute: '/help',
            actions: [
              IconButton(
                onPressed: () => context.push('/help'),
                tooltip: 'Naar de chat',
                icon: const Icon(Icons.chat_bubble_outline_rounded,
                    color: Colors.white),
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(supportThreadsProvider);
                await ref.read(supportThreadsProvider.future);
              },
              child: threadsAsync.when(
                loading: () => ListView(
                  padding: const EdgeInsets.all(20),
                  children: const [
                    SkeletonCard(),
                    SizedBox(height: 10),
                    SkeletonCard(),
                    SizedBox(height: 10),
                    SkeletonCard(),
                  ],
                ),
                error: (e, _) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  children: [
                    EmptyState(
                      icon: Icons.wifi_off_rounded,
                      title: 'Gesprekken konden niet worden geladen',
                      subtitle: e.toString(),
                    ),
                  ],
                ),
                data: (threads) {
                  if (threads.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children: [
                        AppCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 28),
                          child: Column(
                            children: [
                              const IconBadge(
                                icon: Icons.chat_bubble_outline_rounded,
                                color: SupportUi.accent,
                                size: 56,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Nog geen gesprekken',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Stuur ons een bericht. We reageren in dit gesprek.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              SupportPrimaryButton(
                                label: 'Nieuw gesprek',
                                onPressed: () =>
                                    context.push('/help'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    itemCount: threads.length,
                    itemBuilder: (context, index) {
                      final thread = threads[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ThreadTegel(
                          thread: thread,
                          onTap: () =>
                              context.push('/help/support/${thread.id}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadTegel extends StatelessWidget {
  final SupportThread thread;
  final VoidCallback onTap;

  const _ThreadTegel({required this.thread, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final categorieLabel = thread.category == null
        ? null
        : supportCategorieen
            .firstWhere(
              (c) => c.$1 == thread.category,
              orElse: () => (thread.category!, thread.category!),
            )
            .$2;

    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBadge(
            icon: Icons.forum_outlined,
            color: SupportUi.accent,
            size: 38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        thread.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: thread.heeftOngelezen
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (thread.heeftOngelezen)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: const BoxDecoration(
                          color: AppColors.infoSolid,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${thread.ticketLabel}${categorieLabel == null ? '' : ' · $categorieLabel'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  thread.lastMessagePreview.isEmpty
                      ? thread.ticketLabel
                      : thread.lastMessagePreview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SupportStatusChip(status: thread.status),
                    const Spacer(),
                    Text(
                      SupportUi.formatWhen(thread.lastMessageAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
