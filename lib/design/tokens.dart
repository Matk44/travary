import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  /// Timeline stop: "9:00" over "Park".
  static TextStyle get timelineTime => _sans(13.5, FontWeight.w700, TravaryColors.ink, height: 1.2);
  static TextStyle get timelineLabel => _sans(13.5, FontWeight.w400, TravaryColors.ink, height: 1.2);

  /// Home tab labels.
  static TextStyle get tabLabel => _sans(11, FontWeight.w500, TravaryColors.ink, height: 1.1);
  static TextStyle get tabLabelSelected => _sans(13.5, FontWeight.w600, TravaryColors.paper, height: 1.1);

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
  static TextStyle get countdownAction => _serif(24, FontWeight.w700, TravaryColors.paper, height: 1.1);
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

  /// Between the last card and the timeline.
  static const timelineGap = 16.0;

  /// The first and last timeline stops from the card edges.
  static const timelineInset = 30.0;

  /// A timeline stop needs at least this much room; more stops scroll.
  static const timelineStopWidth = 78.0;

  /// Below the timeline, above the home tabs.
  static const bottomGap = 16.0;
}

/// Today between trips: the next trip's postcard with its countdown tag
/// (docs/mockups/today-empty/02-hanging-luggage-tag.png).
abstract final class CountdownLayout {
  /// The postcard's box from the screen edge. Its own transparent margin
  /// and deckled edge add about 4% more.
  static const postcardInset = 6.0;

  /// Wider screens centre the postcard at this width.
  static const postcardMaxWidth = 460.0;

  /// The postcard is at most this share of the screen's height, so the
  /// heading, postcard, facts and button fit above the home tabs on a
  /// 390 × 844 phone (the postcard is taller than it is wide).
  static const postcardMaxHeight = 0.5;

  /// Room above the postcard for the tag's cord, as a share of the
  /// postcard's width. The cord also runs up past the postcard's right
  /// edge (never clipped by the hero itself).
  static const cordRoom = 0.06;

  /// The tag's card (its body, without the cord) as a share of the
  /// postcard's width.
  static const tagWidth = 0.46;

  /// Where the tag's card sits on the postcard at rest: its right edge and
  /// top edge, as shares of the postcard's width.
  static const tagRight = 0.99;
  static const tagTop = 0.095;

  /// The tag hangs this far clockwise, shell and words together.
  static const tagAngleDegrees = 7.0;

  /// On entry it swings in from a few degrees further and settles.
  static const tagSettleDegrees = 4.0;

  /// The tag's words are laid out at this width, then scaled to the tag.
  static const tagCopyWidth = 140.0;

  /// Postcard lift and fade, then the tag's delayed settle.
  static const entryDuration = Duration(milliseconds: 900);
  static const postcardLift = 16.0;

  /// Between the postcard and the facts (its own clear margin already
  /// spaces them), and the facts and the button.
  static const factsGap = 0.0;
  static const buttonGap = 18.0;
  static const factSpacing = 8.0;

  /// The facts' stand-in tags.
  static const factMinHeight = 64.0;
  static const factIconSize = 30.0;

  /// The ticket button.
  static const buttonWidth = 0.56;
  static const buttonMaxWidth = 260.0;
  static const buttonMinHeight = 60.0;
  static const buttonNotch = 9.0;
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
}

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
    textTheme: TravaryText.useGoogleFonts ? GoogleFonts.interTextTheme(base.textTheme) : base.textTheme,
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
    datePickerTheme: const DatePickerThemeData(backgroundColor: TravaryColors.paper),
    timePickerTheme: const TimePickerThemeData(backgroundColor: TravaryColors.paper),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: TravaryColors.ink),
  );
}
