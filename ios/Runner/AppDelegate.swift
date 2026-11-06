import Flutter
import UIKit
import UserNotifications
import FirebaseCore
import FirebaseMessaging

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
