import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';

class RegistreerScreen extends StatefulWidget {
  const RegistreerScreen({super.key});

  @override
  State<RegistreerScreen> createState() => _RegistreerScreenState();
}

class _RegistreerScreenState extends State<RegistreerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passBevestigCtrl = TextEditingController();
  bool _loading = false;
  bool _passVisible = false;
  bool _passBevestigVisible = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passBevestigCtrl.dispose();
    super.dispose();
  }

  Future<void> _registreer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await StudentService.registreren(
        email: _emailCtrl.text.trim(),
        wachtwoord: _passCtrl.text,
      );

      if (!mounted) return;

      if (res.session == null) {
        // E-mailbevestiging vereist
        setState(() {
          _loading = false;
        });
        _toonBevestigingDialog(gaNaarKoppelcode: true);
        return;
      }

      // Direct ingelogd â€” ga naar koppelcode scherm
      context.go('/koppelcode');
    } catch (e) {
      debugPrint('[student.registreer_screen] fout=$e');
      if (!mounted) return;
      setState(() {
        _error = _vertaalFout(e.toString());
        _loading = false;
      });
    }
  }

  void _toonBevestigingDialog({bool gaNaarKoppelcode = false}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Bevestig je e-mail'),
        content: Text(
          'We hebben een bevestigingslink gestuurd naar ${_emailCtrl.text.trim()}. '
          'Klik op de link en log daarna in.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go(gaNaarKoppelcode ? '/koppelcode' : '/login');
            },
            child: Text(gaNaarKoppelcode ? 'Naar koppelcode' : 'Naar inloggen'),
          ),
        ],
      ),
    );
  }

  String _vertaalFout(String raw) {
    final normalized = raw.toLowerCase();

    if (normalized.contains('user already registered')) {
      return 'Er bestaat al een account met dit e-mailadres.';
    }
    if (normalized.contains('password should be at least') ||
        normalized.contains('password should be stronger')) {
      return 'Wachtwoord moet sterker zijn of minimaal 6 tekens bevatten.';
    }
    if (normalized.contains('database error saving new user') ||
        normalized.contains('duplicate key value') ||
        normalized.contains('instructeur_profielen_pkey')) {
      return 'Registratie is nu geblokkeerd door een database-configuratie. Voer de nieuwe Supabase migratie uit en probeer opnieuw.';
    }
    if (normalized.contains('email address') &&
        normalized.contains('invalid')) {
      return 'Het e-mailadres is ongeldig.';
    }
    if (normalized.contains('network') ||
        normalized.contains('socketexception')) {
      return 'Geen internetverbinding. Controleer je verbinding.';
    }
    return 'Registreren mislukt. Probeer het opnieuw.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.directions_car_rounded,
                      color: Colors.white, size: 32),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Account aanmaken',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Maak een leerling account aan',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.dangerBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.dangerText, size: 18),
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
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'E-mailadres',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Vul je e-mailadres in';
                        }
                        if (!v.contains('@')) {
                          return 'Ongeldig e-mailadres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: !_passVisible,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Wachtwoord',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_passVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () =>
                              setState(() => _passVisible = !_passVisible),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Vul een wachtwoord in';
                        }
                        if (v.length < 6) {
                          return 'Minimaal 6 tekens';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passBevestigCtrl,
                      obscureText: !_passBevestigVisible,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _registreer(),
                      decoration: InputDecoration(
                        labelText: 'Wachtwoord bevestigen',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_passBevestigVisible
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined),
                          onPressed: () => setState(() =>
                              _passBevestigVisible = !_passBevestigVisible),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Bevestig je wachtwoord';
                        }
                        if (v != _passCtrl.text) {
                          return 'Wachtwoorden komen niet overeen';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _registreer,
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Account aanmaken'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Al een account?',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Inloggen'),
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
