import CoreText
import Foundation
import ImageIO
import SwiftUI
import UIKit

/// What the app wrote for the widget (lib/logic/countdown_widget.dart):
/// every day ahead, already worded, with each trip's art. The widget only
/// picks the day for its own date and draws it; it never words anything.
struct CountdownData: Decodable {
  let version: Int
  let traviUntilHour: Int
  let days: [String: Day]
  let idle: Idle
  let trips: [String: Art]
  let travi: [String: TraviStill]
  let traviCanvas: Double
  let fonts: [String: String]

  struct Day: Decodable {
    let trip: String
    let heading: String
    let eyebrow: String
    let days: String
    let daysLabel: String
    let place: String
    let dates: String
    let shortDates: String
    let label: String
    let travi: String
  }

  struct Idle: Decodable {
    let trip: String?
    let heading: String
    let eyebrow: String
    let title: String
    let message: String
    let label: String
    let travi: String
    let art: Art
  }

  struct Art: Decodable {
    let portrait: String?
    let landscape: String?
    let tag: String?
    let linen: String?
    let ink: String
    let paper: String
  }

  struct TraviStill: Decodable {
    let file: String
    let box: [Double]
  }

  /// The file shapes this widget knows.
  static let version = 1
}

/// The widget's folder in the App Group container, shared with the app
/// (`CountdownWidgetChannel.swift` hands the app the same place).
enum CountdownFolder {
  static let appGroup = "group.com.travary.app"

  static var url: URL? {
    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)?
      .appendingPathComponent("CountdownWidget", isDirectory: true)
  }

  static func load() -> CountdownData? {
    guard let url = url?.appendingPathComponent("countdown.json"),
          let bytes = try? Data(contentsOf: url),
          let data = try? JSONDecoder().decode(CountdownData.self, from: bytes),
          data.version == CountdownData.version
    else { return nil }
    return data
  }
}

/// A file named in `countdown.json` (relative to the widget's folder), or
/// one of the small pictures and fonts inside this extension (`SampleArt/`,
/// made from the app's art and written no larger than the widget draws
/// them) for the preview before the app has written anything.
struct ArtFile: Hashable {
  let url: URL

  /// The longest side, in pixels, up to which a picture is read as it is.
  private static let readAsIs = 1100

  /// Pictures already read in this process, so the days of a timeline that
  /// draw the same picture share one copy instead of each reading it again.
  /// Room for about one trip's pictures (a large widget's are about 4 MB):
  /// holding every trip's made the widget's peak higher, not lower.
  private static let decoded: NSCache<NSString, UIImage> = {
    let cache = NSCache<NSString, UIImage>()
    cache.totalCostLimit = 6 * 1_048_576
    return cache
  }()

  init?(_ name: String?) {
    guard let name, let folder = CountdownFolder.url else { return nil }
    url = folder.appendingPathComponent(name)
  }

  /// A file in this extension's own bundle. One that's missing gives a URL
  /// nothing can be read from, so the widget draws its stand-in.
  init(sample name: String, _ type: String) {
    url =
      Bundle.main.url(forResource: name, withExtension: type)
      ?? Bundle.main.bundleURL.appendingPathComponent("\(name).\(type)")
  }

  /// Decoded no larger than [pixels] on its longer side. Widgets are stopped
  /// when they use too much memory (about 30 MB) and a picture costs three
  /// to four times its decoded size to read, so the app writes each one no
  /// larger than the largest widget draws it (`CountdownWidgetArtSize`).
  func image(maxPixels: CGFloat) -> UIImage? {
    let pixels = max(1, Int(maxPixels.rounded(.up)))
    let whole = url.path as NSString
    let reduced = "\(url.path)#\(pixels)" as NSString
    if let kept = Self.decoded.object(forKey: whole) ?? Self.decoded.object(forKey: reduced) { return kept }
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    // The app writes each picture no larger than the widget draws it
    // (900 pixels at most): read as it is, not decoded into a second,
    // reduced copy first, which costs three times its size while it's made
    // (a small widget asks for less than that, and gets it scaled down when
    // it's drawn). Only a larger picture (an older app's, before it writes
    // again) is reduced as it's read.
    if let size = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      let width = size[kCGImagePropertyPixelWidth] as? Int, let height = size[kCGImagePropertyPixelHeight] as? Int,
      max(width, height) <= max(pixels, Self.readAsIs), let picture = UIImage(contentsOfFile: url.path)
    {
      Self.decoded.setObject(picture, forKey: whole, cost: width * height * 4)
      return picture
    }
    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceShouldCacheImmediately: true,
      kCGImageSourceThumbnailMaxPixelSize: pixels,
    ]
    guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
    let picture = UIImage(cgImage: image)
    Self.decoded.setObject(picture, forKey: reduced, cost: image.width * image.height * 4)
    return picture
  }
}

/// The tag's fonts: the app's own files, registered for this process the
/// first time they're asked for. Until the app has copied them (or if a
/// file can't be read) the system's serif and sans stand in.
enum CountdownFonts {
  private static var names: [URL: String] = [:]

  static func font(_ file: ArtFile?, size: CGFloat, fallback: Font.Design, weight: Font.Weight) -> Font {
    if let file, let name = postScriptName(file.url) {
      return .custom(name, fixedSize: size)
    }
    return .system(size: size, weight: weight, design: fallback)
  }

  private static func postScriptName(_ url: URL) -> String? {
    if let name = names[url] { return name }
    guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
          let descriptor = descriptors.first,
          let name = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String
    else { return nil }
    var error: Unmanaged<CFError>?
    // Already registered (an earlier render in this process) is fine too.
    _ = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
    names[url] = name
    return name
  }
}

/// Taps on the tag (iOS 17): when the last one was, and how many, so the
/// timeline brings Travi up for a moment and each tap pops him up anew.
enum CountdownTaps {
  struct Tap: Codable {
    let at: Date
    let count: Int
  }

  private static var url: URL? { CountdownFolder.url?.appendingPathComponent("tap.json") }

  static func last() -> Tap? {
    guard let url, let bytes = try? Data(contentsOf: url) else { return nil }
    return try? JSONDecoder().decode(Tap.self, from: bytes)
  }

  static func record(at date: Date = Date()) {
    guard let url else { return }
    let tap = Tap(at: date, count: (last()?.count ?? 0) + 1)
    try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try? JSONEncoder().encode(tap).write(to: url, options: .atomic)
  }
}

extension Color {
  /// `#RRGGBB`, else Travary's navy ink.
  init(hex: String?) {
    var value: UInt64 = 0x1C2A47
    if let hex, hex.hasPrefix("#"), let parsed = UInt64(hex.dropFirst(), radix: 16) { value = parsed }
    self.init(
      red: Double((value >> 16) & 0xFF) / 255,
      green: Double((value >> 8) & 0xFF) / 255,
      blue: Double(value & 0xFF) / 255
    )
  }
}
