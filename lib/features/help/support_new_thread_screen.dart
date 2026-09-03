import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/support_service.dart';
import '../../models/support_thread.dart';
import '../../shared/widgets/main_detail_header.dart';
import '../../shared/widgets/snackbar.dart';
import 'support_provider.dart';
import 'widgets/support_ui.dart';

/// "Nieuw gesprek" -- 1-op-1 poort van de Instructeur-app
/// (support_new_thread_screen.dart) met leerlinggerichte categorieën
/// (zie [supportCategorieen]). `product_context` wordt server-side bepaald
/// door de Edge Function (op basis van het ingelogde account) -- deze
/// schermcode stuurt dat veld bewust niet mee.
class SupportNewThreadScreen extends ConsumerStatefulWidget {
  final String? initialCategory;

  const SupportNewThreadScreen({super.key, this.initialCategory});

  @override
  ConsumerState<SupportNewThreadScreen> createState() =>
      _SupportNewThreadScreenState();
}

class _SupportNewThreadScreenState
    extends ConsumerState<SupportNewThreadScreen> {
  final _onderwerp = TextEditingController();
  final _bericht = TextEditingController();
  String _categorie = 'overig';
  bool _bezig = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialCategory;
    if (initial != null && supportCategorieen.any((c) => c.$1 == initial)) {
      _categorie = initial;
    }
  }

  @override
  void dispose() {
    _onderwerp.dispose();
    _bericht.dispose();
    super.dispose();
  }

  Future<void> _verstuur() async {
    final subject = _onderwerp.text.trim();
    final body = _bericht.text.trim();
    if (subject.isEmpty || body.isEmpty) {
      showAppSnackBar(context, 'Vul een onderwerp en bericht in.',
          isError: true);
      return;
    }
    setState(() => _bezig = true);
    try {
      final result = await SupportService.createThread(
        subject: subject,
        body: body,
        category: _categorie,
      );
      if (!mounted) return;
      ref.invalidate(supportThreadsProvider);
      showAppSnackBar(context, 'Je bericht is verstuurd.', isSuccess: true);
      context.go('/help/support/${result.threadId}');
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
          const MainDetailHeader(
            title: 'Nieuw gesprek',
            fallbackRoute: '/help/support',
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Categorie',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in supportCategorieen)
                      ChoiceChip(
                        label: Text(item.$2),
                        selected: _categorie == item.$1,
                        onSelected: (_) => setState(() => _categorie = item.$1),
                        selectedColor: AppColors.textPrimary,
                        labelStyle: TextStyle(
                          color: _categorie == item.$1
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Onderwerp',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _onderwerp,
                  maxLength: 120,
                  textCapitalization: TextCapitalization.sentences,
                  decoration:
                      _inputDecoration('Bijvoorbeeld: Vraag over factuur'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bericht',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _bericht,
                  minLines: 6,
                  maxLines: 12,
                  maxLength: 8000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration(
                      'Beschrijf kort waar je hulp bij nodig hebt'),
                ),
                const SizedBox(height: 20),
                SupportPrimaryButton(
                  label: 'Versturen',
                  loading: _bezig,
                  onPressed: _verstuur,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.15),
      ),
    );
  }
}
