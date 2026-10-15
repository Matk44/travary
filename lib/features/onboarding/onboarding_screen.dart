import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/smart_import_service.dart';
import '../../design/cards/booking_card.dart';
import '../../design/tokens.dart';
import '../../design/widgets/countdown_trip_hero.dart';
import '../../design/widgets/holiday_dates_sheet.dart';
import '../../design/widgets/ledger.dart';
import '../../design/widgets/onboarding_folio.dart';
import '../../design/widgets/onboarding_scene.dart';
import '../../design/widgets/travi_player.dart';
import '../../domain/domain.dart';
import '../../domain/onboarding.dart';
import '../../logic/ai_consent.dart';
import '../../logic/card_text.dart';
import '../../logic/countdown_text.dart';
import '../../logic/day_plan.dart';
import '../../logic/onboarding_art.dart';
import '../../logic/onboarding_films.dart';
import '../../logic/onboarding_journey.dart';
import '../../logic/onboarding_rules.dart';
import '../../logic/trip_plan.dart';
import '../../state/analytics.dart';
import '../../state/app_session.dart';
import '../../state/onboarding_store.dart';
import '../../state/premium_store.dart';
import '../../state/travel_store.dart';
import '../account/sign_in_sheet.dart';
import '../ai/ai_consent_sheet.dart';
import '../booking/booking_actions.dart';
import '../booking/edit_booking_screen.dart';
import '../import/smart_import_screen.dart';
import '../premium/premium_gate.dart';
import '../sharing/join_trip_sheet.dart';
import '../trips/place_picker_sheet.dart';
import 'onboarding_account_screen.dart';
import 'onboarding_pass_screen.dart';
import 'onboarding_route.dart';
import 'onboarding_stage_layout.dart';

/// After the first booking: the optional sign-in, then the pass desk, then
/// off into the holiday, on the same stage.
enum _Offer { account, signedIn, desk, sendoff }

/// Onboarding as one continuous animated story
/// (`docs/onboarding/STORYBOARD_V2.md`): Travi rolls into the paper
/// workshop, the chosen place folds up behind him, he flicks the dates'
/// tag to the traveller, reads their booking, tosses its card into Day 1,
/// offers sign-in and the passes, and hands over the folio that opens into
/// the holiday. The camera never moves; every move is a film between his
/// key frames (`TraviPlayer`), and what he throws lands as live UI. Booking
/// forms, pickers and sign-in sheets slide over the stage and drop back
/// onto it. Decorative motion never holds up data, pickers or services.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinished});
  final ValueChanged<String?> onFinished;
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final OnboardingStore _setup;
  late final TravelStore _travel;
  late final bool _rollIn;
  Booking? _saved;
  bool _busy = false;
  bool _choosingDates = false;
  String? _error;
  _Offer? _offer;
  bool _email = false;

  /// The desk came straight after the booking: no sign-in was offered.
  bool _signInSkipped = false;

  // Travi's side of the story.
  TraviPose? _resting;
  bool _folioUp = false;
  bool _reading = false;
  String? _misread;
  ({String path, String name})? _misreadFile;
  bool _tagPending = false;
  bool _dayPending = false;
  bool _fresh = false;
  bool _bought = false;
  TraviPose? _awaiting;
  Completer<void>? _arrival;
  Timer? _sendoff;

  @override
  void initState() {
    super.initState();
    _setup = context.read<OnboardingStore>();
    _travel = context.read<TravelStore>()..addListener(_syncError);
    // A first visit starts with the roll-in; a resumed one where it left off.
    _rollIn = _setup.draft.step == OnboardingStep.destination && _setup.draft.bookingId == null;
  }

  void _syncError() {
    if (!mounted || _travel.error == null) return;
    final message = _travel.error!;
    _travel.clearError();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _sendoff?.cancel();
    _travel.removeListener(_syncError);
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) {
        setState(() {
          _reading = false;
          _error = 'Couldn’t finish that step. Your saved plans are still here. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _acting => TraviPlayer.playback && !MediaQuery.disableAnimationsOf(context);

  /// Travi comes to rest on [pose] (and the story moves on where it waits
  /// for him).
  void _onPose(TraviPose? pose) {
    if (!mounted) return;
    setState(() => _resting = pose);
    if (pose == null) return;
    if (pose == _awaiting) {
      _awaiting = null;
      _arrival?.complete();
      _arrival = null;
    }
    if (const {TraviPose.toss, TraviPose.folioOpen, TraviPose.reading}.contains(pose)) {
      setState(() => _tagPending = false);
    }
    if (const {TraviPose.toss, TraviPose.proud}.contains(pose) && _dayPending) {
      setState(() => _dayPending = false);
    }
    if (pose == TraviPose.linked && _offer == _Offer.signedIn) {
      setState(() => _offer = _Offer.desk);
    }
    if (pose == TraviPose.folioFull && _offer == _Offer.sendoff) {
      _sendoff?.cancel();
      _run(_completeHoliday);
    }
  }

  /// What he threw has left the frame: its live version takes over.
  void _onHandoff(TraviFilm film) {
    if (!mounted) return;
    setState(() {
      if (film.from == TraviPose.tag) _tagPending = false;
      if (film.from == TraviPose.card) _dayPending = false;
    });
  }

  /// Travi lifts the folio up to the camera; a form opens out of it.
  Future<void> _folioToCamera() async {
    if (!_acting) return;
    final arrived = Completer<void>();
    setState(() {
      _folioUp = true;
      _awaiting = TraviPose.folioFull;
      _arrival = arrived;
    });
    await arrived.future.timeout(const Duration(milliseconds: 2600), onTimeout: () {});
  }

  void _folioDown() {
    if (!mounted) return;
    setState(() {
      _folioUp = false;
      _awaiting = null;
      _arrival = null;
    });
  }

  Future<void> _destination() => _run(() async {
    final place = await showPlacePicker(
      context,
      title: 'Where are we off to?',
      subtitle: 'Choose your holiday destination.',
    );
    if (!mounted || place == null) return;
    await _setup.save(_setup.draft.copyWith(destination: place.destination, step: OnboardingStep.dates));
    track('onboarding_destination_chosen');
  });

  bool get _sharingAvailable => _travel.sharingAvailable;

  /// Both dates in one sheet; choosing them goes straight on to the booking.
  Future<void> _chooseDates() async {
    // Busy only while saving, so nothing spins behind the open sheet.
    if (_busy || _choosingDates) return;
    _choosingDates = true;
    final draft = _setup.draft;
    final today = _travel.today;
    final picked = await showHolidayDates(
      context,
      today: today,
      start: draft.start,
      end: draft.end,
      // Someone may already be away: the days behind them are theirs too,
      // as in Trip details. It still opens on this month.
      first: today.addDays(-365),
    );
    _choosingDates = false;
    if (picked == null || !mounted) return;
    await _run(() async {
      await _setup.save(_setup.draft.copyWith(start: picked.start, end: picked.end));
      await _startHoliday(dated: true);
    });
  }

  Future<void> _undated() => _run(() => _startHoliday(dated: false));

  Future<void> _startHoliday({required bool dated}) async {
    // He flicks the tag to the traveller; the live one lands as it leaves.
    if (_acting) setState(() => _tagPending = true);
    await _setup.save(_setup.draft.copyWith(step: OnboardingStep.booking, clearDates: !dated));
    await _setup.ensureHoliday(_travel);
    track('onboarding_holiday_started', {'dates_set': dated});
  }

  Future<void> _record(SaveResult result, OnboardingBookingSource source) async {
    // Keep the actual return value even while the repository stream echoes it.
    _saved = result.booking;
    await _setup.recordBooking(result, _travel, source: source);
    // He shows its card, then tosses it into Day 1.
    if (mounted) {
      setState(() {
        _fresh = true;
        _dayPending = _acting;
      });
    }
    track('onboarding_booking_added', {'kind': result.booking.kind.name, 'source': source.name});
  }

  Future<void> _manual() => _run(() async {
    setState(() => _misread = null);
    track('onboarding_booking_started', {'source': 'manual'});
    final trip = _setup.draft.destination == null ? null : await _setup.ensureHoliday(_travel);
    if (!mounted) return;
    await _folioToCamera();
    if (!mounted) return;
    final result = await Navigator.of(context).push<SaveResult>(
      onboardingFolioRoute(
        (_) => _BookingKinds(initialDate: _setup.draft.start, tripId: trip?.id, holiday: _setup.draft.holiday),
      ),
    );
    if (result != null) await _record(result, OnboardingBookingSource.manual);
    _folioDown();
  });

  /// The file is read on the stage while Travi studies it, then checked in
  /// the folio. [again]: the file that couldn't be read, once more.
  Future<void> _import({({String path, String name})? again}) => _run(() async {
    track('onboarding_booking_started', {'source': 'smartImport'});
    final trip = _setup.draft.destination == null ? null : await _setup.ensureHoliday(_travel);
    if (!mounted) return;
    final access = await requirePremium(
      context,
      PremiumFeature.smartImport,
      trip: trip == null ? null : _travel.plan(trip.id),
      source: 'onboarding',
    );
    if (access == null || !mounted) return;
    // Nothing goes to Google's AI without their OK (Travi is already on
    // the stage, so the sheet comes without him).
    if (again == null && !await askAiConsent(context, AiAsk.smartImport, travi: false)) return;
    if (!mounted) return;
    // Opens immediately; no animation delay before the platform picker.
    final file = again ?? await pickFile(context, title: 'Bring in your booking');
    if (file == null || !mounted) return;
    setState(() {
      _reading = true;
      _misread = null;
    });
    final SmartImportResult found;
    try {
      final service = context.read<SmartImportService>();
      found = await readWithPass(
        context,
        (tripId) => service.read(file.path, today: _travel.today, tripId: tripId),
        access: access,
        trip: trip == null ? null : _travel.plan(trip.id),
        source: 'onboarding',
      );
    } on SmartImportException catch (e) {
      track('smart_import_failed', {'reason': e.message});
      if (mounted) {
        setState(() {
          _reading = false;
          _misread = e.message;
          _misreadFile = file;
        });
      }
      return;
    }
    if (!mounted) return;
    if (found.drafts.isEmpty) {
      setState(() {
        _reading = false;
        _misread = found.warning ?? 'There’s no booking I can see in that. Try a clearer screenshot, or type it in.';
        _misreadFile = null;
      });
      return;
    }
    // "Got it": he tucks it into the folio while the check opens over him.
    setState(() => _reading = false);
    final outcome = await Navigator.of(context).push<SmartImportOutcome>(
      onboardingFolioRoute(
        (_) => SmartImportScreen(
          filePath: file.path,
          fileName: file.name,
          access: access,
          tripId: trip?.id,
          onboardingHoliday: _setup.draft.holiday,
          initialResult: found,
        ),
      ),
    );
    if (outcome == null || !mounted) return;
    if (outcome.results.isNotEmpty) {
      await _record(outcome.results.first, OnboardingBookingSource.smartImport);
    }
    if (outcome.addManually) {
      // Release the action lock before starting another deliberate route.
      setState(() => _busy = false);
      await _manual();
    }
  });

  Future<void> _joinHoliday() async {
    final joined = await showJoinTripSheet(context);
    if (joined == null || !mounted) return;
    await _setup.complete();
    if (mounted) widget.onFinished(joined.tripId);
  }

  /// Every way on from a new holiday (its first booking saved, or bookings
  /// for later) visits the optional sign-in and then the pass desk, which
  /// keeps "Continue with free". All on this stage.
  void _sortTheRest() {
    if (_busy) return;
    final saved = _travel.booking(_setup.draft.bookingId ?? '') ?? _saved;
    track('onboarding_offer_requested', {
      'has_booking': saved != null,
      'booking_source': _setup.draft.bookingSource?.name ?? 'unknown',
    });
    final session = context.read<AppSession?>();
    final ask =
        session != null &&
        session.canSignIn &&
        session.account?.isGuest != false &&
        SignInMethod.values.any(session.supports);
    setState(() {
      _offer = ask ? _Offer.account : _Offer.desk;
      _signInSkipped = !ask;
      _email = false;
      _misread = null;
      _fresh = false;
      _dayPending = false;
    });
  }

  /// He tucks the tag into the folio, then presents the passes.
  void _signedIn() => setState(() => _offer = _Offer.signedIn);

  void _passChosen(OnboardingPassOutcome outcome) {
    // A cheer if they bought one, a wave, and the folio opens into the
    // holiday ([_onPose] finishes when it's up).
    setState(() {
      _bought = outcome == OnboardingPassOutcome.upgraded;
      _offer = _Offer.sendoff;
    });
    _sendoff = Timer(const Duration(seconds: 10), () {
      if (mounted) _run(_completeHoliday);
    });
  }

  void _back() {
    context.read<AppSession?>()?.cancelEmailLink();
    setState(() {
      _offer = null;
      _email = false;
    });
  }

  /// Whether the phone's Back button has a step to go to here: the dates
  /// and booking steps, before a booking is saved.
  bool _stepsBack(OnboardingDraft draft, Booking? saved) =>
      _offer == null && saved == null && stepBackFrom(draft.step) != null;

  /// One step toward the start. A booking that couldn't be read goes back
  /// to asking for one.
  Future<void> _stepBack() async {
    if (_busy || _reading) return;
    if (_misread != null) return setState(() => _misread = null);
    await _run(() async => await _setup.stepBack(_travel));
  }

  Future<void> _completeHoliday() async {
    _sendoff?.cancel();
    final saved = _travel.booking(_setup.draft.bookingId ?? '') ?? _saved;
    final trip = saved != null || _setup.draft.destination == null ? null : await _setup.ensureHoliday(_travel);
    await _setup.complete();
    track('onboarding_completed', {'has_booking': saved != null});
    if (mounted) widget.onFinished(saved?.tripId ?? trip?.id ?? _setup.draft.tripId);
  }

  /// "Sign in" on the first screen: a returning traveller on a new phone. An
  /// existing account rebuilds the app straight into their plans; a new
  /// one carries on here.
  Future<void> _signIn() => _run(() async {
    final message = await showSignInSheet(context);
    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$message Let’s plan your first holiday.')));
    }
  });

  OnboardingBeat _beatFor(OnboardingDraft draft, Booking? saved) => switch (_offer) {
    _Offer.sendoff => OnboardingBeat.sendoff,
    _Offer.desk => OnboardingBeat.desk,
    _Offer.signedIn => OnboardingBeat.signedIn,
    _Offer.account => _email ? OnboardingBeat.email : OnboardingBeat.account,
    null when saved != null => OnboardingBeat.proof,
    null when draft.step == OnboardingStep.destination => OnboardingBeat.arrival,
    null when draft.step == OnboardingStep.dates => OnboardingBeat.dates,
    null when _reading => OnboardingBeat.reading,
    null when _misread != null => OnboardingBeat.misread,
    null => OnboardingBeat.booking,
  };

  @override
  Widget build(BuildContext context) {
    final draft = context.watch<OnboardingStore>().draft;
    final travel = context.watch<TravelStore>();
    final premium = context.watch<PremiumStore>();
    final session = context.watch<AppSession?>();
    final saved = travel.booking(draft.bookingId ?? '') ?? _saved;
    final plan = travel.plan(saved?.tripId ?? draft.tripId ?? '');
    final covered = plan != null && premium.forTrip(plan).allowed;
    final beat = _beatFor(draft, saved);
    final destination = plan?.trip.destination ?? draft.destination;
    final countdown = plan == null ? null : countdownTextFor(plan, travel.today);
    final words = onboardingWordsFor(
      beat,
      place: destination?.name,
      emailSent: session?.emailLinkSentTo != null,
      covered: covered,
      problem: _misread,
      day: saved == null ? null : plan?.dayNumber(saved.startDate),
    );
    final arrival = beat == OnboardingBeat.arrival;
    final tagBeats = const {OnboardingBeat.booking, OnboardingBeat.reading, OnboardingBeat.misread};
    final stepsBack = _stepsBack(draft, saved);
    return PopScope(
      canPop: _offer == null && !stepsBack,
      onPopInvokedWithResult: (popped, _) {
        if (popped) return;
        if (_offer == _Offer.account || _offer == _Offer.desk) {
          _back();
        } else if (stepsBack) {
          _stepBack();
        }
      },
      child: OnboardingStageLayout(
        scene: OnboardingScene(
          stage: arrival ? onboardingWorkshopStage : onboardingStage(destination),
          cues: _folioUp
              ? const [(pose: TraviPose.folioFull, hold: Duration.zero, direct: false)]
              : traviCuesFor(beat, bought: _bought, fresh: _fresh, signInSkipped: _signInSkipped),
          start: _rollIn ? TraviPose.empty : null,
          // He holds still under sheets and screens.
          active: ModalRoute.isCurrentOf(context) ?? true,
          onPose: _onPose,
          onHandoff: _onHandoff,
          overlay: switch (beat) {
            // The booking on the card he holds up, fading as he winds up the throw.
            OnboardingBeat.proof when saved != null && _fresh => (context, width) => AnimatedOpacity(
              opacity: _resting == TraviPose.card ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              child: ProofCardWords(text: cardTextForBooking(saved), width: width),
            ),
            _ when tagBeats.contains(beat) && countdown != null && !_tagPending => (context, width) => _DepartureTag(
              key: ValueKey(countdown.dates),
              text: countdown,
              width: width,
            ),
            _ => null,
          },
        ),
        words: words,
        wordsKey: '$beat-${session?.emailLinkSentTo}-$_misread',
        floorKey: beat == OnboardingBeat.email ? OnboardingBeat.account : beat,
        snugFloor: beat == OnboardingBeat.desk,
        onBack: _offer == _Offer.account || _offer == _Offer.desk ? _back : null,
        backEnabled: !premium.busy && session?.isBusy != true,
        backTooltip: _offer == _Offer.desk ? 'Back to your saved booking' : 'Back to your holiday',
        backKey: _offer == _Offer.desk ? 'onboarding-pass-back' : 'onboarding-account-back',
        topRight: switch (beat) {
          OnboardingBeat.arrival when session != null && session.canSignIn && session.account?.isGuest != false =>
            _TopLink(
              key: const ValueKey('onboarding-have-account'),
              label: 'Sign in',
              onPressed: _busy ? null : _signIn,
            ),
          OnboardingBeat.signedIn => _TopLink(
            key: const ValueKey('onboarding-account-skip-motion'),
            label: 'Skip',
            onPressed: () => setState(() => _offer = _Offer.desk),
          ),
          _ => null,
        },
        floor: _floor(beat, draft, saved, plan, covered, premium),
      ),
    );
  }

  Widget _floor(
    OnboardingBeat beat,
    OnboardingDraft draft,
    Booking? saved,
    TripPlan? plan,
    bool covered,
    PremiumStore premium,
  ) {
    final error = _error == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_error!, style: TravaryText.body.copyWith(color: OnboardingColors.coralInk)),
          );
    final quiet = TextButton.styleFrom(foregroundColor: OnboardingColors.navy);
    final manual = OutlinedButton(
      key: const ValueKey('onboarding-manual'),
      onPressed: _busy ? null : _manual,
      style: OutlinedButton.styleFrom(
        foregroundColor: OnboardingColors.navy,
        side: const BorderSide(color: OnboardingColors.navy),
        minimumSize: const Size.fromHeight(46),
      ),
      child: const Text('Type it in myself'),
    );
    final later = TextButton(
      key: const ValueKey('onboarding-later'),
      onPressed: _busy ? null : _sortTheRest,
      style: quiet,
      child: const Text('I’ll add bookings later'),
    );
    switch (beat) {
      case OnboardingBeat.arrival:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?error,
            TicketButton(
              key: const ValueKey('onboarding-destination'),
              label: 'Choose my destination',
              icon: Icons.place_outlined,
              busy: _busy,
              onPressed: _destination,
            ),
            // Family who were sent a code (the link didn't come through the
            // install) join here, in plain sight, not in the destinations.
            if (_sharingAvailable)
              TextButton(
                key: const ValueKey('onboarding-join'),
                // The sheet itself blocks a second tap; nothing spins behind it.
                onPressed: _busy ? null : _joinHoliday,
                style: quiet,
                child: const Text('Joining someone’s holiday? Enter their code'),
              ),
          ],
        );
      case OnboardingBeat.dates:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?error,
            TicketButton(
              key: const ValueKey('onboarding-choose-dates'),
              label: 'Choose my dates',
              icon: Icons.calendar_month_outlined,
              busy: _busy,
              onPressed: _chooseDates,
            ),
            TextButton(
              key: const ValueKey('onboarding-no-dates'),
              onPressed: _busy ? null : _undated,
              style: quiet,
              child: const Text('Dates not decided'),
            ),
            TextButton(
              onPressed: _busy ? null : () => _run(() => _setup.save(draft.copyWith(step: OnboardingStep.destination))),
              style: quiet,
              child: const Text('Change destination'),
            ),
          ],
        );
      case OnboardingBeat.booking:
        final freeImports = premium.policy.freeSmartImportsLeft;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?error,
            TicketButton(
              key: const ValueKey('onboarding-import'),
              label: 'Smart Import',
              icon: Icons.file_present_outlined,
              busy: _busy,
              onPressed: _import,
            ),
            if (freeImports > 0 && !(plan != null && premium.forTrip(plan).allowed))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '$freeImports free Smart Imports to start.',
                  textAlign: TextAlign.center,
                  style: TravaryText.small.copyWith(color: OnboardingColors.navy),
                ),
              ),
            const SizedBox(height: 8),
            manual,
            later,
          ],
        );
      case OnboardingBeat.reading:
        return Semantics(
          liveRegion: true,
          label: 'Reading your booking',
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator(color: OnboardingColors.navy)),
          ),
        );
      case OnboardingBeat.misread:
        final file = _misreadFile;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?error,
            TicketButton(
              key: const ValueKey('onboarding-import-again'),
              label: file != null ? 'Try again' : 'Choose another file',
              icon: Icons.file_present_outlined,
              busy: _busy,
              onPressed: () => _import(again: file),
            ),
            const SizedBox(height: 8),
            manual,
            later,
          ],
        );
      case OnboardingBeat.proof:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?error,
            if (saved != null && !_dayPending) ...[
              // The card he tossed, landed in the plan.
              _LandedCard(booking: saved),
              const SizedBox(height: 12),
            ],
            if (!covered)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  draft.bookingSource == OnboardingBookingSource.smartImport
                      ? 'Read, checked and in your plan. I can do the rest the same way.'
                      : 'It’s in your plan. Got more confirmations? I’ll sort those too.',
                  textAlign: TextAlign.center,
                  style: TravaryText.body.copyWith(color: OnboardingColors.navy),
                ),
              ),
            TicketButton(
              key: const ValueKey('onboarding-see-passes'),
              // Says where it goes: the passes (after the optional sign-in).
              label: covered ? 'Continue' : 'See how I can help',
              busy: _busy,
              onPressed: _sortTheRest,
            ),
            if (saved != null && saved.attachments.isNotEmpty)
              TextButton(
                key: const ValueKey('onboarding-open-confirmation'),
                onPressed: _busy ? null : () => showTickets(context, saved),
                style: quiet,
                child: const Text('Open the confirmation'),
              ),
          ],
        );
      case OnboardingBeat.account || OnboardingBeat.email:
        return OnboardingAccountPanel(
          key: const ValueKey('onboarding-account'),
          tripId: plan?.id ?? draft.tripId,
          hasBooking: saved != null,
          onSignedIn: _signedIn,
          onGuest: () => setState(() => _offer = _Offer.desk),
          onEmail: (email) => setState(() => _email = email),
        );
      case OnboardingBeat.signedIn:
        return Semantics(
          liveRegion: true,
          child: Row(
            key: const ValueKey('onboarding-account-signed-in'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 15,
                backgroundColor: OnboardingColors.navy,
                child: Icon(Icons.check_rounded, size: 18, color: OnboardingColors.paper),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text('Signed in', style: TravaryText.title.copyWith(color: OnboardingColors.navy)),
              ),
            ],
          ),
        );
      case OnboardingBeat.desk:
        return OnboardingPassPanel(
          key: const ValueKey('onboarding-desk'),
          tripId: saved?.tripId ?? draft.tripId,
          bookingId: saved?.id,
          onDone: _passChosen,
        );
      case OnboardingBeat.sendoff:
        return const SizedBox(height: 48);
    }
  }
}

/// The saved booking as a row of the holiday's plan, dropping in where
/// Travi's tossed card lands.
class _LandedCard extends StatelessWidget {
  const _LandedCard({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final travel = context.read<TravelStore>();
    final reduced = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduced ? 1 : 0, end: 1),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, -60 * (1 - t)),
          child: Transform.rotate(angle: (1 - t) * -.08, child: child),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: OnboardingColors.paper,
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [BoxShadow(color: Color(0x33442A14), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: BookingCard(
          key: ValueKey('onboarding-landed-${booking.id}'),
          text: cardTextForLedger(booking),
          art: travel.artFor(booking),
          size: CardSize.ledger,
          status: bookingStatus(booking, travel.now),
        ),
      ),
    );
  }
}

/// A quiet link in the sky's top corner ("Sign in", "Skip").
class _TopLink extends StatelessWidget {
  const _TopLink({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: OnboardingColors.paper,
      backgroundColor: OnboardingColors.sky.withValues(alpha: .55),
      minimumSize: const Size(44, 36),
      shape: const StadiumBorder(),
    ),
    child: Text(label),
  );
}

/// The holiday's luggage tag, the same one Today's countdown wears, slapped
/// onto the stage beside Travi once the dates are set, swinging to rest.
class _DepartureTag extends StatelessWidget {
  const _DepartureTag({super.key, required this.text, required this.width});
  final CountdownText text;
  final double width;

  // Where it hangs in the poses' canvas: over the scenery, above the folio.
  static const _rect = Rect.fromLTWH(40, 420, 250, 375);

  @override
  Widget build(BuildContext context) {
    final rect = onboardingCanvasRect(_rect, width);
    final reduced = MediaQuery.disableAnimationsOf(context);
    const eyelet = CountdownGeometry.eyelet;
    return Stack(
      children: [
        Positioned.fromRect(
          rect: rect,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: reduced ? 1 : 0, end: 1),
            duration: reduced ? Duration.zero : const Duration(milliseconds: 1800),
            builder: (context, t, child) {
              final slap = Curves.easeIn.transform((t / .2).clamp(0, 1));
              return Opacity(
                opacity: slap,
                child: Transform.translate(
                  offset: Offset(0, -24 * (1 - slap)),
                  child: Transform.rotate(
                    angle: CountdownTripHero.tagDegrees(t) * math.pi / 180,
                    alignment: Alignment(eyelet.dx * 2 - 1, eyelet.dy * 2 - 1),
                    child: child,
                  ),
                ),
              );
            },
            child: CountdownLuggageTag(text: text),
          ),
        ),
      ],
    );
  }
}

class _BookingKinds extends StatefulWidget {
  const _BookingKinds({required this.holiday, this.tripId, this.initialDate});
  final OnboardingHoliday holiday;
  final String? tripId;
  final LocalDate? initialDate;
  @override
  State<_BookingKinds> createState() => _BookingKindsState();
}

class _BookingKindsState extends State<_BookingKinds> {
  bool _opening = false;

  /// "Something else": the rest of the kinds, in the same list.
  bool _more = false;

  static const _first = [
    (BookingKind.flight, Icons.flight_takeoff_outlined, 'Find it by number and date'),
    (BookingKind.stay, Icons.bed_outlined, 'Give your check-in a home'),
    (BookingKind.activity, Icons.confirmation_number_outlined, 'Something to look forward to'),
  ];

  static const _rest = [
    (BookingKind.attraction, Icons.attractions_outlined, 'Park, museum or sight tickets'),
    (BookingKind.dining, Icons.restaurant_outlined, 'A table you’ve booked'),
    (BookingKind.transport, Icons.directions_transit_outlined, 'A transfer, train or hire car'),
    (BookingKind.event, Icons.theater_comedy_outlined, 'A show, match or concert'),
    (BookingKind.note, Icons.sticky_note_2_outlined, 'Anything to remember'),
  ];

  Future<void> _choose(BookingKind kind) async {
    if (_opening) return;
    setState(() => _opening = true);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final dates = firstBookingDates(kind, start: widget.initialDate, end: widget.holiday.end);
    final result = await Navigator.of(context).push<SaveResult>(
      PageRouteBuilder(
        pageBuilder: (_, _, _) => EditBookingScreen(
          kind: kind,
          tripId: widget.tripId,
          initialDate: dates.start,
          initialEndDate: dates.end,
          onboardingHoliday: widget.holiday,
        ),
        transitionDuration: reduced ? Duration.zero : const Duration(milliseconds: 200),
        reverseTransitionDuration: reduced ? Duration.zero : const Duration(milliseconds: 150),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(opacity: animation, child: child),
      ),
    );
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) => OnboardingFolio(
    body: ListView(
      padding: const EdgeInsets.all(TravarySpace.gutter),
      children: [
        OnboardingFolioHeading(
          holiday: widget.holiday,
          title: 'Your first',
          accent: 'booking.',
          subtitle: 'Flight, stay or something fun?',
        ),
        for (final (kind, icon, subtitle) in [..._first, if (_more) ..._rest]) ...[
          ListTile(
            key: ValueKey('onboarding-kind-${kind.name}'),
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon),
            title: Text(kind.spec.label, style: TravaryText.title),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: _opening ? null : () => _choose(kind),
          ),
          const Divider(),
        ],
        if (!_more)
          ListTile(
            key: const ValueKey('onboarding-kind-more'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.more_horiz),
            title: Text('Something else', style: TravaryText.title),
            subtitle: const Text('Tickets, a table, transport, a show or a note'),
            trailing: const Icon(Icons.expand_more),
            onTap: _opening ? null : () => setState(() => _more = true),
          ),
      ],
    ),
  );
}
