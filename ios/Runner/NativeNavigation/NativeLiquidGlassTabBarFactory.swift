import SwiftUI
import UIKit

#if DEBUG
private func nativeNavLog(_ message: String) {
    print("[NAVBAR_SWIFT] \(message)")
}
#else
private func nativeNavLog(_ message: String) {}
#endif

@available(iOS 26.0, *)
final class NativeNavHostingController: UIHostingController<NativeLiquidGlassTabBar> {
    var onLayout: (() -> Void)?

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        onLayout?()
    }
}

@available(iOS 26.0, *)
final class NativeLiquidGlassTabBarFactory {

    private weak var parentViewController: UIViewController?
    private var hostingController: NativeNavHostingController?
    private var isDarkMode = false
    private var navState: NativeNavBarState?

    private let onSelect: (Int) -> Void
    private let onHeightChange: (CGFloat) -> Void

    private(set) var isBarVisible: Bool = false
    private(set) var currentHeight: CGFloat = 0

    init(onSelect: @escaping (Int) -> Void, onHeightChange: @escaping (CGFloat) -> Void) {
        self.onSelect = onSelect
        self.onHeightChange = onHeightChange
    }

    private func applyVisibility(to view: UIView, visible: Bool) {
        if visible {
            view.isHidden = false
            view.alpha = 1.0
            view.isUserInteractionEnabled = true
        } else {
            view.isHidden = true
            view.alpha = 0.0
            view.isUserInteractionEnabled = false
        }
    }

    @discardableResult
    func attach(
        to parent: UIViewController,
        items: [NativeNavItem],
        selectedIndex: Int,
        accentColor: UIColor
    ) -> Bool {
        if hostingController != nil {
            setVisible(isBarVisible)
            return true
        }
        guard !items.isEmpty else { return false }

        let state = NativeNavBarState(
            items: items,
            selectedIndex: selectedIndex,
            accentColor: Color(accentColor)
        )
        let content = NativeLiquidGlassTabBar(state: state) { [weak self] index in
            self?.onSelect(index)
        }

        let hosting = NativeNavHostingController(rootView: content)
        hosting.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false

        parent.addChild(hosting)
        parent.view.addSubview(hosting.view)
        hosting.didMove(toParent: parent)

        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(
                equalTo: parent.view.leadingAnchor, constant: 20),
            hosting.view.trailingAnchor.constraint(
                equalTo: parent.view.trailingAnchor, constant: -20),
            hosting.view.bottomAnchor.constraint(
                equalTo: parent.view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
        ])

        hosting.onLayout = { [weak self, weak parent, weak hosting] in
            guard let self, let parent, let hosting else { return }
            self.reportHeightIfNeeded(parentView: parent.view, barView: hosting.view)
        }

        self.parentViewController = parent
        self.hostingController = hosting
        self.navState = state

        parent.view.layoutIfNeeded()
        reportHeightIfNeeded(parentView: parent.view, barView: hosting.view)

        // Standaard verborgen; pas zichtbaar na expliciet setVisible(true).
        isBarVisible = false
        applyVisibility(to: hosting.view, visible: false)

        return true
    }

    func updateSelectedIndex(_ index: Int) {
        navState?.selectedIndex = index
    }

    func setDarkMode(_ isDark: Bool) {
        isDarkMode = isDark
        hostingController?.overrideUserInterfaceStyle = isDark ? .dark : .light
    }

    func setVisible(_ visible: Bool) {
        isBarVisible = visible
        guard let view = hostingController?.view else {
            nativeNavLog(
                "NAVBAR_NATIVE attached=false hidden=n/a alpha=n/a "
                + "interaction=n/a frame=n/a (awaiting hosting view, desired=\(visible))"
            )
            return
        }
        applyVisibility(to: view, visible: visible)
        nativeNavLog(
            "NAVBAR_NATIVE attached=true hidden=\(view.isHidden) "
            + "alpha=\(view.alpha) interaction=\(view.isUserInteractionEnabled) "
            + "frame=\(view.frame)"
        )
    }

    func detach() {
        hostingController?.willMove(toParent: nil)
        hostingController?.view.removeFromSuperview()
        hostingController?.removeFromParent()
        hostingController = nil
        navState = nil
    }

    private func reportHeightIfNeeded(parentView: UIView, barView: UIView) {
        let barFrameInParent = barView.convert(barView.bounds, to: parentView)
        let height = max(0, parentView.bounds.height - barFrameInParent.minY)
        guard abs(height - currentHeight) > 0.5 else { return }
        currentHeight = height
        onHeightChange(height)
    }
}
