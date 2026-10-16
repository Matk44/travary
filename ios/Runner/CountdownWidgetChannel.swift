import Flutter
import WidgetKit

/// The countdown widget's side of the app (lib/data/countdown_widget_bridge.dart):
/// the folder in the App Group the widget extension reads, and asking
/// WidgetKit to draw it again. Dart writes the files.
enum CountdownWidgetChannel {
  static let appGroup = "group.com.travary.app"

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "travary/countdown_widget", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "folder":
        // Nil without the App Group (a build signed without it).
        let folder = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
          .appendingPathComponent("CountdownWidget", isDirectory: true)
        result(folder?.path)
      case "reload":
        WidgetCenter.shared.reloadTimelines(ofKind: "CountdownWidget")
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
