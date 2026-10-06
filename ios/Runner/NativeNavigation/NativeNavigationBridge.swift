import Flutter
import UIKit

#if DEBUG
private func nativeNavLog(_ message: String) {
    print("[NAVBAR_SWIFT] \(message)")
}
#else
private func nativeNavLog(_ message: String) {}
#endif

/// Verbindt de Flutter-navigatieprovider (`native_navigation_bridge.dart`)
/// met de native Liquid Glass-navbar via één `FlutterMethodChannel`.
final class NativeNavigationBridge: NSObject {
    static let shared = NativeNavigationBridge()
    static let channelName = "com.klantio.leerling/native_navigation"

    private var channel: FlutterMethodChannel?
    private var registrar: FlutterPluginRegistrar?
    private var factory: AnyObject?
    private var dateTimePickerPresented = false

    /// Bewaarde zichtbaarheid -- standaard verborgen tot Flutter `setVisible(true)`.
    private var barVisible = false

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
        case "setVisible":
            setVisible(call.arguments)
            result(nil)
        case "setDarkMode":
            setDarkMode(call.arguments)
            result(nil)
        case "isNativeDateTimePickerSupported":
            result(NativeNavigationAvailability.isSupported)
        case "pickDate":
            presentDateTimePicker(kind: .date, arguments: call.arguments, result: result)
        case "pickTime":
            presentDateTimePicker(kind: .time, arguments: call.arguments, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func presentDateTimePicker(
        kind: NativeDateTimePickerViewController.Kind,
        arguments rawArguments: Any?,
        result: @escaping FlutterResult
    ) {
        guard #available(iOS 26.0, *), NativeNavigationAvailability.isSupported else {
            result(FlutterError(
                code: "UNSUPPORTED_IOS_VERSION",
                message: "De native datum/tijd-picker vereist iOS 26 of hoger.",
                details: nil
            ))
            return
        }
        guard !dateTimePickerPresented else {
            result(FlutterError(
                code: "PICKER_ALREADY_PRESENTED",
                message: "Er is al een datum/tijd-picker geopend.",
                details: nil
            ))
            return
        }
        guard
            let args = rawArguments as? [String: Any],
            let initialMilliseconds = (args["initialMilliseconds"] as? NSNumber)?.int64Value,
            let rootViewController = registrar?.viewController
        else {
            result(FlutterError(
                code: "INVALID_PICKER_ARGUMENTS",
                message: "De datum/tijd-picker ontving ongeldige argumenten.",
                details: nil
            ))
            return
        }

        let minimumMilliseconds = (args["minimumMilliseconds"] as? NSNumber)?.int64Value
        let maximumMilliseconds = (args["maximumMilliseconds"] as? NSNumber)?.int64Value
        let showCurrentAction =
            (args[kind == .date ? "showTodayAction" : "showNowAction"] as? Bool) ?? true
        let accentColor = UIColor(
            nativeNavigationHex: args["accentColorHex"] as? String ?? "#D63060"
        )

        let picker = NativeDateTimePickerViewController(
            kind: kind,
            initialDate: Date(timeIntervalSince1970: Double(initialMilliseconds) / 1_000),
            minimumDate: minimumMilliseconds.map {
                Date(timeIntervalSince1970: Double($0) / 1_000)
            },
            maximumDate: maximumMilliseconds.map {
                Date(timeIntervalSince1970: Double($0) / 1_000)
            },
            showCurrentAction: showCurrentAction,
            accentColor: accentColor
        ) { [weak self] selectedMilliseconds in
            self?.dateTimePickerPresented = false
            result(selectedMilliseconds)
        }

        let navigationController = UINavigationController(rootViewController: picker)
        navigationController.modalPresentationStyle = .pageSheet
        navigationController.view.tintColor = accentColor
        if let sheet = navigationController.sheetPresentationController {
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            let compactIdentifier = UISheetPresentationController.Detent.Identifier(
                "dateTimePickerContent"
            )
            sheet.detents = [
                .custom(identifier: compactIdentifier) { context in
                    min(picker.preferredContentSize.height + 52, context.maximumDetentValue)
                },
            ]
            sheet.selectedDetentIdentifier = compactIdentifier
        }
        navigationController.presentationController?.delegate = picker

        dateTimePickerPresented = true
        topViewController(from: rootViewController).present(
            navigationController,
            animated: true
        )
    }

    private func topViewController(from root: UIViewController) -> UIViewController {
        if let presented = root.presentedViewController {
            return topViewController(from: presented)
        }
        if let navigation = root as? UINavigationController,
           let visible = navigation.visibleViewController {
            return topViewController(from: visible)
        }
        if let tabs = root as? UITabBarController,
           let selected = tabs.selectedViewController {
            return topViewController(from: selected)
        }
        return root
    }

    private func applyBarVisibleToFactory() {
        guard #available(iOS 26.0, *),
              let factory = factory as? NativeLiquidGlassTabBarFactory else { return }
        factory.setVisible(barVisible)
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
            existing.updateSelectedIndex(initialIndex)
            applyBarVisibleToFactory()
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
        applyBarVisibleToFactory()

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

    private func setDarkMode(_ rawArguments: Any?) {
        guard
            let args = rawArguments as? [String: Any],
            let isDark = args["isDark"] as? Bool
        else { return }
        guard #available(iOS 26.0, *),
              let factory = factory as? NativeLiquidGlassTabBarFactory else { return }
        factory.setDarkMode(isDark)
    }

    private func setVisible(_ rawArguments: Any?) {
        guard
            let args = rawArguments as? [String: Any],
            let visible = args["visible"] as? Bool
        else { return }

        barVisible = visible
        nativeNavLog("received visible=\(visible) factoryAttached=\(factory != nil)")
        applyBarVisibleToFactory()
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

private final class NativeDateTimePickerViewController: UIViewController,
    UIAdaptivePresentationControllerDelegate {
    enum Kind {
        case date
        case time
    }

    private let kind: Kind
    private let datePicker = UIDatePicker()
    private let minimumDate: Date?
    private let maximumDate: Date?
    private let showCurrentAction: Bool
    private let accentColor: UIColor
    private var completion: ((Int64?) -> Void)?

    init(
        kind: Kind,
        initialDate: Date,
        minimumDate: Date?,
        maximumDate: Date?,
        showCurrentAction: Bool,
        accentColor: UIColor,
        completion: @escaping (Int64?) -> Void
    ) {
        self.kind = kind
        self.minimumDate = minimumDate
        self.maximumDate = maximumDate
        self.showCurrentAction = showCurrentAction
        self.accentColor = accentColor
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
        datePicker.date = initialDate
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is niet ondersteund")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.tintColor = accentColor
        navigationItem.title = kind == .date ? "Datum" : "Tijd"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Annuleren",
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Toepassen",
            style: .done,
            target: self,
            action: #selector(applyTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = accentColor
        navigationItem.rightBarButtonItem?.tintColor = .white
        navigationController?.navigationBar.tintColor = accentColor

        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.locale = Locale(identifier: "nl_NL")
        datePicker.calendar = Calendar(identifier: .gregorian)
        datePicker.timeZone = .autoupdatingCurrent
        datePicker.tintColor = accentColor
        datePicker.minimumDate = minimumDate
        datePicker.maximumDate = maximumDate
        datePicker.datePickerMode = kind == .date ? .date : .time
        datePicker.preferredDatePickerStyle = kind == .date ? .inline : .wheels
        if kind == .time {
            datePicker.minuteInterval = 1
        }
        view.addSubview(datePicker)

        var constraints = [
            datePicker.leadingAnchor.constraint(
                greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 16
            ),
            datePicker.trailingAnchor.constraint(
                lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -16
            ),
            datePicker.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ]

        if showCurrentAction {
            var configuration = UIButton.Configuration.tinted()
            configuration.title = kind == .date ? "Vandaag" : "Nu"
            configuration.baseForegroundColor = .white
            configuration.baseBackgroundColor = accentColor.withAlphaComponent(0.14)
            configuration.cornerStyle = .capsule
            let currentButton = UIButton(configuration: configuration)
            currentButton.translatesAutoresizingMaskIntoConstraints = false
            currentButton.tintColor = .white
            currentButton.addTarget(
                self,
                action: #selector(selectCurrentTapped),
                for: .touchUpInside
            )
            view.addSubview(currentButton)
            constraints.append(contentsOf: [
                datePicker.topAnchor.constraint(
                    equalTo: view.safeAreaLayoutGuide.topAnchor,
                    constant: 12
                ),
                currentButton.topAnchor.constraint(equalTo: datePicker.bottomAnchor, constant: 12),
                currentButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                currentButton.bottomAnchor.constraint(
                    lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor,
                    constant: -16
                ),
            ])
        } else {
            constraints.append(contentsOf: [
                datePicker.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            ])
        }

        NSLayoutConstraint.activate(constraints)

        let measuredPickerHeight = max(
            datePicker.intrinsicContentSize.height,
            kind == .date ? 340 : 216
        )
        let currentActionHeight: CGFloat = showCurrentAction ? 56 : 0
        preferredContentSize = CGSize(
            width: 0,
            height: 12 + measuredPickerHeight + currentActionHeight + 16
        )
    }

    @objc private func cancelTapped() {
        finish(with: nil)
        dismiss(animated: true)
    }

    @objc private func applyTapped() {
        let milliseconds = Int64((datePicker.date.timeIntervalSince1970 * 1_000).rounded())
        finish(with: milliseconds)
        dismiss(animated: true)
    }

    @objc private func selectCurrentTapped() {
        var current = Date()
        if let minimumDate, current < minimumDate {
            current = minimumDate
        }
        if let maximumDate, current > maximumDate {
            current = maximumDate
        }
        datePicker.setDate(current, animated: true)
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        finish(with: nil)
    }

    private func finish(with value: Int64?) {
        guard let completion else { return }
        self.completion = nil
        completion(value)
    }
}
