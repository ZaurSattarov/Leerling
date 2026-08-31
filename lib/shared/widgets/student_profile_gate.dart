import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';
import '../providers/auth_provider.dart';

class StudentProfileGate extends ConsumerWidget {
  const StudentProfileGate({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profielAsync = ref.watch(mijnProfielProvider);

    return profielAsync.when(
      data: (profiel) {
        if (profiel == null) {
          _goToKoppelcode(context);
          return const _ProfileGateLoading();
        }
        if (!profiel.isProfielCompleet) {
          _goToProfileCompletion(context);
          return const _ProfileGateLoading();
        }
        return child;
      },
      loading: () => const _ProfileGateLoading(),
      error: (error, _) => _ProfileGateError(
        wasKnownCoupled:
            error is ProfileLookupException && error.wasKnownCoupled,
        onRetry: () => ref.invalidate(mijnProfielProvider),
      ),
    );
  }

  static void _goToKoppelcode(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (GoRouterState.of(context).uri.path != '/koppelcode') {
        context.go('/koppelcode');
      }
    });
  }

  static void _goToProfileCompletion(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (GoRouterState.of(context).uri.path != '/profiel-afronden') {
        context.go('/profiel-afronden');
      }
    });
  }
}

class _ProfileGateError extends StatelessWidget {
  const _ProfileGateError({
    required this.wasKnownCoupled,
    required this.onRetry,
  });

  final bool wasKnownCoupled;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  color: AppColors.textSecondary,
                  size: 40,
                ),
                const SizedBox(height: 16),
                Text(
                  wasKnownCoupled
                      ? 'Koppeling behouden'
                      : 'Profiel tijdelijk niet beschikbaar',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Controleer je internetverbinding en probeer het opnieuw. Je hoeft geen koppelcode opnieuw in te voeren.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  key: const Key('profile-gate-retry'),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Opnieuw proberen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileGateLoading extends StatelessWidget {
  const _ProfileGateLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}
