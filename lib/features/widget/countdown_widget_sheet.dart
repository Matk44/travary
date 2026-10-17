import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/tokens.dart';
import '../../design/trip_chrome.dart';
import '../../design/widgets/ledger.dart';
import '../../design/widgets/paper_form.dart';
import '../../design/widgets/travi_cameo.dart';
import '../../logic/countdown_widget_setup.dart';
import '../../logic/travi_cameos.dart';
import '../../state/countdown_widget_store.dart';

/// Opens the sheet that gets the countdown widget onto the home screen,
/// from Today's countdown (`today`) or Profile (`profile`). Android asks
/// its launcher to place it; iOS can't be asked, so the sheet shows how.
Future<void> showCountdownWidgetSheet(BuildContext context, {required String from}) {
  context.read<CountdownWidgetStore>().opened(from);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: TravaryColors.linen,
    builder: (_) => CountdownWidgetSheet(canDecline: from == 'today'),
  );
}

/// The ticket: what the widget is, then either the one button that places
/// it or the steps to do it by hand. It follows the phone: when the widget
/// lands on the home screen (found when the app comes back) it says so.
class CountdownWidgetSheet extends StatefulWidget {
  const CountdownWidgetSheet({super.key, this.canDecline = false, this.platform});

  /// Opened from Today's offer, so it can put the offer away for good
  /// ("Not now"). Profile's keeps the widget a tap away and offers nothing.
  final bool canDecline;

  /// The phone's own, unless a test says otherwise.
  final HomeWidgetPlatform? platform;

  @override
  State<CountdownWidgetSheet> createState() => _CountdownWidgetSheetState();
}

class _CountdownWidgetSheetState extends State<CountdownWidgetSheet> {
  bool _busy = false;

  /// The launcher wouldn't open its dialog: show the steps.
  bool _refused = false;

  HomeWidgetPlatform get _platform =>
      widget.platform ??
      (defaultTargetPlatform == TargetPlatform.android ? HomeWidgetPlatform.android : HomeWidgetPlatform.ios);

  Future<void> _act(CountdownWidgetStore store, CountdownWidgetWords words) async {
    if (words.action != countdownWidgetPinAction) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _busy = true);
    final shown = await store.requestPin();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _refused = !shown;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CountdownWidgetStore>();
    final colors = TravaryChrome.of(context).colors;
    final media = MediaQuery.of(context);
    final status = store.status;
    final words = countdownWidgetWords(platform: _platform, status: status);
    final refused = _refused && !status.added;
    final steps = words.steps.isNotEmpty || !refused ? words.steps : countdownWidgetSteps(_platform);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The ticket scrolls on a small phone or with large text; the button stays in view.
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.md),
                child: FormTicket(
                  key: const ValueKey('widget-sheet-ticket'),
                  heading: words.band,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ExcludeSemantics(child: TraviCameo(moment: TraviMoment.hello, height: 72, close: true)),
                        const SizedBox(width: TravarySpace.sm),
                        Expanded(
                          child: Text(
                            words.title,
                            key: const ValueKey('widget-sheet-title'),
                            style: TravaryText.formTitle.copyWith(color: colors.ink),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: TravarySpace.sm),
                    Text(words.lead, style: TravaryText.bodySoft),
                    if (refused) ...[
                      const SizedBox(height: TravarySpace.sm),
                      Text(
                        countdownWidgetPinRefused,
                        key: const ValueKey('widget-sheet-refused'),
                        style: TravaryText.small,
                      ),
                    ],
                    if (steps.isNotEmpty) ...[
                      const SizedBox(height: TravarySpace.md),
                      Perforation(color: colors.ink.withValues(alpha: 0.25)),
                      const SizedBox(height: TravarySpace.md),
                      for (final (i, step) in steps.indexed) ...[
                        if (i > 0) const SizedBox(height: TravarySpace.sm),
                        _Step(key: ValueKey('widget-sheet-step-$i'), number: i + 1, text: step),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TravarySpace.gutter,
                TravarySpace.xs,
                TravarySpace.gutter,
                TravarySpace.sm,
              ),
              child: TicketButton(
                key: const ValueKey('widget-sheet-action'),
                label: words.action,
                busy: _busy,
                onPressed: () => _act(store, words),
              ),
            ),
            if (widget.canDecline && store.offers)
              Padding(
                padding: const EdgeInsets.only(bottom: TravarySpace.sm),
                child: TextButton(
                  key: const ValueKey('widget-sheet-not-now'),
                  onPressed: () {
                    unawaited(store.decline());
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(foregroundColor: TravaryColors.inkSoft, textStyle: TravaryText.label),
                  child: const Text(countdownWidgetNotNow),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One step, numbered on a small ink disc.
class _Step extends StatelessWidget {
  const _Step({super.key, required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = TravaryChrome.of(context).colors;
    return Semantics(
      label: 'Step $number. $text',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: colors.ink, shape: BoxShape.circle),
            child: Text('$number', style: TravaryText.label.copyWith(color: colors.paper, fontSize: 13, height: 1)),
          ),
          const SizedBox(width: TravarySpace.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text, style: TravaryText.body),
            ),
          ),
        ],
      ),
    );
  }
}
