import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// Visueel identiek aan MainTabHeader (main_tab_header.dart) -- zelfde
// donkerblauwe gradient, volledige schermbreedte, SafeArea-gedrag,
// padding, titeltypografie en eyebrow-stijl, geen afgeronde onderhoeken,
// geen boxShadow. Het enige verschil: links een terugknop i.p.v. een
// optionele avatar, en gebruikt door detail-/subschermen i.p.v. de vijf
// hoofdtabs.

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

class MainDetailHeader extends StatelessWidget {
  final String eyebrowText;
  final String title;
  final List<Widget> actions;
  final String fallbackRoute;
  final VoidCallback? onBack;

  const MainDetailHeader({
    super.key,
    required this.eyebrowText,
    required this.title,
    this.actions = const [],
    this.fallbackRoute = '/home',
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                key: const Key('main_detail_header_back'),
                onPressed: onBack ??
                    () => handleDetailBack(context, fallbackRoute: fallbackRoute),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 40, minHeight: 40),
                splashRadius: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      eyebrowText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white54,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.1,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < actions.length; i++) ...[
                actions[i],
                if (i != actions.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
