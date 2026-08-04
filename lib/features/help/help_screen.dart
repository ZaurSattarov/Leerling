import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/contact_uri.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_detail_header.dart';
import '../../shared/widgets/snackbar.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supportUri = ContactUri.email(
      'info@klantio.com',
      subject: 'Klantio Support',
    )!;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          const MainDetailHeader(
            eyebrowText: 'SUPPORT',
            title: 'Help & ondersteuning',
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SectionHeader(title: 'Contact'),
                      const SizedBox(height: 12),
                      AppCard(
                        child: _HelpTile(
                          icon: Icons.email_outlined,
                          iconColor: AppColors.infoSolid,
                          title: 'E-mail support',
                          value: 'info@klantio.com',
                          subtitle:
                              'Stuur ons een e-mail. We reageren zo snel mogelijk.',
                          onTap: () => _openUri(context, supportUri),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Veelgestelde vragen'),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Hoe plan ik een nieuwe les?',
                        antwoord:
                            'Lessen worden ingepland door je instructeur. Via het beschikbaarheidsscherm kun je aangeven wanneer je beschikbaar bent, zodat je instructeur hier rekening mee kan houden.',
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Hoe betaal ik mijn factuur?',
                        antwoord:
                            'Open de factuur in het facturenscherm. Als er een betaallink beschikbaar is, kun je direct betalen. Anders neem je contact op met je rijschool voor betaalinstructies.',
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Hoe wijzig ik mijn profielfoto?',
                        antwoord:
                            'Ga naar het profielscherm en tik op je avatar. Je kunt een foto kiezen uit je galerij of een nieuwe foto maken.',
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Waar vind ik mijn examenresultaten?',
                        antwoord:
                            'Je examenresultaten vind je onder het examenscherm. Je instructeur voert de resultaten in na afloop van je examen.',
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag:
                            'Kan ik mijn koppeling met mijn rijschool verbreken?',
                        antwoord:
                            'Neem hiervoor contact op met je instructeur. Zij kunnen de koppeling aanpassen in het systeem.',
                      ),
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Juridisch'),
                      const SizedBox(height: 12),
                      AppCard(
                        child: Column(
                          children: [
                            _HelpTile(
                              icon: Icons.privacy_tip_outlined,
                              iconColor: AppColors.dark3,
                              title: 'Privacybeleid',
                              subtitle: 'Hoe wij omgaan met je gegevens',
                              onTap: () => context.push('/profiel/privacy'),
                            ),
                            const Divider(height: 20),
                            _HelpTile(
                              icon: Icons.description_outlined,
                              iconColor: AppColors.dark3,
                              title: 'Algemene voorwaarden',
                              subtitle: 'Gebruiksvoorwaarden van de app',
                              onTap: () =>
                                  context.push('/profiel/algemene-voorwaarden'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _openUri(BuildContext context, Uri uri) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (context.mounted) {
      showAppSnackBar(context, 'Openen lukt niet op dit toestel.',
          isError: true);
    }
  }
}

class _HelpTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? value;
  final String subtitle;
  final VoidCallback? onTap;

  const _HelpTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.value,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconBadge(icon: icon, color: iconColor, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (value != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    value!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: onTap == null ? AppColors.border : AppColors.textMuted,
              size: 20),
        ],
      ),
    );
  }
}

class _FaqCard extends StatefulWidget {
  final String vraag;
  final String antwoord;

  const _FaqCard({required this.vraag, required this.antwoord});

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Semantics(
        button: true,
        toggled: _expanded,
        label: widget.vraag,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      widget.vraag,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textHint,
                    size: 22,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                Text(
                  widget.antwoord,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
