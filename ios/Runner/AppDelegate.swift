import Flutter
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Bewaar launchOptions voor FLTFirebaseMessagingPlugin na deferred plugin-registratie.
  private var storedLaunchOptions: [UIApplication.LaunchOptionsKey: Any]?
  // AGENT LOCK (2026-10-08) — DO NOT REMOVE.
  // APNs kan vóór Firebase.initializeApp() (Dart) binnenkomen. Zonder buffer
  // raakt Messaging.apnsToken zoek → geen FCM-token → geen push. Zie
  // .cursor/rules/ios-push-guard.mdc.
  private var pendingApnsDeviceToken: Data?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    storedLaunchOptions = launchOptions
    configureGoogleMaps()
    // UIScene + deferred plugins: FLTFirebaseMessagingPlugin hangt pas tijdens
    // registerWithRegistrar een observer op UIApplicationDidFinishLaunchingNotification.
    // Op scene-lifecycle is die notificatie dan al gepost → geen tap-bridge,
    // getInitialMessage hangt, onMessageOpenedApp fired niet.
    // Zie FLTFirebaseMessagingPlugin.m application_onDidFinishLaunchingNotification:
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // Native iOS 26+ Liquid Glass-navbar (ios/Runner/NativeNavigation/) --
    // zonder deze registratie viel de app altijd terug op de Flutter-pil.
    NativeNavigationBridge.shared.register(with: engineBridge)
    replayDidFinishLaunchingForFirebaseMessaging()
    applyPendingApnsToken()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
      self?.applyPendingApnsToken()
      UIApplication.shared.registerForRemoteNotifications()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
      self?.applyPendingApnsToken()
    }
  }

  private func applyPendingApnsToken() {
    guard let token = pendingApnsDeviceToken, FirebaseApp.app() != nil else { return }
    Messaging.messaging().apnsToken = token
    NSLog("[AppDelegate] APNS token gekoppeld aan Firebase Messaging")
  }

  /// Live Aankomst (Feature 2, Fase 3): Google Maps SDK for iOS.
  /// De key komt uit Info.plist's "GMSApiKey", die op zijn beurt uit
  /// ios/Flutter/Secrets.xcconfig komt (lokaal, gitignored) -- NOOIT
  /// hardcoded hier. Zonder key blijft de kaart leeg/grijs (geen crash);
  /// zie eindrapport voor waarom dit hier een duidelijke runtime-log is
  /// i.p.v. een build-time-fail zoals bij Android (Xcode/xcconfig biedt
  /// geen equivalent zonder een extra, hier niet geverifieerde build phase).
  private func configureGoogleMaps() {
    guard
      let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
      !apiKey.isEmpty
    else {
      NSLog(
        "[AppDelegate] GOOGLE_MAPS_API_KEY ontbreekt -- voeg GOOGLE_MAPS_API_KEY toe aan " +
        "ios/Flutter/Secrets.xcconfig (lokaal, gitignored). Live Aankomst-kaart blijft leeg " +
        "tot dit is ingevuld."
      )
      return
    }
    GMSServices.provideAPIKey(apiKey)
  }

  private func replayDidFinishLaunchingForFirebaseMessaging() {
    var userInfo: [AnyHashable: Any] = [:]
    if let opts = storedLaunchOptions {
      for (key, value) in opts {
        userInfo[key] = value
      }
    }
    NotificationCenter.default.post(
      name: UIApplication.didFinishLaunchingNotification,
      object: UIApplication.shared,
      userInfo: userInfo.isEmpty ? nil : userInfo
    )
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    // Expliciete APNs→FCM-koppeling: FirebaseApp.configure() gebeurt vanuit Dart;
    // swizzling kan later klaar zijn dan didRegister. Token bufferen tot Firebase klaar is.
    pendingApnsDeviceToken = deviceToken
    applyPendingApnsToken()
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("[AppDelegate] APNS_REGISTER_FAILED: %@", error.localizedDescription)
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  // AGENT LOCK (2026-10-08) — DO NOT silence banners.
  // Nooit completionHandler([]) voor remote push: dat maakte push “dood”
  // terwijl de app open was. Productkeuze nodig vóór enige suppressie.
  // Zie .cursor/rules/ios-push-guard.mdc.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .list, .sound, .badge])
  }
}
