import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';
import '../../shared/providers/auth_provider.dart';
import 'koppel_flow.dart';

/// Handmatige koppelcode-invoer. Onderdeel van de bredere koppel-flow --
/// zie ook [KoppelKeuzeScreen] (de keuze-landing) en [QrScanScreen] (de
/// QR-scanner). Alledrie leiden tot dezelfde canonical RPC via
/// [KoppelFlow.koppelEnNavigeer]; er is geen tweede koppelmechanisme.
class KoppelcodeInvoerenScreen extends ConsumerStatefulWidget {
  const KoppelcodeInvoerenScreen({super.key});

  @override
  ConsumerState<KoppelcodeInvoerenScreen> createState() =>
      _KoppelcodeInvoerenScreenState();
}

class _KoppelcodeInvoerenScreenState
    extends ConsumerState<KoppelcodeInvoerenScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _koppel() async {
    if (!_formKey.currentState!.validate()) return;
    if (_loading) return; // dubbele submit voorkomen
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await KoppelFlow.koppelEnNavigeer(
        context: context,
        ref: ref,
        ruweCode: _codeCtrl.text,
      );
      // Navigatie is al door de flow gedaan.
    } on KoppelException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.boodschap;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _uitloggen() async {
    await StudentService.uitloggen();
    ref.invalidate(mijnProfielProvider);
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              )
            : null,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: _uitloggen,
            child: const Text(
              'Uitloggen',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Icoon
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.keyboard_rounded,
                      color: AppColors.primary, size: 36),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Koppelcode invoeren',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Voer de 8-tekens koppelcode in die je van je rijinstructeur hebt ontvangen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 40),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E2E7)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.dangerSolid, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: AppColors.dangerText, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'XXXXXXXX',
                        hintStyle: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 6,
                          color: AppColors.textMuted,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: AppColors.primary, width: 1.5),
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                      ),
                      onFieldSubmitted: (_) => _koppel(),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Vul de koppelcode in';
                        }
                        if (v.trim().length < 6) {
                          return 'Code moet minimaal 6 tekens zijn';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _koppel,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Koppelen'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'Geen code? Neem contact op met je rijinstructeur.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Backward-compatible alias -- oudere imports (bv. tests) verwijzen nog
/// naar `KoppelcodeScreen`. Zowel het handmatige invoerscherm zelf als de
/// nieuwe [KoppelKeuzeScreen] blijven volledig werkend.
@Deprecated('Gebruik KoppelcodeInvoerenScreen (/koppelcode/handmatig) of '
    'KoppelKeuzeScreen (/koppelcode).')
typedef KoppelcodeScreen = KoppelcodeInvoerenScreen;
