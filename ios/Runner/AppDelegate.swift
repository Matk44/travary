import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Reminders (flutter_local_notifications) and flight alerts
    // (firebase_messaging) both reach Flutter through this delegate.
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = registrar(forPlugin: "CountdownWidgetChannel") {
      CountdownWidgetChannel.register(with: registrar)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // A reminder (made on this phone) shows as a banner even while Travary is
  // open. Flight alerts come from Firebase, which decides for its own.
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if notification.request.trigger is UNPushNotificationTrigger {
      super.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
    } else {
      completionHandler([.banner, .list, .sound])
    }
  }
}
