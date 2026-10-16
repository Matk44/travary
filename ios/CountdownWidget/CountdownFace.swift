import SwiftUI

/// Everything one day's widget draws: the words the app wrote for that
/// date, and the trip's art, ink and fonts.
struct CountdownFace {
  /// The trip shown, opened by a tap; nil opens Today.
  let tripId: String?
  let heading: String
  let eyebrow: String

  /// The large number; nil when nothing is coming up (the tag then says
  /// [place] and [dates] as a title and a line under it).
  let days: String?
  let daysLabel: String
  let place: String
  let dates: String
  let shortDates: String
  let label: String

  let portrait: ArtFile?
  let landscape: ArtFile?
  let tag: ArtFile?
  let linen: ArtFile?
  let ink: Color
  let paper: Color

  let travi: TraviStill?
  let serif: ArtFile?
  let sans: ArtFile?
  let sansMedium: ArtFile?

  /// A cameo still and where it stands on its square canvas.
  struct TraviStill {
    let file: ArtFile
    let box: CGRect
    let canvas: CGFloat
  }

  var link: URL {
    guard let tripId, let encoded = tripId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
      return URL(string: "travary://today")!
    }
    return URL(string: "travary://trip/\(encoded)") ?? URL(string: "travary://today")!
  }

  /// The face for [date] on the phone's calendar: its day if the app wrote
  /// one, else the idle face.
  static func on(_ date: Date, data: CountdownData, calendar: Calendar = .current) -> CountdownFace {
    let parts = calendar.dateComponents([.year, .month, .day], from: date)
    let key = String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    let fonts = (
      serif: ArtFile(data.fonts["serif"]), sans: ArtFile(data.fonts["sans"]),
      sansMedium: ArtFile(data.fonts["sansMedium"])
    )
    func still(_ mood: String) -> TraviStill? {
      guard let still = data.travi[mood], let file = ArtFile(still.file), still.box.count == 4 else { return nil }
      let box = CGRect(x: still.box[0], y: still.box[1], width: still.box[2], height: still.box[3])
      return TraviStill(file: file, box: box, canvas: data.traviCanvas)
    }

    if let day = data.days[key] {
      let art = data.trips[day.trip] ?? data.idle.art
      return CountdownFace(
        tripId: day.trip, heading: day.heading, eyebrow: day.eyebrow, days: day.days, daysLabel: day.daysLabel,
        place: day.place, dates: day.dates, shortDates: day.shortDates, label: day.label,
        portrait: ArtFile(art.portrait), landscape: ArtFile(art.landscape), tag: ArtFile(art.tag),
        linen: ArtFile(art.linen), ink: Color(hex: art.ink), paper: Color(hex: art.paper),
        travi: still(day.travi), serif: fonts.serif, sans: fonts.sans, sansMedium: fonts.sansMedium
      )
    }
    let idle = data.idle
    return CountdownFace(
      tripId: idle.trip, heading: idle.heading, eyebrow: idle.eyebrow, days: nil, daysLabel: "",
      place: idle.title, dates: idle.message, shortDates: idle.message, label: idle.label,
      portrait: ArtFile(idle.art.portrait), landscape: ArtFile(idle.art.landscape), tag: ArtFile(idle.art.tag),
      linen: ArtFile(idle.art.linen), ink: Color(hex: idle.art.ink), paper: Color(hex: idle.art.paper),
      travi: still(idle.travi), serif: fonts.serif, sans: fonts.sans, sansMedium: fonts.sansMedium
    )
  }

  /// Before the app has written anything (the widget gallery on a fresh
  /// install): a sample countdown on the app's bundled art.
  static let sample = CountdownFace(
    tripId: nil, heading: "NEXT ADVENTURE", eyebrow: "NEXT TRIP", days: "58", daysLabel: "DAYS TO GO",
    place: "Your next trip", dates: "Open Travary to start", shortDates: "Open Travary", label: "Trip countdown",
    portrait: ArtFile(asset: "assets/art/common/countdown_postcard_anywhere.webp"),
    landscape: ArtFile(asset: "assets/art/common/trip_postcard_anywhere.webp"),
    tag: ArtFile(asset: "assets/art/common/countdown_luggage_tag.webp"),
    linen: ArtFile(asset: "assets/art/common/linen.webp"),
    ink: Color(hex: "#1C2A47"), paper: Color(hex: "#F8F4EC"),
    travi: TraviStill(
      file: ArtFile(asset: "assets/travi/cameos/stills/peek-cheer.webp"),
      box: CGRect(x: 12, y: 88, width: 464, height: 392), canvas: 480
    ),
    serif: ArtFile(asset: "assets/widget/fonts/widget_serif_bold.ttf"),
    sans: ArtFile(asset: "assets/widget/fonts/widget_sans_semibold.ttf"),
    sansMedium: ArtFile(asset: "assets/widget/fonts/widget_sans_medium.ttf")
  )
}
