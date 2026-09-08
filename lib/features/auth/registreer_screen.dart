import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';
import 'auth_design.dart';
import 'social_login_widgets.dart';

class RegistreerScreen extends StatefulWidget {
  const RegistreerScreen({super.key});

  @override
  State<RegistreerScreen> createState() => _RegistreerScreenState();
}

class _RegistreerScreenState extends State<RegistreerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _wachtwoordCtrl = TextEditingController();
  bool _laden = false;
  bool _wachtwoordZichtbaar = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _wachtwoordCtrl.dispose();
    super.dispose();
  }

  Future<void> _registreren() async {
    if (_laden) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _laden = true);

    try {
      final email = _emailCtrl.text.trim().toLowerCase();

      // Registratiescherm vereenvoudigd (2026-09-01): uitsluitend
      // e-mailadres + wachtwoord. Geen naam meer in de signup-payload --
      // de bestaande koppel-/profielafrondflow (voltooi_leerling_profiel)
      // blijft verantwoordelijk voor persoonsgegevens, dus geen
      // dummy/lege naam nodig om iets te omzeilen. Geen enkele
      // trigger/RPC in de canonical Instructeur-repo leest
      // raw_user_meta_data voor leerlingen (geverifieerd) -- 'role'/'type'/
      // 'account_type' blijven staan, die zijn niet naam-gerelateerd.
      final response = await StudentService.registreren(
        email: email,
        wachtwoord: _wachtwoordCtrl.text,
        metadata: const {
          'role': 'leerling',
          'type': 'leerling',
          'account_type': 'leerling',
        },
      );

      final user = response.user;
      final isBevestigd = user?.emailConfirmedAt != null;
      if (isBevestigd) {
        _toonFout('Dit e-mailadres is al bevestigd. Log in om verder te gaan.');
        return;
      }

      if (mounted) context.go('/verificatie', extra: email);
    } on AuthException catch (e) {
      debugPrint('[registratie] Supabase AuthException: ${e.message}');
      if (_isBestaandOnbevestigdAccount(e.message)) {
        final email = _emailCtrl.text.trim().toLowerCase();
        try {
          await _stuurSignupCodeOpnieuw(email);
          if (mounted) context.go('/verificatie', extra: email);
          return;
        } on AuthException catch (resendError) {
          _toonFout(_vriendelijkeFout(resendError.message));
          return;
        }
      }
      _toonFout(_vriendelijkeFout(e.message));
    } catch (e) {
      debugPrint('[registratie] onbekende fout: $e');
      _toonFout('Registratie mislukt: $e');
    } finally {
      if (mounted) setState(() => _laden = false);
    }
  }

  // ── SOCIAL AUTH (2026-09-08) ─────────────────────────────────────────────
  // Zelfde knop/functie voor bestaande én nieuwe gebruikers -- er bestaat
  // BEWUST geen aparte "Registreren met Google/Facebook"-variant. De
  // OAuth-provider/Supabase bepaalt zelf of het om een login of een nieuwe
  // account-aanmaak gaat (signInWithIdToken/signInWithOAuth maken
  // automatisch een nieuwe auth.users-rij aan als er nog geen account met
  // dat e-mailadres bestaat). Deze handlers zijn bewust identiek aan hun
  // tegenhangers in login_screen.dart. Geen eigen profielactivatie hier --
  // de Leerling-app heeft die stap niet (zie student_service.dart); een
  // nieuw social-account wordt normaal, zoals elk nieuw account, pas via
  // de bestaande koppelcode-flow aan een leerlingprofiel gekoppeld.
  Future<void> _meldAanMetGoogle() async {
    if (_laden) return;
    FocusScope.of(context).unfocus();
    setState(() => _laden = true);

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
      _toonFout(_vriendelijkeFout(e.message));
    } on StateError catch (e) {
      debugPrint('[registratie][google] configuratiefout: ${e.message}');
      _toonFout('Google-login is momenteel niet beschikbaar.');
    } catch (e) {
      debugPrint('[registratie][google] onbekende fout: $e');
      _toonFout('Google-login mislukt. Controleer je verbinding.');
    } finally {
      if (mounted) setState(() => _laden = false);
    }
  }

  Future<void> _meldAanMetFacebook() async {
    if (_laden) return;
    FocusScope.of(context).unfocus();
    setState(() => _laden = true);

    try {
      // signInWithOAuth() start alleen de externe browser-/CustomTab-flow en
      // retourneert een bool (of het starten gelukt is), GEEN sessie. De
      // sessie/navigatie komt asynchroon binnen via GoRouter's eigen
      // redirect (gevoed door de refreshListenable/_AuthNotifier in
      // app.dart) -- zelfde mechanisme als voor elke andere inlogmethode,
      // geen eigen navigatie hier nodig.
      final gestart = await StudentService.meldAanMetFacebook();
      debugPrint('[registratie][facebook] signInWithOAuth gestart: $gestart');
    } on AuthException catch (e) {
      debugPrint(
        '[registratie][facebook] AuthException -- statusCode=${e.statusCode} code=${e.code}',
      );
      _toonFout(_vriendelijkeFout(e.message));
    } catch (e) {
      debugPrint(
          '[registratie][facebook] ${e.runtimeType}: kon login niet starten');
      _toonFout('Facebook-login mislukt. Controleer je verbinding.');
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

  Future<void> _stuurSignupCodeOpnieuw(String email) {
    return Supabase.instance.client.auth.resend(
      type: OtpType.signup,
      email: email,
      emailRedirectTo: AppConfig.authConfirmRedirectUrl,
    );
  }

  String _vriendelijkeFout(String msg) {
    final m = msg.toLowerCase();
    if (m.contains('only request this after') ||
        m.contains('security purposes')) {
      return 'Wacht even voordat je opnieuw een code aanvraagt.';
    }
    if (m.contains('rate limit') || m.contains('too many requests')) {
      return 'Wacht even voordat je opnieuw een code aanvraagt.';
    }
    if (m.contains('confirmation email') ||
        m.contains('error sending') ||
        m.contains('unexpected_failure')) {
      return 'De verificatiemail kon niet worden verzonden. Controleer de SMTP/Resend instellingen en probeer het daarna opnieuw.';
    }
    if (m.contains('already registered') ||
        m.contains('already exists') ||
        m.contains('user already') ||
        m.contains('duplicate')) {
      return 'Dit e-mailadres is al geregistreerd. Log in of gebruik een ander adres.';
    }
    if (m.contains('password') && m.contains('characters')) {
      return 'Wachtwoord moet minimaal 8 tekens bevatten.';
    }
    if (m.contains('database error') || m.contains('saving new user')) {
      return 'Registratie mislukt door een databasefout: $msg';
    }
    if (m.contains('email') && m.contains('invalid')) {
      return 'Ongeldig e-mailadres. Controleer het adres en probeer opnieuw.';
    }
    return 'Registratie mislukt: $msg';
  }

  void _toonFout(String bericht) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          bericht,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AuthDesign.error,
        behavior: SnackBarBehavior.floating,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
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
                    'assets/Inlogassets/Signup.png',
                    height: MediaQuery.sizeOf(context).height < 760 ? 140 : 165,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aan de slag',
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
                  'Maak een leerling account aan en volg je rijlessen',
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
                      const SizedBox(height: 12),
                      _WachtwoordVeld(
                        controller: _wachtwoordCtrl,
                        hint: 'Wachtwoord (min. 8 tekens)',
                        zichtbaar: _wachtwoordZichtbaar,
                        onToggle: () => setState(
                            () => _wachtwoordZichtbaar = !_wachtwoordZichtbaar),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Vul een wachtwoord in';
                          }
                          if (v.length < 8) return 'Minimaal 8 tekens';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: AuthDesign.primaryButtonStyle(),
                    onPressed: _laden ? null : _registreren,
                    child: _laden
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Account aanmaken ›',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
                const OfScheiding(),
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
                SocialLoginRij(
                  googleAan: _laden ? null : _meldAanMetGoogle,
                  facebookAan: _laden ? null : _meldAanMetFacebook,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Al een account? ',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        'Inloggen',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
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

  const _WachtwoordVeld({
    required this.controller,
    required this.hint,
    required this.zichtbaar,
    required this.onToggle,
    required this.validator,
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
    );
  }
}
