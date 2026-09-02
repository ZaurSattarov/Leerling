import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';
import '../../shared/widgets/main_scaffold.dart'
    show showKlantioNavbarSafeSheet;
import '../../shared/widgets/snackbar.dart';

export 'account_deletion_exception.dart';

bool isLeerlingDeleteConfirmation(String raw) =>
    raw.trim().toUpperCase() == 'VERWIJDER';

/// Canonical leerling self-service account-delete. Geen tweede verwijderpad.
class AccountDeletionFlow {
  AccountDeletionFlow._();

  static Future<void> start(
    BuildContext context, {
    Future<void> Function()? deleteAccount,
    Future<void> Function()? signOut,
  }) async {
    if (!context.mounted) return;
    final router = GoRouter.of(context);

    final bevestigd = await _toonBevestigingSheet(
      context,
      deleteAccount: deleteAccount ?? StudentService.verwijderAccount,
    );
    if (bevestigd != true) return;

    await finishSuccessfulDeletion(
      router: router,
      signOut: signOut ?? StudentService.uitloggen,
    );
  }

  /// Na backend-succes: sessie beëindigen en exact één keer naar login.
  /// [router] moet vóór de async delete zijn vastgelegd — niet via het
  /// stervende shell-`BuildContext` na `signOut`.
  @visibleForTesting
  static Future<void> finishSuccessfulDeletion({
    required GoRouter router,
    required Future<void> Function() signOut,
  }) async {
    await signOut();
    router.go('/login');
  }

  static Future<bool?> _toonBevestigingSheet(
    BuildContext context, {
    required Future<void> Function() deleteAccount,
  }) {
    return showKlantioNavbarSafeSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx, bottom) {
        return _DeleteConfirmBody(
          bottom: bottom,
          deleteAccount: deleteAccount,
        );
      },
    );
  }
}

class _DeleteConfirmBody extends StatefulWidget {
  const _DeleteConfirmBody({
    required this.bottom,
    required this.deleteAccount,
  });

  final double bottom;
  final Future<void> Function() deleteAccount;

  @override
  State<_DeleteConfirmBody> createState() => _DeleteConfirmBodyState();
}

class _DeleteConfirmBodyState extends State<_DeleteConfirmBody> {
  final _controller = TextEditingController();
  bool _laden = false;
  String? _fout;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _bevestig() async {
    if (_laden) return;
    if (!isLeerlingDeleteConfirmation(_controller.text)) return;
    setState(() {
      _laden = true;
      _fout = null;
    });
    try {
      await widget.deleteAccount();
      if (!mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _laden = false;
        _fout = e.toString().replaceFirst('Exception: ', '');
      });
      showAppSnackBar(context, _fout!, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bevestigd = isLeerlingDeleteConfirmation(_controller.text);
    return PopScope(
      canPop: !_laden,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24, 16, 24, widget.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E2E7),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Account verwijderen',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Je Klantio-account en persoonlijke profiel worden verwijderd '
              'of geanonimiseerd. Dit is definitief en kan niet zomaar worden '
              'teruggedraaid.\n\n'
              'Sommige administratieve of historische gegevens, zoals lessen '
              'en facturen, kunnen langer bewaard blijven als dat wettelijk '
              'of administratief nodig is. Die gegevens worden ontkoppeld van '
              'jouw naam.',
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Typ VERWIJDER om te bevestigen. Deze actie is definitief.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('leerling_delete_confirm_field'),
              controller: _controller,
              enabled: !_laden,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'VERWIJDER',
                filled: true,
                fillColor: const Color(0xFFF0F2F5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_fout != null) ...[
              const SizedBox(height: 10),
              Text(
                _fout!,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.dangerSolid,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('leerling_delete_confirm_cta'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.dangerSolid,
                  disabledBackgroundColor:
                      AppColors.dangerSolid.withValues(alpha: 0.35),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: bevestigd && !_laden ? _bevestig : null,
                child: _laden
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Account definitief verwijderen'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _laden ? null : () => Navigator.pop(context, false),
                child: Text(
                  'Annuleren',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
