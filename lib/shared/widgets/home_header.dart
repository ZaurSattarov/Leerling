import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'klantio_header.dart';
import 'main_tab_header.dart';

/// De bewuste uitzondering op [MainTabHeader]: Home toont een persoonlijke
/// begroeting i.p.v. een gecentreerde standaardtitel. Bouwt desondanks op
/// dezelfde [KlantioHeaderShell] (identieke hoogte/padding/SafeArea) zodat
/// er geen zichtbare layout-jump ontstaat bij het wisselen tussen Home en
/// de andere hoofdtabs.
///
/// Voorheen: een datumregel ("ZATERDAG 8 AUGUSTUS 2026") boven de
/// begroeting -- volledig verwijderd, voegde geen noodzakelijke informatie
/// toe en maakte de header te hoog. Nieuwe structuur, één horizontaal
/// blok:
///
///   [avatar]  Hoi, Naam.                         [notificatie]
///
/// Avatar-logica (echte foto via CachedNetworkImage, initialen-fallback)
/// is 1-op-1 overgenomen -- geen mock-avatar, geen nieuwe databron.
/// Uiterlijk en begroeting (voornaam) gelijk aan de Instructeur-app
/// (rijschool-planner-flutter/lib/shared/widgets/home_header.dart).
class HomeHeader extends StatelessWidget {
  final String? avatarUrl;
  final String naam;

  /// Wordt niet meer gebruikt -- de bel leest het aantal zelf uit
  /// [ongelezenNotificatiesProvider] (MainHeaderNotificatieKnop).
  final int? ongelezenNotificaties;

  const HomeHeader({
    super.key,
    required this.avatarUrl,
    required this.naam,
    this.ongelezenNotificaties,
  });

  /// Eerste woord van de volledige naam ("Sara de Vries" -> "Sara") voor
  /// een natuurlijke, persoonlijke begroeting.
  String get _voornaam {
    final delen = naam.trim().split(RegExp(r'\s+'));
    return delen.first.isNotEmpty ? delen.first : naam;
  }

  @override
  Widget build(BuildContext context) {
    final initials =
        naam.trim().isNotEmpty ? naam.trim()[0].toUpperCase() : '?';

    return KlantioHeaderShell(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _HomeAvatar(avatarUrl: avatarUrl, initials: initials),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              naam.trim().isNotEmpty ? 'Hoi, $_voornaam.' : 'Welkom terug.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: klantioHeaderTitleStyle(context: context),
            ),
          ),
          const SizedBox(width: 8),
          const MainHeaderNotificatieKnop(),
        ],
      ),
    );
  }
}

class _HomeAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String initials;

  const _HomeAvatar({required this.avatarUrl, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Color(0xFFF1F1F1),
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: avatarUrl?.isNotEmpty == true
            ? CachedNetworkImage(
                imageUrl: avatarUrl!,
                fit: BoxFit.cover,
                width: 40,
                height: 40,
                placeholder: (_, __) => _Initials(initials),
                errorWidget: (_, __, ___) => _Initials(initials),
              )
            : _Initials(initials),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String value;
  const _Initials(this.value);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        value,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
