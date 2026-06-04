import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';
import 'auth_design.dart';

class WachtwoordVergetenScreen extends StatefulWidget {
  const WachtwoordVergetenScreen({super.key});

  @override
  State<WachtwoordVergetenScreen> createState() =>
      _WachtwoordVergetenScreenState();
}

class _WachtwoordVergetenScreenState extends State<WachtwoordVergetenScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _emailCtrl.text.trim().toLowerCase();
      await StudentService.stuurWachtwoordReset(email);
      if (mounted) {
        context.go('/wachtwoord-reset-code', extra: email);
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _error = _vriendelijkeFout(e.message);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Herstelcode versturen mislukt. Controleer je verbinding.';
          _loading = false;
        });
      }
    }
  }

  String _vriendelijkeFout(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('rate limit') ||
        lower.contains('too many') ||
        lower.contains('security purposes')) {
      return 'Wacht even voordat je opnieuw een herstelcode aanvraagt.';
    }
    if (lower.contains('email') && lower.contains('invalid')) {
      return 'Ongeldig e-mailadres. Controleer het adres en probeer opnieuw.';
    }
    return 'Herstelcode versturen mislukt. Probeer opnieuw.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/login'),
        ),
        title: const Text('Wachtwoord vergeten'),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Wachtwoord vergeten?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Voer je e-mailadres in en we sturen je een herstelcode.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: AuthDesign.inputDecoration(
                        hint: 'E-mailadres',
                        iconData: Icons.email_outlined,
                      ),
                      validator: AuthDesign.validateEmail,
                      onFieldSubmitted: (_) => _reset(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AuthDesign.error, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: GoogleFonts.inter(
                                  color: AuthDesign.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: AuthDesign.primaryButtonStyle(),
                        onPressed: _loading ? null : _reset,
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Verstuur herstelcode'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
