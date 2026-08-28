import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/nav_shell_tokens.dart';
import '../../core/services/student_service.dart';
import '../../core/utils/contact_uri.dart';
import '../../models/instructeur.dart';
import '../../models/leerling_profiel.dart';
import '../../features/notificaties/notificatie_instellingen_provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_tab_header.dart';
import '../../shared/widgets/snackbar.dart';
import 'profile_hero_copy.dart';
import 'profielfoto_editor.dart';
import 'rijschool_provider.dart';
import 'widgets/profiel_menu_widgets.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
// 1-op-1 overgenomen uit de Instructeur-app (rijschool-planner-flutter,
// lib/features/profiel/profiel_screen.dart, class _ProfileDesign) -- zelfde
// paletnamen, spacing en typografie. Alleen de inhoud van de kaarten is
// leerling-eigen.

class _ProfileDesign {
  const _ProfileDesign._();

  static const background = AppColors.surface;
  static const card = Color(0xFFFFFFFF);
  static const text = AppColors.textPrimary;
  static const secondary = AppColors.textSecondary;
  static const muted = Color(0xFF7B8089);
  static const arrow = Color(0x52222936);
  static const pressed = Color(0x08222936);
  static const hairline = Color(0xFFE4E5E7);
  static const danger = Color(0xFFDC2626);

  static const horizontalPadding = 20.0;
  static const sectionGap = 22.0;
  static const cardRadius = 12.0;
  static const smallRadius = 12.0;

  static const sectionTitle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: muted,
  );

  static const cardTitle = TextStyle(
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
      backgroundColor: _ProfileDesign.background,
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
    final confirm = await showDialog<bool>(
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
    );
    if (confirm != true || !mounted) return;
    await StudentService.uitloggen();
    ref.invalidate(notificatieInstellingenProvider);
    if (mounted) context.go('/login');
  }

  Future<void> _toonAccountVerwijderenGap() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nog niet beschikbaar'),
        content: const Text(
          'Er is nog geen veilige leerling-accountverwijderflow. '
          'Neem contact op met support. We verwijderen geen school- of instructeurdata vanuit deze app.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
  }

  void _toonOverDeApp() {
    showDialog<void>(
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
    );
  }

  Future<void> _toonContactActies(Instructeur instructeur) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isScrollControlled: true,
      builder: (ctx) => _ContactActiesSheet(instructeur: instructeur),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profiel;
    final instructeurAsync = ref.watch(mijnInstructeurProvider);
    const sectionStyle = _ProfileDesign.sectionTitle;

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
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: Text('PERSOONLIJKE GEGEVENS', style: sectionStyle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ProfielMenuCard(children: [
              ProfielMenuTile(
                icon: Icons.badge_outlined,
                label: 'Persoonlijke gegevens',
                subtitle: 'Naam, contactgegevens & rijbewijs',
                onTap: () => context.push('/profiel/persoonlijke-gegevens'),
              ),
            ]),
          ),
          const SizedBox(height: _ProfileDesign.sectionGap),

          // ── MIJN RIJSCHOOL ─────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: Text('MIJN RIJSCHOOL', style: sectionStyle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ProfielMenuCard(children: [
              ProfielMenuTile(
                icon: Icons.school_outlined,
                label: 'Mijn rijschool',
                subtitle: 'Rijschool- en instructeurgegevens',
                onTap: () => context.push('/profiel/mijn-rijschool'),
              ),
            ]),
          ),
          const SizedBox(height: _ProfileDesign.sectionGap),

          // ── RIJOPLEIDING ─────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: Text('RIJOPLEIDING', style: sectionStyle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ProfielMenuCard(children: [
              ProfielMenuTile(
                icon: Icons.inventory_2_outlined,
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
                icon: Icons.trending_up_rounded,
                label: 'Mijn voortgang',
                subtitle: p != null
                    ? '${p.lessenGevolgd}/${p.lessenTotaal} lessen gevolgd'
                    : null,
                onTap: () => context.go('/voortgang'),
              ),
              const Divider(height: 1, indent: 62),
              ProfielMenuTile(
                icon: Icons.quiz_outlined,
                label: 'Mijn examens',
                subtitle: 'Examenstatus & resultaten',
                onTap: () => context.push('/examens'),
              ),
            ]),
          ),
          const SizedBox(height: _ProfileDesign.sectionGap),

          // ── COMMUNICATIE ─────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: Text('COMMUNICATIE', style: sectionStyle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ProfielMenuCard(children: [
              instructeurAsync.maybeWhen(
                data: (instructeur) => ProfielMenuTile(
                  icon: Icons.forum_outlined,
                  label: 'Contact met instructeur',
                  subtitle: 'Bel of app je instructeur',
                  onTap: instructeur == null
                      ? null
                      : () => _toonContactActies(instructeur),
                ),
                orElse: () => const ProfielMenuTile(
                  icon: Icons.forum_outlined,
                  label: 'Contact met instructeur',
                ),
              ),
            ]),
          ),
          const SizedBox(height: _ProfileDesign.sectionGap),

          // ── FACTUREN ─────────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: Text('FACTUREN', style: sectionStyle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ProfielMenuCard(children: [
              ProfielMenuTile(
                icon: Icons.receipt_long_outlined,
                label: 'Mijn facturen',
                subtitle: 'Bekijk en betaal facturen',
                onTap: () => context.go('/facturen'),
              ),
            ]),
          ),
          const SizedBox(height: _ProfileDesign.sectionGap),

          // ── INSTELLINGEN ─────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: Text('INSTELLINGEN', style: sectionStyle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ProfielMenuCard(children: [
              ProfielMenuTile(
                icon: Icons.notifications_none_rounded,
                label: 'Notificaties',
                subtitle: 'Beheer welke meldingen je ontvangt',
                onTap: () => context.push('/profiel/notificatie-instellingen'),
              ),
              const Divider(height: 1, indent: 62),
              ProfielMenuTile(
                icon: Icons.settings_outlined,
                label: 'App-instellingen',
                subtitle: 'Machtigingen en beveiliging',
                onTap: () => context.push('/profiel/app-instellingen'),
              ),
            ]),
          ),
          const SizedBox(height: _ProfileDesign.sectionGap),

          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: Text('PRIVACY', style: sectionStyle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ProfielMenuCard(children: [
              ProfielMenuTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy',
                subtitle: 'Hoe wij omgaan met je gegevens',
                onTap: () => context.push('/profiel/privacy'),
              ),
            ]),
          ),
          const SizedBox(height: _ProfileDesign.sectionGap),

          // ── HELP ─────────────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: Text('HELP', style: sectionStyle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ProfielMenuCard(children: [
              ProfielMenuTile(
                icon: Icons.headset_mic_outlined,
                label: 'Help & Support',
                onTap: () => context.push('/help'),
              ),
              const Divider(height: 1, indent: 62),
              ProfielMenuTile(
                icon: Icons.info_outline_rounded,
                label: 'Over de app',
                onTap: _toonOverDeApp,
              ),
            ]),
          ),
          const SizedBox(height: _ProfileDesign.sectionGap),

          // ── ACCOUNT ACTIES ───────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: Text('ACCOUNT ACTIES', style: sectionStyle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _DangerRow(
                  icon: Icons.logout_rounded,
                  label: 'Uitloggen',
                  onTap: _uitloggen,
                ),
                const SizedBox(height: 14),
                _DangerRow(
                  icon: Icons.delete_forever_rounded,
                  label: 'Account verwijderen',
                  onTap: _toonAccountVerwijderenGap,
                ),
              ],
            ),
          ),

          const SizedBox(height: NavShellTokens.contentBottomClearance),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _ProfileDesign.horizontalPadding,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: _ProfileDesign.card,
              borderRadius: BorderRadius.circular(_ProfileDesign.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EditableProfielAvatar(profiel: p),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              copy.primaryTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ProfileDesign.text,
                                fontSize: 18,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.35,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _HeroStatusBadge(
                            label: copy.statusLabel,
                            tone: copy.statusTone,
                          ),
                        ],
                      ),
                      if (copy.schoolLine != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          copy.schoolLine!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _ProfileDesign.secondary,
                            fontSize: 13,
                            height: 1.3,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroStatusBadge extends StatelessWidget {
  final String label;
  final LearnerHeroBadgeTone tone;

  const _HeroStatusBadge({
    required this.label,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final background = switch (tone) {
      LearnerHeroBadgeTone.success => AppColors.success,
      LearnerHeroBadgeTone.ink => AppColors.accent,
      LearnerHeroBadgeTone.warning => AppColors.warningSolid,
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          height: 1.15,
        ),
      ),
    );
  }
}

// ── Danger row (solid red, white text) ───────────────────────────────────────

class _DangerRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DangerRow({
    required this.icon,
    required this.label,
    required this.onTap,
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
    final background = _pressed ? _ProfileDesign.danger : _ProfileDesign.card;
    final foreground = _pressed ? Colors.white : _ProfileDesign.danger;

    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius:
            const BorderRadius.all(Radius.circular(_ProfileDesign.smallRadius)),
        side: const BorderSide(color: _ProfileDesign.hairline),
      ),
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: _setPressed,
        borderRadius:
            const BorderRadius.all(Radius.circular(_ProfileDesign.smallRadius)),
        splashColor: _ProfileDesign.danger.withValues(alpha: 0.08),
        highlightColor: _ProfileDesign.danger.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          child: Row(
            children: [
              Icon(widget.icon, color: foreground, size: 20),
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
  const _ContactActiesSheet({required this.instructeur});

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

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                const Text(
                  'Contact met je instructeur',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (instructeur.naam?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    instructeur.naam!.trim(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                if (telUri != null)
                  _ContactSheetAction(
                    icon: Icons.phone_outlined,
                    iconColor: AppColors.successSolid,
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
                    icon: Icons.chat_outlined,
                    iconColor: AppColors.whatsapp,
                    label: 'WhatsApp',
                    value: (instructeur.whatsappNummer ?? instructeur.telefoon)!
                        .trim(),
                    onTap: () async {
                      Navigator.pop(context);
                      await _launch(context, whatsappUri);
                    },
                  ),
                if (whatsappUri != null && emailUri != null)
                  const Divider(height: 18),
                if (emailUri != null)
                  _ContactSheetAction(
                    icon: Icons.email_outlined,
                    iconColor: AppColors.infoSolid,
                    label: 'E-mail',
                    value: instructeur.email!.trim(),
                    onTap: () async {
                      Navigator.pop(context);
                      await _launch(context, emailUri);
                    },
                  ),
                if (!heeftActies)
                  const Padding(
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
          ),
        ),
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
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer laadstatus ────────────────────────────────────────────────────────

class _ProfielShimmer extends StatelessWidget {
  const _ProfielShimmer();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}
