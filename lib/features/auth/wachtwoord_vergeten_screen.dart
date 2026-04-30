import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';

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
  bool _verstuurd = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await StudentService.stuurWachtwoordReset(_emailCtrl.text.trim());
      if (mounted) setState(() { _verstuurd = true; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Wachtwoord vergeten'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _verstuurd
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.mark_email_read_outlined,
                        color: AppColors.successText, size: 36),
                  ),
                  const SizedBox(height: 24),
                  const Text('E-mail verstuurd!',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  Text(
                    'Controleer je inbox voor ${_emailCtrl.text.trim()} en volg de link om je wachtwoord opnieuw in te stellen.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Terug naar inloggen'),
                  ),
                ],
              )
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Vul je e-mailadres in en we sturen je een link om je wachtwoord opnieuw in te stellen.',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 28),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'E-mailadres',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Vul je e-mailadres in';
                        if (!v.contains('@')) return 'Ongeldig e-mailadres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _reset,
                      child: _loading
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Verstuur reset link'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
