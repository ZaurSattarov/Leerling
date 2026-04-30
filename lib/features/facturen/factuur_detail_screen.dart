import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/datum_utils.dart';
import '../../models/factuur.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/snackbar.dart';
import '../../shared/widgets/status_pill.dart';
import 'facturen_provider.dart';

class FactuurDetailScreen extends ConsumerWidget {
  final String id;
  const FactuurDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final factuurAsync = ref.watch(factuurDetailProvider(id));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Factuur'),
        actions: [
          factuurAsync.when(
            data: (f) => f != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: StatusPill.factuur(f.status),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: factuurAsync.when(
        data: (factuur) {
          if (factuur == null) {
            return const Center(
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Factuur niet gevonden',
              ),
            );
          }
          return _FactuurDetailBody(factuur: factuur);
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: EmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'Kon factuur niet laden',
            subtitle: e.toString(),
          ),
        ),
      ),
    );
  }
}

class _FactuurDetailBody extends StatelessWidget {
  final Factuur factuur;
  const _FactuurDetailBody({required this.factuur});

  String get _bedragEuro => factuur.bedragEuro;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.dark,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        color: Colors.white54, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      factuur.factuurnummer,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 13),
                    ),
                    const Spacer(),
                    StatusPill.factuur(factuur.status),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  _bedragEuro,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                if (factuur.beschrijving.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    factuur.beschrijving,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Details
          AppCard(
            child: Column(
              children: [
                _DetailRow(
                  label: 'Factuurdatum',
                  value: DatumUtils.korteDatum(factuur.aangemaaktOp
                      .substring(0, 10)),
                ),
                if (factuur.vervaldatum?.isNotEmpty == true) ...[
                  const Divider(height: 20),
                  _DetailRow(
                    label: 'Vervaldatum',
                    value: DatumUtils.korteDatum(factuur.vervaldatum!),
                    valueColor: DatumUtils.isVerlopen(factuur.vervaldatum)
                        ? AppColors.dangerText
                        : null,
                  ),
                ],
                if (factuur.betaaldOp?.isNotEmpty == true) ...[
                  const Divider(height: 20),
                  _DetailRow(
                    label: 'Betaald op',
                    value: DatumUtils.korteDatum(
                        factuur.betaaldOp!.substring(0, 10)),
                    valueColor: AppColors.successText,
                  ),
                ],
                if (factuur.betalingskenmerk?.isNotEmpty == true) ...[
                  const Divider(height: 20),
                  _DetailRow(
                    label: 'Betalingskenmerk',
                    value: factuur.betalingskenmerk!,
                  ),
                ],
                if (factuur.ibanSnapshot?.isNotEmpty == true) ...[
                  const Divider(height: 20),
                  _DetailRow(
                    label: 'IBAN',
                    value: factuur.ibanSnapshot!,
                  ),
                ],
              ],
            ),
          ),

          if (factuur.notities?.isNotEmpty == true) ...[
            const SizedBox(height: 14),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notities',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    factuur.notities!,
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5),
                  ),
                ],
              ),
            ),
          ],

          // Pay button
          if (factuur.isOpen && factuur.betaalLinkUrl?.isNotEmpty == true) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _openBetaalLink(context, factuur.betaalLinkUrl!),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('Betaal nu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successSolid,
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _openBetaalLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        showAppSnackBar(context, 'Kan betaallink niet openen', isError: true);
      }
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
