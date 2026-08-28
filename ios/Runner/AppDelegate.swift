import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// Bewaar launchOptions voor FLTFirebaseMessagingPlugin na deferred plugin-registratie.
  private var storedLaunchOptions: [UIApplication.LaunchOptionsKey: Any]?

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
    replayDidFinishLaunchingForFirebaseMessaging()
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
