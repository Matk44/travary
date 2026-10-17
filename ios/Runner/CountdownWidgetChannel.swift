import Flutter
import WidgetKit

/// The countdown widget's side of the app (lib/data/countdown_widget_bridge.dart):
/// the folder in the App Group the widget extension reads, asking WidgetKit
/// to draw it again, and whether it's on the home screen. Dart writes the files.
enum CountdownWidgetChannel {
  static let appGroup = "group.com.travary.app"
  static let kind = "CountdownWidget"

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
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
        result(nil)
      case "status":
        status(result)
      case "pin":
        // iOS has no way to add a widget for the traveller: the app shows how.
        result(false)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// The widget's extension is iOS 17 and later; before that there is none.
  /// Whether one is on a home screen (or Lock Screen, StandBy) comes from WidgetKit.
  private static func status(_ result: @escaping FlutterResult) {
    guard #available(iOS 17.0, *) else {
      result(["supported": false, "added": false, "canPin": false])
      return
    }
    WidgetCenter.shared.getCurrentConfigurations { outcome in
      var added = false
      if case .success(let widgets) = outcome {
        added = widgets.contains { $0.kind == CountdownWidgetChannel.kind }
      }
      DispatchQueue.main.async {
        result(["supported": true, "added": added, "canPin": false])
      }
    }
  }
}
