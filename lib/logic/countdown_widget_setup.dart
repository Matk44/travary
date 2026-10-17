/// Getting the countdown widget onto the home screen
/// (`logic/countdown_widget.dart` is what it shows): who is offered it,
/// and all the wording. Pure Dart.
///
/// The phone decides how far Travary can go. Android can ask its launcher
/// to place the widget (a system dialog, one tap); iOS has no such call, so
/// the traveller is shown how. Neither lets an app see the home screen, only
/// whether a widget of its own is on it.
library;

enum HomeWidgetPlatform { ios, android }

/// What the phone says about the widget: whether it can have one at all (iOS
/// 15 and 16 can't), whether one is on the home screen now, and whether
/// Travary can ask the launcher to place it.
typedef HomeWidgetStatus = ({bool supported, bool added, bool canPin});

const homeWidgetUnavailable = (supported: false, added: false, canPin: false);

/// Whether Today's countdown, between trips, offers the widget (a note
/// beside its tag): it can be
/// had, isn't on the home screen, was never on it (someone who took it off
/// knows it exists), and wasn't turned down.
bool offersCountdownWidget({required HomeWidgetStatus status, required bool everAdded, required bool declined}) =>
    status.supported && !status.added && !everAdded && !declined;

/// The sheet: what it says and what its one button does.
typedef CountdownWidgetWords = ({
  String band,
  String title,
  String lead,

  /// By hand, in order. Empty when the button does it (or it's done).
  List<String> steps,
  String action,
});

const countdownWidgetBand = 'HOME SCREEN';
const _title = 'Your countdown, on your home screen';
const _lead = 'See the days to go without opening Travary. It counts down by itself. Free.';

/// What the sheet says for [status] on [platform]. Android with a launcher
/// that can place it gets a button that does it; otherwise the steps.
CountdownWidgetWords countdownWidgetWords({required HomeWidgetPlatform platform, required HomeWidgetStatus status}) {
  if (status.added) {
    return (
      band: countdownWidgetBand,
      title: 'It’s on your home screen',
      lead: 'It keeps up to date, even when Travary is closed. Tap its tag and Travi pops up.',
      steps: const [],
      action: 'Done',
    );
  }
  if (platform == HomeWidgetPlatform.android && status.canPin) {
    return (band: countdownWidgetBand, title: _title, lead: _lead, steps: const [], action: countdownWidgetPinAction);
  }
  return (
    band: countdownWidgetBand,
    title: _title,
    lead: _lead,
    steps: countdownWidgetSteps(platform),
    action: 'Got it',
  );
}

const countdownWidgetPinAction = 'Add to home screen';

/// Adding it yourself, as the phone words it.
List<String> countdownWidgetSteps(HomeWidgetPlatform platform) => switch (platform) {
  HomeWidgetPlatform.ios => const [
    'Touch and hold an empty spot on your home screen until the apps jiggle.',
    'Tap + at the top, then search for Travary.',
    'Pick a size, tap Add Widget, then Done.',
  ],
  HomeWidgetPlatform.android => const [
    'Touch and hold an empty spot on your home screen.',
    'Tap Widgets, then find Travary.',
    'Touch and hold the countdown and drop it where you like.',
  ],
};

/// The launcher wouldn't open its dialog: the steps instead.
const countdownWidgetPinRefused = 'Your phone didn’t open its widget picker. Here’s how to add it yourself.';

/// The note beside Today's countdown tag, under "Packing list · Start
/// yours": the same shape, a title and what to do.
///
/// Short, because the note has only the room beside the tag: "Home screen
/// widget" ran out of it and was cut off.
const countdownWidgetNoteTitle = 'Home screen';
const countdownWidgetNoteDetail = 'Add this countdown';
const countdownWidgetNoteLabel = 'Add this countdown to your home screen';

/// The sheet's way out of the offer on Today, for good (Profile keeps it).
const countdownWidgetNotNow = 'Not now';

/// Profile's row.
const countdownWidgetSettingTitle = 'Countdown widget';

String countdownWidgetSettingSubtitle(HomeWidgetStatus status) =>
    status.added ? 'On your home screen' : 'See the days to go from your home screen. Free.';
