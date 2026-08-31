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
import '../arrival/arrival_provider.dart';
import '../arrival/live_aankomst_fullscreen_screen.dart';
import '../arrival/widgets/arrival_live_map.dart';
import '../profiel/rijschool_provider.dart';
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
    // Rijschoolnaam komt uit de bestaande gekoppelde instructeur/
    // rijschoolbron (dezelfde provider als "Mijn rijschool") -- géén
    // hardcoded naam en géén fallback-tekst wanneer die ontbreekt.
    final rijschoolNaam =
        ref.watch(mijnInstructeurProvider).valueOrNull?.rijschoolNaam?.trim();
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

              // 2. Lesinformatie: status + lescontext (rijschool, instructeur,
              // lestype). Voertuig staat hier bewust NIET meer bij -- die
              // heeft nu precies één plek, de LesvoertuigCard hieronder
              // (was eerder dubbel: hier én als losse kaart).
              _LesInformatieCard(les: les, rijschoolNaam: rijschoolNaam),
              const SizedBox(height: 10),

              // 3. Contactacties
              if (les.instructeurTelefoon?.isNotEmpty == true ||
                  les.instructeurEmail?.isNotEmpty == true) ...[
                _ContactActiesCard(les: les),
                const SizedBox(height: 12),
              ],

              // 4. Lesvoertuig -- de ENIGE plek waar voertuiggegevens staan.
              // Staat vóór Locatie: het voertuig is kerninformatie van de
              // afspraak, de ophaallocatie is de praktische vervolgstap.
              if (_heeftVoertuig(les)) ...[
                _VoertuigCard(les: les),
                const SizedBox(height: 12),
              ],

              // 5. Locatie + Kaart -- wordt automatisch Live Aankomst zodra
              // de instructeur voor precies deze les een zichtbare sessie
              // heeft (Feature 2, Fase 4). Zelfde kaart, geen losse feature.
              if (les.locatie?.isNotEmpty == true) ...[
                _OphaallocatieSectie(les: les),
                const SizedBox(height: 12),
              ],

              // 6. Geoefende onderwerpen / voorbereiding
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

              // 7. Feedback van instructeur
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

              // 8. Mijn notitie
              if (les.leerlingNotitie?.trim().isNotEmpty == true) ...[
                _TekstCard(
                  icoon: Icons.edit_note_rounded,
                  iconColor: const Color(0xFFD97706),
                  titel: 'Mijn notitie',
                  tekst: les.leerlingNotitie!,
                ),
                const SizedBox(height: 12),
              ],

              // 9. Evaluatie van instructeur (alleen afgerond + zichtbaar)
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

              // 10. Nieuwe les aanvragen (alleen na afgeronde les)
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
            DatumUtils.dagAfkorting(datum),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            DatumUtils.dagNummer(datum),
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 25,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            DatumUtils.maandAfkorting(datum),
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

}

// ── Lesinformatie: status + instructeur (samengevoegde kaart) ──────────────────
//
// Voorheen twee losse kaarten (Lesstatus, Jouw instructeur). Samengevoegd tot
// één premium kaart voor minder verticale ruimte en duidelijkere samenhang.
// Statuslogica (_stappen/_activeIndex) is ongewijzigd overgenomen — alleen de
// presentatie is verbeterd.

class _LesInformatieCard extends StatelessWidget {
  final Les les;
  final String? rijschoolNaam;
  const _LesInformatieCard({required this.les, this.rijschoolNaam});

  @override
  Widget build(BuildContext context) {
    final instructeurNaam = les.instructeurNaam?.trim();
    final toonInstructeur = instructeurNaam != null &&
        instructeurNaam.isNotEmpty &&
        !instructeurNaam.contains('@');
    final toonRijschool = rijschoolNaam != null && rijschoolNaam!.isNotEmpty;
    final lesType = les.lesType?.trim();
    final toonLesType = lesType != null && lesType.isNotEmpty;

    final lesContextRijen = <Widget>[
      if (toonRijschool)
        _LesContextRij(
          icon: Icons.storefront_rounded,
          label: 'Rijschool',
          inhoud: Text(
            rijschoolNaam!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      if (toonInstructeur)
        _LesContextRij(
          icon: Icons.person_rounded,
          label: 'Instructeur',
          inhoud: Text(
            instructeurNaam,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      if (toonLesType)
        _LesContextRij(
          icon: Icons.school_rounded,
          label: 'Lestype',
          inhoud: Text(
            lesType,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      // Voertuiggegevens staan bewust NIET hier -- die hebben nu precies één
      // plek, de LesvoertuigCard verderop (zie _LesDetailBody), i.p.v. hier
      // én in een aparte kaart (was dubbel).
    ];

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LESINFORMATIE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          _CompactStatusVoortgang(status: les.status),
          if (lesContextRijen.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 14),
            for (var i = 0; i < lesContextRijen.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              lesContextRijen[i],
            ],
          ],
        ],
      ),
    );
  }
}

/// Compacte informatierij met vaste iconkolom: subtiel label, duidelijke
/// donkere waarde eronder. Gedeeld door de rijschool-, instructeur- en
/// lestyperegel in de Lesinformatie-kaart.
class _LesContextRij extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget inhoud;
  const _LesContextRij({
    required this.icon,
    required this.label,
    required this.inhoud,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 3),
              inhoud,
            ],
          ),
        ),
      ],
    );
  }
}

// Statuslogica ongewijzigd: gepland/afgerond gebruiken de normale
// Gepland → Afgerond-stapindicator; geannuleerd/verzet/geen_toon krijgen
// een eigen, niet-misleidende presentatie (zie _AfwijkendeStatusRij).
// Alleen de eind-status ('gepland' → actief, 'afgerond' → actief) bepaalt
// welke stap groot/roze/actief oogt — dezelfde bron als voorheen
// (les.status), geen nieuwe statusberekening.
class _CompactStatusVoortgang extends StatelessWidget {
  final LesStatus status;
  const _CompactStatusVoortgang({required this.status});

  static const _nodeBreedte = 90.0;

  bool get _afwijkendGeeindigd => switch (status) {
        LesStatus.geannuleerd ||
        LesStatus.verzet ||
        LesStatus.geen_toon =>
          true,
        LesStatus.gepland || LesStatus.afgerond => false,
      };

  @override
  Widget build(BuildContext context) {
    if (_afwijkendGeeindigd) {
      return _AfwijkendeStatusRij(status: status);
    }

    final afgerond = status == LesStatus.afgerond;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: _nodeBreedte,
              child: Center(
                child:
                    _StapDot(leeg: false, groot: !afgerond, vinkje: afgerond),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: _StapDot.buitenvak,
                child: Center(child: _Verbindingslijn(volledigRoze: afgerond)),
              ),
            ),
            SizedBox(
              width: _nodeBreedte,
              child: Center(
                child: _StapDot(
                    leeg: !afgerond, groot: afgerond, vinkje: afgerond),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: _nodeBreedte,
              child: Text(
                LesStatus.gepland.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _labelStyle(nadruk: !afgerond),
              ),
            ),
            const Expanded(child: SizedBox()),
            SizedBox(
              width: _nodeBreedte,
              child: Text(
                LesStatus.afgerond.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _labelStyle(nadruk: afgerond),
              ),
            ),
          ],
        ),
      ],
    );
  }

  TextStyle _labelStyle({required bool nadruk}) => TextStyle(
        fontSize: 12,
        height: 1.15,
        fontWeight: nadruk ? FontWeight.w700 : FontWeight.w600,
        color: nadruk ? AppColors.textPrimary : AppColors.textSecondary,
      );
}

/// Eén stap-node. Precies twee vaste afmetingen (24 voor de huidige/eind-
/// stap, 16 voor voltooid of niet-bereikt) — nooit berekend of geanimeerd.
/// Altijd gecentreerd in een vast 24×24-vak, zodat de rij nooit met
/// transforms/offsets uitgelijnd hoeft te worden: de verbindingslijn
/// gebruikt exact dezelfde vakhoogte en sluit zo vanzelf aan op het midden.
class _StapDot extends StatelessWidget {
  final bool leeg;
  final bool groot;
  final bool vinkje;
  const _StapDot({required this.leeg, this.groot = false, this.vinkje = false});

  static const buitenvak = 24.0;
  static const _grootFormaat = 24.0;
  static const _kleinFormaat = 16.0;

  @override
  Widget build(BuildContext context) {
    final formaat =
        leeg ? _kleinFormaat : (groot ? _grootFormaat : _kleinFormaat);

    return SizedBox(
      width: buitenvak,
      height: buitenvak,
      child: Center(
        child: Container(
          width: formaat,
          height: formaat,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: leeg ? const Color(0xFFF0F2F5) : AppColors.primary,
            border: leeg ? Border.all(color: const Color(0xFFD5DAE1)) : null,
          ),
          child: leeg
              ? null
              : vinkje
                  ? Icon(Icons.check_rounded,
                      color: Colors.white, size: formaat * 0.55)
                  : Container(
                      width: formaat * 0.3,
                      height: formaat * 0.3,
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                    ),
        ),
      ),
    );
  }
}

/// Verbindingslijn tussen de twee stappen. Bij status 'afgerond' volledig
/// roze (beide stappen bereikt). Bij status 'gepland' een vaste roze
/// aanloop vanaf de actieve stap die overgaat in lichtgrijs — zodat de lijn
/// zichtbaar bij de actieve stap "begint" zonder te suggereren dat de
/// volgende stap al bereikt is.
class _Verbindingslijn extends StatelessWidget {
  final bool volledigRoze;
  const _Verbindingslijn({required this.volledigRoze});

  static const _aanloop = 18.0;

  @override
  Widget build(BuildContext context) {
    if (volledigRoze) {
      return Container(height: 2, color: AppColors.primary);
    }
    return Row(
      children: [
        Container(width: _aanloop, height: 2, color: AppColors.primary),
        Expanded(child: Container(height: 2, color: const Color(0xFFD5DAE1))),
      ],
    );
  }
}

/// Aparte, niet-misleidende presentatie voor lessen die niet normaal zijn
/// afgerond (geannuleerd/verzet/geen gehoor). Hergebruikt bewust
/// LessonStatusBadge (dezelfde kleuren als de statusbadge bovenaan het
/// scherm) i.p.v. een volledig roze voortgangslijn te tonen die een
/// geslaagde afronding zou suggereren.
class _AfwijkendeStatusRij extends StatelessWidget {
  final LesStatus status;
  const _AfwijkendeStatusRij({required this.status});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
              shape: BoxShape.circle, color: AppColors.primary),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 10),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            LesStatus.gepland.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(color: Color(0xFFE2E2E7)),
            child: SizedBox(height: 1),
          ),
        ),
        const SizedBox(width: 10),
        LessonStatusBadge(status: status),
      ],
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

/// Beslist of de ophaallocatiekaart de normale (statische, extern-Maps)
/// weergave toont of de Live Aankomst-variant (Feature 2, Fase 4) --
/// afhankelijk van de al bestaande [arrivalControllerProvider]-state. Deze
/// widget introduceert GEEN nieuwe backend-/Realtime-logica: ze stuurt
/// alleen de bestaande controller aan (welke les er bekeken wordt) en leest
/// diens state. Geen losse Live Aankomst-feature elders (bv. Home) meer --
/// dit is de enige entrypoint.
class _OphaallocatieSectie extends ConsumerStatefulWidget {
  final Les les;
  const _OphaallocatieSectie({required this.les});

  @override
  ConsumerState<_OphaallocatieSectie> createState() =>
      _OphaallocatieSectieState();
}

class _OphaallocatieSectieState extends ConsumerState<_OphaallocatieSectie> {
  // Vastgelegd in initState (waar `ref` gegarandeerd nog geldig is) i.p.v.
  // in dispose() via ref.read() opgehaald -- Riverpod staat geen
  // ref-gebruik meer toe op het moment dat dispose() draait ("Cannot use
  // ref after the widget was disposed"). De controller zelf is een
  // gewone, langlevende klasse-instantie en blijft dus prima bruikbaar.
  late final ArrivalController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(arrivalControllerProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.onLessonChanged(widget.les.id);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _OphaallocatieSectie oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.les.id != widget.les.id) {
      _controller.onLessonChanged(widget.les.id);
    }
  }

  @override
  void dispose() {
    // Les-detail is de enige plek die deze les laat volgen -- bij het
    // verlaten van dit scherm stopt het volgen (geen losse achtergrond-
    // tracking zonder zichtbaar scherm). Vereenvoudigde aanname: deze
    // pagina pusht nooit een tweede lesdetailpagina bovenop zichzelf, dus
    // er is geen scenario in deze app waarin dit een nog-actieve tracking
    // van een ANDERE les zou overschrijven.
    //
    // Uitgesteld naar een microtask: onLessonChanged(null) kan (via
    // _teardownSubscriptions -> _stopPolling) synchroon de controller-state
    // muteren, en DEZE widget watcht diezelfde provider (ref.watch in
    // build()). Riverpod's listener-afmelding voor dit element is nog niet
    // per se voltooid zolang dispose() zelf nog loopt -- een synchrone
    // mutatie hier kan Flutter's element-lifecycle-assert doen falen
    // ("Cannot markNeedsBuild after widget was disposed"). Een microtask
    // draait pas nadat deze hele unmount-cyclus is afgerond.
    final controller = _controller;
    Future.microtask(() => controller.onLessonChanged(null));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(arrivalControllerProvider);
    final session = state.session;
    final location = state.location;
    final stale = location?.isStale() ?? false;

    final toonLiveAankomst = session != null &&
        session.lessonId == widget.les.id &&
        session.isActive() &&
        session.isVisible &&
        location != null &&
        !stale;

    if (!toonLiveAankomst) {
      return _LocatieCard(les: widget.les);
    }
    return _LiveAankomstOphaalKaart(
      les: widget.les,
      sessionId: session.id,
      latitude: location.latitude,
      longitude: location.longitude,
    );
  }
}

/// Live Aankomst-variant van de ophaallocatiekaart -- zelfde afmeting/vorm/
/// schaduw als [_LocatieCard], maar toont een echte, actuele Google Maps-
/// weergave i.p.v. de statische illustratie. Tikken opent de grotere
/// [LiveAankomstFullscreenScreen] i.p.v. extern Maps te openen (dat blijft
/// de normale [_LocatieCard]'s gedrag).
class _LiveAankomstOphaalKaart extends StatelessWidget {
  final Les les;
  final String sessionId;
  final double latitude;
  final double longitude;

  const _LiveAankomstOphaalKaart({
    required this.les,
    required this.sessionId,
    required this.latitude,
    required this.longitude,
  });

  static const double _hoogte = 168;

  @override
  Widget build(BuildContext context) {
    final locatie = (les.locatie ?? '').trim();

    return Semantics(
      button: true,
      label: 'Instructeur onderweg, live locatie. Open volledige kaart.',
      excludeSemantics: true,
      child: Container(
        height: _hoogte,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.successBorder, width: 0.75),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.25),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LiveAankomstFullscreenScreen(les: les),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Compacte preview: gestures uit, zodat een tik altijd de
                  // fullscreen-weergave opent i.p.v. te pannen/zoomen.
                  ArrivalLiveMap(
                    key: ValueKey(sessionId),
                    latitude: latitude,
                    longitude: longitude,
                    height: _hoogte,
                    gesturesEnabled: false,
                  ),
                  const Positioned.fill(child: _LeesbaarheidsScrim()),
                  const Positioned(top: 12, left: 12, child: _LiveBadge()),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (locatie.isNotEmpty)
                          Text(
                            locatie,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Bekijk live kaart',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge "● Instructeur onderweg · Live" -- zelfde pill-stijl als
/// [_OphaallocatieBadge], vervangt die badge zolang Live Aankomst actief is.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E2E7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'Instructeur onderweg · Live',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Eén tikbare kaart met een decoratieve, statische kaartpreview als
/// achtergrond (`_KaartPatroonPainter`) -- de preview zelf blijft
/// decoratief, maar een tik opent sinds Feature 2/4 altijd primair de
/// interne kaartweergave ([LiveAankomstFullscreenScreen], hier zonder
/// actieve sessie dus de statische ophaallocatie-modus). Extern Google Maps
/// (`MapsUri.open`) is daar alleen nog een expliciete secundaire actie
/// ("Route"-knop), nooit meer de hoofdtik op deze kaart.
class _LocatieCard extends StatelessWidget {
  final Les les;
  const _LocatieCard({required this.les});

  static const double _hoogte = 168;

  @override
  Widget build(BuildContext context) {
    final locatie = les.locatie!.trim();
    final weergave = _weergaveRegels(locatie);

    // Schaduw en rand staan op een NIET-geclipte buitenste Container --
    // een boxShadow tekent buiten de eigen randen, dus zou anders door de
    // afgeronde ClipRRect hieronder worden afgesneden. De ClipRRect zelf
    // (net iets kleiner dan de buitenrand, binnen de 0.75px border) clipt
    // alleen de kaartpreview/overlay-inhoud, niet de schaduw.
    return Semantics(
      button: true,
      label: 'Bekijk ophaallocatie: $locatie',
      excludeSemantics: true,
      child: Container(
        height: _hoogte,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 0.75),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.25),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              // Opent altijd primair intern (LiveAankomstFullscreenScreen,
              // hier zonder actieve sessie dus de statische
              // ophaallocatie-weergave) -- extern Google Maps is alleen nog
              // een expliciete secundaire actie ("Route"-knop) binnen dat
              // scherm, nooit meer de hoofdtik hier.
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => LiveAankomstFullscreenScreen(les: les),
                ),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Decoratieve, statische kaartpreview-achtergrond.
                  const CustomPaint(painter: _KaartPatroonPainter()),

                  // 2. Pin-icoon, los van de tekst-overlay onderaan.
                  const Align(
                    alignment: Alignment(-0.2, -0.15),
                    child: _KaartPin(),
                  ),

                  // 3. Leesbaarheids-scrim onderaan, voor locatietekst/actie.
                  const Positioned.fill(child: _LeesbaarheidsScrim()),

                  // 4. Badge "OPHAALLOCATIE" linksboven.
                  const Positioned(
                    top: 12,
                    left: 12,
                    child: _OphaallocatieBadge(),
                  ),

                  // 5. Locatie + "Open in Maps" linksonder -- alle info in
                  // deze ene kaart, geen dubbele locatievermelding elders.
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          weergave,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Bekijk locatie',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.92),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.92),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Volledig adres (komma-gescheiden) netjes over max. 2 regels: straat +
  /// huisnummer op regel 1, postcode + plaats op regel 2. Een simpele
  /// plaatsnaam (geen komma) blijft ongewijzigd op 1 regel.
  String _weergaveRegels(String locatie) {
    if (!locatie.contains(',')) return locatie;
    final delen = locatie
        .split(',')
        .map((d) => d.trim())
        .where((d) => d.isNotEmpty)
        .toList();
    if (delen.length < 2) return locatie;
    return '${delen.first}\n${delen.sublist(1).join(', ')}';
  }
}

class _OphaallocatieBadge extends StatelessWidget {
  const _OphaallocatieBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E2E7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_rounded, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          const Text(
            'OPHAALLOCATIE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _KaartPin extends StatelessWidget {
  const _KaartPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.14),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.location_on_rounded,
          color: AppColors.primary, size: 20),
    );
  }
}

/// Zachte gradient-scrim (transparant -> donkere navy) zodat de witte
/// locatietekst/actie onderaan de kaart altijd voldoende contrast heeft,
/// ongeacht wat er in de decoratieve achtergrond onder staat.
class _LeesbaarheidsScrim extends StatelessWidget {
  const _LeesbaarheidsScrim();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.45, 1.0],
          colors: [
            Colors.transparent,
            const Color(0xFF141C2B).withValues(alpha: 0.0),
            const Color(0xFF141C2B).withValues(alpha: 0.82),
          ],
        ),
      ),
    );
  }
}

/// Puur decoratieve, statische plattegrond-illustratie: een lichte
/// ondergrond met vage "bouwblokken" en een dun stratenraster. Geen echte
/// kaartdata, geen netwerkverzoek, geen API-key -- alleen een visuele
/// suggestie dat dit een locatie is. `shouldRepaint` is altijd `false`: het
/// patroon is vast en hangt niet af van externe state.
class _KaartPatroonPainter extends CustomPainter {
  const _KaartPatroonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final achtergrond = Paint()..color = const Color(0xFFEBEEF3);
    canvas.drawRect(Offset.zero & size, achtergrond);

    final blok = Paint()..color = const Color(0xFFE1E5EC);
    void tekenBlok(double l, double t, double w, double h) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(l, t, w, h),
          const Radius.circular(4),
        ),
        blok,
      );
    }

    tekenBlok(size.width * 0.05, size.height * 0.10, size.width * 0.22,
        size.height * 0.28);
    tekenBlok(size.width * 0.62, size.height * 0.06, size.width * 0.30,
        size.height * 0.20);
    tekenBlok(size.width * 0.68, size.height * 0.55, size.width * 0.24,
        size.height * 0.30);
    tekenBlok(size.width * 0.08, size.height * 0.55, size.width * 0.18,
        size.height * 0.22);

    final lijn = Paint()
      ..color = const Color(0xFFCDD3DC)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    for (final fx in [0.0, 0.32, 0.58, 0.85]) {
      canvas.drawLine(Offset(size.width * fx, 0),
          Offset(size.width * fx, size.height), lijn);
    }
    for (final fy in [0.0, 0.42, 0.78]) {
      canvas.drawLine(Offset(0, size.height * fy),
          Offset(size.width, size.height * fy), lijn);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// De ENIGE plek in Lesdetails waar voertuiggegevens staan (voorheen ook
/// nog eens samengevat in _LesInformatieCard -- die dubbeling is verwijderd).
/// Elk gegeven (kenteken/transmissie/categorie) krijgt een eigen label/
/// waarde-rij i.p.v. één samengestelde "54-XT-RA - Automaat - Categorie B"
/// string, en wordt individueel verborgen wanneer het ontbreekt. Nooit
/// "null" en nooit een verzonnen waarde.
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
    final kenteken = les.voertuigKenteken?.trim();
    final transmissie = les.voertuigTransmissie?.trim();
    final categorie = les.voertuigCategorie?.trim();

    final velden = <Widget>[
      if (kenteken != null && kenteken.isNotEmpty)
        _VoertuigVeldRij(label: 'Kenteken', waarde: kenteken),
      if (transmissie != null && transmissie.isNotEmpty)
        _VoertuigVeldRij(
            label: 'Transmissie', waarde: _transmissieLabel(transmissie)),
      if (categorie != null && categorie.isNotEmpty)
        _VoertuigVeldRij(label: 'Categorie', waarde: categorie.toUpperCase()),
    ];

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LESVOERTUIG',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          if (naam != null) ...[
            Row(
              children: [
                const IconBadge(
                  icon: Icons.directions_car_rounded,
                  color: AppColors.textPrimary,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    naam,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (velden.isNotEmpty) ...[
            if (naam != null) ...[
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.borderLight),
              const SizedBox(height: 14),
            ],
            for (var i = 0; i < velden.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              velden[i],
            ],
          ],
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

/// Compacte label/waarde-rij zonder icoon (label links, waarde rechts) --
/// gebruikt voor Kenteken/Transmissie/Categorie in _VoertuigCard. Bewust
/// géén los icoon per rij (dat zou voor drie herhaalde kleine gegevens
/// zwaarder ogen dan de informatie rechtvaardigt).
class _VoertuigVeldRij extends StatelessWidget {
  final String label;
  final String waarde;
  const _VoertuigVeldRij({required this.label, required this.waarde});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            waarde,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
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
        // minHeight (i.p.v. een harde vaste hoogte) + maxLines:1 op het
        // label: de inhoud is zo voor elke knop identiek van hoogte (icoon +
        // exact één tekstregel), wat in de praktijk exact gelijke knoppen
        // oplevert, zonder overflow-risico bij een lang label (bv.
        // "Navigeer naar locatie") op smalle schermen of bij grotere
        // tekstschaal.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.1,
                  ),
                  maxLines: 1,
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
