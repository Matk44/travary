import AppIntents
import SwiftUI
import WidgetKit

/// Travary's home-screen countdown: Today's postcard with the luggage tag
/// hung on it, counting down to the next trip, then the days left on it.
/// The app writes every day ahead (lib/logic/countdown_widget.dart); this
/// only picks the day for the phone's date and draws it.
@main
struct TravaryWidgets: WidgetBundle {
  var body: some Widget {
    CountdownWidget()
  }
}

struct CountdownWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "CountdownWidget", provider: CountdownProvider()) { entry in
      CountdownWidgetView(entry: entry)
    }
    .configurationDisplayName("Trip countdown")
    .description("Your next trip's postcard, counting down the days.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    .contentMarginsDisabled()
  }
}

/// One moment of the widget: the day it shows, and whether Travi is up.
struct CountdownEntry: TimelineEntry {
  let date: Date
  let face: CountdownFace

  /// He's up each morning (until `traviUntilHour`), and for a moment after
  /// a tap on the tag.
  let traviUp: Bool

  /// Taps so far: each one pops him up anew.
  let pops: Int

  /// The moment right after a tap: the tag swings.
  let kicked: Bool
}

struct CountdownProvider: TimelineProvider {
  /// How long Travi stays up after a tap before he ducks.
  static let tapHold: TimeInterval = 4

  /// Days of entries in one timeline; the app reloads it whenever it
  /// writes, and the timeline asks again once these run out.
  static let daysAhead = 7

  func placeholder(in context: Context) -> CountdownEntry {
    CountdownEntry(date: Date(), face: .sample, traviUp: false, pops: 0, kicked: false)
  }

  func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
    let now = Date()
    let data = CountdownFolder.load()
    let face = data.map { CountdownFace.on(now, data: $0) } ?? .sample
    // The gallery shows him up, so people know he's there.
    completion(CountdownEntry(date: now, face: face, traviUp: true, pops: 0, kicked: false))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
    let entries = Self.entries(data: CountdownFolder.load(), now: Date(), tap: CountdownTaps.last())
    completion(Timeline(entries: entries, policy: .atEnd))
  }

  /// From [now]: up for the morning or a tap, down after; each midnight
  /// the next day's face (the count rolls over), Travi up again.
  static func entries(
    data: CountdownData?,
    now: Date,
    tap: CountdownTaps.Tap?,
    calendar: Calendar = .current
  ) -> [CountdownEntry] {
    let until = data?.traviUntilHour ?? 12
    let pops = tap?.count ?? 0
    func face(_ date: Date) -> CountdownFace {
      data.map { CountdownFace.on(date, data: $0, calendar: calendar) } ?? .sample
    }
    func morning(_ date: Date) -> Bool { calendar.component(.hour, from: date) < until }
    func entry(_ date: Date, up: Bool, kicked: Bool = false) -> CountdownEntry {
      CountdownEntry(date: date, face: face(date), traviUp: up, pops: pops, kicked: kicked)
    }

    var entries: [CountdownEntry] = []
    let tapEnds = tap.map { $0.at.addingTimeInterval(tapHold) }
    let tapped = tapEnds.map { now < $0 } ?? false
    entries.append(entry(now, up: morning(now) || tapped, kicked: tapped))
    if tapped, let ends = tapEnds { entries.append(entry(ends, up: morning(ends))) }
    let settled = max(now, tapEnds ?? now)

    let today = calendar.startOfDay(for: now)
    for offset in 0...daysAhead {
      guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
      if day > settled { entries.append(entry(day, up: until > 0)) }
      if let noon = calendar.date(bySettingHour: until, minute: 0, second: 0, of: day), noon > settled {
        entries.append(entry(noon, up: false))
      }
    }
    return entries.sorted { $0.date < $1.date }
  }
}

/// A tap on the luggage tag (iOS 17): Travi pops up with how he feels
/// about the days left, as when the tag is tapped on Today. Nothing opens.
struct TraviTapIntent: AppIntent {
  static var title: LocalizedStringResource = "Say hello to Travi"
  static var isDiscoverable = false

  func perform() async throws -> some IntentResult {
    CountdownTaps.record()
    return .result()
  }
}
