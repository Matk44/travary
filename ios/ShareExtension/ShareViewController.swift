import UIKit
import UniformTypeIdentifiers

/// Travary in the share sheet: a booking's screenshot, photo or PDF goes
/// straight into the app, which reads it like "Snap a booking". Nothing is
/// shown here: the file is copied into the app group's folder, listed where
/// receive_sharing_intent (1.8.1) looks for it, and the app is opened.
class ShareViewController: UIViewController {
  /// receive_sharing_intent's names: its user defaults key and link scheme.
  private let sharedKey = "ShareKey"
  private let schemePrefix = "ShareMedia"

  private var appGroupId: String {
    Bundle.main.object(forInfoDictionaryKey: "AppGroupId") as? String ?? "group.\(hostBundleId)"
  }

  /// "com.travary.app.ShareExtension" → "com.travary.app".
  private var hostBundleId: String {
    let id = Bundle.main.bundleIdentifier ?? ""
    guard let dot = id.lastIndex(of: ".") else { return id }
    return String(id[..<dot])
  }

  private var started = false

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard !started else { return }
    started = true
    guard let provider = firstAttachment(), let folder = sharedFolder() else { return finish() }
    save(provider, into: folder) { [weak self] file in
      DispatchQueue.main.async {
        guard let self else { return }
        if let file {
          self.list(file)
          self.openTravary()
        }
        self.finish()
      }
    }
  }

  /// The first PDF or image shared (the activation rule allows just one).
  private func firstAttachment() -> NSItemProvider? {
    let items = extensionContext?.inputItems as? [NSExtensionItem] ?? []
    return items.flatMap { $0.attachments ?? [] }.first {
      $0.hasItemConformingToTypeIdentifier(UTType.pdf.identifier)
        || $0.hasItemConformingToTypeIdentifier(UTType.image.identifier)
    }
  }

  private func sharedFolder() -> URL? {
    guard let group = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId) else {
      return nil
    }
    let folder = group.appendingPathComponent("Shared", isDirectory: true)
    try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
    return folder
  }

  /// Copies the shared file into [folder]; nil if it couldn't be read.
  private func save(_ provider: NSItemProvider, into folder: URL, done: @escaping (URL?) -> Void) {
    let type = provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) ? UTType.pdf : UTType.image
    provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { url, _ in
      // The file is only there until this returns: copy it now.
      if let url, let copy = self.copy(url, into: folder) { return done(copy) }
      // A screenshot straight from the screenshot editor comes as an image.
      provider.loadItem(forTypeIdentifier: type.identifier) { item, _ in
        switch item {
        case let image as UIImage:
          done(self.write(image.pngData(), named: "Screenshot.png", into: folder))
        case let data as Data:
          done(self.write(data, named: type == .pdf ? "Booking.pdf" : "Screenshot.png", into: folder))
        case let url as URL:
          done(self.copy(url, into: folder))
        default:
          done(nil)
        }
      }
    }
  }

  private func copy(_ url: URL, into folder: URL) -> URL? {
    let target = unique(url.lastPathComponent, in: folder)
    do {
      try FileManager.default.copyItem(at: url, to: target)
      return target
    } catch {
      return nil
    }
  }

  private func write(_ data: Data?, named name: String, into folder: URL) -> URL? {
    guard let data else { return nil }
    let target = unique(name, in: folder)
    return (try? data.write(to: target)) == nil ? nil : target
  }

  /// A folder of its own each time, so a second share never overwrites the
  /// first and the file keeps the name the traveller knows.
  private func unique(_ name: String, in folder: URL) -> URL {
    let own = folder.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try? FileManager.default.createDirectory(at: own, withIntermediateDirectories: true)
    return own.appendingPathComponent(name)
  }

  /// Where the app picks it up: receive_sharing_intent's list of files.
  private func list(_ file: URL) {
    let type = file.pathExtension.lowercased() == "pdf" ? "file" : "image"
    let entry: [String: Any] = ["path": file.absoluteString.removingPercentEncoding ?? file.absoluteString, "type": type]
    guard let json = try? JSONSerialization.data(withJSONObject: [entry]) else { return }
    let defaults = UserDefaults(suiteName: appGroupId)
    defaults?.set(json, forKey: sharedKey)
    defaults?.removeObject(forKey: "ShareMessageKey")
    defaults?.synchronize()
  }

  /// Opens Travary on the file. Share extensions can't open apps directly;
  /// the application object up the responder chain can, called through the
  /// runtime because extension-only builds hide its `open`.
  private func openTravary() {
    guard let url = URL(string: "\(schemePrefix)-\(hostBundleId):share") else { return }
    typealias OpenURL = @convention(c) (AnyObject, Selector, NSURL, NSDictionary, AnyObject?) -> Void
    let selector = NSSelectorFromString("openURL:options:completionHandler:")
    var responder: UIResponder? = self
    while let next = responder {
      if let application = next as? UIApplication, application.responds(to: selector) {
        let open = unsafeBitCast(application.method(for: selector), to: OpenURL.self)
        open(application, selector, url as NSURL, NSDictionary(), nil)
        return
      }
      responder = next.next
    }
  }

  private func finish() {
    extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
  }
}
