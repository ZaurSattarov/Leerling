import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';

class RegistreerScreen extends StatefulWidget {
  const RegistreerScreen({super.key});

  @override
  State<RegistreerScreen> createState() => _RegistreerScreenState();
}

class _RegistreerScreenState extends State<RegistreerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _naamCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _wachtwoordCtrl = TextEditingController();
  bool _laden = false;
  bool _wachtwoordZichtbaar = false;

  @override
  void dispose() {
    _naamCtrl.dispose();
    _emailCtrl.dispose();
    _wachtwoordCtrl.dispose();
    super.dispose();
  }

  Future<void> _registreren() async {
    if (_laden) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _laden = true);

    final naam = _naamCtrl.text.trim();
    final email = _emailCtrl.text.trim().toLowerCase();

    try {
      final response = await StudentService.registreren(
        email: email,
        wachtwoord: _wachtwoordCtrl.text,
        metadata: {
          'naam': naam,
          'full_name': naam,
          'role': 'leerling',
          'type': 'leerling',
        },
      );

      final user = response.user;
      final isBevestigd = user?.emailConfirmedAt != null;
      if (isBevestigd) {
        _toonFout(
            'Dit e-mailadres is al bevestigd. Log in om verder te gaan.');
        return;
      }

      if (mounted) context.go('/verificatie', extra: email);
    } on AuthException catch (e) {
      if (!mounted) return;
      if (_isBestaandOnbevestigdAccount(e.message)) {
        try {
          await _stuurCodeOpnieuw(email);
          if (mounted) context.go('/verificatie', extra: email);
          return;
        } on AuthException catch (resendError) {
          _toonFout(_vriendelijkeFout(resendError.message));
          return;
        }
      }
      _toonFout(_vriendelijkeFout(e.message));
    } catch (e) {
      if (mounted) _toonFout('Registratie mislukt. Probeer het opnieuw.');
    } finally {
      if (mounted) setState(() => _laden = false);
    }
  }

  bool _isBestaandOnbevestigdAccount(String msg) {
    final m = msg.toLowerCase();
    return m.contains('already registered') ||
        m.contains('already exists') ||
        m.contains('user already');
  }

  Future<void> _stuurCodeOpnieuw(String email) {
    return Supabase.instance.client.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: AppConfig.authConfirmRedirectUrl,
    );
  }

  String _vriendelijkeFout(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('only request this after') ||
        m.contains('security purposes') ||
        m.contains('rate limit') ||
        m.contains('too many requests')) {
      return 'Wacht even voordat je opnieuw een code aanvraagt.';
    }
    if (m.contains('already registered') ||
        m.contains('already exists') ||
        m.contains('user already')) {
      return 'Dit e-mailadres is al geregistreerd. Log in of gebruik een ander adres.';
    }
    if (m.contains('password') && m.contains('characters')) {
      return 'Wachtwoord moet minimaal 6 tekens bevatten.';
    }
    if (m.contains('email') && m.contains('invalid')) {
      return 'Ongeldig e-mailadres. Controleer het adres en probeer opnieuw.';
    }
    return 'Registratie mislukt. Probeer het opnieuw.';
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
                const SizedBox(height: 16),
                Center(
                  child: Image.asset(
                    'assets/Inlogassets/Signup.png',
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Account aanmaken',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Maak een leerling account aan en volg je rijlessen',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _Veld(
                        controller: _naamCtrl,
                        hint: 'Volledige naam',
                        suffixIcon: Icons.person_outline,
                        keyboardType: TextInputType.name,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Vul je naam in';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _Veld(
                        controller: _emailCtrl,
                        hint: 'E-mailadres',
                        suffixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          final email = v?.trim() ?? '';
                          if (email.isEmpty) return 'Vul je e-mailadres in';
                          final valid = RegExp(
                            r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                          ).hasMatch(email);
                          if (!valid) return 'Ongeldig e-mailadres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _WachtwoordVeld(
                        controller: _wachtwoordCtrl,
                        hint: 'Wachtwoord (min. 6 tekens)',
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
                        onSubmit: _registreren,
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
                    onPressed: _laden ? null : _registreren,
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
                            'Account aanmaken ›',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Al een account? ',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        'Inloggen',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
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

class _Veld extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData suffixIcon;
  final TextInputType keyboardType;
  final String? Function(String?) validator;

  const _Veld({
    required this.controller,
    required this.hint,
    required this.suffixIcon,
    required this.keyboardType,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      autocorrect: false,
      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.dark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            GoogleFonts.poppins(fontSize: 14, color: AppColors.textHint),
        suffixIcon: Icon(suffixIcon, color: AppColors.textHint, size: 20),
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
    );
  }
}

class _WachtwoordVeld extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool zichtbaar;
  final VoidCallback onToggle;
  final String? Function(String?) validator;
  final VoidCallback onSubmit;

  const _WachtwoordVeld({
    required this.controller,
    required this.hint,
    required this.zichtbaar,
    required this.onToggle,
    required this.validator,
    required this.onSubmit,
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
      onFieldSubmitted: (_) => onSubmit(),
    );
  }
}
