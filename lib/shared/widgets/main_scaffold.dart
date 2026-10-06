import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/cool_icons.dart';
import '../../core/providers/main_shell_nav_bar_visibility.dart';
import '../../core/services/native_navigation_bridge.dart';
import 'ios_native_navigation_host.dart';

/// Sluit imperatieve root-overlays zodat een shell-tab via `context.go`
/// daadwerkelijk zichtbaar wordt. Laat de GoRouter-basisroute staan.
@visibleForTesting
void dismissRootNavigatorOverlays(BuildContext context) {
  final rootNav = Navigator.of(context, rootNavigator: true);
  if (!rootNav.canPop()) return;
  rootNav.popUntil((route) => route.isFirst);
}

/// App-shell met de vijf hoofdtabs. Navbar, tab-transitie, content-inset en
/// sheet-afhandeling zijn 1-op-1 overgenomen uit de Instructeur-app
/// (rijschool-planner-flutter/lib/shared/widgets/main_scaffold.dart):
/// native iOS 26+ Liquid Glass-balk, met de Flutter-glascapsule als
/// fallback op Android en iOS < 26.
///
/// Leerling-eigen: de tabs zelf, en de hoofdschermen tekenen hun eigen
/// header (geen gedeelde header vanuit de shell).
class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  // `sfSymbol` wordt alleen gebruikt door de native iOS 26+ Liquid
  // Glass-navbar, zodat deze lijst de enige bron van waarheid blijft voor
  // label, route, volgorde én icoon op beide navbars.
  static const List<NavBarItem> _items = [
    NavBarItem(
      label: 'Home',
      icon: CoolIcons.house01,
      activeIcon: CoolIcons.house01,
      route: '/home',
      sfSymbol: 'house.fill',
    ),
    NavBarItem(
      label: 'Planning',
      icon: CoolIcons.calendar,
      activeIcon: CoolIcons.calendar,
      route: '/planning',
      sfSymbol: 'calendar',
    ),
    NavBarItem(
      label: 'Voortgang',
      icon: CoolIcons.chartBarVertical01,
      activeIcon: CoolIcons.chartBarVertical01,
      route: '/voortgang',
      sfSymbol: 'chart.bar.fill',
    ),
    NavBarItem(
      label: 'Facturen',
      icon: CoolIcons.fileDocument,
      activeIcon: CoolIcons.fileDocument,
      route: '/facturen',
      sfSymbol: 'doc.text.fill',
    ),
    NavBarItem(
      label: 'Profiel',
      icon: CoolIcons.user01,
      activeIcon: CoolIcons.user01,
      route: '/profiel',
      sfSymbol: 'person.crop.circle.fill',
    ),
  ];

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  ProviderContainer? _container;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _container = ProviderScope.containerOf(context, listen: false);
      ref.read(mainShellMountedProvider.notifier).state = true;
      syncMainShellNavBarToNative(ref, caller: 'MainScaffold.initState');
    });
  }

  @override
  void dispose() {
    // Shell weg (uitloggen, account verwijderd, ...): de native overlay mag
    // nooit boven een loginscherm blijven hangen.
    final container = _container;
    if (container != null) {
      Future<void>.microtask(() {
        try {
          container.read(mainShellMountedProvider.notifier).state = false;
          container
              .read(nativeNavigationProvider.notifier)
              .setBarVisible(false, force: true);
        } on StateError {
          // ProviderScope is al opgeruimd (app/test afgesloten) -- niets te doen.
        }
      });
    }
    super.dispose();
  }

  int _activeIndex(String location) {
    if (location.startsWith('/planning')) return 1;
    if (location.startsWith('/voortgang')) return 2;
    if (location.startsWith('/facturen')) return 3;
    if (location.startsWith('/profiel')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final activeIndex = _activeIndex(location);
    final showBottomNav = ref.watch(mainShellNavBarVisibleProvider);

    ref.listen<bool>(mainShellNavBarVisibleProvider, (prev, next) {
      if (prev == next) return;
      ref.read(nativeNavigationProvider.notifier).setBarVisible(next);
    });

    final nativeNavState = ref.watch(nativeNavigationProvider);

    // Zie toelichting bij `bottomNavigationBar` hieronder.
    final systeemInsetOnder = MediaQuery.paddingOf(context).bottom;
    final navBarOnderMarge =
        math.max(12.0, systeemInsetOnder * 0.5) + _kBarLiftPixels;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // De body loopt altijd onder de navbar door, zodat het glas iets te
      // vervagen heeft. De hoofdschermen lezen hun scroll-eindruimte uit
      // [MainShellContentInset].
      extendBody: true,
      body: MainShellContentInset(
        bottom: calculateMainShellBottomContentInset(
          safeAreaBottom: systeemInsetOnder,
          showBottomNav: showBottomNav,
          nativeAvailable: nativeNavState.available,
          nativeHeight: nativeNavState.height,
        ),
        child: TabSlideSwitcher(
          activeIndex: activeIndex,
          child: widget.child,
        ),
      ),
      // Bewust GEEN SafeArea: een kleinere, aan het toestel geschaalde
      // ondermarge (helft van het systeem-inset, minimaal 12px). Op iOS 26+
      // vervangt IosNativeNavigationHost dit door de native glasbalk.
      bottomNavigationBar: IosNativeNavigationHost(
        barVisible: showBottomNav,
        activeIndex: activeIndex,
        items: MainScaffold._items,
        onItemTap: (i) => _handleTabTap(context, i),
        fallback: showBottomNav
            ? Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  _kBarTopPadding,
                  20,
                  navBarOnderMarge,
                ),
                child: PremiumBottomNavBar(
                  activeIndex: activeIndex,
                  items: MainScaffold._items,
                  onItemTap: (i) => _handleTabTap(context, i),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  void _handleTabTap(BuildContext context, int index) {
    dismissRootNavigatorOverlays(context);
    context.go(MainScaffold._items[index].route);
  }
}

// ── Richtingsbewuste tab-transitie ───────────────────────────────────────────
//
// Bug die dit oplost: elke bottom-navbar-tab is een eigen top-level GoRoute
// onder de ShellRoute. GoRouter/Flutter geeft elke routewissel standaard de
// platform-paginatransitie (op iOS: CupertinoPageTransitionsBuilder), die
// altijd "nieuwe pagina komt van rechts" animeert -- ongeacht of je naar een
// hogere of lagere tab-index navigeert. Vandaar de klacht: altijd dezelfde
// slide-richting, ongeacht welke tab je aantikt.
//
// Oplossing: de vijf root-tabroutes in app.dart krijgen NoTransitionPage
// (geen eigen paginatransitie meer), en deze widget verzorgt zelf een
// richtingsbewuste slide op basis van de TAB-INDEX (0 Home .. 4 Profiel) --
// nooit op basis van routegeschiedenis. Bewust een eigen, kleine
// Stack+AnimationController-implementatie i.p.v. AnimatedSwitcher:
// AnimatedSwitcher hergebruikt dezelfde transitionBuilder (dezelfde Tween)
// voor zowel de inkomende als de uitgaande tak, wat geen TEGENGESTELDE
// schuifrichtingen kan opleveren (nieuwe pagina van rechts IN, oude pagina
// naar links UIT bij een hogere index -- en omgekeerd bij een lagere).
// Inkomend en uitgaand krijgen hier elk hun eigen Tween<Offset>, gedreven
// door één gedeelde AnimationController.
const Duration _kTabSlideDuration = Duration(milliseconds: 220);

class TabSlideSwitcher extends StatefulWidget {
  final int activeIndex;
  final Widget child;

  const TabSlideSwitcher({
    super.key,
    required this.activeIndex,
    required this.child,
  });

  @override
  State<TabSlideSwitcher> createState() => _TabSlideSwitcherState();
}

class _TabSlideSwitcherState extends State<TabSlideSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late int _settledIndex;

  /// Omhult de live tab-inhoud, zodat we er vlak voor een tabwissel een
  /// stilstaand beeld van kunnen maken.
  final GlobalKey _snapshotKey = GlobalKey();

  /// Stilstaand beeld van de vorige tab dat wegschuift.
  ///
  /// Leerling-afwijking t.o.v. de Instructeur-app: daar schuift de vorige
  /// tab als LIVE widget weg. Onder een GoRouter-ShellRoute is die widget de
  /// shell-Navigator (met een GlobalKey) -- die zou tijdens de animatie
  /// twee keer in de boom staan ("Multiple widgets used the same
  /// GlobalKey"). Een snapshot geeft visueel exact dezelfde slide, zonder
  /// dubbele navigator.
  ui.Image? _vorigBeeld;
  Animation<Offset>? _currentOffset;
  Animation<Offset>? _previousOffset;

  // Beschermt tegen snelle herhaalde taps: als een nieuwe overgang start
  // vóórdat de vorige klaar is, wordt deze teller verhoogd zodat de
  // afrondingscallback van de VERLATEN animatie de inmiddels nieuwere
  // uitgaande laag niet alsnog kan wegvegen.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _settledIndex = widget.activeIndex;
    _controller =
        AnimationController(vsync: this, duration: _kTabSlideDuration);
  }

  ui.Image? _maakSnapshot() {
    try {
      final boundary = _snapshotKey.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary || boundary.debugNeedsPaint) {
        return null;
      }
      final ratio = MediaQuery.devicePixelRatioOf(context);
      return boundary.toImageSync(pixelRatio: ratio);
    } catch (_) {
      return null;
    }
  }

  @override
  void didUpdateWidget(covariant TabSlideSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Zelfde tab opnieuw aangetikt, of een sub-route-wissel BINNEN dezelfde
    // tab: geen slide-animatie.
    if (widget.activeIndex == _settledIndex) return;

    final vanRechts = widget.activeIndex > _settledIndex;
    _settledIndex = widget.activeIndex;
    _generation++;
    final huidigeGeneratie = _generation;

    _vorigBeeld?.dispose();
    _vorigBeeld = _maakSnapshot();

    final curve =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    _currentOffset = Tween<Offset>(
      begin: Offset(vanRechts ? 1 : -1, 0),
      end: Offset.zero,
    ).animate(curve);
    _previousOffset = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(vanRechts ? -1 : 1, 0),
    ).animate(curve);

    _controller
      ..stop()
      ..value = 0
      ..forward().whenCompleteOrCancel(() {
        if (!mounted || huidigeGeneratie != _generation) return;
        setState(() {
          _vorigBeeld?.dispose();
          _vorigBeeld = null;
          _previousOffset = null;
          _currentOffset = null;
        });
      });
  }

  @override
  void dispose() {
    _vorigBeeld?.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vorig = _vorigBeeld;
    final previousOffset = _previousOffset;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (vorig != null && previousOffset != null)
            SlideTransition(
              position: previousOffset,
              child: RawImage(image: vorig, fit: BoxFit.fill),
            ),
          // Altijd dezelfde boomstructuur (ook als er niets animeert), zodat
          // de live tab-inhoud nooit opnieuw opgebouwd wordt.
          SlideTransition(
            position:
                _currentOffset ?? const AlwaysStoppedAnimation(Offset.zero),
            child: RepaintBoundary(key: _snapshotKey, child: widget.child),
          ),
        ],
      ),
    );
  }
}

// ── Premium floating glass nav bar ──────────────────────────────────────────
//
// Ontwerprichting: "floating glass capsule" -- één volledig afgeronde,
// glazige pil. De actieve tab wordt aangeduid met een solide kleurcapsule
// DIREKT ACHTER het icoon, binnen de pil. Kleuren, iconen, actieve/inactieve
// kleur, navigatiestructuur, routes en functionaliteit zijn ongewijzigd --
// alleen de vorm, schaduw, radius en spacing zijn vernieuwd.
//
// Optische centrering (pixel-perfect-correctie): het icoon simpelweg
// centreren in een Column([iconBox, gap, label]) duwt het icoon zichtbaar
// omhoog, omdat de HELE inhoud (icoon + tussenruimte + label) als blok
// wordt gecentreerd terwijl gap+label alleen ONDER het icoon staan. Gemeten
// op de oude constanten (balk 60, icoon-box 40, gap 2, label 12): 12px
// zichtbare ruimte boven het icoon-glyph tegenover 26px eronder -- een
// 1:2.17-verhouding, precies het "omhoog gedrukt" effect. In plaats van het
// blok te centreren, wordt de icoon-box hieronder expliciet gepositioneerd
// (_iconAlignmentY) zodat er onder het icoon precies genoeg ruimte overblijft
// voor gap+label+_kBottomInset, niets meer. Met de constanten hieronder komt
// dat uit op 14px boven / 20px onder (1:1.43) -- geen perfecte 1:1 (dat zou
// een veel hogere balk vergen om het label alsnog kwijt te kunnen), maar wel
// een normale, oogstrelende verhouding i.p.v. de scheve 1:2.17 van daarvoor.
// Zelfde compacte icoon-box (géén los, over de hele balk berekend
// positie-element meer) voor alle tabs, actief én inactief, zodat er nooit
// een sprongetje ontstaat bij het wisselen van tab.

const double _kBarHeight = 56;
// Balk 6-8px dichter naar de home indicator (zie toelichting bij
// `navBarOnderMarge` in MainScaffold.build()) -- gekozen als het midden
// van de gevraagde 6-8px-bandbreedte.
const double _kBarLiftPixels = 7;
// Top-padding boven de balk in de Padding-wrapper hieronder in
// MainScaffold.build() -- als eigen constante zodat floatingNavBarFootprint()
// hem kan hergebruiken i.p.v. het getal ergens anders te dupliceren.
const double _kBarTopPadding = 10;
const double _kContentEndSpacing = 32;

/// Eindafstand onder de laatste scroll-inhoud binnen [MainScaffold].
///
/// De pagina loopt onder de balk door. Dit is de balkhoogte plus de lucht
/// zodat het laatste item boven de balk blijft staan.
@visibleForTesting
double calculateMainShellBottomContentInset({
  required double safeAreaBottom,
  required bool showBottomNav,
  required bool nativeAvailable,
  required double nativeHeight,
}) {
  if (!showBottomNav) return safeAreaBottom + _kContentEndSpacing;

  final fallbackBottomMargin =
      math.max(12.0, safeAreaBottom * 0.5) + _kBarLiftPixels;
  final fallbackFootprint =
      _kBarTopPadding + _kBarHeight + fallbackBottomMargin;
  final navFootprint =
      nativeAvailable && nativeHeight > 0 ? nativeHeight : fallbackFootprint;
  return navFootprint + _kContentEndSpacing;
}

/// Hoogte van de native tabbalk op een pagina buiten de shell.
/// De pagina loopt door tot onder de balk; alleen de scroll-inhoud telt
/// dit op, zodat er geen apart vlak achter het menu ontstaat.
class NavBarOverlayInset extends InheritedWidget {
  final double bottom;

  const NavBarOverlayInset({
    super.key,
    required this.bottom,
    required super.child,
  });

  static double of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<NavBarOverlayInset>()
            ?.bottom ??
        0;
  }

  @override
  bool updateShouldNotify(NavBarOverlayInset oldWidget) =>
      bottom != oldWidget.bottom;
}

class MainShellContentInset extends InheritedWidget {
  final double bottom;

  const MainShellContentInset({
    super.key,
    required this.bottom,
    required super.child,
  });

  static double bottomOf(BuildContext context) {
    final shell = context
        .dependOnInheritedWidgetOfExactType<MainShellContentInset>()
        ?.bottom;
    if (shell != null) return shell;
    final overlay = NavBarOverlayInset.of(context);
    if (overlay > 0) return overlay + _kContentEndSpacing;
    return MediaQuery.paddingOf(context).bottom + _kContentEndSpacing;
  }

  @override
  bool updateShouldNotify(MainShellContentInset oldWidget) =>
      bottom != oldWidget.bottom;
}

/// Actuele hoogte die de zwevende bottom-navbar (native iOS 26+ Liquid Glass
/// of de Flutter-fallback capsule) op dit moment inneemt, gemeten vanaf de
/// onderkant van het scherm -- voor schermen die een eigen zwevend element
/// (zoals een uitklapbare FAB) boven de navbar moeten positioneren zonder
/// een vaste, apparaat-specifieke offset te gokken. Reageert dynamisch op
/// SafeArea.bottom (via [navBarOnderMarge], hieronder) en op de
/// daadwerkelijk gerapporteerde hoogte van de native balk.
double floatingNavBarFootprint(BuildContext context, WidgetRef ref) {
  if (ref.watch(nativeNavSheetCoverCountProvider) > 0) {
    return MediaQuery.paddingOf(context).bottom;
  }
  final navState = ref.watch(nativeNavigationProvider);
  if (navState.available) return navState.height;

  // Zelfde opbouw als de Padding om PremiumBottomNavBar hieronder in
  // MainScaffold.build(): top-padding + balkhoogte + ondermarge. De
  // ondermarge zelf incorporeert al `MediaQuery.paddingOf(context).bottom`
  // (SafeArea.bottom) -- niet nogmaals los optellen.
  final systeemInsetOnder = MediaQuery.paddingOf(context).bottom;
  final navBarOnderMarge =
      math.max(12.0, systeemInsetOnder * 0.5) + _kBarLiftPixels;
  return _kBarTopPadding + _kBarHeight + navBarOnderMarge;
}

/// Canonieke onderste padding voor bottom sheets/modals/formulieren met een
/// vaste CTA onderaan (Bugfix 2026-09-02).
///
/// Waarom dit bestaat: een `showModalBottomSheet`/dialoog wordt door de
/// dichtstbijzijnde `Navigator` als een NIEUWE, eigen `OverlayEntry`
/// ingevoegd -- als sibling van (niet als kind van) de huidige
/// `MainScaffold`-pagina. Daardoor "ziet" zo'n sheet [MainShellContentInset]
/// meestal niet (die InheritedWidget zit in de andere, huidige pagina-tak
/// van de Overlay) en viel de onderste CTA voorheen achter de zwevende
/// bottom-navbar, omdat sheets alleen met `MediaQuery.viewInsets.bottom`
/// (toetsenbord) rekening hielden -- nooit met de navbar-footprint zelf.
///
/// Gebruikt bewust `ProviderScope.containerOf` i.p.v. een `WidgetRef`, zodat
/// elke sheet (ook plain `StatefulWidget`/`StatelessWidget`, niet alleen
/// Consumer-varianten) deze ene canonical helper kan aanroepen zonder eerst
/// naar Riverpod-widgets te hoeven migreren.
///
/// - Toetsenbord open: het OS-inset is altijd groter dan de navbar-footprint
///   (en de navbar is dan meestal toch al aan het zicht onttrokken) --
///   gebruik dan uitsluitend `viewInsets.bottom`.
/// - Toetsenbord dicht: gebruik de daadwerkelijke navbar-footprint
///   ([floatingNavBarFootprint]-logica), niet een geraden vast getal.
///
/// [extra] is de gewenste visuele lucht tussen CTA en navbar/toetsenbord
/// (default 20, gelijk aan de bestaande sheet-marges in de app).
double bottomSheetSafeInset(
  BuildContext context, {
  double extra = 20,
}) {
  final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
  if (keyboardInset > 0) return keyboardInset + extra;

  final container = ProviderScope.containerOf(context, listen: false);
  if (container.read(nativeNavSheetCoverCountProvider) > 0) {
    return MediaQuery.paddingOf(context).bottom + extra;
  }
  final navState = container.read(nativeNavigationProvider);
  final navFootprint = navState.available
      ? navState.height
      : () {
          final systeemInsetOnder = MediaQuery.paddingOf(context).bottom;
          final navBarOnderMarge =
              math.max(12.0, systeemInsetOnder * 0.5) + _kBarLiftPixels;
          return _kBarTopPadding + _kBarHeight + navBarOnderMarge;
        }();
  return navFootprint + extra;
}

/// Houdt de native tabbalk weg zolang dit scherm open is.
///
/// Voor pagina's die van onder naar boven over de shell schuiven. De
/// teller is dezelfde als bij [showKlantioNavbarSafeSheet], zodat de balk
/// niet terugkomt zolang een formulier of sheet hem bedekt.
class KlantioNavAfdekker extends StatefulWidget {
  final Widget child;

  const KlantioNavAfdekker({super.key, required this.child});

  @override
  State<KlantioNavAfdekker> createState() => _KlantioNavAfdekkerState();
}

class _KlantioNavAfdekkerState extends State<KlantioNavAfdekker> {
  ProviderContainer? _container;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_container != null) return;
    final container = ProviderScope.containerOf(context);
    _container = container;
    // Riverpod verbiedt providerwijzigingen tijdens de build/lifecycle.
    Future<void>.microtask(() {
      try {
        container.read(nativeNavSheetCoverCountProvider.notifier).update(
              (count) => count + 1,
            );
        container.read(nativeNavigationProvider.notifier).setBarVisible(false);
      } on StateError {
        // ProviderScope is al opgeruimd (app/test afgesloten) -- niets te doen.
      }
    });
  }

  @override
  void dispose() {
    final container = _container;
    if (container != null) {
      Future<void>.microtask(() {
        try {
          container.read(nativeNavSheetCoverCountProvider.notifier).update(
                (count) => count > 0 ? count - 1 : 0,
              );
          final stillCovered =
              container.read(nativeNavSheetCoverCountProvider) > 0;
          final shouldShow = container.read(mainShellNavBarVisibleProvider);
          if (!stillCovered && shouldShow) {
            container
                .read(nativeNavigationProvider.notifier)
                .setBarVisible(true);
          }
        } on StateError {
          // ProviderScope is al opgeruimd (app/test afgesloten) -- niets te doen.
        }
      });
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Canonieke Klantio-sheet boven de zwevende navbar.
///
/// Padding met [bottomSheetSafeInset] hoort **in** de ondoorzichtige sheet,
/// niet als transparante buitenmarge. Geen extra `SafeArea(bottom: true)`.
Future<T?> showKlantioNavbarSafeSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context, double bottomInset) builder,
  bool isDismissible = true,
  bool enableDrag = true,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final container = ProviderScope.containerOf(context, listen: false);
  final cover = container.read(nativeNavSheetCoverCountProvider.notifier);
  cover.update((count) => count + 1);
  final nav = container.read(nativeNavigationProvider.notifier);
  // Niet afwachten: de balk verdwijnt tegelijk met het openen van de sheet,
  // en er zit zo geen async gap tussen de context en showModalBottomSheet.
  unawaited(nav.setBarVisible(false));
  try {
    return await showModalBottomSheet<T>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottom = bottomSheetSafeInset(ctx);
        final maxHeight = MediaQuery.sizeOf(ctx).height * 0.9;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: builder(ctx, bottom),
        );
      },
    );
  } finally {
    cover.update((count) => count > 0 ? count - 1 : 0);
    final stillCovered = container.read(nativeNavSheetCoverCountProvider) > 0;
    final shouldShow = container.read(mainShellNavBarVisibleProvider);
    if (!stillCovered && shouldShow) {
      await nav.setBarVisible(true);
    }
  }
}

// Correctie: alle vijf tabs tonen nu ALTIJD icoon + titel, actief én
// inactief -- niet langer alleen de actieve tab. Icoon en titel staan in
// dezelfde vaste Column-structuur voor elke staat; alleen de achtergrond
// (transparant <-> AppColors.primary) en de icoon/tekstkleur veranderen.
// Omdat de inhoud nooit verdwijnt/verschijnt, verspringt er nooit iets bij
// tabwissel -- dezelfde padding, dezelfde Column, dezelfde grootte in
// beide staten. De pil krijgt geen vaste breedte meer (die knelde
// "Leerlingen" op smalle schermen); hij past zich aan de inhoud aan via
// Container-padding, met alleen een responsieve maximumbreedte (per tab)
// zodat hij nooit een naastliggende tab kan raken.
const double _kIconSize = 22;
const double _kIconLabelGap = 3;
const double _kLabelFontSize = 10;
const double _kIndicatorRadius = 16;
const double _kIndicatorHorizontalPadding = 10;
const double _kIndicatorVerticalPadding = 4;
const double _kIndicatorSafeMargin = 6;

class PremiumBottomNavBar extends StatelessWidget {
  final int activeIndex;
  final List<NavBarItem> items;
  final void Function(int) onItemTap;

  const PremiumBottomNavBar({
    super.key,
    required this.activeIndex,
    required this.items,
    required this.onItemTap,
  });

  /// Eén gedeelde labelgrootte voor ALLE vijf tabs, berekend uit het
  /// langste label ("Leerlingen") -- i.p.v. elk label onafhankelijk met
  /// een FittedBox te laten krimpen (dat schaalt icoon+label-hoogte
  /// UNIFORM mee, waardoor tabs die net wel/niet hoeven te krimpen een
  /// andere grid-hoogte kregen: gemeten verschil, geen aanname). Met één
  /// voor de hele balk vooraf gemeten waarde staat elke tab, actief of
  /// inactief, gegarandeerd op exact dezelfde verticale grid.
  double _berekenLabelFontSize(BuildContext context, double tabBreedte) {
    final maxPilBreedte = math.max(0.0, tabBreedte - _kIndicatorSafeMargin * 2);
    final maxTekstBreedte =
        math.max(0.0, maxPilBreedte - _kIndicatorHorizontalPadding * 2);
    final langsteLabel = items
        .map((i) => i.label)
        .reduce((a, b) => a.length >= b.length ? a : b);

    final painter = TextPainter(
      text: TextSpan(
        text: langsteLabel,
        style: GoogleFonts.inter(
          fontSize: _kLabelFontSize,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    if (painter.width <= maxTekstBreedte || painter.width <= 0) {
      return _kLabelFontSize;
    }
    return _kLabelFontSize * (maxTekstBreedte / painter.width);
  }

  @override
  Widget build(BuildContext context) {
    const radius = _kBarHeight / 2;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: _kBarHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color:
                const Color(0xFF0F172A).withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color:
                const Color(0xFF0F172A).withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 22,
            offset: const Offset(0, 7),
          ),
        ],
        border: Border.all(
          color: isDark
              ? const Color(0xFF2D3748).withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Laag 1: blur + witte tint (glassmorphism achtergrond)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                color: isDark
                    ? const Color(0xFF1E2330).withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.78),
              ),
            ),
            // Laag 2: tab-content BOVEN de blur — rode pil mengt niet met witte tint
            LayoutBuilder(builder: (context, constraints) {
              final labelFontSize = _berekenLabelFontSize(
                  context, constraints.maxWidth / items.length);
              return Row(
                children: List.generate(items.length, (i) {
                  final isActive = i == activeIndex;
                  final item = items[i];
                  return Expanded(
                    child: _NavBarTab(
                      item: item,
                      isActive: isActive,
                      labelFontSize: labelFontSize,
                      onTap: () => onItemTap(i),
                    ),
                  );
                }),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _NavBarTab extends StatefulWidget {
  final NavBarItem item;
  final bool isActive;
  final double labelFontSize;
  final VoidCallback onTap;

  const _NavBarTab({
    required this.item,
    required this.isActive,
    required this.labelFontSize,
    required this.onTap,
  });

  @override
  State<_NavBarTab> createState() => _NavBarTabState();
}

class _NavBarTabState extends State<_NavBarTab> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = widget.isActive;
    final color = isActive
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : AppColors.iconPrimary);

    return Semantics(
      key: Key('nav_bar_tab_${widget.item.route}'),
      button: true,
      selected: isActive,
      label: widget.item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        child: ExcludeSemantics(
          child: AnimatedScale(
            scale: _pressed ? 0.9 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: SizedBox(
              height: _kBarHeight,
              width: double.infinity,
              child: Center(
                // Icoon + titel staan ALTIJD samen in dezelfde structuur,
                // actief én inactief -- alleen de achtergrondkleur en
                // icoon/tekstkleur veranderen. Zo verspringt er nooit iets
                // bij tabwissel: dezelfde padding, dezelfde Column,
                // dezelfde grootte. labelFontSize komt van
                // PremiumBottomNavBar (gedeeld, vooraf gemeten op het
                // langste label) zodat alle vijf tabs exact dezelfde
                // verticale grid gebruiken.
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  padding: const EdgeInsets.symmetric(
                    horizontal: _kIndicatorHorizontalPadding,
                    vertical: _kIndicatorVerticalPadding,
                  ),
                  // Actieve pil-achtergrond zonder gekleurde gloed-schaduw --
                  // 1-op-1 overgenomen uit de Leerling-app, die de actieve
                  // indicator puur als vlakke kleurcapsule toont.
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(_kIndicatorRadius),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? widget.item.activeIcon : widget.item.icon,
                        size: _kIconSize,
                        color: color,
                      ),
                      const SizedBox(height: _kIconLabelGap),
                      Text(
                        widget.item.label,
                        maxLines: 1,
                        style: GoogleFonts.inter(
                          fontSize: widget.labelFontSize,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav item model ────────────────────────────────────────────────────────────

class NavBarItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  /// SF Symbol-naam voor de native iOS 26+ Liquid Glass-navbar. Wordt door
  /// PremiumBottomNavBar zelf nooit gelezen -- alleen doorgegeven aan native
  /// via IosNativeNavigationHost. Optioneel (default 'circle.fill') zodat
  /// bestaande NavBarItem-constructies (o.a. in tests) niet hoeven te wijzigen.
  final String sfSymbol;

  const NavBarItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
    this.sfSymbol = 'circle.fill',
  });
}

/// Verbergt de native iOS-glasbalk zolang [show] (bv. een bestaande
/// `showModalBottomSheet`/`showDialog`-aanroep) open is. Die balk is een
/// overlay op het hele venster en tekent anders bovenop de sheet. Zelfde
/// cover-teller als [showKlantioNavbarSafeSheet] en [KlantioNavAfdekker].
Future<T?> metNativeNavAfgedekt<T>(
  BuildContext context,
  Future<T?> Function() show,
) async {
  final container = ProviderScope.containerOf(context, listen: false);
  final cover = container.read(nativeNavSheetCoverCountProvider.notifier);
  cover.update((count) => count + 1);
  final nav = container.read(nativeNavigationProvider.notifier);
  unawaited(nav.setBarVisible(false));
  try {
    return await show();
  } finally {
    cover.update((count) => count > 0 ? count - 1 : 0);
    final stillCovered = container.read(nativeNavSheetCoverCountProvider) > 0;
    final shouldShow = container.read(mainShellNavBarVisibleProvider);
    if (!stillCovered && shouldShow) {
      await nav.setBarVisible(true);
    }
  }
}
