import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/datum_utils.dart';
import '../../models/les.dart';
import '../../models/les_evaluatie.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_detail_header.dart';
import '../../shared/widgets/snackbar.dart';
import 'planning_provider.dart';
import 'widgets/lesson_status_badge.dart';

class LesDetailScreen extends ConsumerWidget {
  final String id;
  const LesDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lesAsync = ref.watch(lesDetailProvider(id));
    final profielAsync = ref.watch(mijnProfielProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          MainDetailHeader(
            eyebrowText: 'PLANNING',
            title: 'Lesdetails',
            actions: [
              lesAsync.when(
                data: (les) => les != null
                    ? LessonStatusBadge(status: les.status)
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          Expanded(
            child: lesAsync.when(
              data: (les) {
                if (les == null) {
                  return const Center(
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Les niet gevonden',
                      subtitle:
                          'Deze les bestaat niet of je hebt geen toegang.',
                    ),
                  );
                }
                final leerlingId = profielAsync.valueOrNull?.id;
                return _LesDetailBody(les: les, leerlingId: leerlingId);
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(
                child: EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Kon les niet laden',
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

class _LesDetailBody extends ConsumerWidget {
  final Les les;
  final String? leerlingId;
  const _LesDetailBody({required this.les, this.leerlingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final evalAsync = (les.status == LesStatus.afgerond &&
            les.zichtbaarVoorLeerling &&
            leerlingId != null)
        ? ref.watch(
            lesEvaluatieProvider((lesId: les.id, leerlingId: leerlingId!)))
        : null;
    final bottomPadding = MediaQuery.paddingOf(context).bottom + 96;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // 1. Datum & Tijd
              _DatumTijdCard(les: les),
              const SizedBox(height: 12),

              // 2. Status tijdlijn
              _StatusTijdlijn(status: les.status),
              const SizedBox(height: 12),

              // 3. Instructeur + contact
              if (les.instructeurNaam?.isNotEmpty == true ||
                  les.instructeurTelefoon?.isNotEmpty == true ||
                  les.instructeurEmail?.isNotEmpty == true) ...[
                _InstructeurCard(les: les),
                const SizedBox(height: 12),
                _ContactActiesCard(les: les),
                const SizedBox(height: 12),
              ],

              // 4. Locatie + Kaart
              if (les.locatie?.isNotEmpty == true) ...[
                _LocatieCard(les: les),
                const SizedBox(height: 12),
              ],

              // 5. Voertuig
              if (_heeftVoertuig(les)) ...[
                _VoertuigCard(les: les),
                const SizedBox(height: 12),
              ],

              // 6. Lestype + rijbewijs
              if (les.lesType?.isNotEmpty == true ||
                  les.rijbewijsSoort?.isNotEmpty == true) ...[
                _LesInfoCard(les: les),
                const SizedBox(height: 12),
              ],

              // 7. Geoefende onderwerpen / voorbereiding
              if (les.geoefendeOnderwerpen.isNotEmpty) ...[
                _OnderwerpCard(
                  titel: les.status == LesStatus.gepland
                      ? 'Geplande onderwerpen'
                      : 'Geoefende onderwerpen',
                  onderwerpen: les.geoefendeOnderwerpen,
                  iconColor: const Color(0xFF5645D4),
                ),
                const SizedBox(height: 12),
              ],

              // 8. Feedback van instructeur
              if (les.zichtbaarVoorLeerling &&
                  les.instructeurFeedback?.trim().isNotEmpty == true) ...[
                _TekstCard(
                  icoon: Icons.notes_rounded,
                  iconColor: const Color(0xFF5645D4),
                  titel: 'Feedback & aandachtspunten',
                  tekst: les.instructeurFeedback!,
                ),
                const SizedBox(height: 12),
              ],

              // 9. Mijn notitie
              if (les.leerlingNotitie?.trim().isNotEmpty == true) ...[
                _TekstCard(
                  icoon: Icons.edit_note_rounded,
                  iconColor: const Color(0xFFD97706),
                  titel: 'Mijn notitie',
                  tekst: les.leerlingNotitie!,
                ),
                const SizedBox(height: 12),
              ],

              // 10. Evaluatie van instructeur (alleen afgerond + zichtbaar)
              if (evalAsync != null) ...[
                evalAsync.when(
                  data: (eval) => eval != null
                      ? _EvaluatieSection(eval: eval)
                      : const _EvaluatieNietBeschikbaar(),
                  loading: () => const _EvaluatieLoadingSkeleton(),
                  error: (_, __) => const _EvaluatieNietBeschikbaar(),
                ),
              ] else if (les.status == LesStatus.afgerond &&
                  les.zichtbaarVoorLeerling &&
                  (les.focusPunten.isNotEmpty ||
                      les.volgendeLesAdvies?.isNotEmpty == true)) ...[
                _EvaluatieFallback(les: les),
              ] else if (les.status == LesStatus.afgerond) ...[
                const _EvaluatieNietBeschikbaar(),
              ],

              // 11. Nieuwe les aanvragen (alleen na afgeronde les)
              if (les.status == LesStatus.afgerond) ...[
                const SizedBox(height: 4),
                _VolgendeLesCTA(les: les),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  bool _heeftVoertuig(Les les) =>
      les.voertuigNaam?.isNotEmpty == true ||
      les.voertuigMerk?.isNotEmpty == true ||
      les.voertuigModel?.isNotEmpty == true ||
      les.voertuigKenteken?.isNotEmpty == true ||
      les.voertuigTransmissie?.isNotEmpty == true ||
      les.voertuigCategorie?.isNotEmpty == true;
}

// ── Datum & Tijd card ─────────────────────────────────────────────────────────

class _DatumTijdCard extends StatelessWidget {
  final Les les;
  const _DatumTijdCard({required this.les});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          _DetailDateBlock(datum: les.datum),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DatumUtils.langeDatum(les.datum),
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 15, color: AppColors.textSecondary),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        '${les.starttijd} - ${les.eindtijd} · ${DatumUtils.duurLabel(les.duurMinuten)}',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailDateBlock extends StatelessWidget {
  final String datum;

  const _DetailDateBlock({required this.datum});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E2E7), width: 0.75),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _dagAfk(datum),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _dagNummer(datum),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 25,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _maandAfk(datum),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _dagAfk(String datum) {
    try {
      const days = ['MAA', 'DIN', 'WOE', 'DON', 'VRI', 'ZAT', 'ZON'];
      return days[DateTime.parse(datum).weekday - 1];
    } catch (_) {
      return '';
    }
  }

  String _dagNummer(String datum) {
    try {
      return DateTime.parse(datum).day.toString();
    } catch (_) {
      return '?';
    }
  }

  String _maandAfk(String datum) {
    try {
      const months = [
        'jan',
        'feb',
        'mrt',
        'apr',
        'mei',
        'jun',
        'jul',
        'aug',
        'sep',
        'okt',
        'nov',
        'dec',
      ];
      return months[DateTime.parse(datum).month - 1];
    } catch (_) {
      return '';
    }
  }
}

// ── Status tijdlijn ────────────────────────────────────────────────────────────

class _StatusTijdlijn extends StatelessWidget {
  final LesStatus status;
  const _StatusTijdlijn({required this.status});

  List<LesStatus> get _stappen {
    return switch (status) {
      LesStatus.afgerond => const [LesStatus.gepland, LesStatus.afgerond],
      LesStatus.geannuleerd => const [LesStatus.gepland, LesStatus.geannuleerd],
      LesStatus.verzet => const [LesStatus.gepland, LesStatus.verzet],
      LesStatus.geen_toon => const [LesStatus.gepland, LesStatus.geen_toon],
      LesStatus.gepland => const [LesStatus.gepland, LesStatus.afgerond],
    };
  }

  int get _activeIndex {
    return switch (status) {
      LesStatus.gepland => 0,
      LesStatus.afgerond ||
      LesStatus.geannuleerd ||
      LesStatus.verzet ||
      LesStatus.geen_toon =>
        1,
    };
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeIndex;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lesstatus',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(_stappen.length * 2 - 1, (i) {
              if (i.isOdd) {
                final stepIndex = i ~/ 2;
                final isCompleted = stepIndex < active;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted
                        ? AppColors.primary
                        : const Color(0xFFD5DAE1),
                  ),
                );
              }
              final stepIndex = i ~/ 2;
              final isActive = stepIndex == active;
              final isCompleted = stepIndex < active;
              return SizedBox(
                width: 82,
                child: Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted || isActive
                            ? AppColors.primary
                            : const Color(0xFFF0F2F5),
                        border: isCompleted || isActive
                            ? null
                            : Border.all(color: const Color(0xFFD5DAE1)),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 14)
                          : isActive
                              ? const Icon(Icons.circle,
                                  color: Colors.white, size: 8)
                              : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _stappen[stepIndex].label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.15,
                        fontWeight: isActive || isCompleted
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isActive || isCompleted
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _InstructeurCard extends StatelessWidget {
  final Les les;
  const _InstructeurCard({required this.les});

  @override
  Widget build(BuildContext context) {
    final naam = les.instructeurNaam?.trim();
    final toonNaam = naam != null && naam.isNotEmpty && !naam.contains('@');
    final telefoon = les.instructeurTelefoon?.trim();
    final email = les.instructeurEmail?.trim();
    final heeftTelefoon = telefoon != null && telefoon.isNotEmpty;
    final heeftEmail = email != null && _isValidEmail(email);

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBadge(
            icon: Icons.person_rounded,
            color: AppColors.textPrimary,
            size: 38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jouw instructeur',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (toonNaam) ...[
                  const SizedBox(height: 7),
                  Text(
                    naam,
                    style: const TextStyle(
                      fontSize: 17,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (heeftTelefoon) ...[
                  const SizedBox(height: 6),
                  _InlineContactValue(
                    icon: Icons.phone_rounded,
                    value: telefoon,
                  ),
                ],
                if (heeftEmail) ...[
                  const SizedBox(height: 5),
                  _InlineContactValue(
                    icon: Icons.mail_outline_rounded,
                    value: email,
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Locatie card ───────────────────────────────────────────────────────────────

class _ContactActiesCard extends StatelessWidget {
  final Les les;
  const _ContactActiesCard({required this.les});

  @override
  Widget build(BuildContext context) {
    final telefoon = les.instructeurTelefoon?.trim();
    final email = les.instructeurEmail?.trim();
    final heeftTelefoon = telefoon != null && telefoon.isNotEmpty;
    final heeftEmail = email != null && _isValidEmail(email);

    final acties = <Widget>[
      if (heeftTelefoon)
        _ContactButton(
          icon: Icons.phone_rounded,
          label: 'Bellen',
          iconColor: const Color(0xFF16A34A),
          onTap: () => _bel(context, telefoon),
        ),
      if (heeftTelefoon)
        _ContactButton(
          icon: Icons.chat_rounded,
          label: 'WhatsApp',
          iconColor: const Color(0xFF22C55E),
          onTap: () => _whatsapp(context, telefoon),
        ),
      if (heeftEmail)
        _ContactButton(
          icon: Icons.mail_outline_rounded,
          label: 'E-mail',
          iconColor: const Color(0xFF2563EB),
          onTap: () => _mail(context, email),
        ),
    ];

    if (acties.isEmpty) return const SizedBox.shrink();

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: _ContactActions(actions: acties),
    );
  }

  Future<void> _bel(BuildContext context, String telefoon) async {
    final normalized = _normaliseerTelefoon(telefoon);
    if (normalized.isEmpty) {
      showAppSnackBar(context, 'Geen geldig telefoonnummer', isError: true);
      return;
    }

    final uri = Uri(scheme: 'tel', path: normalized);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      showAppSnackBar(context, 'Kan telefoon-app niet openen', isError: true);
    }
  }

  Future<void> _whatsapp(BuildContext context, String telefoon) async {
    final digits = telefoon.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      showAppSnackBar(context, 'Geen geldig telefoonnummer', isError: true);
      return;
    }

    final uri = Uri.https('wa.me', '/$digits');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      showAppSnackBar(context, 'Kan WhatsApp niet openen', isError: true);
    }
  }

  Future<void> _mail(BuildContext context, String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: const {'subject': 'Vraag over mijn rijles'},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      showAppSnackBar(context, 'Kan e-mail-app niet openen', isError: true);
    }
  }
}

class _InlineContactValue extends StatelessWidget {
  final IconData icon;
  final String value;
  final int maxLines;

  const _InlineContactValue({
    required this.icon,
    required this.value,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: SelectableText(
            value,
            maxLines: maxLines,
            style: const TextStyle(
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _LocatieCard extends StatelessWidget {
  final Les les;
  const _LocatieCard({required this.les});

  @override
  Widget build(BuildContext context) {
    final locatie = les.locatie!.trim();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            icon: Icons.location_on_rounded,
            iconColor: const Color(0xFFE11D48),
            label: 'Ophaallocatie',
            value: _formatLocatie(locatie),
          ),
          const SizedBox(height: 14),
          _ContactButton(
            icon: Icons.navigation_rounded,
            label: 'Navigeer naar locatie',
            iconColor: const Color(0xFF2563EB),
            onTap: () => _openNavigation(context, locatie),
          ),
        ],
      ),
    );
  }

  String _formatLocatie(String locatie) {
    return locatie.replaceAll(RegExp(r',\s*'), '\n');
  }

  Future<void> _openNavigation(BuildContext context, String locatie) async {
    final encoded = Uri.encodeComponent(locatie);
    final uri = Uri.parse('https://maps.google.com/?q=$encoded');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        showAppSnackBar(context, 'Kan navigatie niet openen', isError: true);
      }
    }
  }
}

class _VoertuigCard extends StatelessWidget {
  final Les les;
  const _VoertuigCard({required this.les});

  String? get _naam {
    final parts = [
      les.voertuigMerk?.trim(),
      les.voertuigModel?.trim(),
    ].where((part) => part != null && part.isNotEmpty).cast<String>().toList();
    if (parts.isEmpty) {
      final naam = les.voertuigNaam?.trim();
      return naam != null && naam.isNotEmpty ? naam : null;
    }
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final naam = _naam;
    final meta = [
      if (les.voertuigTransmissie?.trim().isNotEmpty == true)
        _transmissieLabel(les.voertuigTransmissie!.trim()),
      if (les.voertuigCategorie?.trim().isNotEmpty == true)
        'Categorie ${les.voertuigCategorie!.trim().toUpperCase()}',
    ].join(' - ');
    final details = <String>[
      if (les.voertuigKenteken?.trim().isNotEmpty == true)
        les.voertuigKenteken!.trim(),
      if (meta.isNotEmpty) meta,
    ];

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconBadge(
            icon: Icons.directions_car_rounded,
            color: AppColors.textPrimary,
            size: 36,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lesvoertuig',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (naam != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    naam,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    details.join('\n'),
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _transmissieLabel(String value) {
    return switch (value.toLowerCase()) {
      'automatic' || 'automaat' => 'Automaat',
      'manual' || 'schakel' || 'schakelauto' => 'Schakel',
      _ => value.isEmpty ? value : value[0].toUpperCase() + value.substring(1),
    };
  }
}

// ── Les info card ──────────────────────────────────────────────────────────────

class _LesInfoCard extends StatelessWidget {
  final Les les;
  const _LesInfoCard({required this.les});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          if (les.lesType?.isNotEmpty == true)
            _InfoRow(
              icon: Icons.school_rounded,
              iconColor: const Color(0xFF5645D4),
              label: 'Lestype',
              value: les.lesType!,
            ),
        ],
      ),
    );
  }
}

// ── Onderwerpen / voorbereiding card ──────────────────────────────────────────

class _OnderwerpCard extends StatelessWidget {
  final String titel;
  final List<String> onderwerpen;
  final Color iconColor;
  const _OnderwerpCard({
    required this.titel,
    required this.onderwerpen,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                  icon: Icons.checklist_rounded, color: iconColor, size: 36),
              const SizedBox(width: 10),
              Text(
                titel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: onderwerpen.map((o) => _OnderwerpChip(label: o)).toList(),
          ),
        ],
      ),
    );
  }
}

class _OnderwerpChip extends StatelessWidget {
  final String label;
  const _OnderwerpChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E2E7)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ── Tekst card (feedback / notitie) ───────────────────────────────────────────

class _TekstCard extends StatelessWidget {
  final IconData icoon;
  final Color iconColor;
  final String titel;
  final String tekst;
  const _TekstCard({
    required this.icoon,
    required this.iconColor,
    required this.titel,
    required this.tekst,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: icoon, color: iconColor, size: 36),
              const SizedBox(width: 10),
              Text(
                titel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tekst,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Volgende les CTA ──────────────────────────────────────────────────────────

class _VolgendeLesCTA extends StatelessWidget {
  final Les les;
  const _VolgendeLesCTA({required this.les});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.push('/beschikbaarheid'),
        icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
        label: const Text('Nieuwe les aanvragen'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Gedeelde hulpwidgets ──────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
            softWrap: true,
          ),
        ),
      ],
    );
  }
}

class _ContactActions extends StatelessWidget {
  final List<Widget> actions;

  const _ContactActions({required this.actions});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 320 && actions.length > 1) {
          return Row(
            children: [
              for (var index = 0; index < actions.length; index++) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(child: actions[index]),
              ],
            ],
          );
        }

        return Column(
          children: [
            for (var index = 0; index < actions.length; index++) ...[
              if (index > 0) const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: actions[index]),
            ],
          ],
        );
      },
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E2E7)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Les Evaluatie sectie ──────────────────────────────────────────────────────

bool _isValidEmail(String value) =>
    RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim());

String _normaliseerTelefoon(String value) {
  final trimmed = value.trim();
  final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '';
  return trimmed.startsWith('+') ? '+$digits' : digits;
}

const _skillLabels = {
  'spiegels': 'Spiegels',
  'dode_hoek': 'Dode hoek',
  'voorrang': 'Voorrang',
  'invoegen': 'Invoegen',
  'rotondes': 'Rotondes',
  'snelweg': 'Snelweg',
  'parkeren': 'Parkeren',
  'achteruitrijden': 'Achteruitrijden',
  'bochten': 'Bochten',
  'remmen': 'Remmen',
  'rijstroken': 'Rijstroken',
  'voorsorteren': 'Voorsorteren',
  'kijkgedrag': 'Kijkgedrag',
  'anticiperen': 'Anticiperen',
  'zelfstandigheid': 'Zelfstandigheid',
};

class _EvaluatieSection extends StatelessWidget {
  final LesEvaluatie eval;
  const _EvaluatieSection({required this.eval});

  @override
  Widget build(BuildContext context) {
    final goede = eval.skillScores.where((s) => s.score >= 4).toList();
    final verbeter = eval.skillScores.where((s) => s.score <= 2).toList();

    return Column(
      children: [
        const SizedBox(height: 4),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.stars_rounded,
                        size: 18, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Les evaluatie',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        _RatingChip(rating: eval.rating),
                      ],
                    ),
                  ),
                  if (eval.interventionCount != 'geen')
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFE2E2E7), width: 0.75),
                      ),
                      child: Text(
                        eval.interventionLabel,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warningSolid),
                      ),
                    ),
                ],
              ),
              if (eval.feedback?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFE2E2E7)),
                const SizedBox(height: 14),
                Text(
                  '"${eval.feedback!.trim()}"',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontStyle: FontStyle.italic,
                    height: 1.55,
                  ),
                ),
              ],
              if (goede.isNotEmpty || verbeter.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFE2E2E7)),
                const SizedBox(height: 14),
                if (goede.isNotEmpty) ...[
                  _SkillGroep(
                    label: 'Goed gedaan',
                    icon: Icons.check_circle_rounded,
                    kleur: const Color(0xFF16A34A),
                    achtergrond: const Color(0xFFF0F2F5),
                    scores: goede,
                  ),
                  if (verbeter.isNotEmpty) const SizedBox(height: 10),
                ],
                if (verbeter.isNotEmpty)
                  _SkillGroep(
                    label: 'Aandachtspunten',
                    icon: Icons.warning_amber_rounded,
                    kleur: const Color(0xFFD97706),
                    achtergrond: const Color(0xFFF0F2F5),
                    scores: verbeter,
                  ),
              ],
              if (eval.nextLessonAdvice?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFE2E2E7)),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_rounded,
                        size: 16, color: Color(0xFF5645D4)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Advies volgende les',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5645D4),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            eval.nextLessonAdvice!.trim(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (eval.skillScores.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SkillScoreBar(scores: eval.skillScores),
        ],
      ],
    );
  }
}

class _RatingChip extends StatelessWidget {
  final String rating;
  const _RatingChip({required this.rating});

  @override
  Widget build(BuildContext context) {
    final (label, kleur) = switch (rating) {
      'uitstekend' => ('Uitstekend', const Color(0xFF16A34A)),
      'goed' => ('Goed', const Color(0xFF2563EB)),
      'voldoende' => ('Voldoende', const Color(0xFF64748B)),
      'moeizaam' => ('Moeizaam', const Color(0xFFD97706)),
      _ => (rating, const Color(0xFF64748B)),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.only(top: 2, right: 4),
          decoration: BoxDecoration(color: kleur, shape: BoxShape.circle),
        ),
        Text(
          label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: kleur),
        ),
      ],
    );
  }
}

class _SkillGroep extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color kleur;
  final Color achtergrond;
  final List<LesSkillScore> scores;
  const _SkillGroep({
    required this.label,
    required this.icon,
    required this.kleur,
    required this.achtergrond,
    required this.scores,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: achtergrond,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: kleur),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kleur,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: scores
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kleur.withAlpha(60)),
                      ),
                      child: Text(
                        _skillLabels[s.skillKey] ?? s.skillKey,
                        style: TextStyle(
                          fontSize: 12,
                          color: kleur,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SkillScoreBar extends StatelessWidget {
  final List<LesSkillScore> scores;
  const _SkillScoreBar({required this.scores});

  @override
  Widget build(BuildContext context) {
    final top = [...scores]..sort((a, b) => b.score.compareTo(a.score));
    final shown = top.take(8).toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vaardighedenscores',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...shown.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ScoreRij(score: s),
              )),
        ],
      ),
    );
  }
}

class _ScoreRij extends StatelessWidget {
  final LesSkillScore score;
  const _ScoreRij({required this.score});

  @override
  Widget build(BuildContext context) {
    final kleur = switch (score.score) {
      5 => const Color(0xFF16A34A),
      4 => const Color(0xFF2563EB),
      3 => const Color(0xFF64748B),
      2 => const Color(0xFFD97706),
      _ => const Color(0xFFDC2626),
    };
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            _skillLabels[score.skillKey] ?? score.skillKey,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score.score / 5,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E2E7),
              valueColor: AlwaysStoppedAnimation<Color>(kleur),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${score.score}/5',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: kleur),
        ),
      ],
    );
  }
}

class _EvaluatieFallback extends StatelessWidget {
  final Les les;
  const _EvaluatieFallback({required this.les});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 4),
        if (les.focusPunten.isNotEmpty)
          _OnderwerpCard(
            titel: 'Focus punten',
            onderwerpen: les.focusPunten,
            iconColor: const Color(0xFF5645D4),
          ),
        if (les.volgendeLesAdvies?.trim().isNotEmpty == true) ...[
          const SizedBox(height: 12),
          _TekstCard(
            icoon: Icons.lightbulb_rounded,
            iconColor: const Color(0xFF5645D4),
            titel: 'Advies volgende les',
            tekst: les.volgendeLesAdvies!,
          ),
        ],
      ],
    );
  }
}

class _EvaluatieNietBeschikbaar extends StatelessWidget {
  const _EvaluatieNietBeschikbaar();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(
            icon: Icons.rate_review_outlined,
            color: AppColors.textPrimary,
            size: 36,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Evaluatie nog niet beschikbaar',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Je instructeur heeft deze les nog niet beoordeeld.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EvaluatieLoadingSkeleton extends StatelessWidget {
  const _EvaluatieLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          Container(
            height: 14,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E2E7),
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 14,
            width: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E2E7),
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ],
      ),
    );
  }
}
