import SwiftUI
import UIKit

/// Eén navigatie-item zoals aangeleverd door Flutter (`MainScaffold._items`).
struct NativeNavItem: Identifiable {
    let id: Int
    let label: String
    let sfSymbol: String
}

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

private let kIconSize: CGFloat = 22
private let kIconLabelGap: CGFloat = 3
private let kLabelFontSize: CGFloat = 10
private let kTabHorizontalPadding: CGFloat = 10
private let kTabVerticalPadding: CGFloat = 4

@available(iOS 26.0, *)
struct NativeLiquidGlassTabBar: View {
    @ObservedObject var state: NativeNavBarState
    let onSelect: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var indicatorNamespace
    private let haptic = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        GeometryReader { proxy in
            let labelFontSize = sharedLabelFontSize(totalWidth: proxy.size.width)
            GlassEffectContainer(spacing: 8) {
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
            .glassEffect(.clear.interactive(), in: Capsule())
        }
        .frame(height: 56)
    }

    private func sharedLabelFontSize(totalWidth: CGFloat) -> CGFloat {
        guard !state.items.isEmpty, totalWidth > 0 else { return kLabelFontSize }
        let perTabWidth = totalWidth / CGFloat(state.items.count)
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
            onSelect(item.id)
        } label: {
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
                    : Color(red: 95 / 255, green: 102 / 255, blue: 115 / 255)
            )
            .padding(.horizontal, kTabHorizontalPadding)
            .padding(.vertical, kTabVerticalPadding)
            .background {
                if isActive {
                    Capsule()
                        .fill(state.accentColor)
                        .shadow(color: state.accentColor.opacity(0.4), radius: 8, y: 3)
                        .matchedGeometryEffect(id: "activeIndicator", in: indicatorNamespace)
                }
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(item.label))
        .accessibilityAddTraits(isActive ? [.isButton, .isSelected] : .isButton)
    }
}
