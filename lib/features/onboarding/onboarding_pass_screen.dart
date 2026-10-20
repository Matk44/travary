import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/purchase_service.dart';
import '../../design/tokens.dart';
import '../../design/widgets/fit_column.dart';
import '../../design/widgets/onboarding_pass_desk.dart';
import '../../design/widgets/onboarding_scene.dart';
import '../../design/widgets/pass_badge.dart';
import '../../domain/domain.dart';
import '../../logic/access.dart';
import '../../logic/formatters.dart';
import '../../logic/onboarding_art.dart';
import '../../logic/onboarding_films.dart';
import '../../logic/onboarding_journey.dart';
import '../../logic/pass_confirmation.dart';
import '../../logic/price_text.dart';
import '../../logic/trip_plan.dart';
import '../../state/analytics.dart';
import '../../state/premium_store.dart';
import '../../state/travel_store.dart';
import '../help/help_links.dart';
import 'onboarding_stage_layout.dart';

enum OnboardingPassOutcome { free, upgraded }

/// The pass desk ("Shall I help with the rest?") as controls on the stage's
/// floor: the passes slide in under Travi's open palm. A holiday may have no
/// booking yet; exploring with no holiday offers Annual only, without
/// inventing a trip. Free stays one tap away.
///
/// Once a pass is bought (or restored) the desk confirms it: the pass's
/// foil badge is stamped onto the floor over what it now covers, the stage
/// is told ([onConfirmed]: Travi cheers, the words change), and one button
/// ([confirmedLabel]) hands back to what the traveller was doing.
class OnboardingPassPanel extends StatefulWidget {
  const OnboardingPassPanel({
    super.key,
    this.tripId,
    this.bookingId,
    this.notice,
    this.feature,
    this.freeLabel = 'Continue with free',
    this.confirmedLabel = 'Open my holiday',
    this.source,
    this.onConfirmed,
    required this.onDone,
  });
  final String? tripId;
  final String? bookingId;

  /// What they reached for (the paywall): its benefit leads.
  final PremiumFeature? feature;

  /// "Continue with free" in onboarding, "Not now" on the paywall.
  final String freeLabel;

  /// The button once a pass is bought: "Open my holiday" in onboarding,
  /// "Carry on" on the paywall.
  final String confirmedLabel;

  /// A pass was just bought, or restored: the stage cheers and says so
  /// (`passConfirmedWords`, `traviCuesForPassConfirmed`).
  final ValueChanged<PassConfirmation>? onConfirmed;

  /// Where the desk was opened from, for funnel analytics.
  final String? source;

  /// What just happened ("Signed in with Google…"), said quietly.
  final String? notice;

  /// Free, or a pass bought (or already held).
  final ValueChanged<OnboardingPassOutcome> onDone;

  @override
  State<OnboardingPassPanel> createState() => _OnboardingPassPanelState();
}

class _OnboardingPassPanelState extends State<OnboardingPassPanel> {
  OfferKind? _selected;
  bool _working = false;
  late String? _message = widget.notice;

  /// The pass just bought or restored, once it's on.
  PassConfirmation? _confirmed;

  @override
  void initState() {
    super.initState();
    track('onboarding_pass_desk_shown');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PremiumStore>().refreshOffers();
    });
  }

  @override
  void didUpdateWidget(OnboardingPassPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The holiday arrived (or changed): choose again for it, so a Holiday
    // Pass it can have is the one chosen.
    if (oldWidget.tripId != widget.tripId) _selected = null;
  }

  void _continue(OnboardingPassOutcome outcome) {
    track('onboarding_pass_desk_continued', {'outcome': outcome.name});
    widget.onDone(outcome);
  }

  void _confirm(PassConfirmation confirmation) {
    track('pass_confirmed', {
      'kind': confirmation.kind == OfferKind.tripPass ? 'holiday' : 'annual',
      'restored': confirmation.restored,
      'source': widget.source ?? 'onboarding',
    });
    setState(() {
      _confirmed = confirmation;
      _message = null;
    });
    widget.onConfirmed?.call(confirmation);
  }

  bool _validContext(TravelStore travel) {
    final plan = travel.plan(widget.tripId ?? '');
    return widget.tripId == null && widget.bookingId == null ||
        plan != null && (widget.bookingId == null || travel.booking(widget.bookingId!)?.tripId == widget.tripId);
  }

  Future<void> _buy() async {
    final premium = context.read<PremiumStore>();
    final travel = context.read<TravelStore>();
    final plan = travel.plan(widget.tripId ?? '');
    if (_working || premium.busy || !_validContext(travel)) return;
    if (premium.forTrip(plan).allowed) return _continue(OnboardingPassOutcome.upgraded);
    final kind = _selected;
    if (kind == null) return;
    final offer = premium.offer(kind);
    if (offer == null ||
        (offer.kind == OfferKind.tripPass && (plan == null || !premium.policy.canBuyTripPassFor(plan)))) {
      return;
    }
    setState(() {
      _working = true;
      _message = null;
    });
    final outcome = await premium.purchase(
      offer,
      tripPass: offer.kind == OfferKind.tripPass ? newTripPassFor(plan!) : null,
      source: widget.source ?? (widget.bookingId == null ? 'onboarding_holiday_started' : 'onboarding_booking_added'),
    );
    if (!mounted) return;
    setState(() => _working = false);
    switch (outcome) {
      case PurchaseOutcome.purchased:
        _confirm((kind: offer.kind, restored: false));
      case PurchaseOutcome.cancelled:
        break;
      case PurchaseOutcome.failed:
        setState(
          () => _message = 'That didn’t go through. Your holiday is still saved. Try again or continue with free.',
        );
      case PurchaseOutcome.pending:
        setState(() => _message = passPendingText);
    }
  }

  Future<void> _restore() async {
    final premium = context.read<PremiumStore>();
    if (_working || premium.busy) return;
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      await premium.restore();
      if (!mounted) return;
      final plan = context.read<TravelStore>().plan(widget.tripId ?? '');
      // A restore can be for another holiday. Check this holiday's access:
      // the traveller's own pass is confirmed like one just bought; access
      // shared from someone else's pass is never shown as theirs.
      final own = premium.policy.purchasedPassFor(plan);
      if (premium.forTrip(plan).allowed && own != null) return _confirm((kind: own, restored: true));
      setState(
        () => _message = premium.forTrip(plan).allowed
            ? 'Your pass is restored. Your holiday is ready.'
            : 'No active pass for this holiday was found. You can still continue with free.',
      );
    } catch (_) {
      if (mounted) setState(() => _message = 'Couldn’t restore purchases. Try again or continue with free.');
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumStore>();
    final travel = context.watch<TravelStore>();
    final plan = travel.plan(widget.tripId ?? '');
    if (_confirmed case final confirmed?) return _confirmation(confirmed, premium, plan);
    final validContext = _validContext(travel);
    final covered = validContext && premium.forTrip(plan).allowed;
    final pass = premium.offer(OfferKind.tripPass);
    final annual = premium.offer(OfferKind.plusAnnual);
    final canPass = validContext && !covered && pass != null && premium.policy.canBuyTripPassFor(plan);
    if (validContext && !covered && _selected == null && (pass != null || annual != null)) {
      _selected = canPass ? OfferKind.tripPass : OfferKind.plusAnnual;
    }
    final selected = validContext && !covered
        ? (_selected == OfferKind.tripPass ? (canPass ? pass : null) : annual)
        : null;
    final busy = _working || premium.busy;
    final ready = covered || !validContext;
    final terms = selected == null
        ? null
        : selected.kind == OfferKind.plusAnnual
        ? '${selected.displayTitle} renews at ${priceOf(selected)} each year until cancelled in your App Store or Google Play settings.'
        : '${selected.displayTitle} is one payment of ${priceOf(selected)}. It does not renew.';
    Widget fine(String text) => Text(
      text,
      textAlign: TextAlign.center,
      style: TravaryText.small.copyWith(color: OnboardingColors.navy),
    );
    final small = TextButton.styleFrom(
      minimumSize: const Size(44, 40),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      foregroundColor: OnboardingColors.navy,
      textStyle: TravaryText.small.copyWith(decoration: TextDecoration.underline),
    );
    // Under the passes: the passes, then what paying adds while there's
    // room for it. At the bottom, always on screen: the button, free, and
    // the small print's links. Nothing to scroll on a phone of today.
    final top = <Widget>[
      if (!ready) ...[
        if (canPass)
          _SlideIn(
            order: 0,
            child: OnboardingPaperPass(
              key: const ValueKey('onboarding-pass-holiday'),
              annual: false,
              selected: _selected == OfferKind.tripPass,
              title: pass.displayTitle,
              scope: pass.displayScope,
              price: priceOf(pass),
              onTap: busy
                  ? null
                  : () => setState(() {
                      _selected = OfferKind.tripPass;
                      _message = null;
                    }),
            ),
          ),
        if (annual != null)
          _SlideIn(
            order: canPass ? 1 : 0,
            child: OnboardingPaperPass(
              key: const ValueKey('onboarding-pass-annual'),
              annual: true,
              selected: _selected == OfferKind.plusAnnual,
              title: annual.displayTitle,
              scope: annual.displayScope,
              price: priceOf(annual),
              onTap: busy
                  ? null
                  : () => setState(() {
                      _selected = OfferKind.plusAnnual;
                      _message = null;
                    }),
            ),
          ),
        if (selected == null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              premium.offersLoading
                  ? 'Loading passes…'
                  : premium.offersError ?? 'Choose an available pass, or continue with free.',
              textAlign: TextAlign.center,
              style: TravaryText.body.copyWith(color: OnboardingColors.navy),
            ),
          ),
        if (premium.offersError != null)
          TextButton(
            key: const ValueKey('onboarding-pass-retry'),
            onPressed: busy ? null : premium.refreshOffers,
            child: const Text('Try again'),
          ),
        // Why there's no Holiday Pass for this holiday (none at all: nothing to say).
        if (!canPass && !premium.offersLoading && pass != null && plan != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: fine(
              premium.policy.isTooLongForTripPass(plan)
                  ? '${pass.displayTitle} covers trips of up to ${Pricing.tripPassMaxDays} days. Your longer holiday can use the ${annual?.displayTitle ?? 'Annual Pass'}.'
                  : '${pass.displayTitle} needs dates for a holiday that hasn’t ended. You can choose an available pass or continue with free.',
            ),
          ),
        // What paying adds, family first, as much as there's room for.
        for (final (i, line) in passBenefits(
          first: widget.feature,
          flightAlerts: PremiumFeature.flightAlerts.released,
        ).indexed)
          FitItem(
            keep: 50 - i * 10,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.check_rounded, size: 16, color: OnboardingColors.navy),
                  ),
                  Expanded(child: _Benefit(line)),
                ],
              ),
            ),
          ),
        if (plan != null && selected?.kind == OfferKind.tripPass)
          FitItem(
            keep: 5,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: fine(
                '${plan.trip.title} · ${formatDayMonthRange(plan.start!, plan.end!)}. '
                'It covers this holiday until ${formatDate(newTripPassFor(plan).lastDay)}. '
                'Covers a holiday of up to ${Pricing.tripPassMaxDays} days.',
              ),
            ),
          ),
      ] else
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            covered
                ? 'Your holiday is already covered. Let’s open your plan.'
                : 'Your saved plans are still here. Let’s open your holiday.',
            textAlign: TextAlign.center,
            style: TravaryText.body.copyWith(color: OnboardingColors.navy),
          ),
        ),
    ];
    final bottom = <Widget>[
      if (_message != null)
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Semantics(
            liveRegion: true,
            child: Text(
              _message!,
              textAlign: TextAlign.center,
              style: TravaryText.body.copyWith(color: OnboardingColors.navy),
            ),
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: PassDeskButton(
          key: const ValueKey('onboarding-pass-buy'),
          label: ready
              ? 'Open my holiday'
              : selected == null
              ? 'Choose a pass'
              : 'Get ${selected.displayTitle}',
          busy: busy,
          onPressed: ready
              ? () => _continue(covered ? OnboardingPassOutcome.upgraded : OnboardingPassOutcome.free)
              : selected == null
              ? null
              : _buy,
        ),
      ),
      // The passes above always say the title, price, period and whether it
      // renews (Apple's Schedule 2 §3.8(b), Google Play's subscriptions
      // policy); this spells it out again when there's room.
      if (terms != null)
        FitItem(
          keep: 25,
          child: Padding(padding: const EdgeInsets.only(top: 4), child: fine(terms)),
        ),
      if (premium.isTestStore)
        FitItem(
          keep: 1,
          child: Padding(padding: const EdgeInsets.only(top: 4), child: fine('Test store: nothing is charged.')),
        ),
      // Free first, then the small print's links: one line when they fit,
      // else free on its own above them.
      OverflowBar(
        alignment: MainAxisAlignment.center,
        overflowAlignment: OverflowBarAlignment.center,
        children: [
          if (!ready)
            TextButton(
              key: const ValueKey('onboarding-pass-free'),
              onPressed: busy ? null : () => _continue(OnboardingPassOutcome.free),
              style: small.copyWith(
                textStyle: WidgetStatePropertyAll(
                  TravaryText.title.copyWith(fontSize: 17, decoration: TextDecoration.underline),
                ),
              ),
              child: Text(widget.freeLabel),
            ),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                key: const ValueKey('onboarding-pass-restore'),
                onPressed: busy ? null : _restore,
                style: small,
                child: const Text('Restore', semanticsLabel: 'Restore purchases'),
              ),
              TextButton(
                key: const ValueKey('onboarding-pass-terms'),
                onPressed: busy ? null : () => openTravaryPage(context, TravaryLinks.terms),
                style: small,
                child: const Text('Terms of Use'),
              ),
              TextButton(
                key: const ValueKey('onboarding-pass-privacy'),
                onPressed: busy ? null : () => openTravaryPage(context, TravaryLinks.privacy),
                style: small,
                child: const Text('Privacy Policy'),
              ),
            ],
          ),
        ],
      ),
    ];
    return FitColumn(
      height: OnboardingFloorSpace.maybeOf(context) ?? double.infinity,
      bottomFrom: top.length,
      children: [...top, ...bottom],
    );
  }

  /// The pass just bought or restored: its foil badge stamped onto the
  /// floor, what it covers now, and the way back to what they were doing,
  /// where the desk's button was.
  Widget _confirmation(PassConfirmation confirmed, PremiumStore premium, TripPlan? plan) {
    final coverage = passCoverageFor(confirmed.kind, plan: plan, entitlements: premium.entitlements);
    final width = min(PassBadgeLayout.confirmedWidth, MediaQuery.sizeOf(context).width * .62);
    return FitColumn(
      height: OnboardingFloorSpace.maybeOf(context) ?? double.infinity,
      bottomFrom: 2,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: _StampIn(
            child: PassBadge(key: const ValueKey('pass-confirmed-badge'), kind: confirmed.kind, width: width),
          ),
        ),
        Semantics(
          liveRegion: true,
          child: Column(
            key: const ValueKey('pass-confirmed-coverage'),
            children: [
              Text(
                coverage.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TravaryText.title.copyWith(color: OnboardingColors.navy),
              ),
              const SizedBox(height: 2),
              Text(
                coverage.detail,
                textAlign: TextAlign.center,
                style: TravaryText.small.copyWith(color: OnboardingColors.navy),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 8),
          child: PassDeskButton(
            key: const ValueKey('pass-confirmed-done'),
            label: widget.confirmedLabel,
            busy: false,
            onPressed: () => _continue(OnboardingPassOutcome.upgraded),
          ),
        ),
      ],
    );
  }
}

/// A just-bought pass slapped onto the floor like a sticker: it lands from
/// a little above, a touch turned, and settles slightly askew. Reduced
/// motion: it's simply there.
class _StampIn extends StatelessWidget {
  const _StampIn({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduced ? 1 : 0, end: 1),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 560),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: (t * 2).clamp(0, 1),
        child: Transform.scale(
          scale: 1.35 - .35 * t,
          child: Transform.rotate(angle: -.14 + .12 * t, child: child),
        ),
      ),
      child: child,
    );
  }
}

/// A benefit on one line, a touch smaller if that's all it takes (down to
/// 90%), else wrapped: one line leaves room on the floor for the next.
class _Benefit extends StatelessWidget {
  const _Benefit(this.line);
  final String line;

  @override
  Widget build(BuildContext context) {
    final style = TravaryText.small.copyWith(color: OnboardingColors.navy);
    return LayoutBuilder(
      builder: (context, box) {
        final painter = TextPainter(
          text: TextSpan(text: line, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final oneLine = painter.width * .9 <= box.maxWidth;
        painter.dispose();
        if (!oneLine) return Text(line, style: style);
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(line, maxLines: 1, style: style),
        );
      },
    );
  }
}

/// A pass sliding up onto the floor, one after the other.
class _SlideIn extends StatelessWidget {
  const _SlideIn({required this.order, required this.child});
  final int order;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduced ? 1 : 0, end: 1),
      duration: reduced ? Duration.zero : Duration(milliseconds: 520 + order * 140),
      curve: Interval(order * .2, 1, curve: Curves.easeOutBack),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, (1 - t) * 40), child: child),
      ),
      child: Padding(padding: const EdgeInsets.only(bottom: 4), child: child),
    );
  }
}

/// The pass desk on its own, for a holiday brought into an existing
/// account (its sign-in rebuilt the app): the same stage, Travi presenting
/// the passes, and cheering once one is bought. Pops with the outcome, or
/// null for Back (once a pass is bought, Back is "upgraded" too).
class OnboardingPassScreen extends StatefulWidget {
  const OnboardingPassScreen({super.key, this.tripId, this.bookingId, this.notice});
  final String? tripId;
  final String? bookingId;
  final String? notice;

  @override
  State<OnboardingPassScreen> createState() => _OnboardingPassScreenState();
}

class _OnboardingPassScreenState extends State<OnboardingPassScreen> {
  PassConfirmation? _confirmed;

  void _back() => Navigator.of(context).pop(_confirmed == null ? null : OnboardingPassOutcome.upgraded);

  @override
  Widget build(BuildContext context) {
    final travel = context.watch<TravelStore>();
    final premium = context.watch<PremiumStore>();
    final plan = travel.plan(widget.tripId ?? '');
    final confirmed = _confirmed;
    return PopScope(
      canPop: confirmed == null,
      onPopInvokedWithResult: (popped, _) {
        if (!popped) _back();
      },
      child: OnboardingStageLayout(
        scene: OnboardingScene(
          stage: onboardingStage(plan?.trip.destination),
          cues: confirmed == null ? traviCuesFor(OnboardingBeat.desk) : traviCuesForPassConfirmed(),
        ),
        words: confirmed == null
            ? onboardingWordsFor(OnboardingBeat.desk, covered: plan != null && premium.forTrip(plan).allowed)
            : passConfirmedWords(confirmed.kind, restored: confirmed.restored),
        wordsKey: confirmed == null ? 'desk' : 'desk-confirmed',
        onBack: _back,
        backEnabled: !premium.busy,
        backTooltip: 'Back to your saved booking',
        backKey: 'onboarding-pass-back',
        snugFloor: true,
        floor: OnboardingPassPanel(
          tripId: widget.tripId,
          bookingId: widget.bookingId,
          notice: widget.notice,
          onConfirmed: (confirmation) => setState(() => _confirmed = confirmation),
          onDone: (outcome) => Navigator.of(context).pop(outcome),
        ),
      ),
    );
  }
}
