import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/datum_utils.dart';
import '../../core/utils/factuur_pdf_utils.dart';
import '../../models/factuur.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_detail_header.dart';
import '../../core/services/student_service.dart';
import '../../shared/widgets/snackbar.dart';
import '../../shared/widgets/status_pill.dart';
import 'facturen_provider.dart';
import '../home/home_provider.dart';

class FactuurDetailScreen extends ConsumerWidget {
  final String id;
  // Hint (GEEN bewijs van betaling) gezet door de deep-link-handler in
  // app.dart na terugkeer van de Mollie-betaalpagina (leerlingplanner://
  // factuur?id=...). Alleen gebruikt om kort "Betaling wordt verwerkt" te
  // tonen en de factuur een beperkt aantal keer opnieuw te verversen — de
  // echte status komt altijd uit een verse Supabase-fetch.
  final bool verifyPayment;
  const FactuurDetailScreen({
    super.key,
    required this.id,
    this.verifyPayment = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final factuurAsync = ref.watch(factuurDetailProvider(id));

    final factuur = factuurAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MainDetailHeader(
            title: 'Factuur',
            actions: [
              if (factuur != null) StatusPill.factuur(factuur.status),
            ],
          ),
          Expanded(
            child: factuurAsync.when(
              data: (f) {
                if (f == null) {
                  return const Center(
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Factuur niet gevonden',
                    ),
                  );
                }
                return _FactuurDetailBody(
                  factuur: f,
                  verifyPayment: verifyPayment,
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Kon factuur niet laden',
                  subtitle: e.toString(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FactuurDetailBody extends ConsumerStatefulWidget {
  final Factuur factuur;
  final bool verifyPayment;
  const _FactuurDetailBody({
    required this.factuur,
    this.verifyPayment = false,
  });

  @override
  ConsumerState<_FactuurDetailBody> createState() => _FactuurDetailBodyState();
}

class _FactuurDetailBodyState extends ConsumerState<_FactuurDetailBody>
    with WidgetsBindingObserver {
  bool _wachtOpBetaalTerugkeer = false;
  bool _betalingAanvragen = false;
  bool _betalingVerifieren = false;
  bool _pdfBezig = false;

  Factuur get factuur => widget.factuur;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.verifyPayment && factuur.status != FactuurStatus.betaald) {
      _betalingVerifieren = true;
      unawaited(_verifieerBetalingBeperkt());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _wachtOpBetaalTerugkeer) {
      _wachtOpBetaalTerugkeer = false;
      _refreshFacturen();
    }
  }

  /// Beperkte (NIET-oneindige) refetch na terugkeer via de betaal-deep-link:
  /// een paar keer met oplopende vertraging rechtstreeks bij Supabase
  /// checken of de authoritative webhook de factuur al op betaald heeft
  /// gezet. Ververst bewust NIET via de provider tussentijds (dat zou de
  /// hele detailpagina laten "flitsen" naar een laadscherm) -- pas bij een
  /// bevestigde overgang naar betaald, of na de laatste poging, wordt de
  /// provider/lijst/dashboard écht ververst.
  Future<void> _verifieerBetalingBeperkt() async {
    const vertragingen = [
      Duration(seconds: 2),
      Duration(seconds: 3),
      Duration(seconds: 5),
    ];
    for (final vertraging in vertragingen) {
      await Future.delayed(vertraging);
      if (!mounted) return;
      try {
        final vernieuwd = await StudentService.getFactuur(factuur.id);
        if (!mounted) return;
        if (vernieuwd != null && vernieuwd.status == FactuurStatus.betaald) {
          ref.invalidate(factuurDetailProvider(factuur.id));
          ref.invalidate(facturenProvider);
          ref.invalidate(homeProvider);
          setState(() => _betalingVerifieren = false);
          return;
        }
      } catch (e) {
        debugPrint('[factuur_detail] betaling verifieren fout: $e');
      }
    }
    if (mounted) setState(() => _betalingVerifieren = false);
  }

  @override
  Widget build(BuildContext context) {
    final betaalUrl = factuur.effectieveBetaalUrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_betalingVerifieren &&
              factuur.status != FactuurStatus.betaald) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.warningBorder),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.warningText,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Betaling wordt verwerkt',
                          style: TextStyle(
                            color: AppColors.warningText,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'We controleren je betaling. Dit duurt meestal maar enkele seconden.',
                          style: TextStyle(
                            color: AppColors.warningText,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E2E7), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded,
                        color: AppColors.textHint, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        factuur.factuurnummer,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    StatusPill.factuur(factuur.status),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  factuur.bedragEuro,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  factuur.beschrijving.isNotEmpty
                      ? factuur.beschrijving
                      : 'Geen omschrijving toegevoegd',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                _DetailRow(
                    label: 'Factuurnummer', value: factuur.factuurnummer),
                const Divider(height: 20),
                _DetailRow(label: 'Bedrag', value: factuur.bedragEuro),
                const Divider(height: 20),
                _DetailRow(label: 'Status', value: factuur.status.label),
                if (factuur.aangemaaktOp.isNotEmpty) ...[
                  const Divider(height: 20),
                  _DetailRow(
                    label: 'Factuurdatum',
                    value: _formatDate(factuur.aangemaaktOp),
                  ),
                ],
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
                    value: _formatDate(factuur.betaaldOp!),
                    valueColor: AppColors.successText,
                  ),
                ],
                const Divider(height: 20),
                _DetailRow(
                  label: 'Betaalmethode',
                  value: factuur.betaalmethodeLabel,
                ),
                const Divider(height: 20),
                _DetailRow(
                  label: 'Betaalstatus',
                  value: factuur.status == FactuurStatus.betaald
                      ? 'Betaald'
                      : betaalUrl == null
                          ? 'Betaallink ontbreekt'
                          : 'Wacht op betaling',
                  valueColor: factuur.status == FactuurStatus.betaald
                      ? AppColors.successText
                      : null,
                ),
                if (factuur.betalingskenmerk?.isNotEmpty == true) ...[
                  const Divider(height: 20),
                  _DetailRow(
                    label: 'Betalingskenmerk',
                    value: factuur.betalingskenmerk!,
                  ),
                ],
                if (factuur.ibanSnapshot?.isNotEmpty == true) ...[
                  const Divider(height: 20),
                  _DetailRow(label: 'IBAN', value: factuur.ibanSnapshot!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Omschrijving',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  factuur.beschrijving.isNotEmpty
                      ? factuur.beschrijving
                      : 'Geen omschrijving toegevoegd.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
                if (factuur.notities?.isNotEmpty == true) ...[
                  const Divider(height: 24),
                  Text(
                    factuur.notities!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: factuur.isBetaalbaar && !_betalingAanvragen
                ? () => _startBetaling(context, betaalUrl)
                : null,
            icon: _betalingAanvragen
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.account_balance_rounded, size: 18),
            label: Text(_betalingAanvragen
                ? 'Betaling aanmaken...'
                : 'Betaal met iDEAL'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.neutralBg,
              disabledForegroundColor: AppColors.textHint,
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          if (!factuur.isBetaalbaar)
            const _ActionHint(
                text: 'Deze factuur staat niet open voor betaling.'),
          const SizedBox(height: 10),
          // Canonical factuur-PDF -- zelfde bron/opbouw als de Instructeur-
          // app (FactuurPdfUtils, 1-op-1 port van FactuurShareUtils), client-
          // side gegenereerd op basis van de eigen, RLS-gescoped factuurdata.
          // GEEN losse "downloadUrl"-kolom meer nodig (die werd nooit
          // gevuld).
          OutlinedButton.icon(
            onPressed: _pdfBezig ? null : () => _bekijkFactuurPdf(context),
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('Factuur bekijken'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.dark,
              disabledForegroundColor: AppColors.textHint,
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pdfBezig ? null : () => _downloadFactuurPdf(context),
            icon: _pdfBezig
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.dark,
                    ),
                  )
                : const Icon(Icons.download_rounded, size: 18),
            label: const Text('Download PDF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.dark,
              disabledForegroundColor: AppColors.textHint,
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    final date = raw.length >= 10 ? raw.substring(0, 10) : raw;
    return DatumUtils.korteDatum(date);
  }

  Future<void> _bekijkFactuurPdf(BuildContext context) async {
    setState(() => _pdfBezig = true);
    try {
      await FactuurPdfUtils.openPdf(factuur);
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, 'Kan factuur-PDF niet openen', isError: true);
      }
    } finally {
      if (mounted) setState(() => _pdfBezig = false);
    }
  }

  Future<void> _downloadFactuurPdf(BuildContext context) async {
    setState(() => _pdfBezig = true);
    try {
      await FactuurPdfUtils.downloadPdf(factuur);
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, 'Kan factuur-PDF niet downloaden',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _pdfBezig = false);
    }
  }

  Future<void> _startBetaling(BuildContext context, String? betaalUrl) async {
    if (betaalUrl != null) {
      return _openBetaalLink(context, betaalUrl);
    }

    setState(() => _betalingAanvragen = true);
    try {
      final result =
          await StudentService.requestMollieFactuurPayment(factuur.id);
      if (!context.mounted) return;

      final checkoutUrl = result['checkout_url'] as String?;
      if (checkoutUrl != null) {
        await _openBetaalLink(context, checkoutUrl);
      } else if (result['error'] == 'MOLLIE_NOT_CONNECTED') {
        showAppSnackBar(
          context,
          'Je instructeur heeft iDEAL nog niet ingesteld. Neem contact op.',
          isError: true,
        );
      } else {
        final errMsg = result['error']?.toString() ?? 'Onbekende fout';
        final mollieErr = result['mollie_error']?.toString() ?? '';
        showAppSnackBar(
          context,
          'Fout: $errMsg ${mollieErr.isNotEmpty ? "| $mollieErr" : ""}',
          isError: true,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Er ging iets mis bij het aanmaken van de betaling.',
          isError: true,
        );
      }
    } finally {
      if (context.mounted) setState(() => _betalingAanvragen = false);
    }
  }

  Future<void> _openBetaalLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await canLaunchUrl(uri)) {
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Kan betaallink niet openen',
          isError: true,
        );
      }
      return;
    }

    _wachtOpBetaalTerugkeer = true;
    final geopend = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!geopend) {
      _wachtOpBetaalTerugkeer = false;
      if (context.mounted) {
        showAppSnackBar(
          context,
          'Kan betaallink niet openen',
          isError: true,
        );
      }
      return;
    }

    if (!mounted) return;
    await _refreshFacturen();
    if (context.mounted) {
      showAppSnackBar(
        context,
        'Factuurstatus wordt opnieuw opgehaald.',
      );
    }
  }

  Future<void> _refreshFacturen() async {
    ref.invalidate(factuurDetailProvider(factuur.id));
    ref.invalidate(facturenProvider);
    ref.invalidate(homeProvider);
    try {
      await ref.read(factuurDetailProvider(factuur.id).future);
    } catch (_) {
      // De provider toont zelf de foutmelding in het scherm.
    }
  }
}

class _ActionHint extends StatelessWidget {
  final String text;
  const _ActionHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
    );
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
