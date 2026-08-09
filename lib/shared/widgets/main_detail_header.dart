import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'klantio_header.dart';

/// Centrale terug-actie voor alle detailschermen: `pop()` als de
/// navigatiestack dat toelaat (normale flow, ook via deep link binnen een
/// bestaande sessie), anders een veilige expliciete fallbackroute (bv.
/// cold start of een directe/gedeelde link waar geen stack bestaat om naar
/// terug te poppen). Op één plek gedefinieerd zodat geen enkel scherm zijn
/// eigen afwijkende terugvariant (hard `go()`, `maybePop()`, ...) hoeft te
/// verzinnen.
void handleDetailBack(BuildContext context, {String fallbackRoute = '/home'}) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallbackRoute);
  }
}

/// Enige gedeelde header voor detail-/subschermen (Lesdetails,
/// Lesvoorbereiding, Examenadvies, en alle vergelijkbare schermen). Bouwt
/// op [KlantioHeaderShell]/[KlantioCenteredTitleRow] -- exact dezelfde
/// hoogte, padding en titelstijl als [MainTabHeader] (main_tab_header.dart),
/// alleen met een vaste terugknop in de leading-zone i.p.v. geen leading of
/// een avatar.
///
/// Geen eyebrow-label meer (voorheen bv. "PLANNING" boven "Lesdetails").
class MainDetailHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final String fallbackRoute;
  final VoidCallback? onBack;

  const MainDetailHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.fallbackRoute = '/home',
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return KlantioHeaderShell(
      child: KlantioCenteredTitleRow(
        leading: IconButton(
          key: const Key('main_detail_header_back'),
          onPressed:
              onBack ?? () => handleDetailBack(context, fallbackRoute: fallbackRoute),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Colors.white,
            size: 22,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: kKlantioHeaderZoneWidth,
            minHeight: kKlantioHeaderZoneWidth,
          ),
          splashRadius: 22,
        ),
        title: title,
        trailing: actions.isEmpty ? null : _ActionsRow(actions: actions),
      ),
    );
  }
}

class _ActionsRow extends StatelessWidget {
  final List<Widget> actions;
  const _ActionsRow({required this.actions});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          actions[i],
          if (i != actions.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}
