// Lesvoorbereiding: een rustige, compacte vertaling van de laatste
// relevante lesevaluatie (zie preparation_mapper.dart) -- GEEN AI, geen
// verzonnen advies. Alleen letterlijk opgeslagen data + vaste
// score-templates. Design volgt Impeccable-richtlijnen: geen pastelkleuren,
// geen gigantische kaarten, geen dashboard-KPI's -- witte kaarten met
// semantische tekst-/icoonaccenten, zoals de rest van de app.
//
// UI-polish (2026-08-09, zie werkopdracht): uitsluitend presentatie
// aangepast -- geen enkele databron, mapper-regel of provider gewijzigd.
// Zie preparation_mapper.dart voor de (ongewijzigde) businesslogica.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/les.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_detail_header.dart';
import 'lesvoorbereiding_provider.dart';

class LesvoorbereidingScreen extends ConsumerWidget {
  const LesvoorbereidingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voorbereidingAsync = ref.watch(lesvoorbereidingProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          const MainDetailHeader(
            title: 'Lesvoorbereiding',
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                voorbereidingAsync.when(
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SliverFillRemaining(
                    child: EmptyState(
                      icon: Icons.wifi_off_rounded,
                      title: 'Kon voorbereiding niet laden',
                      subtitle: 'Probeer het later opnieuw.',
                    ),
                  ),
                  data: (vm) => _LesvoorbereidingSliver(vm: vm),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Content, per empty-state ──────────────────────────────────────────────

class _LesvoorbereidingSliver extends StatelessWidget {
  final PreparationViewModel vm;
  const _LesvoorbereidingSliver({required this.vm});

  @override
  Widget build(BuildContext context) {
    // F: geen komende les -- nooit doen alsof er een concrete voorbereiding
    // voor een specifieke afspraak bestaat.
    if (vm.emptyState == PreparationEmptyState.geenVolgendeLes) {
      return const SliverFillRemaining(
        child: EmptyState(
          icon: Icons.event_available_outlined,
          title: 'Nog geen volgende les gepland',
          subtitle:
              'Zodra je instructeur een les plant, verschijnt hier je voorbereiding.',
        ),
      );
    }

    final nextLesson = vm.nextLesson!;

    // A: wel een komende les, maar (nog) geen relevante evaluatie.
    if (vm.emptyState == PreparationEmptyState.geenEvaluatie) {
      return SliverPadding(
        padding: const EdgeInsets.all(20),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            _VolgendeLesContext(les: nextLesson),
            const SizedBox(height: 24),
            const EmptyState(
              icon: Icons.checklist_rounded,
              title: 'Nog geen voorbereiding beschikbaar',
              subtitle:
                  'Na een afgeronde les met evaluatie verschijnt hier je voorbereiding voor de volgende les.',
            ),
          ]),
        ),
      );
    }

    // B/C/D/E: (gedeeltelijke) inhoud -- elke sectie verschijnt alleen als
    // er echt iets voor is, geen lege kaarten.
    //
    // "Laatste beoordeling" hoort inhoudelijk bij de evaluatie (Extra
    // aandacht/Sterk), niet los onderaan de pagina -- daarom wordt hij hier
    // aangesloten op de LAATSTE van die twee kaarten die daadwerkelijk
    // rendert (Sterk heeft voorrang op Extra aandacht, want die staat
    // visueel het dichtst bij de beoordeling). Alleen als geen van beide
    // aanwezig is (instructeur gaf wel een eindbeoordeling maar geen losse
    // scores) krijgt de beoordeling een eigen compacte kaart -- nooit een
    // kale losstaande regel.
    final beoordeling = vm.overallRating;
    final toonInSterk = beoordeling != null && vm.strongItems.isNotEmpty;
    final toonInAandacht =
        beoordeling != null && !toonInSterk && vm.attentionItems.isNotEmpty;
    final toonStandalone =
        beoordeling != null && !toonInSterk && !toonInAandacht;

    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          _VolgendeLesContext(les: nextLesson),
          const SizedBox(height: 20),
          if (vm.focusItems.isNotEmpty) ...[
            _FocusSectie(items: vm.focusItems),
            const SizedBox(height: 20),
          ],
          if (vm.attentionItems.isNotEmpty) ...[
            _SkillLijstKaart(
              titel: vm.attentionSectionLabel,
              items: vm.attentionItems,
              kleur: AppColors.warningSolid,
              beoordelingLabel: toonInAandacht ? beoordeling : null,
            ),
            const SizedBox(height: 14),
          ],
          if (vm.strongItems.isNotEmpty) ...[
            _SkillLijstKaart(
              titel: 'Sterk',
              items: vm.strongItems,
              kleur: AppColors.successSolid,
              beoordelingLabel: toonInSterk ? beoordeling : null,
            ),
            const SizedBox(height: 14),
          ],
          if (toonStandalone) ...[
            _BeoordelingKaart(label: beoordeling),
            const SizedBox(height: 14),
          ],
          if (vm.studentFeedback != null) ...[
            _QuoteKaart(
              titel: 'Feedback van je instructeur',
              icon: Icons.chat_bubble_outline_rounded,
              iconColor: AppColors.textSecondary,
              tekst: vm.studentFeedback!,
              alsCitaat: true,
            ),
            const SizedBox(height: 14),
          ],
          if (vm.preparationNote != null) ...[
            _QuoteKaart(
              titel: 'Voorbereiding volgende les',
              icon: Icons.map_outlined,
              iconColor: AppColors.primary,
              tekst: vm.preparationNote!,
              alsCitaat: false,
            ),
          ],
          const SizedBox(height: 4),
        ]),
      ),
    );
  }
}

// ── Compacte volgende-les context ─────────────────────────────────────────
//
// Eén regel context bovenaan de vaste micro-label "Volgende les" zodat
// meteen duidelijk is waar de rest van de pagina zich op richt -- geen
// aparte kaart, geen extra ruimte-inname.

class _VolgendeLesContext extends StatelessWidget {
  final Les les;
  const _VolgendeLesContext({required this.les});

  static String _datumLabel(String datum) {
    try {
      final tekst =
          DateFormat('EEEE d MMMM', 'nl_NL').format(DateTime.parse(datum));
      return tekst.isEmpty
          ? tekst
          : tekst[0].toUpperCase() + tekst.substring(1);
    } catch (_) {
      return datum;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const IconBadge(
          icon: Icons.event_outlined,
          color: AppColors.primary,
          size: 40,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VOLGENDE LES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _datumLabel(les.datum),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${les.starttijd} – ${les.eindtijd}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Focuspunten (hoogste prioriteit) ──────────────────────────────────────

class _FocusSectie extends StatelessWidget {
  final List<String> items;
  const _FocusSectie({required this.items});

  static String _hoofdletter(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Focus volgende les'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items
              .map(
                (item) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _hoofdletter(item),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

// ── Vaardigheden-lijst (Extra aandacht / Verder oefenen / Sterk) ─────────
//
// Ongewijzigd t.o.v. de vorige versie op inhoud/gedrag -- alleen labels
// nu met vaste maxLines/ellipsis (score blijft altijd rechts uitgelijnd,
// ook bij een lange vaardigheidsnaam op een smal scherm), en een optionele
// "beoordelingLabel"-footer zodat "Laatste beoordeling" niet meer los
// hoeft te zweven maar rechtstreeks aansluit op de evaluatie-inhoud.

class _SkillLijstKaart extends StatelessWidget {
  final String titel;
  final List<PreparationSkillItem> items;
  final Color kleur;
  final String? beoordelingLabel;

  const _SkillLijstKaart({
    required this.titel,
    required this.items,
    required this.kleur,
    this.beoordelingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titel.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: AppColors.borderLight),
              ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    items[i].label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${items[i].score}/5',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: kleur,
                  ),
                ),
              ],
            ),
          ],
          if (beoordelingLabel != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: AppColors.borderLight),
            ),
            _BeoordelingRij(label: beoordelingLabel!),
          ],
        ],
      ),
    );
  }
}

// ── Laatste beoordeling: rij (binnen een evaluatiekaart) ──────────────────

class _BeoordelingRij extends StatelessWidget {
  final String label;
  const _BeoordelingRij({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'LAATSTE BEOORDELING',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.neutralBg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Laatste beoordeling: eigen compacte kaart (fallback zonder Extra ──────
// ── aandacht/Sterk om op aan te sluiten) ───────────────────────────────────

class _BeoordelingKaart extends StatelessWidget {
  final String label;
  const _BeoordelingKaart({required this.label});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: _BeoordelingRij(label: label),
    );
  }
}

// ── Letterlijk instructeur-citaat / -aandachtspunt ────────────────────────
//
// Feedback = terugblik van de instructeur -> citaatstijl (aanhalingstekens,
// cursief, rustige/neutrale icoonkleur).
// Voorbereiding volgende les = actiegerichte instructie -> geen citaat,
// gewone (beter leesbare) tekst, iets sterkere typografische nadruk en de
// merkkleur op het icoon zodat het net iets belangrijker oogt -- zonder een
// grote gekleurde CTA-kaart te worden.

class _QuoteKaart extends StatelessWidget {
  final String titel;
  final IconData icon;
  final Color iconColor;
  final String tekst;
  final bool alsCitaat;

  const _QuoteKaart({
    required this.titel,
    required this.icon,
    required this.iconColor,
    required this.tekst,
    required this.alsCitaat,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, color: iconColor, size: 34),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titel,
                  style: TextStyle(
                    fontSize: alsCitaat ? 13 : 14,
                    fontWeight: alsCitaat ? FontWeight.w700 : FontWeight.w800,
                    color: alsCitaat
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            alsCitaat ? '"$tekst"' : tekst,
            style: TextStyle(
              fontSize: alsCitaat ? 14 : 15,
              height: 1.5,
              fontStyle: alsCitaat ? FontStyle.italic : FontStyle.normal,
              fontWeight: alsCitaat ? FontWeight.w400 : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
