import Flutter
import UIKit

/// Verbindt de Flutter-navigatieprovider met de native Liquid Glass-navbar.
final class NativeNavigationBridge: NSObject {
    static let shared = NativeNavigationBridge()
    static let channelName = "com.klantio.leerling/native_navigation"

    private var channel: FlutterMethodChannel?
    private var registrar: FlutterPluginRegistrar?
    private var factory: AnyObject?

    private override init() {
        super.init()
    }

    func register(with engineBridge: FlutterImplicitEngineBridge) {
        guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NativeNavigationBridge") else {
            return
        }

        let channel = FlutterMethodChannel(
            name: Self.channelName,
            binaryMessenger: registrar.messenger()
        )
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }

        self.channel = channel
        self.registrar = registrar
    }

    private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "configure":
            configure(call.arguments)
            result(nil)
        case "setSelectedIndex":
            setSelectedIndex(call.arguments)
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func configure(_ rawArguments: Any?) {
        guard #available(iOS 26.0, *), NativeNavigationAvailability.isSupported else {
            channel?.invokeMethod("nativeReady", arguments: ["available": false])
            return
        }

        guard let viewController = registrar?.viewController else {
            channel?.invokeMethod("nativeReady", arguments: ["available": false])
            return
        }
        guard
            let args = rawArguments as? [String: Any],
            let rawItems = args["items"] as? [[String: Any]],
            let initialIndex = args["initialIndex"] as? Int,
            let colorHex = args["primaryColorHex"] as? String
        else {
            channel?.invokeMethod("nativeReady", arguments: ["available": false])
            return
        }

        let items: [NativeNavItem] = rawItems.enumerated().compactMap { index, dict in
            guard
                let label = dict["label"] as? String,
                let sfSymbol = dict["sfSymbol"] as? String
            else { return nil }
            return NativeNavItem(id: index, label: label, sfSymbol: sfSymbol)
        }

        guard items.count == rawItems.count, !items.isEmpty else {
            channel?.invokeMethod("nativeReady", arguments: ["available": false])
            return
        }

        if let existing = factory as? NativeLiquidGlassTabBarFactory {
            channel?.invokeMethod(
                "nativeReady",
                arguments: ["available": true, "height": Double(existing.currentHeight)]
            )
            return
        }

        let concreteFactory = NativeLiquidGlassTabBarFactory(
            onSelect: { [weak self] index in
                self?.channel?.invokeMethod("tabSelected", arguments: ["index": index])
            },
            onHeightChange: { [weak self] height in
                self?.channel?.invokeMethod("heightChanged", arguments: ["height": height])
            }
        )

        let attached = concreteFactory.attach(
            to: viewController,
            items: items,
            selectedIndex: initialIndex,
            accentColor: UIColor(nativeNavigationHex: colorHex)
        )

        guard attached else {
            channel?.invokeMethod("nativeReady", arguments: ["available": false])
            return
        }

        self.factory = concreteFactory

        channel?.invokeMethod(
            "nativeReady",
            arguments: ["available": true, "height": Double(concreteFactory.currentHeight)]
        )
    }

    private func setSelectedIndex(_ rawArguments: Any?) {
        guard
            #available(iOS 26.0, *),
            let factory = factory as? NativeLiquidGlassTabBarFactory,
            let args = rawArguments as? [String: Any],
            let index = args["index"] as? Int
        else { return }
        factory.updateSelectedIndex(index)
    }
}

private extension UIColor {
    convenience init(nativeNavigationHex hex: String) {
        var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("#") {
            cleaned.removeFirst()
        }
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
