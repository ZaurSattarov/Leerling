import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/coach_widgets.dart';
import '../../shared/widgets/gradient_header.dart';
import '../../shared/providers/auth_provider.dart';
import 'les_logboek_item.dart';
import 'les_logboek_provider.dart';

class LesLogboekScreen extends ConsumerWidget {
  const LesLogboekScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessenAsync = ref.watch(lesLogboekProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: DetailGradientHeader(title: 'Les-logboek'),
          ),
          lessenAsync.when(
            data: (lessen) => SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList.separated(
                itemCount: lessen.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return _LogboekLesCard(
                    item: lessen[index],
                    onEditNote: () =>
                        _openNotitieSheet(context, ref, lessen[index]),
                  );
                },
              ),
            ),
            loading: () => SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SkeletonCard(),
                  const SizedBox(height: 12),
                  const SkeletonCard(),
                  const SizedBox(height: 12),
                  const SkeletonCard(),
                ]),
              ),
            ),
            error: (_, __) => SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Icon(Icons.history_rounded,
                          size: 48, color: AppColors.textHint),
                      const SizedBox(height: 12),
                      Text(
                        'Kon logboek niet laden',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Controleer je verbinding en probeer opnieuw.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openNotitieSheet(
    BuildContext context,
    WidgetRef ref,
    LesLogboekItem item,
  ) async {
    final profiel = await ref.read(mijnProfielProvider.future);
    if (!context.mounted || profiel == null) return;

    final opgeslagen = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LesNotitieSheet(
        initialValue: item.leerlingNotitie,
        onSave: (notitie) async {
          await StudentService.updateMijnLesNotitie(
            lesId: item.id,
            leerlingId: profiel.id,
            notitie: notitie,
          );
        },
      ),
    );

    if (opgeslagen == true) {
      ref.invalidate(lesLogboekProvider);
      ref.invalidate(laatsteLesLogboekItemProvider);
    }
  }
}

class _LogboekLesCard extends StatelessWidget {
  final LesLogboekItem item;
  final VoidCallback? onEditNote;

  const _LogboekLesCard({required this.item, this.onEditNote});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconBadge(
                icon: Icons.fact_check_rounded,
                color: AppColors.dark3,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.datumLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.tijdLabel}  ·  ${item.instructeur}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _AssessmentPill(label: item.beoordeling),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: item.onderwerpen
                .map((label) => NeutralChip(
                      label: label,
                      backgroundColor: AppColors.white,
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.neutralBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              item.feedback,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (item.leerlingNotitie?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mijn notitie',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.leerlingNotitie!,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (onEditNote != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onEditNote,
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: Text(item.leerlingNotitie?.isNotEmpty == true
                    ? 'Notitie bewerken'
                    : 'Mijn notitie toevoegen'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LesNotitieSheet extends StatefulWidget {
  final String? initialValue;
  final Future<void> Function(String? notitie) onSave;

  const _LesNotitieSheet({
    required this.initialValue,
    required this.onSave,
  });

  @override
  State<_LesNotitieSheet> createState() => _LesNotitieSheetState();
}

class _LesNotitieSheetState extends State<_LesNotitieSheet> {
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(_controller.text);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notitie opslaan mislukt')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Mijn notitie',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Schrijf kort wat je zelf wilt onthouden voor de volgende les.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText:
                      'Bijvoorbeeld: Volgende keer extra letten op spiegelen bij rotondes.',
                  filled: true,
                  fillColor: AppColors.neutralBg,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _saving ? null : () => Navigator.pop(context, false),
                      child: const Text('Annuleren'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Opslaan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssessmentPill extends StatelessWidget {
  final String label;

  const _AssessmentPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
