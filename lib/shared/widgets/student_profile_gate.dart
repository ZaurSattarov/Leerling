import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
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
        return child;
      },
      loading: () => const _ProfileGateLoading(),
      error: (_, __) {
        _goToKoppelcode(context);
        return const _ProfileGateLoading();
      },
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
