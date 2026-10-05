import 'package:flutter/material.dart';

import '../art/art_catalog.dart';
import '../art/art_slots.dart';
import '../cards/card_parts.dart';
import '../tokens.dart';
import '../trip_chrome.dart';

/// The ledger look's shared pieces (C2, "refined ledger"): woven linen
/// behind screens pushed over the tabs, paper panels and rows, the ticket's
/// notched outline, its notched button and a perforated tear line. All
/// drawn: no raster needed, so they're crisp at any size and take the
/// trip's palette.

/// A ticket's outline: rounded corners with a semicircle bitten out of
/// each side, where a ticket tears. The bites sit [notchOffset] from the
/// top when it's set (a form ticket's band), else halfway down.
class NotchedTicketBorder extends OutlinedBorder {
  const NotchedTicketBorder({
    super.side,
    this.radius = 12,
    this.notchRadius = LedgerLayout.buttonNotch,
    this.notchOffset,
  });

  final double radius;
  final double notchRadius;
  final double? notchOffset;

  Path _path(Rect rect) {
    final body = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final y = rect.top + (notchOffset ?? rect.height / 2);
    final bites = Path()
      ..addOval(Rect.fromCircle(center: Offset(rect.left, y), radius: notchRadius))
      ..addOval(Rect.fromCircle(center: Offset(rect.right, y), radius: notchRadius));
    return Path.combine(PathOperation.difference, body, bites);
  }

  @override
  NotchedTicketBorder copyWith({BorderSide? side}) =>
      NotchedTicketBorder(side: side ?? this.side, radius: radius, notchRadius: notchRadius, notchOffset: notchOffset);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  ShapeBorder scale(double t) => NotchedTicketBorder(
    side: side.scale(t),
    radius: radius * t,
    notchRadius: notchRadius * t,
    notchOffset: notchOffset == null ? null : notchOffset! * t,
  );

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => _path(rect.deflate(side.width));

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawPath(_path(rect.deflate(side.width / 2)), side.toPaint());
  }

  @override
  bool operator ==(Object other) =>
      other is NotchedTicketBorder &&
      other.side == side &&
      other.radius == radius &&
      other.notchRadius == notchRadius &&
      other.notchOffset == notchOffset;

  @override
  int get hashCode => Object.hash(side, radius, notchRadius, notchOffset);
}

/// The one primary button: flat ink, full width, with a ticket's notches
/// cut into each end. "Add stay", "Use this flight", "Add a booking".
class TicketButton extends StatelessWidget {
  const TicketButton({super.key, required this.label, required this.onPressed, this.busy = false, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    final child = busy
        ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: colors.paper))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: TravarySpace.sm)],
              Flexible(child: Text(label, textAlign: TextAlign.center, maxLines: 2)),
            ],
          );
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: colors.ink,
        foregroundColor: colors.paper,
        disabledBackgroundColor: colors.ink.withValues(alpha: 0.32),
        disabledForegroundColor: colors.paper.withValues(alpha: 0.85),
        minimumSize: const Size.fromHeight(LedgerLayout.buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: TravarySpace.xxl, vertical: TravarySpace.md),
        shape: const NotchedTicketBorder(),
        textStyle: TravaryText.ticketButton,
      ),
      child: child,
    );
  }
}

/// A ticket's tear line: a row of small punched holes.
class Perforation extends StatelessWidget {
  const Perforation({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 8,
    width: double.infinity,
    child: CustomPaint(painter: _PerforationPainter(color ?? TravaryColors.line)),
  );
}

class _PerforationPainter extends CustomPainter {
  _PerforationPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 8.0;
    final paint = Paint()..color = color;
    final count = (size.width / gap).floor();
    final start = (size.width - (count - 1) * gap) / 2;
    for (var i = 0; i < count; i++) {
      canvas.drawCircle(Offset(start + i * gap, size.height / 2), 1.7, paint);
    }
  }

  @override
  bool shouldRepaint(_PerforationPainter oldDelegate) => oldDelegate.color != color;
}

/// The woven linen behind a screen pushed over the tabs (a trip, a form):
/// the same tile as the home screens, so moving between them is seamless.
class LinenBackground extends StatelessWidget {
  const LinenBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final linen = TravaryChrome.of(context).slots.surface(SurfaceSlot.linen);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TravaryColors.linen,
        image: linen == null
            ? null
            : DecorationImage(image: artImageProvider(linen), repeat: ImageRepeat.repeat, scale: 3),
      ),
      child: child,
    );
  }
}

/// A sheet of cream travel paper on the linen, holding rows or a form.
class PaperPanel extends StatelessWidget {
  const PaperPanel({super.key, required this.child, this.padding = EdgeInsets.zero});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(LedgerLayout.panelRadius),
        border: Border.all(color: TravaryColors.paperEdge),
        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LedgerLayout.panelRadius),
        child: Material(
          type: MaterialType.transparency,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A hairline between rows on a paper panel.
class PaperDivider extends StatelessWidget {
  const PaperDivider({super.key, this.indent = TravarySpace.lg});

  final double indent;

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, indent: indent, endIndent: indent, color: TravaryColors.line);
}

/// One row on a paper panel: an optional icon or picture, a title, a
/// line under it, and a chevron (or [trailing]).
class PaperRow extends StatelessWidget {
  const PaperRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.titleStyle,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 54),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TravarySpace.lg, vertical: TravarySpace.md),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: TravarySpace.md)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: titleStyle ?? TravaryText.ledgerTitle.copyWith(fontSize: 17)),
                    if (subtitle != null) ...[const SizedBox(height: 2), Text(subtitle!, style: TravaryText.small)],
                  ],
                ),
              ),
              trailing ??
                  (onTap == null
                      ? const SizedBox.shrink()
                      : const Icon(Icons.chevron_right_rounded, color: TravaryColors.inkSoft)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A raster picture for a row (the add sheet's snapshot, the passport),
/// or its stand-in glyph on a paper square while the file is missing.
class RowPicture extends StatelessWidget {
  const RowPicture({super.key, required this.image, required this.fallback, this.size = 64});

  final ArtImageRef? image;
  final IconData fallback;
  final double size;

  @override
  Widget build(BuildContext context) {
    final raster = image;
    final standIn = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: TravaryColors.linen,
        borderRadius: BorderRadius.circular(TravaryRadius.small),
        border: Border.all(color: TravaryColors.line),
      ),
      child: Icon(fallback, color: TravaryChrome.of(context).colors.ink, size: size * 0.45),
    );
    if (raster == null) return standIn;
    return SizedBox.square(
      dimension: size,
      child: Image(
        image: artImageProvider(raster),
        fit: BoxFit.contain,
        excludeFromSemantics: true,
        errorBuilder: (context, error, stackTrace) => standIn,
      ),
    );
  }
}

/// A row's small letterpress icon (a booking kind, attach, invite), in
/// the trip's ink, or its stand-in glyph.
class RowIcon extends StatelessWidget {
  const RowIcon(this.slot, {super.key, this.size = 22});

  final IconSlot slot;
  final double size;

  @override
  Widget build(BuildContext context) {
    final chrome = TravaryChrome.of(context);
    return SlotIcon(icon: chrome.slots.icon(slot), color: chrome.colors.ink, size: size);
  }
}

/// A top bar's text grows with the reader's text size up to 1.3×, like
/// iOS's own navigation bars, so "Trips" and "Trip details" still fit side
/// by side on a small phone. The screen below takes their full size.
class BarText extends StatelessWidget {
  const BarText({super.key, required this.child});

  final Widget child;

  static const maxScale = 1.3;

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(maxScaleFactor: maxScale, child: child);
}
