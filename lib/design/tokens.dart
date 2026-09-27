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

  static TextStyle _serif(double size, FontWeight weight, Color color, {double height = 1.15}) =>
      useGoogleFonts
          ? GoogleFonts.sourceSerif4(fontSize: size, fontWeight: weight, color: color, height: height)
          : TextStyle(fontSize: size, fontWeight: weight, color: color, height: height);

  static TextStyle _sans(double size, FontWeight weight, Color color,
          {double height = 1.3, double letterSpacing = 0}) =>
      useGoogleFonts
          ? GoogleFonts.inter(
              fontSize: size, fontWeight: weight, color: color, height: height,
              letterSpacing: letterSpacing)
          : TextStyle(
              fontSize: size, fontWeight: weight, color: color, height: height,
              letterSpacing: letterSpacing);

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
  static TextStyle get eyebrow =>
      _sans(11.5, FontWeight.w700, TravaryColors.inkSoft, letterSpacing: 2.2);
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
    textTheme: TravaryText.useGoogleFonts
        ? GoogleFonts.interTextTheme(base.textTheme)
        : base.textTheme,
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
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: TravaryColors.ink,
    ),
  );
}
