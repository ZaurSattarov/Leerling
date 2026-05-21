import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _wachtwoordCtrl = TextEditingController();
  final _bevestigCtrl = TextEditingController();
  bool _laden = false;
  bool _wachtwoordZichtbaar = false;
  bool _bevestigZichtbaar = false;

  @override
  void dispose() {
    _wachtwoordCtrl.dispose();
    _bevestigCtrl.dispose();
    super.dispose();
  }

  Future<void> _slaOpEnUitloggen() async {
    if (_laden) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _laden = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _wachtwoordCtrl.text),
      );
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/login');
    } on AuthException catch (e) {
      if (mounted) _toonFout(_vriendelijkeFout(e.message));
    } catch (e) {
      debugPrint('[password-recovery] onverwachte fout: $e');
      if (mounted) _toonFout('Wachtwoord opslaan mislukt. Probeer opnieuw.');
    } finally {
      if (mounted) setState(() => _laden = false);
    }
  }

  String _vriendelijkeFout(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('password') && m.contains('characters')) {
      return 'Wachtwoord moet minimaal 6 tekens bevatten.';
    }
    if (m.contains('same password')) {
      return 'Kies een ander wachtwoord dan je huidige.';
    }
    return 'Wachtwoord opslaan mislukt. Probeer opnieuw.';
  }

  void _toonFout(String bericht) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          bericht,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                Text(
                  'Nieuw wachtwoord',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Kies een nieuw wachtwoord voor je account',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 36),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _WachtwoordVeld(
                        controller: _wachtwoordCtrl,
                        hint: 'Nieuw wachtwoord (min. 6 tekens)',
                        zichtbaar: _wachtwoordZichtbaar,
                        onToggle: () => setState(
                          () => _wachtwoordZichtbaar = !_wachtwoordZichtbaar,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Vul een wachtwoord in';
                          }
                          if (v.length < 6) return 'Minimaal 6 tekens';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _WachtwoordVeld(
                        controller: _bevestigCtrl,
                        hint: 'Wachtwoord bevestigen',
                        zichtbaar: _bevestigZichtbaar,
                        onToggle: () => setState(
                          () => _bevestigZichtbaar = !_bevestigZichtbaar,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Bevestig je wachtwoord';
                          }
                          if (v != _wachtwoordCtrl.text) {
                            return 'Wachtwoorden komen niet overeen';
                          }
                          return null;
                        },
                        onSubmit: _slaOpEnUitloggen,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _laden ? null : _slaOpEnUitloggen,
                    child: _laden
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Wachtwoord opslaan ›',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WachtwoordVeld extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool zichtbaar;
  final VoidCallback onToggle;
  final String? Function(String?) validator;
  final VoidCallback? onSubmit;

  const _WachtwoordVeld({
    required this.controller,
    required this.hint,
    required this.zichtbaar,
    required this.onToggle,
    required this.validator,
    this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !zichtbaar,
      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.dark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.poppins(fontSize: 14, color: AppColors.textHint),
        suffixIcon: IconButton(
          icon: Icon(
            zichtbaar
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AppColors.textHint,
            size: 20,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dangerText),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
      onFieldSubmitted: onSubmit != null ? (_) => onSubmit!() : null,
    );
  }
}
