import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/screen_header.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF141C2B), Color(0xFF1A2D42)],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 16, 20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      const Expanded(
                        child: ScreenHeader(
                          label: 'SUPPORT',
                          title: 'Help & ondersteuning',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SectionHeader(title: 'Contact'),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    children: [
                      _HelpTile(
                        icon: Icons.email_outlined,
                        iconColor: AppColors.infoSolid,
                        title: 'E-mail support',
                        subtitle: 'Stuur ons een bericht',
                        onTap: () => _openEmail(),
                      ),
                      const Divider(height: 20),
                      _HelpTile(
                        icon: Icons.phone_outlined,
                        iconColor: AppColors.successSolid,
                        title: 'Bel je rijschool',
                        subtitle:
                            'Neem direct contact op met je instructeur',
                        onTap: () => _openPhone(),
                      ),
                    ],
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
                const SizedBox(height: 10),
                const _FaqCard(
                  vraag: 'Hoe betaal ik mijn factuur?',
                  antwoord:
                      'Open de factuur in het facturenscherm. Als er een betaallink beschikbaar is, kun je direct betalen. Anders neem je contact op met je rijschool voor betaalinstructies.',
                ),
                const SizedBox(height: 10),
                const _FaqCard(
                  vraag: 'Hoe wijzig ik mijn profielfoto?',
                  antwoord:
                      'Ga naar het profielscherm en tik op je avatar. Je kunt een foto kiezen uit je galerij of een nieuwe foto maken.',
                ),
                const SizedBox(height: 10),
                const _FaqCard(
                  vraag: 'Waar vind ik mijn examenresultaten?',
                  antwoord:
                      'Je examenresultaten vind je onder het examenscherm. Je instructeur voert de resultaten in na afloop van je examen.',
                ),
                const SizedBox(height: 10),
                const _FaqCard(
                  vraag: 'Kan ik mijn koppeling met mijn rijschool verbreken?',
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
                        onTap: () => _openUrl(
                            'https://klantio.nl/privacy'),
                      ),
                      const Divider(height: 20),
                      _HelpTile(
                        icon: Icons.description_outlined,
                        iconColor: AppColors.dark3,
                        title: 'Algemene voorwaarden',
                        subtitle: 'Gebruiksvoorwaarden van de app',
                        onTap: () => _openUrl(
                            'https://klantio.nl/voorwaarden'),
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
    );
  }

  Future<void> _openEmail() async {
    final uri = Uri.parse('mailto:support@klantio.nl?subject=Hulpvraag Leerling App');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _openPhone() async {
    final uri = Uri.parse('tel:');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  static Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _HelpTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HelpTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          IconBadge(icon: icon, color: iconColor, size: 38),
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
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.vraag,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                _expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: AppColors.textHint,
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 10),
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
    );
  }
}
