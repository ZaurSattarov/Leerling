import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/cool_icons.dart';
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

/// Enige gedeelde header voor detail-/subschermen. Uiterlijk 1-op-1 gelijk
/// aan de Instructeur-app (rijschool-planner-flutter/lib/shared/widgets/
/// main_detail_header.dart): donkere balk, coolicons-chevron in een ronde
/// tikzone, gecentreerde titel. Leerling-eigen: de pop-of-fallback-
/// terugactie ([handleDetailBack]) omdat detailschermen hier go_router-
/// routes zijn.
class MainDetailHeader extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final String fallbackRoute;
  final VoidCallback? onBack;
  final double titleHorizontalPadding;

  const MainDetailHeader({
    super.key,
    required this.title,
    this.actions = const [],
    this.fallbackRoute = '/home',
    this.onBack,
    this.titleHorizontalPadding = kKlantioHeaderZoneWidth + 8,
  });

  @override
  Widget build(BuildContext context) {
    return KlantioHeaderShell(
      child: KlantioCenteredTitleRow(
        leading: Semantics(
          button: true,
          label: 'Terug',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('main_detail_header_back'),
              onTap: onBack ??
                  () => handleDetailBack(context, fallbackRoute: fallbackRoute),
              borderRadius: BorderRadius.circular(999),
              // 44x44: minimale tikzone (iOS HIG), zelfde als de headerzone.
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Icon(
                    CoolIcons.chevronLeft,
                    color: Color(0xFFF8FAFC),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ),
        title: title,
        titleHorizontalPadding: titleHorizontalPadding,
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
