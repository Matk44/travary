import 'dart:math' as math;

/// A trip's interface colours: navy and warm cream anchors plus a few
/// accents drawn from the destination's landscape, architecture, craft,
/// season or time of day. Destination and experience art packs may carry
/// one in their `pack.json`; the bundled Travary palette is the fallback.
///
/// Gemini never produces colours, flags never imply them, and raster
/// pixels are never sampled: a palette is authored, validated data.
///
/// Colours are `0xFFRRGGBB` integers so the domain stays free of Flutter;
/// the design layer turns them into `Color`s.
class DestinationPalette {
  const DestinationPalette({
    required this.id,
    required this.ink,
    required this.paper,
    required this.accents,
    required this.primary,
    required this.secondary,
    required this.highlight,
    required this.onPrimary,
  });

  /// Lowercase slug (`kyoto_autumn`).
  final String id;

  /// Anchors: text ink and paper.
  final int ink;
  final int paper;

  /// Two to four illustrative accents.
  final List<int> accents;

  /// UI tokens. [primary] fills selected states (the raised home tab);
  /// [secondary] is an accent the app doesn't draw with at the moment (the
  /// time rail uses [ink]); [highlight] marks what matters now (category
  /// labels, the current step); [onPrimary] is text and icons on [primary].
  final int primary;
  final int secondary;
  final int highlight;
  final int onPrimary;

  /// Travary's own palette: navy ink on warm cream, deep teal selection,
  /// coral highlights. Used when no installed pack supplies one.
  static const bundled = DestinationPalette(
    id: 'travary_classic',
    ink: 0xFF1C2A47,
    paper: 0xFFF8F4EC,
    accents: [0xFF1E5B70, 0xFFE5785B, 0xFF9DB29C, 0xFFD7A443],
    primary: 0xFF1E5B70,
    secondary: 0xFF1C2A47,
    highlight: 0xFFE5785B,
    onPrimary: 0xFFF8F4EC,
  );

  /// WCAG AA for normal text.
  static const minimumContrast = 4.5;

  static const _keys = {'id', 'anchors', 'accents', 'ui'};
  static const _anchorKeys = {'ink', 'paper'};
  static const _uiKeys = {'primary', 'secondary', 'highlight', 'onPrimary'};
  static final _slug = RegExp(r'^[a-z0-9_]{1,64}$');
  static final _hex = RegExp(r'^#[0-9A-F]{6}$');

  /// Validates a `palette` object from `pack.json`. Throws [FormatException]
  /// naming the problem:
  ///
  /// - only the documented keys (`id`, `anchors`, `accents`, `ui`, and
  ///   within them `ink`/`paper` and `primary`/`secondary`/`highlight`/
  ///   `onPrimary`), every one present;
  /// - `id` a lowercase slug;
  /// - every colour an uppercase `#RRGGBB`;
  /// - two to four accents;
  /// - no colour repeated within `anchors`, `accents` or `ui`;
  /// - `ui.onPrimary` on `ui.primary` at least 4.5:1 (WCAG AA).
  static DestinationPalette parse(Object? json) {
    if (json is! Map) throw const FormatException('palette must be an object.');
    _onlyKeys(json, _keys, 'palette');
    final id = json['id'];
    if (id is! String || !_slug.hasMatch(id)) {
      throw const FormatException('palette.id must be a lowercase slug.');
    }

    final anchors = json['anchors'];
    if (anchors is! Map) throw const FormatException('palette.anchors must be an object.');
    _onlyKeys(anchors, _anchorKeys, 'palette.anchors', required: true);
    final ink = _colour(anchors['ink'], 'palette.anchors.ink');
    final paper = _colour(anchors['paper'], 'palette.anchors.paper');
    _distinct([ink, paper], 'palette.anchors');

    final rawAccents = json['accents'];
    if (rawAccents is! List || rawAccents.length < 2 || rawAccents.length > 4) {
      throw const FormatException('palette.accents must list two to four colours.');
    }
    final accents = [for (var i = 0; i < rawAccents.length; i++) _colour(rawAccents[i], 'palette.accents[$i]')];
    _distinct(accents, 'palette.accents');

    final ui = json['ui'];
    if (ui is! Map) throw const FormatException('palette.ui must be an object.');
    _onlyKeys(ui, _uiKeys, 'palette.ui', required: true);
    final primary = _colour(ui['primary'], 'palette.ui.primary');
    final secondary = _colour(ui['secondary'], 'palette.ui.secondary');
    final highlight = _colour(ui['highlight'], 'palette.ui.highlight');
    final onPrimary = _colour(ui['onPrimary'], 'palette.ui.onPrimary');
    _distinct([primary, secondary, highlight, onPrimary], 'palette.ui');

    final contrast = contrastRatio(primary, onPrimary);
    if (contrast < minimumContrast) {
      throw FormatException(
        'palette.ui.onPrimary on palette.ui.primary is ${contrast.toStringAsFixed(2)}:1; '
        'WCAG AA needs $minimumContrast:1.',
      );
    }

    return DestinationPalette(
      id: id,
      ink: ink,
      paper: paper,
      accents: List.unmodifiable(accents),
      primary: primary,
      secondary: secondary,
      highlight: highlight,
      onPrimary: onPrimary,
    );
  }

  /// Like [parse], but null for anything invalid. For reading data this
  /// app wrote itself; packs are checked with [parse] so a bad palette
  /// rejects the pack.
  static DestinationPalette? tryParse(Object? json) {
    try {
      return parse(json);
    } on FormatException {
      return null;
    }
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'anchors': {'ink': hexOf(ink), 'paper': hexOf(paper)},
    'accents': [for (final accent in accents) hexOf(accent)],
    'ui': {
      'primary': hexOf(primary),
      'secondary': hexOf(secondary),
      'highlight': hexOf(highlight),
      'onPrimary': hexOf(onPrimary),
    },
  };

  @override
  bool operator ==(Object other) =>
      other is DestinationPalette &&
      other.id == id &&
      other.ink == ink &&
      other.paper == paper &&
      _sameInts(other.accents, accents) &&
      other.primary == primary &&
      other.secondary == secondary &&
      other.highlight == highlight &&
      other.onPrimary == onPrimary;

  @override
  int get hashCode => Object.hash(id, ink, paper, Object.hashAll(accents), primary, secondary, highlight, onPrimary);

  @override
  String toString() => 'DestinationPalette($id)';
}

/// `#RRGGBB` for an `0xFFRRGGBB` colour.
String hexOf(int colour) => '#${(colour & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// WCAG 2 relative luminance of an `0xFFRRGGBB` colour.
double relativeLuminance(int colour) {
  double channel(int shift) {
    final c = ((colour >> shift) & 0xFF) / 255;
    return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0);
}

/// WCAG 2 contrast ratio between two colours (1 to 21).
double contrastRatio(int a, int b) {
  final la = relativeLuminance(a);
  final lb = relativeLuminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

void _onlyKeys(Map<dynamic, dynamic> json, Set<String> allowed, String where, {bool required = false}) {
  final unknown = json.keys.where((key) => !allowed.contains(key)).toList();
  if (unknown.isNotEmpty) throw FormatException('$where has unknown keys: ${unknown.join(', ')}.');
  if (required) {
    final missing = allowed.where((key) => !json.containsKey(key)).toList();
    if (missing.isNotEmpty) throw FormatException('$where is missing ${missing.join(', ')}.');
  }
}

int _colour(Object? value, String where) {
  if (value is! String || !DestinationPalette._hex.hasMatch(value)) {
    throw FormatException('$where must be an uppercase #RRGGBB colour.');
  }
  return 0xFF000000 | int.parse(value.substring(1), radix: 16);
}

void _distinct(List<int> colours, String where) {
  // Colours are parsed from validated uppercase hex, so equal integers are
  // exactly the duplicates "after case normalisation".
  if (colours.toSet().length != colours.length) throw FormatException('$where repeats a colour.');
}

bool _sameInts(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
