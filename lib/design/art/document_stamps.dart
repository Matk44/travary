import 'art_catalog.dart';
import 'card_shells.dart' show FractionRect;

/// Where a Documents stamp frame's parts are, as fractions of its image
/// ([StampDesign.width] × [StampDesign.height]), measured from the supplied
/// files (docs/documents_stamps_prompts.md). A pack's frame is made to the
/// same template.
class StampGeometry {
  const StampGeometry({required this.body, required this.window});

  /// The stamp itself, perforation tips included. Rows size the stamp by
  /// this; its soft shadow spills outside.
  final FractionRect body;

  /// The transparent window the booking's scene shows through (its
  /// anti-aliased edge included).
  final FractionRect window;

  /// Where the scene is drawn: the window and a few pixels more, tucked
  /// under the frame's lip so no gap can show at its edge.
  FractionRect get scene => FractionRect(
    window.left - _tuck / StampDesign.width,
    window.top - _tuck / StampDesign.height,
    window.right + _tuck / StampDesign.width,
    window.bottom + _tuck / StampDesign.height,
  );

  static const _tuck = 3;
}

/// The three stamp frames of the Documents list (`common/<key>.png`). A
/// booking always gets the same one: [forVariant].
enum StampDesign {
  /// Warm ivory with one navy keyline.
  classic(
    'documents_stamp_01',
    StampGeometry(
      body: FractionRect(0.0400, 0.0547, 0.9590, 0.9453),
      window: FractionRect(0.1387, 0.1741, 0.8604, 0.8270),
    ),
  ),

  /// Navy and coral double keyline, cut from the same die as [classic].
  airmail(
    'documents_stamp_02',
    StampGeometry(
      body: FractionRect(0.0400, 0.0547, 0.9590, 0.9453),
      window: FractionRect(0.1387, 0.1741, 0.8604, 0.8270),
    ),
  ),

  /// Mustard-toned paper, softer perforations, a sage keyline.
  vintage(
    'documents_stamp_03',
    StampGeometry(
      body: FractionRect(0.0400, 0.0536, 0.9600, 0.9453),
      window: FractionRect(0.1357, 0.1708, 0.8643, 0.8359),
    ),
  );

  const StampDesign(this.key, this.geometry);

  final String key;
  final StampGeometry geometry;

  /// Every frame's pixel size.
  static const width = 1024;
  static const height = 896;

  /// The design for a booking with this `ArtChoice.variant`.
  static StampDesign forVariant(int variant) => values[variant % values.length];
}

/// A resolved stamp frame.
class StampArt {
  const StampArt({required this.design, required this.image});

  final StampDesign design;
  final ArtImageRef image;

  StampGeometry get geometry => design.geometry;
}

/// A Documents row's pictures for one trip: the stamp frames that exist,
/// the date postmark and its cancellation lines (`SurfaceSlot`s). Any may be
/// missing; the row then draws its plain stand-in for that part.
class DocumentArt {
  const DocumentArt({this.stamps = const {}, this.postmark, this.cancelLines});

  static const none = DocumentArt();

  final Map<StampDesign, ArtImageRef> stamps;
  final ArtImageRef? postmark;
  final ArtImageRef? cancelLines;

  /// The frame for a booking with this `ArtChoice.variant`: its own design,
  /// or, if that file is missing, the first design there is, so the choice
  /// never changes from one build to the next.
  StampArt? stampFor(int variant) {
    final design = StampDesign.forVariant(variant);
    final own = stamps[design];
    if (own != null) return StampArt(design: design, image: own);
    for (final other in StampDesign.values) {
      if (stamps[other] case final image?) return StampArt(design: other, image: image);
    }
    return null;
  }
}

/// Where the parts of a destination's stamp beside the Documents heading
/// are (`documentsDestinationStampArt`, 1024 × 1280), as fractions of the
/// image, measured from the five supplied packs' stamps.
abstract final class DestinationStampGeometry {
  static const width = 1024;
  static const height = 1280;

  /// The stamp, perforation tips included (the widest of the five packs').
  static const body = FractionRect(0.039, 0.026, 0.961, 0.974);

  /// Where the place name goes: the part of the blank ivory label band
  /// under the picture that every pack's stamp leaves clear.
  static const label = FractionRect(0.150, 0.826, 0.850, 0.894);
}
