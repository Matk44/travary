import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The foil ticket at a readable size, including its transparent margin.
abstract final class PassBadgeLayout {
  static const width = 120.0;
  static const height = width / aspect;

  /// The foil tickets' shape (1983 × 793).
  static const aspect = 1983 / 793;

  /// The widest the pass desk shows a just-bought pass.
  static const confirmedWidth = 250.0;

  /// The ticket itself within the artwork (its transparent margin around),
  /// as fractions of the image.
  static const artTicket = Rect.fromLTRB(.029, .111, .971, .872);
}

/// Colours from the "travel ephemera" mockup (v1): linen desk, cream paper,
/// navy ink, coral and teal accents.
abstract final class TravaryColors {
  static const linen = Color(0xFFEFE8DC);
  static const paper = Color(0xFFF8F4EC);
  static const paperEdge = Color(0xFFE2D8C7);
  static const ink = Color(0xFF1C2A47);
  static const inkSoft = Color(0xFF56617A);
  static const inkFaint = Color(0xFF8C909B);
  static const teal = Color(0xFF1E5B70);
  static const tealDeep = Color(0xFF143F52);
  static const coral = Color(0xFFE5785B);
  static const sage = Color(0xFF9DB29C);
  static const kraft = Color(0xFFC9A77D);
  static const mustard = Color(0xFFD7A443);
  static const plum = Color(0xFF5B3F63);
  static const line = Color(0xFFDCD2C1);
  static const profileCastShadow = Color(0x24382B1D);
  static const profileContactShadow = Color(0x16382B1D);

  // Trip looks (tiles and theme chips).
  static const alpine = Color(0xFF6F8FAF);
  static const moss = Color(0xFF6E8B5E);
  static const pine = Color(0xFF3F5E48);
  static const harbour = Color(0xFF2F4F7F);
  static const lilac = Color(0xFF8E7BA8);
}

abstract final class TravarySpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  /// Side margin for screen content.
  static const gutter = 20.0;
}

/// The approved paper-theatre onboarding has a fixed stage palette.
abstract final class OnboardingColors {
  static const navy = Color(0xFF102B46);
  static const binding = Color(0xFF0B263B);
  static const paper = Color(0xFFFFF1D9);
  static const cream = Color(0xFFFFF7E9);
  static const coral = Color(0xFFFA815A);
  static const coralInk = Color(0xFFB85132);
  static const brass = Color(0xFFD1AB68);
  static const teal = Color(0xFF086078);
  static const secondary = Color(0xFF655440);

  /// The stages' cream floor, below the artwork on tall phones.
  static const floor = Color(0xFFFBE8D3);

  /// The stages' petrol sky, above a stage that's been lowered.
  static const sky = Color(0xFF014D6E);
}

abstract final class TravaryRadius {
  static const card = 16.0;
  static const chip = 999.0;
  static const small = 10.0;
}

/// Type styles. Headings are a bookish serif, everything else a clean sans.
abstract final class TravaryText {
  /// Tests turn this off so no fonts are fetched.
  static bool useGoogleFonts = true;

  /// With Google Fonts off, families already loaded some other way (the
  /// visual QA render loads the same Source Serif 4 and Inter files).
  static String? serifFamily;
  static String? sansFamily;

  static TextStyle _serif(double size, FontWeight weight, Color color, {double height = 1.15, double? letterSpacing}) =>
      useGoogleFonts
      ? GoogleFonts.sourceSerif4(
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        )
      : TextStyle(
          fontFamily: serifFamily,
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        );

  static TextStyle _sans(
    double size,
    FontWeight weight,
    Color color, {
    double height = 1.3,
    double letterSpacing = 0,
  }) => useGoogleFonts
      ? GoogleFonts.inter(
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        )
      : TextStyle(
          fontFamily: sansFamily,
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: height,
          letterSpacing: letterSpacing,
        );

  /// "Good morning".
  static TextStyle get display => _serif(36, FontWeight.w700, TravaryColors.ink, height: 1.05);

  /// Screen titles.
  static TextStyle get headline => _serif(28, FontWeight.w700, TravaryColors.ink);

  /// Card titles.
  static TextStyle get title => _serif(21, FontWeight.w700, TravaryColors.ink);

  /// Regular serif copy on the illustrated onboarding paper. Resolve its own
  /// font face; changing a bold Google Fonts style's weight retains that face.
  static TextStyle get onboardingCopy => _serif(21, FontWeight.w400, OnboardingColors.navy, height: 1.06);

  /// Title on the featured (hero) card.
  static TextStyle get heroTitle => _serif(30, FontWeight.w700, TravaryColors.paper, height: 1.05);

  static TextStyle get body => _sans(15.5, FontWeight.w400, TravaryColors.ink);
  static TextStyle get bodySoft => _sans(14.5, FontWeight.w400, TravaryColors.inkSoft);
  static TextStyle get label => _sans(14, FontWeight.w600, TravaryColors.ink);
  static TextStyle get small => _sans(12.5, FontWeight.w500, TravaryColors.inkSoft);

  /// Small spaced capitals above titles: "NEXT UP".
  static TextStyle get eyebrow => _sans(11.5, FontWeight.w700, TravaryColors.inkSoft, letterSpacing: 2.2);

  // ---- Today: header, raster card shells, timeline, home tabs ----------

  /// "Good morning" on Today.
  static TextStyle get greeting => _serif(43, FontWeight.w700, TravaryColors.ink, height: 1.0, letterSpacing: -0.8);

  /// "Day 3 of 7 · Orlando".
  static TextStyle get daySubtitle => _sans(16.5, FontWeight.w400, TravaryColors.ink, height: 1.25);

  /// The weather or countdown pill.
  static TextStyle get pill => _sans(12.5, FontWeight.w500, TravaryColors.ink, height: 1.2);

  /// Spaced capitals on shells: "NEXT UP", "HOTEL", "LUNCH".
  static TextStyle get shellEyebrow => _sans(11, FontWeight.w600, TravaryColors.ink, height: 1.2, letterSpacing: 2.6);

  /// Title on the featured ticket.
  static TextStyle get ticketTitle =>
      _serif(32, FontWeight.w700, TravaryColors.paper, height: 1.08, letterSpacing: -0.5);

  /// Title on the hotel key card.
  static TextStyle get roomTitle => _serif(28, FontWeight.w700, TravaryColors.ink, height: 1.08, letterSpacing: -0.5);

  /// Title on tagged reservation cards.
  static TextStyle get reservationTitle =>
      _serif(25, FontWeight.w700, TravaryColors.ink, height: 1.08, letterSpacing: -0.4);

  /// Times and details on shells: "12:30pm · Table for 4".
  static TextStyle get shellLine => _sans(16, FontWeight.w400, TravaryColors.ink, height: 1.3);

  /// The small supporting line on a key card: "CHECK-OUT IN 4 DAYS".
  static TextStyle get footnote => _sans(10, FontWeight.w600, TravaryColors.ink, height: 1.2, letterSpacing: 1.8);

  /// "ADMIT TWO" up the ticket stub.
  static TextStyle get stubLabel => _sans(10.5, FontWeight.w600, TravaryColors.ink, height: 1.0, letterSpacing: 3.2);

  /// The "Show tickets" stamp.
  static TextStyle get stamp => _serif(18, FontWeight.w700, TravaryColors.ink, height: 1.0);

  /// Words on the card Travi holds up, in his navy trim.
  static TextStyle get traviSign => _serif(20, FontWeight.w700, OnboardingColors.navy, height: 1.0, letterSpacing: 1.2);

  /// A stop on the time rail: "9:00" over "am".
  static TextStyle get railTime => _sans(14, FontWeight.w700, TravaryColors.ink, height: 1.2);
  static TextStyle get railPeriod => _sans(12, FontWeight.w400, TravaryColors.inkSoft, height: 1.15);

  /// The trip calendar: weekday letters over day numbers.
  static TextStyle get calendarWeekday =>
      _sans(12, FontWeight.w600, TravaryColors.inkSoft, height: 1.2, letterSpacing: 0.6);
  static TextStyle get calendarDay => _sans(15, FontWeight.w500, TravaryColors.ink, height: 1.0);

  /// Home tab labels.
  static TextStyle get tabLabel => _sans(11, FontWeight.w500, TravaryColors.ink, height: 1.1);
  static TextStyle get tabLabelSelected => _sans(13.5, FontWeight.w600, TravaryColors.paper, height: 1.1);

  // ---- The trip ledger and paper forms (C2 "refined ledger") ------------

  /// A screen's own heading in the ledger look: "Your plan", "Add a booking".
  static TextStyle get ledgerHeading =>
      _serif(28, FontWeight.w700, TravaryColors.ink, height: 1.1, letterSpacing: -0.4);

  /// A centred form title: "Add a stay", "Find your flight".
  static TextStyle get formTitle => _serif(24, FontWeight.w700, TravaryColors.ink, height: 1.1, letterSpacing: -0.3);

  /// A row of a trip's plan: "Kyoto House".
  static TextStyle get ledgerTitle => _serif(18, FontWeight.w700, TravaryColors.ink, height: 1.15);

  /// The date column of a plan row: "11" over "OCT".
  static TextStyle get ledgerDay => _serif(22, FontWeight.w700, TravaryColors.ink, height: 1.0);
  static TextStyle get ledgerMonth => _sans(10.5, FontWeight.w700, TravaryColors.ink, height: 1.2, letterSpacing: 1.4);

  /// A paper form's small-caps label: "PROPERTY NAME".
  static TextStyle get fieldLabel =>
      _sans(10.5, FontWeight.w700, TravaryColors.inkSoft, height: 1.2, letterSpacing: 1.8);

  /// What's written on a paper form's line: "Kyoto House".
  static TextStyle get fieldValue => _serif(20, FontWeight.w500, TravaryColors.ink, height: 1.2);

  /// A date in a ticket's box: "12 OCT 2026".
  static TextStyle get ticketDate => _sans(15.5, FontWeight.w600, TravaryColors.ink, height: 1.1, letterSpacing: 1.3);

  /// The heading on a form ticket's band: "YOUR STAY".
  static TextStyle get ticketBand => _sans(13, FontWeight.w700, TravaryColors.paper, height: 1.1, letterSpacing: 3.4);

  /// The notched primary button: "Add stay".
  static TextStyle get ticketButton => _serif(20, FontWeight.w700, TravaryColors.paper, height: 1.1);

  // ---- Profile: the account folio and Annual Pass ----------------------
  static TextStyle get profileSubtitle => _sans(15, FontWeight.w400, TravaryColors.inkSoft);
  static TextStyle get profileAccountTitle => _serif(22, FontWeight.w700, TravaryColors.ink, height: 1.1);
  static TextStyle get profilePassTitle => _serif(27, FontWeight.w700, TravaryColors.ink, height: 1.1);
  static TextStyle get profilePassLead => _sans(14.5, FontWeight.w600, TravaryColors.ink);
  static TextStyle get profileBenefit => _sans(13.5, FontWeight.w400, TravaryColors.ink, height: 1.3);
  static TextStyle get profileSettingTitle => _serif(17, FontWeight.w600, TravaryColors.ink, height: 1.15);
  static TextStyle get profileSettingCopy => _sans(12.5, FontWeight.w400, TravaryColors.inkSoft, height: 1.35);

  /// The departures board: its labels, a split-flap character, and the
  /// route between them.
  static TextStyle get boardLabel => _sans(10.5, FontWeight.w700, TravaryColors.paper, height: 1.2, letterSpacing: 2.2);
  static TextStyle get boardFlap => _sans(30, FontWeight.w800, TravaryColors.paper, height: 1.0);
  static TextStyle get boardRoute => _serif(24, FontWeight.w600, TravaryColors.paper, height: 1.1);

  /// A flight's live line under its card on Today: "Delayed 45 min · Gate 12".
  static TextStyle get liveLine => _sans(13, FontWeight.w600, TravaryColors.paper, height: 1.2, letterSpacing: 0.2);

  // ---- Trips: the tag on a coming trip's postcard ------------------------
  // Sized for the tag's copy area at TripPostcardLayout.tagCopyWidth; the
  // tag scales the whole block to the tag it's drawn on.

  /// The countdown: "58".
  static TextStyle get tripTagNumber =>
      _serif(62, FontWeight.w700, TravaryColors.ink, height: 1.0, letterSpacing: -1.5);

  /// "DAYS".
  static TextStyle get tripTagLabel => _sans(11, FontWeight.w600, TravaryColors.ink, height: 1.2, letterSpacing: 3.0);

  /// The trip's name. A longer name steps down to
  /// [tripTagPlaceOneLineMinSize] on one line, else takes two lines,
  /// stepping down to [tripTagPlaceMinSize].
  static TextStyle get tripTagPlace => _serif(22, FontWeight.w700, TravaryColors.ink, height: 1.1, letterSpacing: -0.3);
  static const tripTagPlaceOneLineMinSize = 17.0;
  static const tripTagPlaceMinSize = 14.0;

  /// "25–28 Nov 2026".
  static TextStyle get tripTagDates => _sans(13, FontWeight.w500, TravaryColors.ink, height: 1.2);

  /// "4 days · 3 bookings".
  static TextStyle get tripTagFacts => _sans(11, FontWeight.w500, TravaryColors.ink, height: 1.25);

  // ---- Today between trips: the countdown tag ---------------------------
  // Sized for the tag's copy area at CountdownLayout.tagCopyWidth; the tag
  // scales the whole block to the tag it's drawn on.

  /// "NEXT TRIP" and "DAYS TO GO".
  static TextStyle get tagEyebrow => _sans(11, FontWeight.w600, TravaryColors.ink, height: 1.2, letterSpacing: 3.0);

  /// The countdown number: "58".
  static TextStyle get tagNumber => _serif(84, FontWeight.w700, TravaryColors.ink, height: 1.0, letterSpacing: -2);

  /// The trip's name: "Lake District". A longer name steps down to
  /// [tagPlaceOneLineMinSize] to stay on one line, else takes two lines,
  /// stepping down to [tagPlaceMinSize].
  static TextStyle get tagPlace => _serif(24, FontWeight.w700, TravaryColors.ink, height: 1.1, letterSpacing: -0.3);
  static const tagPlaceOneLineMinSize = 19.0;
  static const tagPlaceMinSize = 15.0;

  /// "25–28 Nov 2026".
  static TextStyle get tagDates => _sans(14, FontWeight.w500, TravaryColors.ink, height: 1.2);

  /// "4 days", "3 bookings", "Opens 25 Nov" under the postcard.
  static TextStyle get countdownFact => _sans(14, FontWeight.w500, TravaryColors.ink, height: 1.2);

  /// "View trip" on the ticket button.
  static TextStyle get countdownAction => _serif(22, FontWeight.w600, TravaryColors.paper, height: 1.0);

  // ---- Documents: the stamp rows --------------------------------------

  /// The postmark's date: "26" over "Sep".
  static TextStyle get documentDay => _serif(15, FontWeight.w700, TravaryColors.ink, height: 1.0);
  static TextStyle get documentMonth => _serif(12.5, FontWeight.w700, TravaryColors.ink, height: 1.05);

  /// The booking's name. A long one shrinks a little
  /// ([DocumentStampLayout.titleMinScale]), then ends in an ellipsis.
  static TextStyle get documentTitle =>
      _serif(17, FontWeight.w700, TravaryColors.ink, height: 1.15, letterSpacing: -0.2);

  /// "Lunch · ST-4412".
  static TextStyle get documentLine => _sans(13, FontWeight.w400, TravaryColors.inkSoft, height: 1.25);

  /// The place on a destination stamp's label: "ORLANDO".
  static TextStyle get destinationLabel =>
      _sans(9, FontWeight.w700, TravaryColors.ink, height: 1.0, letterSpacing: 1.6);
}

/// Text on the raster card shells.
abstract final class ShellLayout {
  /// A title that won't fit its two lines at its usual smallest size (a
  /// long name on a narrow card) steps down to this share of its size
  /// before it ends in an ellipsis.
  static const titleFloorScale = 0.5;
}

/// Spacing of the Today composition, tuned at the reference 390 × 927
/// point viewport (docs/reference/travary_today_reference.png).
abstract final class TodayLayout {
  /// Above the greeting (below any status bar).
  static const headerTop = 30.0;

  /// Header text from the screen edge.
  static const headerInset = 20.0;

  /// The weather pill from the right edge.
  static const pillInset = 12.0;

  /// The pill's tap target is at least this tall, the pill centred in it.
  static const pillTarget = 48.0;

  /// Between the header and the first card.
  static const headerGap = 26.0;

  /// The featured ticket's scalloped edge reaches further out than cards.
  static const featuredInset = 10.0;

  /// Cards from the screen edge.
  static const cardInset = 16.0;

  /// Between cards.
  static const cardGap = 25.0;

  /// Compact rows (finished items) are closer together.
  static const compactGap = 8.0;

  /// The time rail's column of times, from the screen edge, and its width.
  /// The line and dots run down the middle of it.
  static const railLeft = 4.0;
  static const railWidth = 44.0;

  /// Cards beside the rail start this far from the screen edge. A tagged
  /// card's luggage-tag cord hangs out left of the card, above it; this
  /// keeps the cord short of the line.
  static const railCardLeft = 64.0;

  /// A stop's time starts this far below its card's top edge, level with
  /// a tagged card's first line of text.
  static const railStopTop = 14.0;

  /// The line stops this far short of a stop's time; below, it leaves
  /// from behind the dot.
  static const railLineGap = 6.0;

  /// The line's width, and a stop's dot.
  static const railLine = 2.4;
  static const railDot = 13.0;

  /// The times grow with the text size up to this much; the card beside
  /// each one says its time at any size.
  static const railMaxTextScale = 1.3;

  /// Below the last card, above the home tabs.
  static const bottomGap = 16.0;

  /// Let go of the day sheet and it settles on a spring a little short of
  /// critical damping (a ratio of 0.7): it overshoots a few points and
  /// bobbles into place in about 0.4 s, like the tabs' slide
  /// ([NavLayout.switchCurve]) but smaller, as the finger did most of the
  /// move.
  static const daySettle = SpringDescription(mass: 0.5, stiffness: 160, damping: 12.5);
}

/// The trip calendar in the day chooser.
abstract final class CalendarLayout {
  /// A day's row, which is also its tap target's height.
  static const rowHeight = 48.0;

  /// The disc behind a day's number: filled for the day on screen, ringed
  /// for today.
  static const disc = 38.0;
  static const ring = 1.8;

  /// The dot under the number on a day with something booked.
  static const bookedDot = 4.5;

  /// Numbers grow with the text size up to this much, to stay in the disc.
  static const maxTextScale = 1.6;
}

/// Today between trips: the next trip's postcard with its countdown tag
/// (docs/mockups/today-empty/02-hanging-luggage-tag.png).
abstract final class CountdownLayout {
  /// The postcard's box from the screen edge. Its own transparent margin
  /// and deckled edge add about 4% more.
  static const postcardInset = 6.0;

  /// Wider screens centre the postcard at this width.
  static const postcardMaxWidth = 460.0;

  /// The postcard with the tag hanging below it is at most this share of
  /// the screen's height, so the greeting, heading, postcard and tag fit
  /// above the home tabs: on a 390 × 844 phone the postcard spans the
  /// full width.
  static const stageMaxHeight = 0.67;

  /// The tag's card (its body, without the cord) as a share of the
  /// postcard's width: small enough to leave most of the picture showing.
  static const tagWidth = 0.36;

  /// The tag hangs over the postcard's lower right corner: its card reaches
  /// this share of the postcard's width past the card's right edge, and
  /// this share of the tag's card hangs below the card's bottom edge.
  static const tagPastEdge = 0.02;
  static const tagBelow = 0.5;

  /// The tag hangs this far clockwise, shell and words together.
  static const tagAngleDegrees = 6.0;

  /// The note under the postcard (the packing list): in from the card's
  /// left edge, and kept clear of the tag as if it leant this far (its
  /// resting angle and most of its swing).
  static const noteInset = 2.0;
  static const noteClearDegrees = 10.0;

  /// The tag's words are laid out at this width, then scaled to the tag.
  static const tagCopyWidth = 140.0;

  /// The entry, played each time Today shows the countdown: the postcard
  /// lifts in, the tag is slapped on, the card gives, the tag swings and
  /// settles (phases in `CountdownTripHero`).
  static const entryDuration = Duration(milliseconds: 2200);

  /// The postcard rises this far and grows from [postcardStartScale].
  static const postcardLift = 16.0;
  static const postcardStartScale = 0.96;

  /// How far the postcard gives under the slap, as a share of its size.
  static const postcardGive = 0.015;

  /// The tag comes down from this much larger, this many points higher,
  /// turned this many degrees the other way.
  static const tagSlapScale = 1.4;
  static const tagSlapDrop = 28.0;
  static const tagSlapTurnDegrees = 8.0;

  /// Then it swings: this many degrees either side at first, this many
  /// times, dying away at this rate, and stops exactly at rest.
  static const tagSwingDegrees = 10.0;
  static const tagSwingCycles = 2.5;
  static const tagSwingDamping = 4.5;

  /// The postcard sinks a little under a finger.
  static const pressScale = 0.98;

  /// Travi peeking from behind the postcard's top right: his square as a
  /// share of the postcard's width (90 points on a 390-point phone), its
  /// right edge at [traviRight] of the postcard, sunk [traviSink] of
  /// himself below the card's top edge.
  static const traviWidth = 0.24;
  static const traviRight = 0.88;
  static const traviSink = 0.07;
}

/// The Documents list's stamp rows (`DocumentStampCard`), tuned on a
/// 390-point phone against
/// docs/mockups/documents-themed-v2/02-collectible-scenic-stamps.png.
/// Sizes are for the full-size row; a narrow phone draws the postmark and
/// stamp smaller (down to [minArtScale]) so the text keeps its width.
abstract final class DocumentStampLayout {
  /// Rows from the screen edge (like Today's cards), and between rows.
  static const inset = 16.0;
  static const gap = 6.0;

  /// A row's least height (it grows with larger text) and corner radius.
  static const rowHeight = 62.0;
  static const radius = 10.0;

  /// Inside the row, before the postmark and after the chevron.
  static const paddingStart = 6.0;
  static const paddingEnd = 4.0;

  /// The postmark's outer ring, across.
  static const ringDiameter = 44.0;

  /// Between the ring and the stamp, crossed by the cancellation lines;
  /// without the lines (a narrow phone), [ringGapTight].
  static const ringGap = 16.0;
  static const ringGapTight = 6.0;

  /// The stamp itself, perforation tips included.
  static const stampWidth = 70.0;

  /// Between the stamp and the title.
  static const stampGap = 12.0;

  /// The chevron; a row with ticket files has the wider "Show tickets"
  /// button (a full-size target) in its place.
  static const chevron = 30.0;
  static const ticketsButton = 44.0;

  /// The kind icon's paper badge in the window's top-right corner.
  static const badge = 16.0;
  static const badgeInset = 3.0;

  /// The title and details are never narrower than this while the art can
  /// still shrink. Below [linesMinScale] the cancellation lines are left
  /// out; the art never goes below [minArtScale].
  static const minTextWidth = 150.0;
  static const minArtScale = 0.72;
  static const linesMinScale = 0.9;

  /// The lines' band as a share of the ring's diameter, and where they
  /// start: this share of the ring's radius right of its centre.
  static const linesHeight = 0.36;
  static const linesStart = 0.58;

  /// The date inside the ring, as a share of its diameter.
  static const dateSize = 0.56;

  /// The smallest a long title shrinks, as a share of its size, before it
  /// ends in an ellipsis; and the space under it.
  static const titleMinScale = 0.78;
  static const lineGap = 2.0;

  /// The destination stamp beside the heading, and its postmark (as a
  /// share of the stamp's width).
  static const headerStampWidth = 100.0;
  static const headerRing = 0.5;
}

/// The raised home tabs.
abstract final class NavLayout {
  /// A resting tab's height above the bottom safe area.
  static const height = 46.0;

  /// How high a selected tab rises above the others.
  static const rise = 11.0;

  /// Tabs are this far apart and this far from the screen edge.
  static const gap = 4.0;
  static const inset = 8.0;

  /// The add tab is narrower than the others.
  static const addFlex = 9;
  static const tabFlex = 10;

  static const radius = 14.0;

  /// Raster nav icons keep a wide margin round the ink.
  static const iconSize = 36.0;
  static const selectedIconSize = 40.0;

  /// The pop when a tab is chosen.
  static const popDuration = Duration(milliseconds: 380);

  /// The pages slide sideways through every tab in between, overshooting a
  /// little (that curve is the bobble) before they settle on the chosen one.
  static const switchDuration = Duration(milliseconds: 500);
  static const switchCurve = Curves.easeOutBack;
}

/// Trips: a coming trip's landscape postcard with the countdown tag hung
/// on its right edge (docs/mockups/trips-postcards-v2/02-hanging-tag-postcards.png).
/// The ledger look's measures: paper panels, plan rows, form tickets and
/// the departures board.
abstract final class LedgerLayout {
  /// Corner radius of paper panels and the board.
  static const panelRadius = 14.0;

  /// Width of a plan row's date column.
  static const dateColumn = 44.0;

  /// The form ticket's coloured band, its notches (cut where the band
  /// meets the paper) and the notched button's.
  static const bandHeight = 64.0;
  static const ticketRadius = 18.0;
  static const ticketNotch = 12.0;
  static const buttonNotch = 9.0;
  static const buttonHeight = 56.0;

  /// A split-flap character's tile on the board, before it scales down to
  /// fit, and the pause between neighbouring tiles as they flip.
  static const flapTile = Size(34, 48);
  static const flapStagger = Duration(milliseconds: 35);
  static const flapDuration = Duration(milliseconds: 260);
}

/// Travi's peeks outside Today's countdown (`TraviPopUp`).
abstract final class TraviCameoLayout {
  /// His square, as on the countdown on a 390-point phone.
  static const peekSize = 88.0;

  /// Over the New trip sheet: his square's right edge this far in from the
  /// sheet's, clear of its rounded corner.
  static const sheetRight = 28.0;

  /// Over a new trip's plan: his square's left edge in from the panel's,
  /// and how far he's sunk behind its top edge.
  static const planLeft = 12.0;
  static const planSink = 6.0;

  /// He pops up once the sheet or screen has slid in.
  static const popUpDelay = Duration(milliseconds: 350);

  /// Holding up a card with words on it (the AI question): larger, so the
  /// words can be read.
  static const signSize = 132.0;
}

abstract final class TripPostcardLayout {
  /// The postcard's box from the screen edge; its own transparent margin
  /// and deckled edge add about 2% more.
  static const inset = 6.0;

  /// Wider screens centre the postcard at this width.
  static const maxWidth = 560.0;

  /// Share of the postcard's height (the top of its transparent margin)
  /// tucked under the row above, so postcards sit about as close as in
  /// the mockup.
  static const rise = 0.04;

  /// The tag's card (its body, without the cord) as a share of the
  /// postcard's width.
  static const tagWidth = 0.31;

  /// Where the tag's card sits at rest: its right edge and top edge, as
  /// shares of the postcard's width.
  static const tagRight = 0.99;
  static const tagTop = 0.045;

  /// The tag hangs this far clockwise, give or take [tagAngleSpread] per
  /// trip, shell and words together.
  static const tagAngleDegrees = 4.0;
  static const tagAngleSpread = 1.0;

  /// The tag's words are laid out at this width, then scaled to the tag.
  static const tagCopyWidth = 112.0;
}

/// The face of a time picker's dial and unselected hour and minute boxes.
const _pickerFace = Color(0xFFE7DCC9);

ThemeData buildTravaryTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: TravaryColors.ink,
      primary: TravaryColors.ink,
      secondary: TravaryColors.coral,
      surface: TravaryColors.paper,
    ),
    scaffoldBackgroundColor: TravaryColors.linen,
  );
  return base.copyWith(
    // Renders with the real fonts loaded locally (visual QA, the website's
    // screens) give unstyled text, such as a search hint, Inter too.
    textTheme: TravaryText.useGoogleFonts
        ? GoogleFonts.interTextTheme(base.textTheme)
        : base.textTheme.apply(fontFamily: TravaryText.sansFamily),
    appBarTheme: const AppBarTheme(
      backgroundColor: TravaryColors.linen,
      foregroundColor: TravaryColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TravaryColors.paper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TravaryRadius.small),
        borderSide: const BorderSide(color: TravaryColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(TravaryRadius.small),
        borderSide: const BorderSide(color: TravaryColors.line),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: TravaryColors.ink,
        foregroundColor: TravaryColors.paper,
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TravaryRadius.small)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: TravaryColors.paper,
      selectedColor: const Color(0xFFE7DCC9),
      checkmarkColor: TravaryColors.ink,
      side: const BorderSide(color: TravaryColors.line),
      labelStyle: TravaryText.small.copyWith(color: TravaryColors.ink),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TravaryRadius.small)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        selectedBackgroundColor: const Color(0xFFE7DCC9),
        selectedForegroundColor: TravaryColors.ink,
        foregroundColor: TravaryColors.ink,
        side: const BorderSide(color: TravaryColors.line),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: TravaryColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TravaryRadius.small)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: TravaryColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TravaryRadius.card)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: TravaryColors.linen),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: TravaryColors.paper,
      surfaceTintColor: Colors.transparent,
      headerForegroundColor: TravaryColors.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TravaryRadius.card)),
      dayForegroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? TravaryColors.paper : TravaryColors.ink,
      ),
      dayBackgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? TravaryColors.ink : null,
      ),
      todayForegroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? TravaryColors.paper : TravaryColors.coral,
      ),
      todayBorder: const BorderSide(color: TravaryColors.coral),
      yearForegroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? TravaryColors.paper : TravaryColors.ink,
      ),
      yearBackgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? TravaryColors.ink : null,
      ),
      confirmButtonStyle: TextButton.styleFrom(foregroundColor: TravaryColors.ink),
      cancelButtonStyle: TextButton.styleFrom(foregroundColor: TravaryColors.inkSoft),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: TravaryColors.paper,
      hourMinuteColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected) ? TravaryColors.ink : _pickerFace,
      ),
      hourMinuteTextColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected) ? TravaryColors.paper : TravaryColors.ink,
      ),
      dayPeriodColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected) ? TravaryColors.ink : Colors.transparent,
      ),
      dayPeriodTextColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected) ? TravaryColors.paper : TravaryColors.ink,
      ),
      dayPeriodBorderSide: const BorderSide(color: TravaryColors.line),
      dialBackgroundColor: _pickerFace,
      dialHandColor: TravaryColors.ink,
      dialTextColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.selected) ? TravaryColors.paper : TravaryColors.ink,
      ),
      entryModeIconColor: TravaryColors.inkSoft,
      helpTextStyle: TravaryText.small.copyWith(color: TravaryColors.inkSoft),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TravaryRadius.card)),
      confirmButtonStyle: TextButton.styleFrom(foregroundColor: TravaryColors.ink),
      cancelButtonStyle: TextButton.styleFrom(foregroundColor: TravaryColors.inkSoft),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: TravaryColors.ink),
  );
}
