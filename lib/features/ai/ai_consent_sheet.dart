import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../design/tokens.dart';
import '../../design/trip_chrome.dart';
import '../../design/widgets/common.dart';
import '../../design/widgets/ledger.dart';
import '../../design/widgets/paper_form.dart';
import '../../design/widgets/travi_cameo.dart';
import '../../domain/domain.dart';
import '../../logic/ai_consent.dart';
import '../../logic/travi_cameos.dart';
import '../../state/ai_consent_store.dart';
import '../help/help_links.dart';

/// Asks before anything goes to Google's Gemini AI (`logic/ai_consent.dart`),
/// unless it's already allowed. Returns whether it may go now.
///
/// "Allow" allows it on this phone; "Not now" declines (Smart Import asks
/// again when it's next used); putting the sheet away answers nothing.
/// [travi]: Travi pops up over the sheet holding his sign; off where he's
/// already on stage (onboarding).
Future<bool> askAiConsent(BuildContext context, AiAsk ask, {bool travi = true}) async {
  final consent = context.read<AiConsentStore>();
  await consent.ready;
  if (consent.allowed) return true;
  if (!context.mounted) return false;
  final answer = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    // The sheet draws its own handle: the built-in one would clip Travi,
    // who pops up over the top edge.
    showDragHandle: false,
    backgroundColor: TravaryColors.linen,
    builder: (context) => AiConsentSheet(ask: ask, travi: travi),
  );
  switch (answer) {
    case true:
      await consent.allow(ask);
      return true;
    case false:
      await consent.decline(ask);
      return false;
    case null:
      return false;
  }
}

/// The question as a paper ticket in the trip's colours: what's asked, what
/// goes to Gemini, what never does, then "Allow" or "Not now".
class AiConsentSheet extends StatelessWidget {
  const AiConsentSheet({super.key, required this.ask, this.travi = true});

  final AiAsk ask;
  final bool travi;

  @override
  Widget build(BuildContext context) {
    final words = aiConsentWordsFor(ask);
    final colors = TravaryChrome.of(context).colors;
    final media = MediaQuery.of(context);
    // Smaller on a short phone, so the ticket keeps its room.
    final peek = travi ? math.min(TraviCameoLayout.signSize, media.size.height * 0.17) : 0.0;

    final sheet = ConstrainedBox(
      // Short enough that Travi, above it, stays on screen.
      constraints: BoxConstraints(maxHeight: media.size.height - media.padding.top - peek - TravarySpace.sm),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            // The ticket scrolls on a small phone; the answers stay in view.
            Flexible(
              child: _FadeWhenThereIsMore(
                padding: const EdgeInsets.fromLTRB(TravarySpace.gutter, 0, TravarySpace.gutter, TravarySpace.md),
                child: FormTicket(
                  key: const ValueKey('ai-consent-ticket'),
                  heading: words.band,
                  children: [
                    Text(words.title, style: TravaryText.formTitle.copyWith(color: colors.ink)),
                    const SizedBox(height: TravarySpace.sm),
                    Text(words.lead, style: TravaryText.bodySoft),
                    const SizedBox(height: TravarySpace.md),
                    const _Field(label: aiSentLabel, text: aiSentWords),
                    const SizedBox(height: TravarySpace.md),
                    const _Field(label: aiNeverSentLabel, text: aiNeverSentWords),
                    const SizedBox(height: TravarySpace.md),
                    Perforation(color: colors.ink.withValues(alpha: 0.25)),
                    const SizedBox(height: TravarySpace.sm),
                    Text(aiFinePrint, style: TravaryText.small),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        key: const ValueKey('ai-consent-privacy'),
                        onPressed: () => openTravaryPage(context, TravaryLinks.privacy),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.ink,
                          padding: EdgeInsets.zero,
                          textStyle: TravaryText.label.copyWith(decoration: TextDecoration.underline),
                        ),
                        child: const Text('Privacy Policy'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TravarySpace.gutter,
                TravarySpace.sm,
                TravarySpace.gutter,
                TravarySpace.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TicketButton(
                    key: const ValueKey('ai-consent-allow'),
                    label: 'Allow',
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                  const SizedBox(height: TravarySpace.xs),
                  TextButton(
                    key: const ValueKey('ai-consent-not-now'),
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(foregroundColor: TravaryColors.inkSoft, textStyle: TravaryText.label),
                    child: const Text('Not now'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (!travi) return sheet;
    // Travi pops up over the sheet's top edge, holding up his question.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        sheet,
        Positioned(
          right: TraviCameoLayout.sheetRight,
          top: -peek,
          width: peek,
          height: peek,
          child: const ExcludeSemantics(
            child: TraviPopUp(key: ValueKey('ai-consent-travi'), peek: TraviPeek.today, sign: aiConsentSign),
          ),
        ),
      ],
    );
  }
}

/// A printed field on the ticket: its label in small capitals, then what
/// it says.
class _Field extends StatelessWidget {
  const _Field({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TravaryText.fieldLabel),
      const SizedBox(height: TravarySpace.xs),
      Text(text, style: TravaryText.body),
    ],
  );
}

/// Scrolls [child], fading its bottom edge out while there's more below,
/// so a ticket cut off by a small screen reads as "keep scrolling" rather
/// than torn.
class _FadeWhenThereIsMore extends StatefulWidget {
  const _FadeWhenThereIsMore({required this.child, required this.padding});

  final Widget child;
  final EdgeInsets padding;

  @override
  State<_FadeWhenThereIsMore> createState() => _FadeWhenThereIsMoreState();
}

class _FadeWhenThereIsMoreState extends State<_FadeWhenThereIsMore> {
  static const _fade = 40.0;
  final _controller = ScrollController();
  bool _more = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _check() {
    if (!mounted) return;
    final more = _controller.hasClients && _controller.position.extentAfter > 1;
    if (more != _more) setState(() => _more = more);
  }

  @override
  Widget build(BuildContext context) => NotificationListener<ScrollMetricsNotification>(
    onNotification: (_) {
      _check();
      return false;
    },
    child: ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFF000000), const Color(0xFF000000), Color(_more ? 0x00000000 : 0xFF000000)],
        stops: [0, (1 - _fade / bounds.height).clamp(0, 1), 1],
      ).createShader(bounds),
      child: SingleChildScrollView(controller: _controller, padding: widget.padding, child: widget.child),
    ),
  );
}
