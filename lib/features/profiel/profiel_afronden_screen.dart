import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/avatar_service.dart';
import '../../core/services/student_service.dart';
import '../../shared/providers/auth_provider.dart';

class ProfielAfrondenScreen extends ConsumerStatefulWidget {
  const ProfielAfrondenScreen({super.key});
  @override
  ConsumerState<ProfielAfrondenScreen> createState() =>
      _ProfielAfrondenScreenState();
}

class _ProfielAfrondenScreenState extends ConsumerState<ProfielAfrondenScreen> {
  final _formKey = GlobalKey<FormState>();
  final _achternaam = TextEditingController();
  DateTime? _geboortedatum;
  String? _avatarId;
  bool _saving = false;
  String? _error;
  bool _prefilled = false;

  @override
  void dispose() {
    _achternaam.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: 'Geboortedatum',
    );
    if (result != null) setState(() => _geboortedatum = result);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_geboortedatum == null) {
      setState(() => _error = 'Kies je geboortedatum.');
      return;
    }
    if (_avatarId == null) {
      setState(() => _error = 'Kies een avatar.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await StudentService.voltooiMijnProfiel(
        achternaam: _achternaam.text,
        geboortedatum: _geboortedatum!,
        avatarId: _avatarId!,
      );
      ref.invalidate(mijnProfielProvider);
      final profile = await ref.read(mijnProfielProvider.future);
      if (!mounted) return;
      if (profile?.isProfielCompleet != true) {
        setState(() {
          _saving = false;
          _error = 'Profiel is nog niet volledig opgeslagen. Probeer opnieuw.';
        });
        return;
      }
      context.go('/home');
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = StudentService.currentUser?.email ?? '';
    final profile = ref.watch(mijnProfielProvider).valueOrNull;
    if (!_prefilled && profile != null) {
      _prefilled = true;
      _achternaam.text = profile.achternaam;
      _avatarId = profile.avatarId;
      final rawDate = profile.geboortedatum;
      if (rawDate != null) _geboortedatum = DateTime.tryParse(rawDate);
    }
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        automaticallyImplyLeading: false,
        title: const Text('Maak je profiel af'),
        actions: [
          TextButton(
              onPressed: _saving
                  ? null
                  : () async {
                      await StudentService.uitloggen();
                      ref.invalidate(mijnProfielProvider);
                      if (context.mounted) context.go('/login');
                    },
              child: const Text('Uitloggen'))
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(padding: const EdgeInsets.all(20), children: [
            const Text('Nog een paar gegevens',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text(
                'Je profiel is al gekoppeld. Vul de ontbrekende gegevens aan om Klantio te gebruiken.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.4)),
            const SizedBox(height: 20),
            TextFormField(
                controller: _achternaam,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Achternaam'),
                validator: (v) => v?.trim().isEmpty == true
                    ? 'Achternaam is verplicht'
                    : null),
            const SizedBox(height: 14),
            InputDecorator(
                decoration: const InputDecoration(labelText: 'E-mailadres'),
                child: Text(email,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
            const SizedBox(height: 14),
            OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.cake_outlined),
                label: Text(_geboortedatum == null
                    ? 'Kies geboortedatum'
                    : '${_geboortedatum!.day}-${_geboortedatum!.month}-${_geboortedatum!.year}')),
            const SizedBox(height: 20),
            const Text('Kies een avatar',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5, mainAxisSpacing: 10, crossAxisSpacing: 10),
              itemCount: AvatarService.avatars.length,
              itemBuilder: (_, index) {
                final avatar = AvatarService.avatars[index];
                final selected = avatar.id == _avatarId;
                return InkWell(
                    onTap: () => setState(() => _avatarId = avatar.id),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: selected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                width: 3)),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(avatar.assetPath,
                                fit: BoxFit.cover))));
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(color: AppColors.dangerText))
            ],
            const SizedBox(height: 24),
            FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Opslaan…' : 'Profiel afronden')),
          ]),
        ),
      ),
    );
  }
}
