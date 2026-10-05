import 'package:flutter/material.dart';

import '../art/art_resolver.dart';
import '../art/art_slots.dart';
import '../cards/card_parts.dart';
import '../tokens.dart';
import '../trip_chrome.dart';
import 'ledger.dart';

/// The add and edit forms as a paper ticket (C2): small-caps labels over
/// writing on a hairline, dates printed in boxes, a coloured band at the
/// top with the booking's picture, and notches where the band meets the
/// paper.

/// A field on a paper form: its label in small capitals above, the
/// writing on a hairline below. A field Smart Import wasn't sure of is
/// ruled in coral with "Check this".
class PaperTextField extends StatelessWidget {
  const PaperTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.check = false,
    this.autofocus = false,
    this.errorText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.sentences,
    this.minLines,
    this.maxLines = 1,
    this.small = false,
    this.onChanged,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool check;
  final bool autofocus;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int? minLines;
  final int? maxLines;

  /// Body-sized writing for secondary fields (reference, notes).
  final bool small;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    UnderlineInputBorder rule(Color color, double width) => UnderlineInputBorder(
      borderSide: BorderSide(color: color, width: width),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TravaryText.fieldLabel.copyWith(color: check ? TravaryColors.coral : null)),
        TextField(
          controller: controller,
          autofocus: autofocus,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          minLines: minLines,
          maxLines: maxLines,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: small
              ? TravaryText.body.copyWith(color: colors.ink)
              : TravaryText.fieldValue.copyWith(color: colors.ink),
          decoration: InputDecoration(
            isDense: true,
            filled: false,
            hintText: hint,
            hintStyle: (small ? TravaryText.body : TravaryText.fieldValue).copyWith(color: TravaryColors.inkFaint),
            contentPadding: const EdgeInsets.only(top: 6, bottom: 8),
            border: rule(TravaryColors.line, 1),
            enabledBorder: check ? rule(TravaryColors.coral, 2) : rule(TravaryColors.line, 1),
            focusedBorder: rule(check ? TravaryColors.coral : colors.ink, 1.6),
            errorText: errorText,
            helperText: check ? 'Check this' : null,
            helperStyle: TravaryText.small.copyWith(color: TravaryColors.coral),
          ),
        ),
      ],
    );
  }
}

/// A date printed in a ticket's box ("12 OCT 2026") under its label, and
/// its time below ("3:00pm ×", or "+ Time"). Tapping either changes it.
class TicketDateBox extends StatelessWidget {
  const TicketDateBox({
    super.key,
    required this.label,
    required this.date,
    required this.onDate,
    this.time,
    this.onTime,
    this.onClearTime,
    this.checkDate = false,
    this.checkTime = false,
  });

  final String label;
  final String date;
  final VoidCallback onDate;

  /// The time ("3:00pm"), or null for none yet.
  final String? time;

  /// Null hides the time (a kind without one).
  final VoidCallback? onTime;
  final VoidCallback? onClearTime;
  final bool checkDate;
  final bool checkTime;

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TravaryText.fieldLabel),
        const SizedBox(height: 6),
        Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(
              color: checkDate ? TravaryColors.coral : colors.ink.withValues(alpha: 0.55),
              width: checkDate ? 2 : 1.2,
            ),
          ),
          child: InkWell(
            onTap: onDate,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(date, style: TravaryText.ticketDate.copyWith(color: colors.ink), maxLines: 1),
              ),
            ),
          ),
        ),
        if (onTime != null) ...[
          const SizedBox(height: 6),
          InkWell(
            onTap: onTime,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: checkTime
                  ? BoxDecoration(
                      border: Border.all(color: TravaryColors.coral, width: 2),
                      borderRadius: BorderRadius.circular(6),
                    )
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (time == null)
                    Icon(Icons.add_rounded, size: 16, color: colors.ink)
                  else
                    SlotIcon(icon: TravaryChrome.of(context).slots.icon(IconSlot.clock), color: colors.ink, size: 18),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      time ?? 'Time',
                      style: TravaryText.label.copyWith(color: time == null ? TravaryColors.inkSoft : colors.ink),
                    ),
                  ),
                  if (time != null && onClearTime != null)
                    GestureDetector(
                      onTap: onClearTime,
                      behavior: HitTestBehavior.opaque,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.close_rounded, size: 16, color: TravaryColors.inkSoft),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// How long it lasts, between the two dates: "—— 2 nights ——".
class SpanLabel extends StatelessWidget {
  const SpanLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider(color: TravaryColors.line, thickness: 1)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: TravarySpace.md),
        child: Text(text, style: TravaryText.body.copyWith(color: TravaryChrome.of(context).colors.ink)),
      ),
      const Expanded(child: Divider(color: TravaryColors.line, thickness: 1)),
    ],
  );
}

/// The form itself as a ticket: a band in the trip's colour carrying
/// [heading] ("YOUR STAY") and the booking's picture, notches where the
/// band meets the paper, and the fields below.
class FormTicket extends StatelessWidget {
  const FormTicket({super.key, required this.heading, required this.children, this.art});

  final String heading;
  final ArtChoice? art;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    const shape = NotchedTicketBorder(
      radius: LedgerLayout.ticketRadius,
      notchRadius: LedgerLayout.ticketNotch,
      notchOffset: LedgerLayout.bandHeight,
    );
    final picture = art?.scene ?? art?.vignette;
    return DecoratedBox(
      key: const ValueKey('form-ticket'),
      decoration: ShapeDecoration(
        color: colors.paper,
        shape: shape,
        shadows: const [BoxShadow(color: Color(0x1F000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      child: ClipPath(
        clipper: const ShapeBorderClipper(shape: shape),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: LedgerLayout.bandHeight,
              child: ColoredBox(
                color: colors.primary,
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: TravarySpace.xl),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(heading, style: TravaryText.ticketBand.copyWith(color: colors.onPrimary)),
                          ),
                        ),
                      ),
                    ),
                    if (picture != null)
                      SizedBox(
                        width: 140,
                        child: ShaderMask(
                          // The picture fades in from the band's colour.
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0x00000000), Color(0xFF000000)],
                            stops: [0.0, 0.35],
                          ).createShader(bounds),
                          blendMode: BlendMode.dstIn,
                          child: Image(
                            image: artImageProvider(picture.image),
                            fit: BoxFit.cover,
                            alignment: Alignment.centerRight,
                            excludeFromSemantics: true,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(TravarySpace.xl, TravarySpace.xl, TravarySpace.xl, TravarySpace.lg),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
            ),
          ],
        ),
      ),
    );
  }
}
