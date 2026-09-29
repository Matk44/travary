import 'package:flutter/material.dart';

/// A place name on a tag, [width] wide: on one line if it fits at
/// [oneLineMinSize] or larger, else on two lines, stepping down to
/// [minSize] until no word breaks. Never cut short: a name too long even
/// at [minSize] wraps further, and the tag scales its words to fit.
class FittedPlaceName extends StatelessWidget {
  const FittedPlaceName(
    this.text, {
    super.key,
    required this.style,
    required this.width,
    required this.oneLineMinSize,
    required this.minSize,
  });

  final String text;

  /// The name at its largest.
  final TextStyle style;
  final double width;
  final double oneLineMinSize;
  final double minSize;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    double? sizeFor(int lines, double smallest) {
      for (var size = style.fontSize!; size >= smallest; size -= 1) {
        if (_fits(style.copyWith(fontSize: size), lines, scaler, direction)) return size;
      }
      return null;
    }

    final size = sizeFor(1, oneLineMinSize) ?? sizeFor(2, minSize) ?? minSize;
    return Text(
      text,
      style: style.copyWith(fontSize: size),
      textAlign: TextAlign.center,
    );
  }

  /// Whether [text] fits [width] in [lines] lines without breaking a word.
  bool _fits(TextStyle style, int lines, TextScaler scaler, TextDirection direction) {
    TextPainter measure(String value, {int? maxLines}) => TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: maxLines,
    )..layout(maxWidth: width);

    final whole = measure(text, maxLines: lines);
    final fits = !whole.didExceedMaxLines;
    whole.dispose();
    if (!fits) return false;
    for (final word in text.split(RegExp(r'\s+'))) {
      final painter = measure(word);
      final wordFits = painter.computeLineMetrics().length <= 1;
      painter.dispose();
      if (!wordFits) return false;
    }
    return true;
  }
}
