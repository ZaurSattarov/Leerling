import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';
import '../../shared/providers/auth_provider.dart';

/// Landing-scherm na registratie/login voor leerlingen die nog niet gekoppeld
/// zijn aan een rijschool. Toont TWEE opties:
///
///  1. QR-code scannen  -> /koppelcode/scan
///  2. Koppelcode invoeren -> /koppelcode/handmatig
///
/// Beide opties leiden uiteindelijk naar dezelfde canonical RPC
/// `koppel_leerling_met_code` via `KoppelFlow.koppelEnNavigeer`. Er is geen
/// tweede koppelmechanisme.
class KoppelKeuzeScreen extends ConsumerWidget {
  const KoppelKeuzeScreen({super.key});

  Future<void> _uitloggen(BuildContext context, WidgetRef ref) async {
    await StudentService.uitloggen();
    ref.invalidate(mijnProfielProvider);
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => _uitloggen(context, ref),
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
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.school_rounded,
                      color: AppColors.primary, size: 36),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Koppel je account',
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
                'Je rijinstructeur heeft een QR-code en een koppelcode voor '
                'je klaargezet. Kies hieronder hoe je wilt koppelen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),

              _KoppelOptieKaart(
                icoon: Icons.qr_code_scanner_rounded,
                titel: 'Scan QR-code',
                omschrijving:
                    'Richt je camera op de QR-code die je van je rijinstructeur '
                    'hebt gekregen.',
                aanbevolen: true,
                onTap: () => context.push('/koppelcode/scan'),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'of',
                      style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 12),
              _KoppelOptieKaart(
                icoon: Icons.keyboard_rounded,
                titel: 'Koppelcode invoeren',
                omschrijving:
                    'Typ de 8-tekens koppelcode handmatig in.',
                onTap: () => context.push('/koppelcode/handmatig'),
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

class _KoppelOptieKaart extends StatelessWidget {
  const _KoppelOptieKaart({
    required this.icoon,
    required this.titel,
    required this.omschrijving,
    required this.onTap,
    this.aanbevolen = false,
  });

  final IconData icoon;
  final String titel;
  final String omschrijving;
  final VoidCallback onTap;
  final bool aanbevolen;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  aanbevolen ? AppColors.primary : AppColors.borderLight,
              width: aanbevolen ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: aanbevolen
                      ? AppColors.primaryLight
                      : AppColors.iconPrimaryBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icoon,
                  color:
                      aanbevolen ? AppColors.primary : AppColors.iconPrimary,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          titel,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (aanbevolen) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'AANBEVOLEN',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      omschrijving,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
