import '../../domain/domain.dart';
import '../../logic/art_pack_selection.dart';
import 'art_catalog.dart';

/// A rectangle as fractions of an image, measured from its top-left corner.
class FractionRect {
  const FractionRect(this.left, this.top, this.right, this.bottom);

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;

  @override
  bool operator ==(Object other) =>
      other is FractionRect && other.left == left && other.top == top && other.right == right && other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() => 'FractionRect($left, $top, $right, $bottom)';
}

/// The complete raster objects a booking card is drawn on. Each role has a
/// shared-art name (`common/<key>.webp` in a pack, or bundled with a look
/// prefix: `coastal_resort_featured_ticket.webp`) and a fixed pixel size
/// every shell of that role is made at.
enum ShellRole {
  /// The featured "next up" admission ticket with its tear-off stub.
  featuredTicket('featured_ticket', 1774, 887),

  /// The hotel key card.
  roomCard('room_card', 1774, 887),

  /// A tagged reservation card whose illustration is part of the shell.
  reservationCard('reservation_card', 1983, 793),

  /// The neutral tagged reservation card: blank, so the booking's own
  /// vignette sits in its right-hand panel.
  reservationBlank('reservation_card_blank', 1983, 793),

  /// A flight that's next up: a boarding pass with an open picture window
  /// for the booking's scene.
  boardingPass('boarding_pass', 1774, 887),

  /// A restaurant booking that's next up: menu-card stock with a picture
  /// window and a table stub.
  featuredReservation('featured_reservation', 1774, 887),

  /// A train, coach, ferry, transfer or car pick-up that's next up: a
  /// travel ticket with a picture window.
  travelTicket('travel_ticket', 1774, 887),

  /// A note, next up or not: ruled paper with a paperclip.
  notePaper('note_paper', 1983, 793),

  /// Something you're in the middle of that isn't a hotel (a hire car, a
  /// multi-day pass): a key tag.
  ongoingTag('ongoing_tag', 1983, 466);

  const ShellRole(this.key, this.width, this.height);

  final String key;
  final int width;
  final int height;

  double get aspectRatio => width / height;
}

/// Which ink reads on a part of a shell.
enum ShellInk {
  /// Navy ink, on light paper, kraft or a coral tag.
  dark,

  /// Paper-coloured ink, on a dark printed panel or dyed tag.
  light,
}

/// Where live text, buttons and icons go on a shell, as fractions of the
/// whole image (shadow and transparent margin included), measured from the
/// supplied PNGs. Nothing here is drawn: these are anchors for real text.
class ShellGeometry {
  const ShellGeometry({
    required this.body,
    required this.text,
    this.action,
    this.actionAngle = 0,
    this.actionFramed = false,
    this.stubLabel,
    this.footnote,
    this.tagIcon,
    this.tagAngle = 0,
    this.tagInk = ShellInk.dark,
    this.vignette,
    this.scene,
    this.badge,
    this.textInk = ShellInk.dark,
  });

  /// The physical card itself (for a tagged card, without the tag and
  /// twine that hang off its left edge). Cards lay out to this rectangle;
  /// shadows and the tag spill outside it.
  final FractionRect body;

  /// The calm area for the eyebrow, title and details.
  final FractionRect text;

  /// Featured tickets: the "Show tickets" button, rotated by [actionAngle]
  /// radians. [actionFramed]: the shell already prints the stamp frame, so
  /// only the words are added.
  final FractionRect? action;
  final double actionAngle;
  final bool actionFramed;

  /// Featured tickets: the stub strip between the security band and the
  /// barcode, where "ADMIT TWO" runs upwards.
  final FractionRect? stubLabel;

  /// Room cards: a small supporting line near the bottom ("CHECK-OUT IN
  /// 4 DAYS").
  final FractionRect? footnote;

  /// The blank spot for the category icon: a luggage tag's face, or the
  /// printed medallion on a note or key tag. Tilted like the tag by
  /// [tagAngle] radians.
  final FractionRect? tagIcon;
  final double tagAngle;
  final ShellInk tagInk;

  /// Blank tagged cards: the panel right of the rule, for the booking's
  /// vignette.
  final FractionRect? vignette;

  /// Windowed featured shells: the transparent picture window. The
  /// booking's scene is drawn beneath the shell here, so the shell's own
  /// frame, keyline and rounded corners sit on top of it.
  final FractionRect? scene;

  /// Restaurant tickets: the blank table disc on the stub ("TABLE FOR" / "4").
  final FractionRect? badge;

  /// The ink for the card's live text and printed-frame words.
  final ShellInk textInk;

  /// The geometry for a shell: measured values for each bundled file, the
  /// role's template for pack shells (which are made to the same template).
  static ShellGeometry of(ShellRole role, SharedArtRef art) =>
      (art.isBundled ? _bundled[art.fileKey] : null) ?? _templates[role]!;

  /// Every bundled shell file with measured geometry.
  static Iterable<String> get measuredFiles => _bundled.keys;

  static const _templates = <ShellRole, ShellGeometry>{
    ShellRole.featuredTicket: ShellGeometry(
      body: FractionRect(0.030, 0.120, 0.970, 0.890),
      text: FractionRect(0.090, 0.180, 0.560, 0.620),
      action: FractionRect(0.090, 0.640, 0.360, 0.800),
      stubLabel: FractionRect(0.822, 0.260, 0.868, 0.760),
      textInk: ShellInk.light,
    ),
    ShellRole.boardingPass: _boardingPass,
    ShellRole.featuredReservation: _featuredReservation,
    ShellRole.travelTicket: _travelTicket,
    ShellRole.notePaper: _notePaper,
    ShellRole.ongoingTag: _ongoingTag,
    ShellRole.roomCard: ShellGeometry(
      body: FractionRect(0.035, 0.100, 0.970, 0.920),
      text: FractionRect(0.090, 0.220, 0.600, 0.700),
      footnote: FractionRect(0.090, 0.745, 0.380, 0.815),
    ),
    ShellRole.reservationCard: ShellGeometry(
      body: _reservationBody,
      text: _completeText,
      tagIcon: _tagIcon,
      tagAngle: _tagAngle,
      // Destination packs dye their tags (navy, green): light ink reads.
      tagInk: ShellInk.light,
    ),
    ShellRole.reservationBlank: ShellGeometry(
      body: _reservationBody,
      text: _blankText,
      tagIcon: _tagIcon,
      tagAngle: _tagAngle,
      vignette: _blankVignette,
    ),
  };

  // The universal round-2 shells: one bundled file each, the same for
  // every look (a pack may still supply its own, made to these anchors).

  /// Navy pass: light text left, picture window centre, barcode outline on
  /// the stub for the seat or flight number. Its stamp frame is printed.
  static const _boardingPass = ShellGeometry(
    body: FractionRect(0.027, 0.117, 0.974, 0.898),
    text: FractionRect(0.075, 0.175, 0.385, 0.635),
    action: FractionRect(0.080, 0.668, 0.363, 0.808),
    actionAngle: -0.059,
    actionFramed: true,
    stubLabel: FractionRect(0.880, 0.235, 0.924, 0.785),
    scene: FractionRect(0.406, 0.174, 0.746, 0.835),
    textInk: ShellInk.light,
  );

  /// Deep-teal menu card: light text left, picture window, a table disc on
  /// the stub.
  static const _featuredReservation = ShellGeometry(
    body: FractionRect(0.030, 0.121, 0.970, 0.873),
    text: FractionRect(0.075, 0.175, 0.405, 0.630),
    action: FractionRect(0.070, 0.674, 0.368, 0.815),
    actionAngle: -0.087,
    actionFramed: true,
    scene: FractionRect(0.423, 0.169, 0.761, 0.831),
    // Inset well inside the printed ring, where the circle is wide
    // enough for the caption.
    badge: FractionRect(0.847, 0.408, 0.931, 0.574),
    textInk: ShellInk.light,
  );

  /// Sage travel ticket: navy text (cream wouldn't read on sage), picture
  /// window, a ticket-number strip on the stub for the company.
  static const _travelTicket = ShellGeometry(
    body: FractionRect(0.028, 0.111, 0.972, 0.886),
    text: FractionRect(0.080, 0.190, 0.395, 0.635),
    action: FractionRect(0.073, 0.655, 0.347, 0.780),
    actionFramed: true,
    stubLabel: FractionRect(0.861, 0.215, 0.918, 0.765),
    scene: FractionRect(0.409, 0.181, 0.745, 0.813),
  );

  /// Ruled paper: the medallion by the paperclip takes the icon; text on
  /// the ruled lines, clear of the washi tape.
  static const _notePaper = ShellGeometry(
    body: FractionRect(0.040, 0.135, 0.975, 0.910),
    text: FractionRect(0.215, 0.265, 0.930, 0.850),
    tagIcon: FractionRect(0.075, 0.250, 0.167, 0.486),
  );

  /// Key tag: the key and ring hang off the left of the label (the body
  /// starts at the ring so little of it leaves the screen); the medallion
  /// takes the icon, two lines of text follow.
  static const _ongoingTag = ShellGeometry(
    body: FractionRect(0.040, 0.219, 0.980, 0.713),
    text: FractionRect(0.270, 0.245, 0.955, 0.690),
    tagIcon: FractionRect(0.186, 0.355, 0.238, 0.583),
  );

  static const _reservationBody = FractionRect(0.104, 0.204, 0.978, 0.906);
  static const _blankText = FractionRect(0.272, 0.305, 0.815, 0.865);
  static const _completeText = FractionRect(0.272, 0.305, 0.690, 0.865);

  /// Everything right of the printed rule, less a small margin inside the
  /// card's rounded edge.
  static const _blankVignette = FractionRect(0.834, 0.235, 0.972, 0.880);
  static const _tagIcon = FractionRect(0.117, 0.455, 0.229, 0.735);
  static const _tagAngle = -0.07;

  static const _bundled = <String, ShellGeometry>{
    // The theme-park anchor: castle ticket with a printed stamp frame.
    'featured_ticket': ShellGeometry(
      body: FractionRect(0.046, 0.130, 0.951, 0.884),
      text: FractionRect(0.100, 0.180, 0.620, 0.620),
      action: FractionRect(0.103, 0.628, 0.372, 0.792),
      actionAngle: -0.075,
      actionFramed: true,
      stubLabel: FractionRect(0.805, 0.260, 0.860, 0.760),
      textInk: ShellInk.light,
    ),
    'coastal_resort_featured_ticket': ShellGeometry(
      body: FractionRect(0.040, 0.123, 0.970, 0.893),
      text: FractionRect(0.090, 0.180, 0.550, 0.620),
      action: FractionRect(0.090, 0.640, 0.360, 0.800),
      stubLabel: FractionRect(0.805, 0.260, 0.865, 0.760),
      textInk: ShellInk.light,
    ),
    'urban_heritage_featured_ticket': ShellGeometry(
      body: FractionRect(0.025, 0.117, 0.976, 0.890),
      text: FractionRect(0.075, 0.180, 0.580, 0.620),
      action: FractionRect(0.075, 0.640, 0.345, 0.800),
      stubLabel: FractionRect(0.835, 0.260, 0.880, 0.760),
      textInk: ShellInk.light,
    ),
    'alpine_adventure_featured_ticket': ShellGeometry(
      body: FractionRect(0.033, 0.125, 0.968, 0.876),
      text: FractionRect(0.085, 0.180, 0.550, 0.620),
      action: FractionRect(0.085, 0.640, 0.355, 0.800),
      stubLabel: FractionRect(0.828, 0.260, 0.875, 0.760),
      textInk: ShellInk.light,
    ),
    'countryside_escape_featured_ticket': ShellGeometry(
      body: FractionRect(0.026, 0.121, 0.974, 0.890),
      text: FractionRect(0.075, 0.180, 0.580, 0.620),
      action: FractionRect(0.075, 0.640, 0.345, 0.800),
      stubLabel: FractionRect(0.832, 0.260, 0.870, 0.760),
      textInk: ShellInk.light,
    ),
    // The theme-park anchor key card prints a small palm bottom-left; the
    // footnote starts after it, and the text stops above it (its leaves
    // reach up to 0.665), so a name on two lines never runs into it.
    'room_card': ShellGeometry(
      body: FractionRect(0.057, 0.114, 0.944, 0.912),
      text: FractionRect(0.110, 0.245, 0.760, 0.655),
      footnote: FractionRect(0.180, 0.745, 0.580, 0.815),
    ),
    'coastal_resort_room_card': ShellGeometry(
      body: FractionRect(0.049, 0.112, 0.965, 0.917),
      text: FractionRect(0.100, 0.220, 0.660, 0.700),
      footnote: FractionRect(0.100, 0.745, 0.340, 0.815),
    ),
    'urban_heritage_room_card': ShellGeometry(
      body: FractionRect(0.029, 0.094, 0.975, 0.927),
      text: FractionRect(0.080, 0.220, 0.600, 0.700),
      footnote: FractionRect(0.080, 0.745, 0.450, 0.815),
    ),
    'alpine_adventure_room_card': ShellGeometry(
      body: FractionRect(0.034, 0.097, 0.971, 0.931),
      text: FractionRect(0.085, 0.220, 0.620, 0.700),
      footnote: FractionRect(0.085, 0.745, 0.380, 0.815),
    ),
    'countryside_escape_room_card': ShellGeometry(
      body: FractionRect(0.029, 0.103, 0.971, 0.901),
      text: FractionRect(0.080, 0.220, 0.600, 0.700),
      footnote: FractionRect(0.080, 0.745, 0.380, 0.815),
    ),
    'boarding_pass': _boardingPass,
    'featured_reservation': _featuredReservation,
    'travel_ticket': _travelTicket,
    'note_paper': _notePaper,
    'ongoing_tag': _ongoingTag,
    'reservation_card_blank': ShellGeometry(
      body: _reservationBody,
      text: _blankText,
      tagIcon: _tagIcon,
      tagAngle: _tagAngle,
      vignette: _blankVignette,
    ),
    'coastal_resort_reservation_card': ShellGeometry(
      body: _reservationBody,
      text: _completeText,
      tagIcon: _tagIcon,
      tagAngle: _tagAngle,
    ),
    'urban_heritage_reservation_card': ShellGeometry(
      body: _reservationBody,
      text: _completeText,
      tagIcon: _tagIcon,
      tagAngle: _tagAngle,
    ),
    'alpine_adventure_reservation_card': ShellGeometry(
      body: _reservationBody,
      text: _completeText,
      tagIcon: _tagIcon,
      tagAngle: _tagAngle,
      tagInk: ShellInk.light,
    ),
    'countryside_escape_reservation_card': ShellGeometry(
      body: _reservationBody,
      text: _completeText,
      tagIcon: _tagIcon,
      tagAngle: _tagAngle,
    ),
  };
}

/// A resolved shell: the picture, its role and where things go on it.
class ShellArt {
  const ShellArt({required this.art, required this.role, required this.geometry, this.standInFor});

  final SharedArtRef art;
  final ShellRole role;
  final ShellGeometry geometry;

  /// Set when the trip's look has no shells of its own yet and another
  /// look's stand in (see [shellStandIns] and docs/ART_ASSET_GAPS.md).
  final ExperienceTheme? standInFor;

  ArtImageRef get image => art.image;

  /// Whether the shell already carries its illustration (every role but the
  /// blank reservation card). No second picture is layered on top; a
  /// windowed shell shows the booking's scene *through* its window instead.
  bool get isComplete => role != ShellRole.reservationBlank;

  /// Whether the booking's scene shows through a window in the shell.
  bool get hasSceneWindow => geometry.scene != null;
}

/// The shells for one booking's cards, and which one each card uses.
class CardShells {
  const CardShells({
    this.featured,
    this.room,
    this.reservation,
    this.boardingPass,
    this.featuredReservation,
    this.travelTicket,
    this.note,
    this.ongoing,
  });

  static const none = CardShells();

  /// The look's featured admission ticket (with its destination printed on).
  final ShellArt? featured;

  /// The hotel key card (stays).
  final ShellArt? room;

  /// The tagged reservation card: the look's complete one, else blank.
  final ShellArt? reservation;

  /// Windowed featured shells for flights, restaurants and travel.
  final ShellArt? boardingPass;
  final ShellArt? featuredReservation;
  final ShellArt? travelTicket;

  /// Note paper.
  final ShellArt? note;

  /// The key tag for something in progress that isn't a stay.
  final ShellArt? ongoing;

  /// These shells with [reservation] as the tagged reservation card.
  CardShells withReservation(ShellArt? reservation) => CardShells(
    featured: featured,
    room: room,
    reservation: reservation,
    boardingPass: boardingPass,
    featuredReservation: featuredReservation,
    travelTicket: travelTicket,
    note: note,
    ongoing: ongoing,
  );

  /// The featured "next up" card for a booking of [kind]: a flight's
  /// boarding pass, a restaurant's reservation card, transport's travel
  /// ticket, a note's paper, a stay's key card, and the look's admission
  /// ticket for attractions, activities and shows (and for any kind whose
  /// own shell is missing).
  ShellArt? featuredFor(BookingKind kind) =>
      switch (kind) {
        BookingKind.flight => boardingPass,
        BookingKind.dining => featuredReservation,
        BookingKind.transport => travelTicket,
        BookingKind.note => note,
        BookingKind.stay => room,
        BookingKind.attraction || BookingKind.activity || BookingKind.event => null,
      } ??
      featured;

  /// The card for a booking of [kind] in a day's list: a stay's key card,
  /// a note's paper, the tagged reservation card for everything else.
  ShellArt? standardFor(BookingKind kind) =>
      switch (kind) {
        BookingKind.stay => room,
        BookingKind.note => note,
        _ => null,
      } ??
      reservation;
}

/// Looks without their own shell family borrow the nearest one until theirs
/// is made (listed in docs/ART_ASSET_GAPS.md). Only featured tickets and
/// room cards stand in: a tagged card falls back to the neutral blank shell
/// with the booking's own vignette, which always fits.
const shellStandIns = <ExperienceTheme, ExperienceTheme>{
  ExperienceTheme.classicTravel: ExperienceTheme.urbanHeritage,
  ExperienceTheme.urbanModern: ExperienceTheme.urbanHeritage,
  ExperienceTheme.outdoorAdventure: ExperienceTheme.alpine,
  ExperienceTheme.cruise: ExperienceTheme.coastalResort,
  ExperienceTheme.roadtrip: ExperienceTheme.countryside,
  ExperienceTheme.wellnessRetreat: ExperienceTheme.coastalResort,
};

/// Picks card shells for a trip, the one place shell art is chosen. The
/// round-2 shells (boarding pass, reservation and travel tickets, note
/// paper, key tag) are universal: one bundled file each, overridable by a
/// look-prefixed bundled file or a pack.
///
/// Order, per role: the trip's city, region and country packs; its look
/// (pack, then bundled `<look>_<role>`); a secondary look; then the core: a
/// classic pack, the stand-in look's bundled shell, and the unthemed
/// bundled anchor (`featured_ticket.webp`, `room_card.webp`). A tagged card
/// uses a complete `reservation_card` from the trip's own look or place
/// only; otherwise the neutral `reservation_card_blank` plus the booking's
/// vignette. A pack shell whose pixel size doesn't match its role's
/// template is skipped (its anchors wouldn't line up).
class ShellResolver {
  const ShellResolver(this.catalog);

  final ArtCatalog catalog;

  CardShells resolve(TripArtContext context) => CardShells(
    featured: shell(ShellRole.featuredTicket, context),
    room: shell(ShellRole.roomCard, context),
    reservation: shell(ShellRole.reservationCard, context) ?? shell(ShellRole.reservationBlank, context),
    boardingPass: shell(ShellRole.boardingPass, context),
    featuredReservation: shell(ShellRole.featuredReservation, context),
    travelTicket: shell(ShellRole.travelTicket, context),
    note: shell(ShellRole.notePaper, context),
    ongoing: shell(ShellRole.ongoingTag, context),
  );

  ShellArt? shell(ShellRole role, TripArtContext context) {
    final standIn = role == ShellRole.featuredTicket || role == ShellRole.roomCard
        ? shellStandIns[context.theme]
        : null;
    var ranked = context;
    SharedArtRef? art;
    while (true) {
      art = catalog.commonArt(role.key, context: ranked, fallbackThemes: [?standIn]);
      if (art == null || art.isBundled || _fitsTemplate(role, art)) break;
      // A pack shell made to another size: skip that pack for this role.
      ranked = TripArtContext(
        theme: ranked.theme,
        secondaryThemes: ranked.secondaryThemes,
        packRanks: {...ranked.packRanks}..remove(art.pack!.id),
        rankOrder: ranked.rankOrder,
      );
    }
    if (art == null) return null;
    if (role == ShellRole.reservationCard && art.isBundled && art.theme == null) {
      // An unthemed complete reservation card would be some other place's
      // illustration; the blank shell suits every booking.
      return null;
    }
    return ShellArt(
      art: art,
      role: role,
      geometry: ShellGeometry.of(role, art),
      standInFor: art.isBundled && standIn != null && art.theme == standIn ? context.theme : null,
    );
  }

  static bool _fitsTemplate(ShellRole role, SharedArtRef art) {
    final width = art.width;
    final height = art.height;
    if (width == null || height == null || height == 0) return false;
    return ((width / height) - role.aspectRatio).abs() / role.aspectRatio < 0.02;
  }
}
