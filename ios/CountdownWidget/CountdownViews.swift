import AppIntents
import SwiftUI
import WidgetKit

/// The widget: the trip's linen behind its postcard, the luggage tag with
/// the count, and Travi. Every word is live text over raster art, as in
/// the app. A tap opens the trip; a tap on the tag (iOS 17) brings Travi up.
struct CountdownWidgetView: View {
  let entry: CountdownEntry

  @Environment(\.widgetFamily) private var family
  @Environment(\.displayScale) private var scale

  var body: some View {
    GeometryReader { geometry in
      let stage = CountdownStage.of(size, bounds: geometry.size)
      CountdownStageView(entry: entry, stage: stage, scale: scale)
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(entry.face.label)
    .widgetURL(entry.face.link)
    .containerBackground(for: .widget) {
      LinenView(face: entry.face, scale: scale)
    }
  }

  private var size: CountdownStage.Size {
    switch family {
    case .systemSmall: return .small
    case .systemMedium: return .medium
    default: return .large
    }
  }
}

private struct CountdownStageView: View {
  let entry: CountdownEntry
  let stage: CountdownStage
  let scale: CGFloat

  private var face: CountdownFace { entry.face }

  var body: some View {
    ZStack(alignment: .topLeading) {
      if let origin = stage.heading {
        Text(face.heading)
          .font(CountdownFonts.font(face.sans, size: 0.027 * stage.bounds.height, fallback: .default, weight: .semibold))
          .tracking(0.0068 * stage.bounds.height)
          .foregroundStyle(face.ink)
          .lineLimit(1)
          .fixedSize()
          .offset(x: origin.x, y: origin.y)
      }
      if stage.traviBehind { travi }
      PostcardView(face: face, stage: stage, scale: scale)
      if !stage.traviBehind { travi }
      tag
    }
    .frame(width: stage.bounds.width, height: stage.bounds.height, alignment: .topLeading)
    .clipped()
  }

  /// Up for the morning or a tap: he rises from behind the postcard (or
  /// the widget's edge) and ducks back down, one move each way.
  @ViewBuilder private var travi: some View {
    if entry.traviUp, let still = face.travi {
      TraviView(still: still, side: stage.travi.width, scale: scale)
        .frame(width: stage.travi.width, height: stage.travi.height)
        .position(x: stage.travi.midX, y: stage.travi.midY)
        .id(entry.pops)
        // Down by his own height: behind the postcard, or past the edge.
        .transition(.offset(y: 1.05 * stage.travi.height))
    }
  }

  private var tag: some View {
    let image = stage.tagImage
    let degrees = stage.tagDegrees + (entry.kicked ? -7 : 0)
    return Button(intent: TraviTapIntent()) {
      TagView(face: face, stage: stage, scale: scale)
        .frame(width: image.width, height: image.height)
        .rotationEffect(.degrees(degrees), anchor: WidgetGeometry.eyelet)
        .animation(.spring(response: 0.55, dampingFraction: 0.32), value: entry.kicked)
    }
    .buttonStyle(.plain)
    .frame(width: image.width, height: image.height)
    .position(x: image.midX, y: image.midY)
  }
}

/// The whole postcard, deckled edge and all, never cropped; without a
/// landscape postcard the medium widget prints the portrait's picture
/// cropped to landscape on plain paper, as a trip's own screen does.
private struct PostcardView: View {
  let face: CountdownFace
  let stage: CountdownStage
  let scale: CGFloat

  var body: some View {
    let frame = stage.postcard
    Group {
      if stage.landscape, let image = face.landscape?.image(maxPixels: frame.width * scale) {
        Image(uiImage: image).resizable().interpolation(.high)
      } else if stage.landscape, let portrait = face.portrait {
        CroppedPrint(file: portrait, paper: face.paper, size: frame.size, scale: scale)
      } else if !stage.landscape, let image = face.portrait?.image(maxPixels: frame.height * scale) {
        Image(uiImage: image).resizable().interpolation(.high)
      } else {
        PaperStandIn(paper: face.paper)
      }
    }
    .frame(width: frame.width, height: frame.height)
    .position(x: frame.midX, y: frame.midY)
  }
}

/// The picture from a portrait postcard as a landscape print: its middle,
/// from the upper part of the scene, in a paper border.
private struct CroppedPrint: View {
  let file: ArtFile
  let paper: Color
  let size: CGSize
  let scale: CGFloat

  var body: some View {
    let card = WidgetGeometry.landscapeCard
    let inner = CGRect(
      x: size.width * card.left, y: size.height * card.top,
      width: size.width * (card.right - card.left), height: size.height * (card.bottom - card.top))
    let border = 0.03 * inner.width
    let picture = inner.insetBy(dx: border, dy: border)
    let width = picture.width / 0.80
    let height = width / WidgetGeometry.portraitAspect
    return ZStack(alignment: .topLeading) {
      RoundedRectangle(cornerRadius: 3)
        .fill(paper)
        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
        .frame(width: inner.width, height: inner.height)
        .offset(x: inner.minX, y: inner.minY)
      if let image = file.image(maxPixels: height * scale) {
        Image(uiImage: image)
          .resizable()
          .frame(width: width, height: height)
          .offset(x: -0.10 * width, y: -0.12 * height)
          .frame(width: picture.width, height: picture.height, alignment: .topLeading)
          .clipped()
          .offset(x: picture.minX, y: picture.minY)
      }
    }
    .frame(width: size.width, height: size.height, alignment: .topLeading)
  }
}

/// A plain card where a picture can't be read.
private struct PaperStandIn: View {
  let paper: Color

  var body: some View {
    RoundedRectangle(cornerRadius: 3)
      .fill(paper)
      .shadow(color: .black.opacity(0.15), radius: 5, y: 2)
      .padding(6)
  }
}

/// The luggage tag: its raster (or a paper card) with the count written
/// on it in the trip's ink.
private struct TagView: View {
  let face: CountdownFace
  let stage: CountdownStage
  let scale: CGFloat

  var body: some View {
    let image = stage.tagImage
    let card = stage.tagCard.offsetBy(dx: -image.minX, dy: -image.minY)
    let copy = stage.copy.offsetBy(dx: -image.minX, dy: -image.minY)
    ZStack(alignment: .topLeading) {
      if let raster = face.tag?.image(maxPixels: image.height * scale) {
        Image(uiImage: raster).resizable().frame(width: image.width, height: image.height)
      } else {
        RoundedRectangle(cornerRadius: 6)
          .fill(face.paper)
          .shadow(color: .black.opacity(0.18), radius: 5, y: 2)
          .frame(width: card.width, height: card.height)
          .offset(x: card.minX, y: card.minY)
      }
      TagCopy(face: face, size: stage.size, cardWidth: card.width)
        .frame(width: copy.width, height: copy.height)
        .offset(x: copy.minX, y: copy.minY)
    }
    .frame(width: image.width, height: image.height, alignment: .topLeading)
  }
}

/// The words on the tag, sized to the card ([cardWidth]) and fewer on the
/// smaller tags: the count always, then the place, then the dates. Like the
/// app's tag, they shrink together when they don't fit, never one alone.
private struct TagCopy: View {
  let face: CountdownFace
  let size: CountdownStage.Size
  let cardWidth: CGFloat

  var body: some View {
    ViewThatFits(in: .vertical) {
      ForEach([1.0, 0.92, 0.84, 0.76, 0.68, 0.6], id: \.self) { k in
        VStack(spacing: 0) {
          if let days = face.days { count(days, cardWidth * k) } else { idle(cardWidth * k) }
        }
      }
    }
    .foregroundStyle(face.ink)
    .multilineTextAlignment(.center)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  @ViewBuilder private func count(_ days: String, _ w: CGFloat) -> some View {
    switch size {
    case .large:
      eyebrow(face.eyebrow, 0.087 * w)
      gap(0.03 * w)
      number(days, 0.56 * w)
      gap(0.02 * w)
      eyebrow(face.daysLabel, 0.087 * w)
      rule(0.06 * w, w)
      place(0.175 * w, lines: 2)
      gap(0.03 * w)
      line(face.dates, 0.10 * w)
    case .medium:
      number(days, 0.56 * w)
      gap(0.02 * w)
      eyebrow(face.daysLabel, 0.10 * w)
      rule(0.055 * w, w)
      place(0.19 * w, lines: 2)
      gap(0.025 * w)
      line(face.shortDates, 0.115 * w)
    case .small:
      number(days, 0.63 * w)
      gap(0.02 * w)
      eyebrow(face.daysLabel, 0.13 * w)
      gap(0.07 * w)
      place(0.21 * w, lines: 2)
    }
  }

  /// Nothing coming up: the question (or the undated holiday) as a title.
  @ViewBuilder private func idle(_ w: CGFloat) -> some View {
    if size == .large {
      eyebrow(face.eyebrow, 0.087 * w)
      gap(0.08 * w)
    }
    place(size == .small ? 0.24 * w : 0.22 * w, lines: 3)
    gap(0.05 * w)
    line(size == .large ? face.dates : face.shortDates, size == .small ? 0.13 * w : 0.11 * w)
  }

  /// The count's line box hugs its figures, as on the app's tag.
  private func number(_ text: String, _ size: CGFloat) -> some View {
    Text(text)
      .font(CountdownFonts.font(face.serif, size: size, fallback: .serif, weight: .bold))
      .tracking(-0.025 * size)
      .lineLimit(1)
      .minimumScaleFactor(0.4)
      .contentTransition(.numericText(countsDown: true))
      .padding(.vertical, -0.14 * size)
  }

  private func eyebrow(_ text: String, _ size: CGFloat) -> some View {
    Text(text)
      .font(CountdownFonts.font(face.sans, size: size, fallback: .default, weight: .semibold))
      .tracking(0.22 * size)
      .lineLimit(1)
      .minimumScaleFactor(0.5)
  }

  /// The trip's name: on one line if it fits a little smaller, else on up
  /// to [lines] lines (the app's tag steps down the same way).
  private func place(_ size: CGFloat, lines: Int) -> some View {
    ViewThatFits(in: .horizontal) {
      ForEach([1.0, 0.9, 0.8], id: \.self) { k in placeText(size * k).lineLimit(1) }
      placeText(size).lineLimit(lines).minimumScaleFactor(0.55)
    }
  }

  private func placeText(_ size: CGFloat) -> Text {
    Text(face.place)
      .font(CountdownFonts.font(face.serif, size: size, fallback: .serif, weight: .bold))
      .tracking(-0.012 * size)
  }

  private func line(_ text: String, _ size: CGFloat) -> some View {
    Text(text)
      .font(CountdownFonts.font(face.sansMedium, size: size, fallback: .default, weight: .medium))
      .lineLimit(1)
      .minimumScaleFactor(0.55)
  }

  private func gap(_ height: CGFloat) -> some View { Color.clear.frame(height: height) }

  private func rule(_ space: CGFloat, _ w: CGFloat) -> some View {
    Rectangle()
      .fill(face.ink.opacity(0.35))
      .frame(width: 0.6 * w, height: max(0.5, 0.008 * w))
      .padding(.vertical, space)
  }
}

/// Travi's still on his square canvas, the square [side] points wide.
private struct TraviView: View {
  let still: CountdownFace.TraviStill
  let side: CGFloat
  let scale: CGFloat

  var body: some View {
    let k = side / still.canvas
    let box = still.box
    ZStack(alignment: .topLeading) {
      if let image = still.file.image(maxPixels: max(box.width, box.height) * k * scale) {
        Image(uiImage: image)
          .resizable()
          .frame(width: box.width * k, height: box.height * k)
          .offset(x: box.minX * k, y: box.minY * k)
      }
    }
    .frame(width: side, height: side, alignment: .topLeading)
  }
}

/// The trip's woven linen, tiled as behind the app's screens (its 1024-pixel
/// tile drawn at a third: 341 points).
private struct LinenView: View {
  let face: CountdownFace
  let scale: CGFloat

  var body: some View {
    ZStack {
      Color(red: 0xEF / 255, green: 0xE8 / 255, blue: 0xDC / 255)
      if let tile = face.linen?.image(maxPixels: 341 * scale), let cgImage = tile.cgImage {
        Image(uiImage: UIImage(cgImage: cgImage, scale: scale, orientation: .up))
          .resizable(resizingMode: .tile)
      }
    }
  }
}
