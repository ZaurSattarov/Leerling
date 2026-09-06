import 'dart:io' show Platform;

import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, visibleForTesting;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';
import 'auth_design.dart';

/// Apple-login alleen op iOS. Op Android en web nooit tonen of aanroepen.
@visibleForTesting
bool leerlingToonAppleLogin({
  bool? isWeb,
  bool? isAndroid,
  bool? isIOS,
  TargetPlatform? platform,
}) {
  final web = isWeb ?? kIsWeb;
  if (web) return false;

  final android = isAndroid ?? (!kIsWeb && Platform.isAndroid);
  if (android) return false;

  final ios = isIOS ?? (!kIsWeb && Platform.isIOS);
  final doel = platform ?? defaultTargetPlatform;
  return ios || doel == TargetPlatform.iOS;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _rememberEmailKey = 'auth_remembered_email';

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _wachtwoordCtrl = TextEditingController();
  bool _laden = false;
  bool _wachtwoordZichtbaar = false;
  bool _onthoudenMij = false;
  String? _fout;

  @override
  void initState() {
    super.initState();
    _laadOnthoudenEmail();
  }

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
      final response = await StudentService.inloggen(
        email: _emailCtrl.text.trim(),
        wachtwoord: _wachtwoordCtrl.text,
      );
      if (response.session == null || response.user == null) {
        setState(() => _fout = 'Inloggen lukte niet. Probeer opnieuw.');
        return;
      }
      await _bewaarOnthoudenEmail();
      if (response.user!.emailConfirmedAt == null) {
        await StudentService.uitloggen();
        if (mounted) {
          context.go('/verificatie',
              extra: _emailCtrl.text.trim().toLowerCase());
        }
        return;
      }
      if (!mounted) return;
      final profiel = await StudentService.getMijnProfiel();
      if (mounted) context.go(profiel != null ? '/home' : '/koppelcode');
    } on AuthException catch (e) {
      if (mounted) setState(() => _fout = _vriendelijkeFout(e.message));
    } catch (_) {
      if (mounted) {
        setState(() => _fout = 'Inloggen mislukt. Controleer je verbinding.');
      }
    } finally {
      if (mounted) setState(() => _laden = false);
    }
  }

  Future<void> _meldAanMetGoogle() async {
    if (_laden) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _laden = true;
      _fout = null;
    });

    try {
      final response = await StudentService.meldAanMetGoogle();
      if (response == null) {
        // Gebruiker annuleerde de Google-accountkiezer -- normaal gedrag,
        // geen foutmelding tonen.
        return;
      }
      if (!mounted) return;
      final profiel = await StudentService.getMijnProfiel();
      if (mounted) context.go(profiel != null ? '/home' : '/koppelcode');
    } on AuthException catch (e) {
      if (mounted) setState(() => _fout = _vriendelijkeFout(e.message));
    } on StateError catch (e) {
      debugPrint('[login][google] configuratiefout: ${e.message}');
      if (mounted) {
        setState(() => _fout = 'Google-login is momenteel niet beschikbaar.');
      }
    } catch (e) {
      debugPrint('[login][google] onbekende fout: $e');
      if (mounted) {
        setState(
            () => _fout = 'Google-login mislukt. Controleer je verbinding.');
      }
    } finally {
      if (mounted) setState(() => _laden = false);
    }
  }

  Future<void> _meldAanMetFacebook() async {
    if (_laden) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _laden = true;
      _fout = null;
    });

    try {
      final response = await StudentService.meldAanMetFacebook();
      if (response == null) {
        // Gebruiker annuleerde de Facebook-login -- normaal gedrag, geen
        // foutmelding tonen.
        return;
      }
      if (!mounted) return;
      final profiel = await StudentService.getMijnProfiel();
      if (mounted) context.go(profiel != null ? '/home' : '/koppelcode');
    } on AuthException catch (e) {
      if (mounted) setState(() => _fout = _vriendelijkeFout(e.message));
    } on StateError catch (e) {
      debugPrint('[login][facebook] configuratiefout: ${e.message}');
      if (mounted) {
        setState(
            () => _fout = 'Facebook-login is momenteel niet beschikbaar.');
      }
    } catch (e) {
      debugPrint('[login][facebook] onbekende fout: $e');
      if (mounted) {
        setState(() =>
            _fout = 'Facebook-login mislukt. Controleer je verbinding.');
      }
    } finally {
      if (mounted) setState(() => _laden = false);
    }
  }

  Future<void> _laadOnthoudenEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_rememberEmailKey);
    if (!mounted || email == null || email.isEmpty) return;
    setState(() {
      _emailCtrl.text = email;
      _onthoudenMij = true;
    });
  }

  Future<void> _bewaarOnthoudenEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (_onthoudenMij) {
      await prefs.setString(
        _rememberEmailKey,
        _emailCtrl.text.trim().toLowerCase(),
      );
    } else {
      await prefs.remove(_rememberEmailKey);
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
    return 'Inloggen mislukt: $msg';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Image.asset(
                    'assets/Inlogassets/Login-bro.png',
                    height: MediaQuery.sizeOf(context).height < 700 ? 150 : 180,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welkom terug',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Log in met je leerling account',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _Veld(
                        controller: _emailCtrl,
                        hint: 'E-mailadres',
                        suffixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: AuthDesign.validateEmail,
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
                const SizedBox(height: 10),
                Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () =>
                          setState(() => _onthoudenMij = !_onthoudenMij),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _onthoudenMij,
                            activeColor: AppColors.primary,
                            checkColor: Colors.white,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5)),
                            onChanged: (v) =>
                                setState(() => _onthoudenMij = v ?? false),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Onthoud mij',
                      style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
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
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8FA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F2F5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.error_outline_rounded,
                              color: Color(0xFFB91C1C), size: 17),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _fout!,
                            style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _fout = null),
                          child: const Icon(Icons.close_rounded,
                              color: AppColors.textHint, size: 16),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: AuthDesign.primaryButtonStyle(),
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
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                const _OfScheiding(),
                const SizedBox(height: 16),
                Text(
                  'Of ga verder met',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                _SocialLoginRij(
                  googleAan: _laden ? null : _meldAanMetGoogle,
                  facebookAan: _laden ? null : _meldAanMetFacebook,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Nieuw hier? ',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/registreer'),
                      child: Text(
                        'Registreer nu',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
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
      enableSuggestions: keyboardType != TextInputType.emailAddress,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.dark),
      decoration: AuthDesign.inputDecoration(hint: hint, iconData: suffixIcon),
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
      autocorrect: false,
      enableSuggestions: false,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.dark),
      decoration: AuthDesign.inputDecoration(
        hint: hint,
        iconData: Icons.lock_outline_rounded,
        suffixIcon: IconButton(
          icon: Icon(
            zichtbaar
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: AuthDesign.icon,
            size: 20,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: validator,
      onFieldSubmitted: (_) => onSubmit(),
    );
  }
}

class _SocialLoginRij extends StatelessWidget {
  final VoidCallback? googleAan;
  final VoidCallback? facebookAan;

  const _SocialLoginRij({
    required this.googleAan,
    required this.facebookAan,
  });

  Widget _googleKnop() {
    return _SocialLoginKnop(
      label: 'Inloggen met Google',
      onPressed: googleAan,
      child: Image.asset(
        'assets/icons/google_logo.png',
        height: 22,
        width: 22,
      ),
    );
  }

  Widget _facebookKnop() {
    return _SocialLoginKnop(
      label: 'Inloggen met Facebook',
      onPressed: facebookAan,
      // Officieel, herkenbaar Facebook-logo (ingebouwd Material-icoon, geen
      // los asset nodig) in het officiële Facebook-blauw.
      child: const Icon(
        Icons.facebook,
        size: 26,
        color: Color(0xFF1877F2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Google en Facebook altijd naast elkaar, op zowel Android als iOS --
    // zelfde rij-opbouw/styling als voorheen (Expanded + 12px tussenruimte).
    return Row(
      children: [
        Expanded(child: _googleKnop()),
        const SizedBox(width: 12),
        Expanded(child: _facebookKnop()),
      ],
    );
  }
}

class _OfScheiding extends StatelessWidget {
  const _OfScheiding();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: AppColors.textHint.withValues(alpha: 0.3)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'of',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: AppColors.textHint.withValues(alpha: 0.3)),
        ),
      ],
    );
  }
}

class _SocialLoginKnop extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget child;

  const _SocialLoginKnop({
    required this.label,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final hoogte = MediaQuery.sizeOf(context).height < 700 ? 48.0 : 52.0;
    return SizedBox(
      height: hoogte,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Semantics(
            button: true,
            label: label,
            child: Ink(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
