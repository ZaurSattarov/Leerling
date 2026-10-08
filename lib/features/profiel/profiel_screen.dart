import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';
import '../../core/utils/contact_uri.dart';
import '../../models/instructeur.dart';
import '../../models/leerling_profiel.dart';
import '../../features/notificaties/notificatie_instellingen_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_tab_header.dart';
import '../../shared/widgets/snackbar.dart';
import 'account_deletion_flow.dart';
import 'profile_hero_copy.dart';
import 'profielfoto_editor.dart';
import 'rijschool_provider.dart';
import 'widgets/profiel_menu_widgets.dart';
import '../../core/constants/cool_icons.dart';
import '../../shared/widgets/isomorphic_icons.dart';
import '../../shared/widgets/main_scaffold.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
// 1-op-1 overgenomen uit de Instructeur-app (rijschool-planner-flutter,
// lib/features/profiel/profiel_screen.dart, class _ProfileDesign) -- zelfde
// paletnamen, spacing en typografie. Alleen de inhoud van de kaarten is
// leerling-eigen.

class _ProfileDesign {
  const _ProfileDesign._();

  static const card = Color(0xFFFFFFFF);
  static Color get text => AppColors.textPrimary;
  static Color get secondary => AppColors.textSecondary;
  static const muted = Color(0xFF7B8089);
  static const arrow = Color(0x52222936);
  static const pressed = Color(0x08222936);
  static const hairline = Color(0xFFE4E5E7);
  static const danger = Color(0xFFDC2626);

  static const horizontalPadding = 20.0;
  static const sectionGap = 22.0;
  static const cardRadius = 12.0;
  static const smallRadius = 12.0;

  static final cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: text,
    height: 1.3,
  );

  static const subtitle = TextStyle(
    fontSize: 13,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: muted,
  );
}

// ── Hoofdscherm ───────────────────────────────────────────────────────────────

class ProfielScreen extends ConsumerWidget {
  const ProfielScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profielAsync = ref.watch(mijnProfielProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const MainTabHeader(
            title: 'Profiel',
            actions: [MainHeaderNotificatieKnop()],
          ),
          Expanded(
            child: profielAsync.when(
              loading: () => const _ProfielShimmer(),
              error: (e, _) =>
                  const Center(child: Text('Kan profiel niet laden')),
              data: (profiel) => _ProfielHub(profiel: profiel),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfielHub extends ConsumerStatefulWidget {
  final LeerlingProfiel? profiel;
  const _ProfielHub({required this.profiel});

  @override
  ConsumerState<_ProfielHub> createState() => _ProfielHubState();
}

class _ProfielHubState extends ConsumerState<_ProfielHub> {
  Future<void> _uitloggen() async {
    final confirm = await metNativeNavAfgedekt<bool>(
      context,
      () => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Uitloggen?'),
          content: const Text('Weet je zeker dat je wilt uitloggen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuleren'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Uitloggen'),
            ),
          ],
        ),
      ),
    );
    if (confirm != true || !mounted) return;
    await StudentService.uitloggen();
    ref.invalidate(notificatieInstellingenProvider);
    if (mounted) context.go('/login');
  }

  Future<void> _toonAccountVerwijderen() async {
    if (!mounted) return;
    await AccountDeletionFlow.start(context);
  }

  void _toonOverDeApp() {
    metNativeNavAfgedekt<void>(
      context,
      () => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Over de app'),
          content: const Text('Leerling App · versie 1.0.7'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Sluiten'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toonContactActies(Instructeur instructeur) async {
    await showKlantioNavbarSafeSheet<void>(
      context: context,
      builder: (ctx, bottom) => _ContactActiesSheet(
        instructeur: instructeur,
        bottom: bottom,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profiel;
    final instructeurAsync = ref.watch(mijnInstructeurProvider);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ref.invalidate(mijnProfielProvider);
        ref.invalidate(mijnInstructeurProvider);
      },
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _ProfielIdentiteitskaart(
            profiel: p,
            instructeur: instructeurAsync.valueOrNull,
          ),
          const SizedBox(height: _ProfileDesign.sectionGap),

          // ── PERSOONLIJKE GEGEVENS ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ProfielMenuCard(children: [
              ProfielMenuTile(
                icon: CoolIcons.userCardId,
                label: 'Persoonlijke gegevens',
                subtitle: 'Naam, contactgegevens & rijbewijs',
                onTap: () => context.push('/profiel/persoonlijke-gegevens'),
              ),
            ]),
          ),
          const SizedBox(height: _ProfileDesign.sectionGap),

          // ── MIJN RIJSCHOOL ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ProfielMenuCard(children: [
              ProfielMenuTile(
                icon: CoolIcons.bookOpen,
                label: 'Mijn rijschool',
                subtitle: 'Rijschool- en instructeurgegevens',
                onTap: () => context.push('/profiel/mijn-rijschool'),
              ),
            ]),
          ),
          const SizedBox(height: _ProfileDesign.sectionGap),

          // ── RIJOPLEIDING ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ProfielMenuCard(children: [
              ProfielMenuTile(
                icon: CoolIcons.archive,
                label: 'Lespakket',
                subtitle: _lespakketSubtitle(p),
                // Fallback naar het oude pakket-enum (basis/standaard/...)
                // uitsluitend wanneer er nog geen snapshot-pakketnaam is
                // (legacy leerling) -- deze tegel rendert synchroon en
                // raadpleegt daarom niet de catalogus-fallback (die is
                // async); het detailscherm (ProfielLespakketScreen) doet
                // dat wel en toont daar het echte cataloguspakket.
                onTap: () => context.push('/profiel/lespakket'),
              ),
              const Divider(height: 1, indent: 62),
              ProfielMenuTile(
                icon: CoolIcons.circleHelp,
                label: 'Mijn examens',
                subtitle: 'Examenstatus & resultaten',
                onTap: () => context.push('/examens'),
              ),
            ]),
          ),
          const SizedBox(height: _ProfileDesign.sectionGap),

          // ── COMMUNICATIE ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ProfielMenuCard(children: [
              instructeurAsync.maybeWhen(
                data: (instructeur) => ProfielMenuTile(
                  icon: CoolIcons.chatConversation,
                  label: 'Contact met instructeur',
                  subtitle: 'Bel of app je instructeur',
                  onTap: instructeur == null
                      ? null
                      : () => _toonContactActies(instructeur),
                ),
                orElse: () => const ProfielMenuTile(
                  icon: CoolIcons.chatConversation,
                  label: 'Contact met instructeur',
                ),
              ),
            ]),
          ),
          const SizedBox(height: _ProfileDesign.sectionGap),

          // ── INSTELLINGEN ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ProfielMenuCard(children: [
              ProfielMenuTile(
                icon: CoolIcons.bell,
                label: 'Notificaties',
                subtitle: 'Beheer welke meldingen je ontvangt',
                onTap: () => context.push('/profiel/notificatie-instellingen'),
              ),
              const Divider(height: 1, indent: 62),
              ProfielMenuTile(
                icon: CoolIcons.settings,
                label: 'App-instellingen',
                subtitle: 'Donkere modus en voorkeuren',
                onTap: () => context.push('/profiel/app-instellingen'),
              ),
            ]),
          ),
          const SizedBox(height: _ProfileDesign.sectionGap),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ProfielMenuCard(children: [
              ProfielMenuTile(
                icon: CoolIcons.shieldCheck,
                label: 'Privacy, gegevens & juridisch',
                subtitle: 'Documenten, gegevens en toestemmingen',
                onTap: () => context.push('/profiel/privacy'),
              ),
            ]),
          ),
          const SizedBox(height: _ProfileDesign.sectionGap),

          // ── HELP ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ProfielMenuCard(children: [
              ProfielMenuTile(
                icon: CoolIcons.headphones,
                label: 'Help & Support',
                onTap: () => context.push('/help'),
              ),
              const Divider(height: 1, indent: 62),
              ProfielMenuTile(
                icon: CoolIcons.info,
                label: 'Over de app',
                onTap: _toonOverDeApp,
              ),
            ]),
          ),
          const SizedBox(height: _ProfileDesign.sectionGap),

          // ── ACCOUNT ACTIES ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Uitloggen is geen gevaar: grijze variant, 1-op-1 de
                // Instructeur-app. Account verwijderen blijft rood.
                _DangerRow(
                  icon: CoolIcons.logOut,
                  label: 'Uitloggen',
                  onTap: _uitloggen,
                  neutraal: true,
                ),
                const SizedBox(height: 14),
                _DangerRow(
                  icon: CoolIcons.trashFull,
                  label: 'Account verwijderen',
                  onTap: _toonAccountVerwijderen,
                ),
              ],
            ),
          ),

          SizedBox(height: MainShellContentInset.bottomOf(context)),
        ],
      ),
    );
  }

  String _lespakketSubtitle(LeerlingProfiel? profiel) {
    if (profiel == null) return 'Pakket- en voortgangsdetails';
    final pakketNaam = profiel.pakketNaam?.trim().isNotEmpty == true
        ? profiel.pakketNaam!.trim()
        : profiel.pakket.label;
    final resterend =
        (profiel.lessenTotaal - profiel.lessenGevolgd).clamp(0, 999);
    return '$pakketNaam · $resterend lessen resterend';
  }
}

// ── Menu tegel ────────────────────────────────────────────────────────────────
// 1-op-1 overgenomen visueel patroon uit de Instructeur-app (_ProfielMenuTile):
// iconbadge 36x36, cardTitle/subtitle-typografie, pijl alleen zichtbaar als
// de tegel navigeerbaar is (onTap != null).

// ── Identiteitskaart ─────────────────────────────────────────────────────────
// 1-op-1 overgenomen uit de Instructeur-app (_ProfielSaasHeader): witte
// kaart met marge, afgeronde hoeken, avatar links, naam + statusbadges,
// donkere infochips onder de naam. Alleen de inhoud is leerling-eigen.

class _ProfielIdentiteitskaart extends StatelessWidget {
  final LeerlingProfiel? profiel;
  final Instructeur? instructeur;

  const _ProfielIdentiteitskaart({
    required this.profiel,
    required this.instructeur,
  });

  @override
  Widget build(BuildContext context) {
    final p = profiel;
    final copy = buildLearnerProfileHeroCopy(
      profiel: p,
      instructeur: instructeur,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Tokens 1-op-1 uit FramerCmsProfileCard (Instructeur-app).
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : const Color(0xFFE5E7EB);
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : const Color(0xFF111827);
    final textSecondary =
        isDark ? const Color(0xFFE2E8F0) : const Color(0xFF4B5563);
    final textMuted =
        isDark ? AppColors.darkTextSecondary : const Color(0xFF9CA3AF);

    final lessen = p == null ? 0 : p.lessenGevolgd;
    final voortgang = p == null ? 0 : (p.voortgangPercent * 100).round();
    final adres = p?.adres?.trim();
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Avatar links, naam + rol rechts
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2E2E33)
                            : const Color(0xFFE5E7EB),
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: EditableProfielAvatar(
                        profiel: p,
                        size: 52,
                        toonBadge: false,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: cardBg, width: 2.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            copy.primaryTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(CoolIcons.check,
                                size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    if (copy.schoolLine != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        copy.schoolLine!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // 2. Locatie
          if (adres != null && adres.isNotEmpty) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(CoolIcons.mapPin, size: 14, color: textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    adres,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // 3. Cijfers, gelijk verdeeld met een verticale scheidingslijn
          Row(
            children: [
              Expanded(
                  child: _KaartCijfer(
                      '$lessen', 'LESSEN', textPrimary, textMuted)),
              Container(width: 1, height: 36, color: borderColor),
              Expanded(
                  child: _KaartCijfer(
                      '$voortgang%', 'VOORTGANG', textPrimary, textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _KaartCijfer extends StatelessWidget {
  final String waarde;
  final String label;
  final Color kleur;
  final Color gedempt;
  const _KaartCijfer(this.waarde, this.label, this.kleur, this.gedempt);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          waarde,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: kleur,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: gedempt,
          ),
        ),
      ],
    );
  }
}

// ── Danger row (solid red, white text) ───────────────────────────────────────

class _DangerRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool neutraal;

  const _DangerRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.neutraal = false,
  });

  @override
  State<_DangerRow> createState() => _DangerRowState();
}

class _DangerRowState extends State<_DangerRow> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final neutraal = widget.neutraal;
    final basis = isDark ? AppColors.darkCard : _ProfileDesign.card;
    final ingedrukt =
        isDark ? const Color(0xFF283244) : const Color(0xFFF1F1F1);

    final background =
        _pressed ? (neutraal ? ingedrukt : _ProfileDesign.danger) : basis;
    final foreground = neutraal
        ? (isDark ? AppColors.darkTextPrimary : const Color(0xFF374151))
        : (_pressed ? Colors.white : _ProfileDesign.danger);
    final iconColor = neutraal
        ? (isDark ? AppColors.darkTextSecondary : const Color(0xFF8A8A8E))
        : foreground;
    final borderColor = _pressed && !neutraal
        ? _ProfileDesign.danger
        : (isDark ? AppColors.darkBorder : AppColors.border);

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius:
            const BorderRadius.all(Radius.circular(_ProfileDesign.smallRadius)),
        side: BorderSide(color: borderColor),
      ),
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: _setPressed,
        borderRadius:
            const BorderRadius.all(Radius.circular(_ProfileDesign.smallRadius)),
        splashColor: neutraal
            ? ingedrukt
            : _ProfileDesign.danger.withValues(alpha: 0.08),
        highlightColor: neutraal
            ? ingedrukt
            : _ProfileDesign.danger.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          child: Row(
            children: [
              Icon(widget.icon, color: iconColor, size: 20),
              const SizedBox(width: 14),
              Text(
                widget.label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Contact-acties sheet (bellen / WhatsApp / route) ─────────────────────────

class _ContactActiesSheet extends StatelessWidget {
  final Instructeur instructeur;
  final double bottom;
  const _ContactActiesSheet({
    required this.instructeur,
    required this.bottom,
  });

  Future<void> _launch(BuildContext context, Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (context.mounted) {
      showAppSnackBar(context, 'Openen lukt niet op dit toestel.',
          isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final telUri = ContactUri.tel(instructeur.telefoon);
    final whatsappUri =
        ContactUri.whatsapp(instructeur.whatsappNummer ?? instructeur.telefoon);
    final emailUri = ContactUri.email(
      instructeur.email,
      subject: 'Vraag via Klantio Leerlingen-app',
    );
    final heeftActies =
        telUri != null || whatsappUri != null || emailUri != null;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final subColor =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Contact met je instructeur',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          if (instructeur.naam?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              instructeur.naam!.trim(),
              style: TextStyle(
                fontSize: 13,
                color: subColor,
              ),
            ),
          ],
          const SizedBox(height: 18),
          if (telUri != null)
            _ContactSheetAction(
              icon: CoolIcons.phone,
              iconColor: titleColor,
              label: 'Bellen',
              value: instructeur.telefoon!.trim(),
              onTap: () async {
                Navigator.pop(context);
                await _launch(context, telUri);
              },
            ),
          if (telUri != null && (whatsappUri != null || emailUri != null))
            const Divider(height: 18),
          if (whatsappUri != null)
            _ContactSheetAction(
              icon: CoolIcons.chat,
              iconColor: titleColor,
              label: 'WhatsApp',
              value:
                  (instructeur.whatsappNummer ?? instructeur.telefoon)!.trim(),
              onTap: () async {
                Navigator.pop(context);
                await _launch(context, whatsappUri);
              },
            ),
          if (whatsappUri != null && emailUri != null)
            const Divider(height: 18),
          if (emailUri != null)
            _ContactSheetAction(
              icon: CoolIcons.mail,
              iconColor: titleColor,
              label: 'E-mail',
              value: instructeur.email!.trim(),
              onTap: () async {
                Navigator.pop(context);
                await _launch(context, emailUri);
              },
            ),
          if (!heeftActies)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Geen geldige contactgegevens bekend voor je instructeur.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContactSheetAction extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Future<void> Function() onTap;

  const _ContactSheetAction({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            IconBadge(icon: icon, color: iconColor, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(CoolIcons.chevronRight, color: iconColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ProfielShimmer extends StatelessWidget {
  const _ProfielShimmer();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}
