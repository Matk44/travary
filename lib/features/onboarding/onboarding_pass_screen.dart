import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/purchase_service.dart';
import '../../design/tokens.dart';
import '../../design/widgets/onboarding_pass_desk.dart';
import '../../design/widgets/onboarding_scene.dart';
import '../../domain/domain.dart';
import '../../logic/access.dart';
import '../../logic/formatters.dart';
import '../../logic/onboarding_art.dart';
import '../../logic/onboarding_films.dart';
import '../../logic/onboarding_journey.dart';
import '../../logic/price_text.dart';
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
class OnboardingPassPanel extends StatefulWidget {
  const OnboardingPassPanel({super.key, this.tripId, this.bookingId, this.notice, required this.onDone});
  final String? tripId;
  final String? bookingId;

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

  @override
  void initState() {
    super.initState();
    track('onboarding_pass_desk_shown');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<PremiumStore>().refreshOffers();
    });
  }

  void _continue(OnboardingPassOutcome outcome) {
    track('onboarding_pass_desk_continued', {'outcome': outcome.name});
    widget.onDone(outcome);
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
      source: widget.bookingId == null ? 'onboarding_holiday_started' : 'onboarding_booking_added',
    );
    if (!mounted) return;
    setState(() => _working = false);
    switch (outcome) {
      case PurchaseOutcome.purchased:
        _continue(OnboardingPassOutcome.upgraded);
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
      // A restore can be for another holiday. Check this holiday's access.
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
    final link = TextButton.styleFrom(
      minimumSize: const Size(44, 44),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      foregroundColor: OnboardingColors.navy,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          const SizedBox(height: 6),
          Text(
            'Smart Import  ·  Shared plans  ·  Ticket backup',
            textAlign: TextAlign.center,
            style: TravaryText.small.copyWith(color: OnboardingColors.navy),
          ),
          const SizedBox(height: 8),
        ] else
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              covered
                  ? 'Your holiday already has Plus. Let’s open your plan.'
                  : 'Your saved plans are still here. Let’s open your holiday.',
              textAlign: TextAlign.center,
              style: TravaryText.body.copyWith(color: OnboardingColors.navy),
            ),
          ),
        PassDeskButton(
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
        if (!ready)
          TextButton(
            key: const ValueKey('onboarding-pass-free'),
            onPressed: busy ? null : () => _continue(OnboardingPassOutcome.free),
            style: link.copyWith(
              textStyle: WidgetStatePropertyAll(
                TravaryText.title.copyWith(fontSize: 17, decoration: TextDecoration.underline),
              ),
            ),
            child: const Text('Continue with free'),
          ),
        TextButton(
          key: const ValueKey('onboarding-pass-restore'),
          onPressed: busy ? null : _restore,
          style: link.copyWith(
            textStyle: WidgetStatePropertyAll(TravaryText.small.copyWith(decoration: TextDecoration.underline)),
          ),
          child: const Text('Restore purchases'),
        ),
        if (_message != null)
          Semantics(
            liveRegion: true,
            child: Text(
              _message!,
              textAlign: TextAlign.center,
              style: TravaryText.body.copyWith(color: OnboardingColors.navy),
            ),
          ),
        if (!ready && plan != null && selected?.kind == OfferKind.tripPass)
          Text(
            '${plan.trip.title} · ${formatDayMonthRange(plan.start!, plan.end!)}. '
            'Plus stays on until ${formatDate(newTripPassFor(plan).lastDay)}. '
            'Covers a holiday of up to ${Pricing.tripPassMaxDays} days.',
            style: TravaryText.small.copyWith(color: OnboardingColors.navy),
            textAlign: TextAlign.center,
          ),
        if (!ready && !canPass && !premium.offersLoading && pass != null)
          Text(
            premium.policy.isTooLongForTripPass(plan)
                ? '${pass.displayTitle} covers trips of up to ${Pricing.tripPassMaxDays} days. Your longer holiday can use ${annual?.displayTitle ?? 'Annual Pass'}.'
                : '${pass.displayTitle} needs dates for a holiday that hasn’t ended. You can choose an available pass or continue with free.',
            style: TravaryText.small.copyWith(color: OnboardingColors.navy),
            textAlign: TextAlign.center,
          ),
        if (terms != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              terms,
              textAlign: TextAlign.center,
              style: TravaryText.small.copyWith(color: OnboardingColors.navy),
            ),
          ),
        if (premium.isTestStore)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'Test store: nothing is charged.',
              textAlign: TextAlign.center,
              style: TravaryText.small.copyWith(color: OnboardingColors.navy),
            ),
          ),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton(
              key: const ValueKey('onboarding-pass-terms'),
              onPressed: busy ? null : () => openTravaryPage(context, TravaryLinks.terms),
              style: TextButton.styleFrom(textStyle: TravaryText.small, foregroundColor: OnboardingColors.navy),
              child: const Text('Terms of Use'),
            ),
            TextButton(
              onPressed: busy ? null : () => openTravaryPage(context, TravaryLinks.privacy),
              style: TextButton.styleFrom(textStyle: TravaryText.small, foregroundColor: OnboardingColors.navy),
              child: const Text('Privacy Policy'),
            ),
          ],
        ),
      ],
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
      child: Padding(padding: const EdgeInsets.only(bottom: 8), child: child),
    );
  }
}

/// The pass desk on its own, for a holiday brought into an existing
/// account (its sign-in rebuilt the app): the same stage, Travi presenting
/// the passes. Pops with the outcome, or null for Back.
class OnboardingPassScreen extends StatelessWidget {
  const OnboardingPassScreen({super.key, this.tripId, this.bookingId, this.notice});
  final String? tripId;
  final String? bookingId;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final travel = context.watch<TravelStore>();
    final premium = context.watch<PremiumStore>();
    final plan = travel.plan(tripId ?? '');
    return OnboardingStageLayout(
      scene: OnboardingScene(stage: onboardingStage(plan?.trip.destination), cues: traviCuesFor(OnboardingBeat.desk)),
      words: onboardingWordsFor(OnboardingBeat.desk, covered: plan != null && premium.forTrip(plan).allowed),
      wordsKey: 'desk',
      onBack: () => Navigator.of(context).pop(),
      backEnabled: !premium.busy,
      backTooltip: 'Back to your saved booking',
      backKey: 'onboarding-pass-back',
      floor: OnboardingPassPanel(
        tripId: tripId,
        bookingId: bookingId,
        notice: notice,
        onDone: (outcome) => Navigator.of(context).pop(outcome),
      ),
    );
  }
}
