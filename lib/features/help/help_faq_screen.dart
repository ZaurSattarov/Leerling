import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/contact_uri.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/main_detail_header.dart';
import '../../shared/widgets/snackbar.dart';

/// Leerlinggerichte Help & FAQ -- zelfde layout/stijl als de bestaande
/// Help & FAQ van de Instructeur-app (support_faq_screen.dart: Contact
/// bovenaan, daarna categorieën met uitklapbare vragen, Juridisch onderaan),
/// maar met content die uitsluitend voor leerlingen relevant is. Geen
/// instructeurspecifieke vragen.
class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

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
            title: 'Help & FAQ',
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
                      const SectionHeader(title: 'Account & profiel'),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Hoe wijzig ik mijn persoonlijke gegevens?',
                        antwoord:
                            'Ga naar Profiel > Persoonlijke gegevens. Daar kun je je naam, contactgegevens en rijbewijsgegevens bijwerken.',
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Hoe wijzig ik mijn profielfoto?',
                        antwoord:
                            'Ga naar het profielscherm en tik op je avatar. Je kunt een foto kiezen uit je galerij of een nieuwe foto maken.',
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Hoe wijzig ik mijn wachtwoord?',
                        antwoord:
                            'Ga naar Profiel > App-instellingen > Beveiliging en vraag een resetlink aan. Je ontvangt een e-mail waarmee je een nieuw wachtwoord instelt.',
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Hoe verwijder ik mijn account?',
                        antwoord:
                            'Ga naar Profiel > Account verwijderen, onderaan het scherm. Je moet dit expliciet bevestigen — dit kan niet ongedaan worden gemaakt.',
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag:
                            'Wat gebeurt er met mijn gegevens na accountverwijdering?',
                        antwoord:
                            'Je account en persoonlijke gegevens worden verwijderd volgens ons privacybeleid. Bekijk de details bij Profiel > Privacy, gegevens & juridisch.',
                      ),
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Planning & lessen'),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Hoe bekijk ik mijn geplande lessen?',
                        antwoord:
                            'Op het tabblad Planning zie je al je komende en afgeronde lessen. Lessen worden ingepland door je instructeur.',
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Hoe zie ik de details van een les?',
                        antwoord:
                            'Tik op een les in Planning voor de lesdetails: datum/tijd, status, instructeur, voertuig, ophaallocatie en (na afloop) evaluatie.',
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Wat gebeurt er als een les wordt gewijzigd?',
                        antwoord:
                            'Wijzigt je instructeur een les (tijd, status, voertuig), dan zie je dat automatisch bijgewerkt in Planning en ontvang je een melding.',
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Wat gebeurt er als een les wordt geannuleerd?',
                        antwoord:
                            'Een geannuleerde les krijgt die status in Planning (onder "Afgerond") en je ontvangt een melding. De les telt niet mee als afgerond in je voortgang.',
                      ),
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Lespakket & voortgang'),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Hoe werkt mijn lespakket?',
                        antwoord:
                            'Je instructeur koppelt een lespakket aan jouw profiel. Ga naar Profiel > Lespakket voor de inhoud, status en voorwaarden.',
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Hoe zie ik hoeveel lessen ik heb gevolgd?',
                        antwoord:
                            'Op het Voortgang-tabblad en op de Lespakket-pagina zie je hoeveel lessen je hebt afgerond en hoeveel er nog resteren.',
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Hoe bekijk ik mijn voortgang?',
                        antwoord:
                            'Op het Voortgang-tabblad: CBR-competenties, examenadvies en je voortgangstijdlijn.',
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Waar zie ik mijn evaluaties?',
                        antwoord:
                            'Onder Voortgang tijdlijn zie je de laatst afgeronde les met evaluatie; via "Zie alles" bekijk je de volledige geschiedenis. Ook op elke afgeronde les zelf (Planning) staat de evaluatie.',
                      ),
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Live Aankomst'),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Wat is Live Aankomst?',
                        antwoord:
                            'Met Live Aankomst zie je de live locatie van je instructeur op de kaart wanneer die onderweg is naar je afspraak.',
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Wanneer wordt Live Aankomst zichtbaar?',
                        antwoord:
                            'Vanaf een vast aantal minuten vóór je les, als je instructeur Live Aankomst voor die les heeft aangezet. Je ziet dit venster op de lesdetailpagina.',
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag:
                            'Wanneer kan ik de locatie van mijn instructeur zien?',
                        antwoord:
                            'Zodra het zichtbaarheidsvenster is begonnen én je instructeur onderweg is. Open de banner of ophaallocatiekaart op de lesdetailpagina voor de live kaart.',
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag:
                            'Wat gebeurt er als mijn instructeur Live Aankomst niet gebruikt?',
                        antwoord:
                            'Dan blijft de gewone, statische ophaallocatie zichtbaar (indien ingevuld) zonder live kaart. Dit is geen fout — Live Aankomst is een keuze per les/instructeur.',
                      ),
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Facturen & betalingen'),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Waar vind ik mijn facturen?',
                        antwoord:
                            'Op het tabblad Facturen zie je al je facturen met status (open, betaald, verlopen).',
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Hoe betaal ik een factuur?',
                        antwoord:
                            'Open de factuur; als er een betaallink beschikbaar is, kun je direct via iDEAL betalen. Anders neem je contact op met je rijschool voor betaalinstructies.',
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Wat betekent de betaalstatus van mijn factuur?',
                        antwoord:
                            '"Openstaand" wacht nog op betaling, "Betaald" is voldaan, "Te laat" betekent dat de vervaldatum is verstreken zonder betaling.',
                      ),
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Notificaties'),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Welke meldingen kan ik ontvangen?',
                        antwoord:
                            'Onder andere over lessen, facturen, evaluaties, lespakket en Live Aankomst. Tik op het belletje rechtsboven voor je meldingenoverzicht.',
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Hoe wijzig ik mijn notificatie-instellingen?',
                        antwoord:
                            'Ga naar Profiel > Notificaties om te kiezen welke meldingen je wilt ontvangen.',
                      ),
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Rijschool & instructeur'),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Hoe neem ik contact op met mijn instructeur?',
                        antwoord:
                            'Ga naar Profiel > Contact met instructeur, of gebruik de bel-/WhatsApp-/e-mailknoppen op de lesdetailpagina.',
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Waar vind ik mijn rijschoolgegevens?',
                        antwoord:
                            'Ga naar Profiel > Mijn rijschool voor de gegevens van je rijschool en instructeur.',
                      ),
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Privacy & gegevens'),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Welke gegevens worden opgeslagen?',
                        antwoord:
                            'Bekijk ons privacybeleid via Profiel > Privacy, gegevens & juridisch voor een volledig overzicht.',
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Hoe kan ik mijn gegevens bekijken?',
                        antwoord:
                            'Je persoonlijke gegevens staan in Profiel > Persoonlijke gegevens. Voor een volledig gegevensoverzicht kun je contact opnemen met support.',
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag: 'Hoe verwijder ik mijn account?',
                        antwoord:
                            'Ga naar Profiel > Account verwijderen en bevestig de verwijdering. Dit is direct en kan niet ongedaan worden gemaakt.',
                      ),
                      const SizedBox(height: 24),
                      const SectionHeader(title: 'Support'),
                      const SizedBox(height: 12),
                      _FaqCard(
                        vraag: 'Hoe neem ik contact op met support?',
                        antwoord:
                            'Ga naar Help & Support > Chat met support voor een gesprek dat we samen kunnen bijhouden, of gebruik de "E-mail support"-knop bovenaan deze pagina.',
                        actionLabel: 'Chat met support',
                        onAction: () => context.push('/help/support'),
                      ),
                      const SizedBox(height: 12),
                      const _FaqCard(
                        vraag:
                            'Wat gebeurt er nadat ik een supportvraag verstuur?',
                        antwoord:
                            'Je gesprek verschijnt onder "Mijn supportvragen". Klantio Support reageert daar; je krijgt een melding zodra er antwoord is.',
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
                              onTap: () =>
                                  context.push('/profiel/privacy-beleid'),
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
  final String? actionLabel;
  final VoidCallback? onAction;

  const _FaqCard({
    required this.vraag,
    required this.antwoord,
    this.actionLabel,
    this.onAction,
  });

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
                if (widget.actionLabel != null && widget.onAction != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: widget.onAction,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      widget.actionLabel!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
