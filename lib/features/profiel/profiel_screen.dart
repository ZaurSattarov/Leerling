import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/student_service.dart';
import '../../models/instructeur.dart';
import '../../models/leerling_profiel.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/widgets/main_tab_header.dart';
import '../../shared/widgets/snackbar.dart';
import 'profielfoto_editor.dart';
import 'rijschool_provider.dart';

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
            eyebrowText: 'LEERLING',
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
  Future<void> _wijzigWachtwoord() async {
    final email = StudentService.currentUser?.email;
    if (email == null) return;

    final bevestig = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Wachtwoord wijzigen'),
        content: Text(
          'We sturen een resetlink naar $email. Volg de instructies in de '
          'e-mail om een nieuw wachtwoord in te stellen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verstuur'),
          ),
        ],
      ),
    );
    if (bevestig != true || !mounted) return;

    try {
      await StudentService.stuurWachtwoordReset(email);
      if (mounted) {
        showAppSnackBar(context, 'E-mail met resetlink verstuurd',
            isSuccess: true);
      }
    } catch (_) {
      if (mounted) {
        showAppSnackBar(context, 'Versturen mislukt. Probeer opnieuw.',
            isError: true);
      }
    }
  }

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
    if (mounted) context.go('/login');
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

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _toonContactActies(Instructeur instructeur) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
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
          _ProfielIdentiteitskaart(profiel: p),
          const SizedBox(height: _ProfileDesign.sectionGap),

          // ── PERSOONLIJKE GEGEVENS ─────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 10),
            child: Text('PERSOONLIJKE GEGEVENS', style: sectionStyle),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _sectieKaart([
              _ProfielMenuTile(
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
            child: _sectieKaart([
              _ProfielMenuTile(
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
            child: _sectieKaart([
              _ProfielMenuTile(
                icon: Icons.inventory_2_outlined,
                label: 'Lespakket',
                subtitle: 'Pakket & voortgangsdetails',
                // Fallback naar het oude pakket-enum (basis/standaard/...)
                // uitsluitend wanneer er nog geen snapshot-pakketnaam is
                // (legacy leerling) -- deze tegel rendert synchroon en
                // raadpleegt daarom niet de catalogus-fallback (die is
                // async); het detailscherm (ProfielLespakketScreen) doet
                // dat wel en toont daar het echte cataloguspakket.
                trailingText: p?.pakketNaam ?? p?.pakket.label,
                onTap: () => context.push('/profiel/lespakket'),
              ),
              const Divider(height: 1, indent: 62),
              _ProfielMenuTile(
                icon: Icons.trending_up_rounded,
                label: 'Mijn voortgang',
                subtitle: p != null
                    ? '${p.lessenGevolgd}/${p.lessenTotaal} lessen gevolgd'
                    : null,
                onTap: () => context.go('/voortgang'),
              ),
              const Divider(height: 1, indent: 62),
              _ProfielMenuTile(
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
            child: _sectieKaart([
              _ProfielMenuTile(
                icon: Icons.notifications_none_rounded,
                label: 'Meldingen',
                subtitle: 'Bekijk je meldingen',
                onTap: () => context.push('/notificaties'),
              ),
              const Divider(height: 1, indent: 62),
              instructeurAsync.maybeWhen(
                data: (instructeur) => _ProfielMenuTile(
                  icon: Icons.forum_outlined,
                  label: 'Contact met instructeur',
                  subtitle: 'Bel of app je instructeur',
                  onTap: instructeur == null
                      ? null
                      : () => _toonContactActies(instructeur),
                ),
                orElse: () => const _ProfielMenuTile(
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
            child: _sectieKaart([
              _ProfielMenuTile(
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
            child: _sectieKaart([
              _ProfielMenuTile(
                icon: Icons.lock_outline_rounded,
                label: 'Wachtwoord',
                subtitle: 'Wijzig via e-mail',
                onTap: StudentService.currentUser?.email == null
                    ? null
                    : _wijzigWachtwoord,
              ),
              const Divider(height: 1, indent: 62),
              _ProfielMenuTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Privacy',
                subtitle: 'Hoe wij omgaan met je gegevens',
                onTap: () => _openUrl('https://klantio.nl/privacy'),
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
            child: _sectieKaart([
              _ProfielMenuTile(
                icon: Icons.headset_mic_outlined,
                label: 'Help & Support',
                onTap: () => context.push('/help'),
              ),
              const Divider(height: 1, indent: 62),
              _ProfielMenuTile(
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
            child: _DangerRow(
              icon: Icons.logout_rounded,
              label: 'Uitloggen',
              onTap: _uitloggen,
            ),
          ),

          const SizedBox(height: 44),
        ],
      ),
    );
  }
}

Widget _sectieKaart(List<Widget> children) {
  return DecoratedBox(
    decoration: BoxDecoration(
      color: _ProfileDesign.card,
      borderRadius: BorderRadius.circular(_ProfileDesign.cardRadius),
      border: Border.all(color: AppColors.border),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(_ProfileDesign.cardRadius),
      child: Column(children: children),
    ),
  );
}

// ── Menu tegel ────────────────────────────────────────────────────────────────
// 1-op-1 overgenomen visueel patroon uit de Instructeur-app (_ProfielMenuTile):
// iconbadge 36x36, cardTitle/subtitle-typografie, pijl alleen zichtbaar als
// de tegel navigeerbaar is (onTap != null).

class _ProfielMenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? trailingText;
  final VoidCallback? onTap;

  const _ProfielMenuTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailingText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return _ProfileDesign.pressed;
        }
        return Colors.transparent;
      }),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _ProfileDesign.hairline),
              ),
              child: Icon(icon, color: const Color(0xFF475569), size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: _ProfileDesign.cardTitle),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle!, style: _ProfileDesign.subtitle),
                  ],
                ],
              ),
            ),
            if (trailingText != null) ...[
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  trailingText!,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _ProfileDesign.secondary,
                  ),
                ),
              ),
            ],
            if (onTap != null) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  color: _ProfileDesign.arrow, size: 17),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Identiteitskaart ─────────────────────────────────────────────────────────
// 1-op-1 overgenomen uit de Instructeur-app (_ProfielSaasHeader): witte
// kaart met marge, afgeronde hoeken, avatar links, naam + statusbadges,
// donkere infochips onder de naam. Alleen de inhoud is leerling-eigen.

class _ProfielIdentiteitskaart extends StatelessWidget {
  final LeerlingProfiel? profiel;

  const _ProfielIdentiteitskaart({required this.profiel});

  @override
  Widget build(BuildContext context) {
    final p = profiel;
    final naam = p?.volledigeNaam ?? 'Mijn profiel';
    final plaats = p?.email ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _ProfileDesign.horizontalPadding,
          ),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _ProfileDesign.card,
              borderRadius: BorderRadius.circular(_ProfileDesign.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    EditableProfielAvatar(profiel: p),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            naam,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ProfileDesign.text,
                              fontSize: 21,
                              height: 1.16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (p != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _StatusBadge(status: p.status),
                                const SizedBox(width: 6),
                                _PakketChip(pakket: p.pakket),
                              ],
                            ),
                          if (plaats.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              plaats,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ProfileDesign.secondary,
                                fontSize: 14,
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
                if (p != null) ...[
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (p.telefoon?.isNotEmpty == true)
                        _DarkInfoChip(
                          icon: Icons.phone_rounded,
                          label: p.telefoon!,
                        ),
                      _DarkInfoChip(
                        icon: Icons.school_rounded,
                        label: '${p.lessenGevolgd}/${p.lessenTotaal} lessen',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final LeerlingStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, textColor) = switch (status) {
      LeerlingStatus.actief => (
          'ACTIEF',
          AppColors.success,
          Colors.white,
        ),
      LeerlingStatus.geslaagd => (
          'GESLAAGD',
          AppColors.primary,
          Colors.white,
        ),
      LeerlingStatus.wachtlijst => (
          'WACHTLIJST',
          AppColors.warningSolid,
          Colors.white,
        ),
      LeerlingStatus.gestopt => (
          'GESTOPT',
          _ProfileDesign.card,
          _ProfileDesign.muted,
        ),
    };

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: status == LeerlingStatus.gestopt
            ? Border.all(color: _ProfileDesign.hairline)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: textColor,
        ),
      ),
    );
  }
}

class _PakketChip extends StatelessWidget {
  final PakketType pakket;
  const _PakketChip({required this.pakket});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 9, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E2E7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_rounded,
              size: 12, color: AppColors.iconPrimary),
          const SizedBox(width: 4),
          Text(
            pakket.label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DarkInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DarkInfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 11, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _ProfileDesign.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.iconPrimary, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
    final background =
        _pressed ? _ProfileDesign.danger : _ProfileDesign.card;
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

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? tel =
        instructeur.telefoon?.isNotEmpty == true ? instructeur.telefoon : null;
    final String? wa = instructeur.whatsappNummer?.isNotEmpty == true
        ? instructeur.whatsappNummer
        : tel;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            if (tel != null)
              PhotoSourceTile(
                icon: Icons.phone_outlined,
                label: 'Bellen',
                onTap: () {
                  Navigator.pop(context);
                  _launch('tel:$tel');
                },
              ),
            if (wa != null) ...[
              if (tel != null) const Divider(height: 18),
              PhotoSourceTile(
                icon: Icons.chat_outlined,
                label: 'WhatsApp',
                onTap: () {
                  Navigator.pop(context);
                  final nr = wa.replaceAll(RegExp(r'\D'), '');
                  _launch('https://wa.me/$nr');
                },
              ),
            ],
            if (tel == null && wa == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Geen contactgegevens bekend voor je instructeur.',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textSecondary),
                ),
              ),
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
