import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _wachtwoordCtrl = TextEditingController();
  bool _laden = false;
  bool _wachtwoordZichtbaar = false;
  bool _onthoudenMij = false;
  String? _fout;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _wachtwoordCtrl.dispose();
    super.dispose();
  }

  Future<void> _inloggen() async {
    if (_laden) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _laden = true;
      _fout = null;
    });

    try {
      await StudentService.inloggen(
        email: _emailCtrl.text.trim(),
        wachtwoord: _wachtwoordCtrl.text,
      );
      if (!mounted) return;

      final profiel = await StudentService.getMijnProfiel();
      if (!mounted) return;

      if (profiel == null) {
        context.go('/koppelcode');
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fout = _vriendelijkeFout(e.toString());
        _laden = false;
      });
    } finally {
      if (mounted && _laden) setState(() => _laden = false);
    }
  }

  String _vriendelijkeFout(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'E-mailadres of wachtwoord is onjuist.';
    }
    if (m.contains('email not confirmed') || m.contains('not verified')) {
      return 'Je e-mailadres is nog niet bevestigd.';
    }
    if (m.contains('too many requests')) {
      return 'Te veel pogingen. Wacht even en probeer opnieuw.';
    }
    if (m.contains('network') || m.contains('socketexception')) {
      return 'Geen internetverbinding. Controleer je verbinding.';
    }
    return 'Inloggen mislukt. Probeer het opnieuw.';
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
                    'assets/Inlogassets/Login-bro.png',
                    height: 220,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Welkom terug',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Log in met je leerling account',
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
                        controller: _emailCtrl,
                        hint: 'E-mailadres',
                        suffixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Vul je e-mailadres in';
                          }
                          if (!v.contains('@')) return 'Ongeldig e-mailadres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      _WachtwoordVeld(
                        controller: _wachtwoordCtrl,
                        hint: 'Wachtwoord',
                        zichtbaar: _wachtwoordZichtbaar,
                        onToggle: () => setState(
                            () => _wachtwoordZichtbaar = !_wachtwoordZichtbaar),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Vul je wachtwoord in';
                          }
                          return null;
                        },
                        onSubmit: _inloggen,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _onthoudenMij,
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        onChanged: (v) =>
                            setState(() => _onthoudenMij = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Onthoud mij',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.go('/wachtwoord-vergeten'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Wachtwoord vergeten?',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_fout != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.24),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _fout!,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _fout = null),
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _laden ? null : _inloggen,
                    child: _laden
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Inloggen ›',
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
                      'Nieuw hier? ',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/registreer'),
                      child: Text(
                        'Registreer nu',
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
