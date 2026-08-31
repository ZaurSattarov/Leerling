import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Bewaar launchOptions voor FLTFirebaseMessagingPlugin na deferred plugin-registratie.
  private var storedLaunchOptions: [UIApplication.LaunchOptionsKey: Any]?

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
    replayDidFinishLaunchingForFirebaseMessaging()
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
    // swizzling kan later klaar zijn dan didRegister.
    if FirebaseApp.app() != nil {
      Messaging.messaging().apnsToken = deviceToken
    }
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NSLog("[AppDelegate] APNS_REGISTER_FAILED: %@", error.localizedDescription)
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
