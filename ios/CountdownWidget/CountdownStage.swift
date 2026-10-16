import SwiftUI

/// Where everything sits on each size of widget. The same numbers draw
/// the Android widget (CountdownWidgetStage.kt) and are explained in
/// docs/COUNTDOWN_WIDGET.md; the rasters' own measurements are Today's
/// (`CountdownGeometry`, `UpcomingTripPostcard`).
enum WidgetGeometry {
  /// `common/countdown_postcard` is 1122 × 1402; the card sits inside a
  /// transparent margin with its shadow.
  static let portraitAspect: CGFloat = 1122.0 / 1402.0
  static let portraitCard = Insets(left: 0.034, top: 0.05, right: 0.966, bottom: 0.96)

  /// `common/trip_postcard` is 1536 × 1024.
  static let landscapeAspect: CGFloat = 1.5
  static let landscapeCard = Insets(left: 0.02, top: 0.045, right: 0.98, bottom: 0.97)

  /// `common/countdown_luggage_tag` is 1024 × 1536; its card (without the
  /// cord) is `SurfaceSlot.countdownTag.body`, and it hangs from its eyelet.
  static let tagAspect: CGFloat = 1024.0 / 1536.0
  static let tagBody = Insets(left: 0.170, top: 0.261, right: 0.788, bottom: 0.982)
  static let eyelet = UnitPoint(x: 0.593, y: 0.342)

  /// The words inside the tag's card: clear of the eyelet at the top.
  static let copySide: CGFloat = 0.11
  static let copyTop: CGFloat = 0.20
  static let copyBottom: CGFloat = 0.06

  /// A card's height for its width.
  static var tagCardRatio: CGFloat {
    (tagBody.bottom - tagBody.top) / tagAspect / (tagBody.right - tagBody.left)
  }

  struct Insets {
    let left: CGFloat
    let top: CGFloat
    let right: CGFloat
    let bottom: CGFloat
  }
}

/// One widget's layout, in points from its top left.
struct CountdownStage {
  enum Size { case small, medium, large }

  let size: Size
  let bounds: CGSize

  /// The postcard image (its transparent margin included).
  let postcard: CGRect
  let landscape: Bool

  /// The tag's card, at rest before it's turned; [tagImage] is the whole
  /// raster round it, cord and shadow.
  let tagCard: CGRect
  let tagDegrees: Double

  /// Travi's square when he's up. Behind the postcard (large: he pops up
  /// over its top edge, as on Today), else in front of it, rising from the
  /// widget's bottom edge.
  let travi: CGRect
  let traviBehind: Bool

  /// The heading's top left (the large widget only).
  let heading: CGPoint?

  var tagImage: CGRect {
    let body = WidgetGeometry.tagBody
    let width = tagCard.width / (body.right - body.left)
    let height = width / WidgetGeometry.tagAspect
    return CGRect(x: tagCard.minX - body.left * width, y: tagCard.minY - body.top * height, width: width, height: height)
  }

  /// Where the words go inside the tag's card.
  var copy: CGRect {
    CGRect(
      x: tagCard.minX + tagCard.width * WidgetGeometry.copySide,
      y: tagCard.minY + tagCard.height * WidgetGeometry.copyTop,
      width: tagCard.width * (1 - 2 * WidgetGeometry.copySide),
      height: tagCard.height * (1 - WidgetGeometry.copyTop - WidgetGeometry.copyBottom)
    )
  }

  static func of(_ size: Size, bounds: CGSize) -> CountdownStage {
    switch size {
    case .large: return large(bounds)
    case .medium: return medium(bounds)
    case .small: return small(bounds)
    }
  }

  /// Today's countdown: the heading over the portrait postcard, the tag on
  /// its lower right reaching past its edge, Travi behind its top right.
  private static func large(_ b: CGSize) -> CountdownStage {
    let card = WidgetGeometry.portraitCard
    let overhang: CGFloat = 0.16
    var top = 0.155 * b.height
    let bottom = 0.972 * b.height
    var imageHeight = (bottom - top) / (card.bottom - card.top)
    var imageWidth = imageHeight * WidgetGeometry.portraitAspect
    // A narrow widget: as wide as it allows, lower down.
    let widest = 0.94 * b.width / (card.right - card.left + overhang)
    if imageWidth > widest {
      imageWidth = widest
      imageHeight = imageWidth / WidgetGeometry.portraitAspect
      top = bottom - imageHeight * (card.bottom - card.top)
    }
    let cardWidth = imageWidth * (card.right - card.left)
    let cardLeft = (b.width - cardWidth - overhang * imageWidth) / 2
    let postcard = CGRect(
      x: cardLeft - card.left * imageWidth, y: top - card.top * imageHeight, width: imageWidth, height: imageHeight)
    let tagWidth = 0.40 * imageWidth
    let tagHeight = tagWidth * WidgetGeometry.tagCardRatio
    let tagRight = cardLeft + cardWidth + overhang * imageWidth
    let tagBottom = 0.966 * b.height
    let traviSize = 0.28 * imageWidth
    return CountdownStage(
      size: .large, bounds: b, postcard: postcard, landscape: false,
      tagCard: CGRect(x: tagRight - tagWidth, y: tagBottom - tagHeight, width: tagWidth, height: tagHeight),
      tagDegrees: 6,
      travi: CGRect(
        x: postcard.minX + 0.88 * imageWidth - traviSize, y: top + 0.22 * traviSize - traviSize,
        width: traviSize, height: traviSize),
      traviBehind: true,
      heading: CGPoint(x: cardLeft + 2, y: 0.045 * b.height)
    )
  }

  /// The Trips tab's postcard: landscape, the tag hung on its right edge,
  /// and Travi popping up beside it from the bottom edge.
  private static func medium(_ b: CGSize) -> CountdownStage {
    let card = WidgetGeometry.landscapeCard
    let overhang: CGFloat = 0.13
    let traviSize = 0.52 * b.height
    let cardLeft = 0.03 * b.width
    var imageHeight = 0.9 * b.height / (card.bottom - card.top)
    var imageWidth = imageHeight * WidgetGeometry.landscapeAspect
    // A taller widget (Android's 4 × 2 is about 1.6 wide): Travi tucks
    // partly behind the tag so the postcard needn't shrink as much.
    let widest = (b.width - cardLeft - 0.7 * traviSize) / (card.right - card.left + overhang)
    if imageWidth > widest {
      imageWidth = widest
      imageHeight = imageWidth / WidgetGeometry.landscapeAspect
    }
    let cardTop = (b.height - imageHeight * (card.bottom - card.top)) / 2
    let postcard = CGRect(
      x: cardLeft - card.left * imageWidth, y: cardTop - card.top * imageHeight, width: imageWidth,
      height: imageHeight)
    let cardRight = cardLeft + imageWidth * (card.right - card.left)
    let tagWidth = 0.34 * imageWidth
    let tagHeight = tagWidth * WidgetGeometry.tagCardRatio
    let tagBottom = 0.95 * b.height
    return CountdownStage(
      size: .medium, bounds: b, postcard: postcard, landscape: true,
      tagCard: CGRect(
        x: cardRight + overhang * imageWidth - tagWidth, y: tagBottom - tagHeight, width: tagWidth, height: tagHeight),
      tagDegrees: 4,
      travi: CGRect(
        x: b.width - 0.97 * traviSize, y: b.height - 0.98 * traviSize, width: traviSize, height: traviSize),
      traviBehind: false,
      heading: nil
    )
  }

  /// The portrait postcard filling the height, the tag over its right side.
  private static func small(_ b: CGSize) -> CountdownStage {
    let card = WidgetGeometry.portraitCard
    let imageHeight = 0.9 * b.height / (card.bottom - card.top)
    let imageWidth = imageHeight * WidgetGeometry.portraitAspect
    let cardLeft = 0.05 * b.width
    let postcard = CGRect(
      x: cardLeft - card.left * imageWidth, y: 0.05 * b.height - card.top * imageHeight, width: imageWidth,
      height: imageHeight)
    let tagWidth = 0.48 * imageWidth
    let tagHeight = tagWidth * WidgetGeometry.tagCardRatio
    let traviSize = 0.45 * b.height
    return CountdownStage(
      size: .small, bounds: b, postcard: postcard, landscape: false,
      tagCard: CGRect(
        x: 0.95 * b.width - tagWidth, y: 0.95 * b.height - tagHeight, width: tagWidth, height: tagHeight),
      tagDegrees: 5,
      travi: CGRect(x: -0.02 * b.width, y: b.height - 0.92 * traviSize, width: traviSize, height: traviSize),
      traviBehind: false,
      heading: nil
    )
  }
}
