import SwiftUI
import UIKit

/// Eén navigatie-item zoals aangeleverd door Flutter (`MainScaffold._items`
/// in `lib/shared/widgets/main_scaffold.dart`). Flutter blijft de enige bron
/// van waarheid voor label, route, volgorde en aantal tabs -- Swift kent hier
/// bewust geen eigen hardcoded tabnamen of routes, om drift tussen de twee
/// navbars te voorkomen.
struct NativeNavItem: Identifiable {
    let id: Int
    let label: String
    let sfSymbol: String
}

/// Gedeelde, observeerbare status tussen de UIKit-factory en de SwiftUI-inhoud.
///
/// `selectedIndex` wordt UITSLUITEND door Flutter gezet, via
/// `NativeNavigationBridge.setSelectedIndex` -> `factory.updateSelectedIndex`.
/// Een tik door de gebruiker verandert deze waarde niet rechtstreeks: die tik
/// gaat via `onSelect` terug naar Flutter (go_router navigeert), en pas
/// wanneer de widget herbouwt met de nieuwe actieve tab stuurt Flutter de
/// nieuwe index opnieuw naar hier. Doordat de twee richtingen strikt
/// gescheiden zijn (native -> Flutter alleen bij een echte tik, Flutter ->
/// native alleen als visuele sync) kan er geen oneindige native/Flutter-lus
/// ontstaan.
@available(iOS 26.0, *)
final class NativeNavBarState: ObservableObject {
    @Published var selectedIndex: Int
    let items: [NativeNavItem]
    let accentColor: Color

    init(items: [NativeNavItem], selectedIndex: Int, accentColor: Color) {
        self.items = items
        self.selectedIndex = selectedIndex
        self.accentColor = accentColor
    }
}

// Zelfde constanten als Flutter's PremiumBottomNavBar (_kIconSize,
// _kIconLabelGap, _kLabelFontSize, _kIndicatorHorizontalPadding,
// _kIndicatorVerticalPadding in main_scaffold.dart) -- icoon BOVEN het
// label (verticaal), niet naast elkaar, zodat de native balk er niet
// anders uitziet dan zowel de bestaande Flutter-pil als de referentie.
private let kIconSize: CGFloat = 22
private let kIconLabelGap: CGFloat = 3
private let kLabelFontSize: CGFloat = 10
private let kTabHorizontalPadding: CGFloat = 10
private let kTabVerticalPadding: CGFloat = 4

/// De echte native Liquid Glass-navbar: één zwevende glazen capsule
/// (`.glassEffect` op een `GlassEffectContainer`, publieke SwiftUI-API sinds
/// iOS 26) met daarbinnen een solide kleurcapsule die met de systeem-eigen
/// veer-animatie naar de actieve tab schuift -- zelfde visuele taal als de
/// bestaande Flutter-pil (`PremiumBottomNavBar` in main_scaffold.dart), maar
/// nu met echte systeemtransparantie/refractie in plaats van een
/// `BackdropFilter`-nabootsing.
///
/// De balk krijgt van de factory een volledige breedte (net als de Flutter-
/// pil, die ook over de volle `Row`-breedte tussen de 20pt-marges loopt) --
/// elke tab krijgt daarbinnen een GELIJKE kolombreedte (`.frame(maxWidth:
/// .infinity)`, het SwiftUI-equivalent van Flutter's `Expanded`), en alle
/// vijf labels delen ÉÉN gezamenlijk berekend lettertype (zie
/// `sharedLabelFontSize`) -- exact dezelfde aanpak als
/// `PremiumBottomNavBar._berekenLabelFontSize` in main_scaffold.dart, om te
/// voorkomen dat het langste label ("Leerlingen") alleen zichzelf laat
/// krimpen terwijl de andere tabs een andere verticale grid krijgen.
@available(iOS 26.0, *)
struct NativeLiquidGlassTabBar: View {
    @ObservedObject var state: NativeNavBarState
    let onSelect: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var indicatorNamespace
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        GeometryReader { proxy in
            let labelFontSize = sharedLabelFontSize(totalWidth: proxy.size.width)
            GlassEffectContainer(spacing: 8) {
                // Animatie op dit gedeelde niveau (i.p.v. per tab herhaald)
                // is de aanbevolen plek voor `matchedGeometryEffect`: alle
                // tabs delen dezelfde transactie, zodat de kleurcapsule
                // vloeiend van de oude naar de nieuwe actieve tab schuift
                // i.p.v. los per tab te knipperen.
                HStack(spacing: 0) {
                    ForEach(state.items) { item in
                        tabButton(item, labelFontSize: labelFontSize)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .animation(
                    reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.82),
                    value: state.selectedIndex
                )
            }
            // `.clear` i.p.v. `.regular`: publieke SwiftUI-Glass-variant
            // (SwiftUICore.Glass, iOS 26 SDK) zonder de grijs/wit getinte
            // vulling van `.regular` -- puurdere, transparantere glasrand
            // zodat de content erachter duidelijker doorschijnt.
            .glassEffect(.clear.interactive(), in: Capsule())
        }
        // Zelfde balkhoogte als de Flutter-fallback (`_kBarHeight` in
        // main_scaffold.dart) zodat wisselen tussen de twee navbars nooit
        // een zichtbare sprong in de gereserveerde hoogte geeft.
        .frame(height: 56)
    }

    /// Zelfde formule als Flutter's `_berekenLabelFontSize`: meet het
    /// langste label bij het volle lettertype, en krimp -- indien nodig --
    /// ALLE labels tegelijk zodat ze allemaal in hun kolom passen, zonder
    /// per-tab afkapping ("...").
    private func sharedLabelFontSize(totalWidth: CGFloat) -> CGFloat {
        guard !state.items.isEmpty, totalWidth > 0 else { return kLabelFontSize }
        let perTabWidth = totalWidth / CGFloat(state.items.count)
        // Icoon staat nu BOVEN het label (geen horizontale ruimte meer nodig
        // naast de tekst) -- alleen de horizontale pil-padding gaat van de
        // beschikbare tekstbreedte af.
        let beschikbareTekstbreedte = max(0, perTabWidth - 2 * kTabHorizontalPadding)
        let langsteLabel = state.items.map(\.label).max(by: { $0.count < $1.count }) ?? ""
        let breedteBijVolleGrootte = (langsteLabel as NSString).size(
            withAttributes: [.font: UIFont.boldSystemFont(ofSize: kLabelFontSize)]
        ).width

        guard breedteBijVolleGrootte > beschikbareTekstbreedte, breedteBijVolleGrootte > 0 else {
            return kLabelFontSize
        }
        return kLabelFontSize * (beschikbareTekstbreedte / breedteBijVolleGrootte)
    }

    @ViewBuilder
    private func tabButton(_ item: NativeNavItem, labelFontSize: CGFloat) -> some View {
        let isActive = item.id == state.selectedIndex

        Button {
            if item.id != state.selectedIndex {
                haptic.impactOccurred()
            }
            // Altijd doorsturen, ook bij een tik op de al-actieve tab --
            // zelfde gedrag als de Flutter-pil (bv. Agenda reset de
            // geselecteerde datum ook wanneer je er al op staat).
            onSelect(item.id)
        } label: {
            // Icoon+label+achtergrond blijven CONTENT-HUGGEND (mainAxisSize.min
            // in Flutter-termen) en worden pas daarna gecentreerd binnen de
            // volle kolombreedte -- exact zoals `_NavBarTab` in
            // main_scaffold.dart (`Center(child: AnimatedContainer(...))`
            // binnen een `SizedBox(width: double.infinity)`). Zou de
            // achtergrond zelf de volle kolom vullen, dan wordt de actieve
            // pil op elke tab een andere breedte i.p.v. één consistente
            // vorm die alleen van positie verschuift.
            VStack(spacing: kIconLabelGap) {
                Image(systemName: item.sfSymbol)
                    .font(.system(size: kIconSize, weight: .semibold))
                    .frame(height: kIconSize)
                Text(item.label)
                    .font(.system(size: labelFontSize, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .foregroundStyle(
                isActive
                    ? .white
                    : (colorScheme == .dark
                        ? .white
                        : Color(red: 95 / 255, green: 102 / 255, blue: 115 / 255))
            )
            .padding(.horizontal, kTabHorizontalPadding)
            .padding(.vertical, kTabVerticalPadding)
            .background {
                if isActive {
                    Capsule()
                        .fill(state.accentColor)
                        // Zachte gekleurde gloed onder de actieve pil --
                        // puur SwiftUI `.shadow`, native nagemaakt naar het
                        // idee van de referentie-demo (geen code/dependency
                        // overgenomen, alleen het visuele effect).
                        .shadow(color: state.accentColor.opacity(0.4), radius: 8, y: 3)
                        .matchedGeometryEffect(id: "activeIndicator", in: indicatorNamespace)
                }
            }
            .frame(maxWidth: .infinity)
            // Hele kolom tikbaar maken, niet alleen de zichtbare pil --
            // zelfde bedoeling als Flutter's `HitTestBehavior.opaque` op de
            // GestureDetector in `_NavBarTab`.
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(item.label))
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
    }
}
