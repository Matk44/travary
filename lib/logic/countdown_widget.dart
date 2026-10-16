import '../domain/domain.dart';
import 'formatters.dart';
import 'travi_cameos.dart';
import 'trip_plan.dart';
import 'trip_postcard_text.dart';

/// The countdown on the phone's home screen (iOS WidgetKit, Android app
/// widget): Today's postcard and luggage tag, counting down to the next
/// trip, then the days left on it. The widget runs without the app, so the
/// app works out every day ahead here, already worded, and the widget only
/// picks the one for its own date: the number turns over at midnight even
/// if Travary isn't opened for weeks.
///
/// Which trip a day shows is Today's rule (`focusFor`): the trip on that
/// day, else the next one. Wording comes from the Trips tab's postcard
/// (`tripPostcardTextFor`), so the widget, Today and Trips always agree.
class CountdownWidgetDay {
  const CountdownWidgetDay({
    required this.date,
    required this.tripId,
    required this.heading,
    required this.eyebrow,
    required this.days,
    required this.daysLabel,
    required this.place,
    required this.dates,
    required this.shortDates,
    required this.semanticLabel,
    required this.travi,
  });

  final LocalDate date;
  final String tripId;

  /// Above the postcard (the large widget): "NEXT ADVENTURE", or "ON YOUR
  /// TRIP" once it has started.
  final String heading;

  /// The tag's first line: "NEXT TRIP", or "DAY 3 OF 7" on the trip.
  final String eyebrow;

  /// The large number, "58", and under it "DAYS TO GO" ("DAY TO GO",
  /// "DAYS LEFT", "DAY LEFT").
  final String days;
  final String daysLabel;

  /// "Lake District".
  final String place;

  /// "25–28 Nov 2026", and without the year for the smaller tags,
  /// "25–28 Nov" (a span across a new year keeps both years).
  final String dates;
  final String shortDates;

  /// The whole widget for screen readers.
  final String semanticLabel;

  /// How Travi feels that morning when he pops up: by the days left, as
  /// when the countdown's tag is tapped in the app, and a wave once the
  /// trip is on.
  final TraviPeek travi;

  Map<String, Object?> toJson() => {
    'trip': tripId,
    'heading': heading,
    'eyebrow': eyebrow,
    'days': days,
    'daysLabel': daysLabel,
    'place': place,
    'dates': dates,
    'shortDates': shortDates,
    'label': semanticLabel,
    'travi': travi.name,
  };
}

/// When nothing is coming up (or the days worked out run out): the neutral
/// postcard, with the tag asking where to next, or naming a holiday still
/// waiting for its dates.
class CountdownWidgetIdle {
  const CountdownWidgetIdle({
    required this.heading,
    required this.eyebrow,
    required this.title,
    required this.message,
    required this.semanticLabel,
    this.tripId,
  });

  final String heading;
  final String eyebrow;

  /// On the tag in place of the count: "Where to next?", or the undated
  /// holiday's name.
  final String title;

  /// Under it: "Plan a trip", "Dates to come".
  final String message;
  final String semanticLabel;

  /// The undated holiday the widget opens, if any.
  final String? tripId;

  Map<String, Object?> toJson() => {
    'trip': tripId,
    'heading': heading,
    'eyebrow': eyebrow,
    'title': title,
    'message': message,
    'label': semanticLabel,
    'travi': TraviPeek.wave.name,
  };
}

/// How far ahead the days are worked out: past any trip someone is likely
/// to have planned, so the widget keeps counting while the app is closed.
const countdownWidgetHorizonDays = 400;

/// Travi pops up from first thing each morning until this hour (on the
/// phone's clock), at most once a day, as he greets on Today; tapping the
/// tag brings him up any time. Widgets can't play the app's films, so he
/// rises and ducks as one move between two stills.
const countdownWidgetTraviUntilHour = 12;

/// Every day from [today] that has a trip to show, for at most [horizon]
/// days: consecutive, ending the day the last trip on or coming ends.
/// Empty when nothing dated is on or coming up.
List<CountdownWidgetDay> countdownWidgetDays(
  List<TripPlan> plans,
  LocalDate today, {
  int horizon = countdownWidgetHorizonDays,
}) {
  final dated = plans.where((p) => p.hasDates && !p.end!.isBefore(today)).toList();
  final days = <CountdownWidgetDay>[];
  for (var i = 0; i < horizon; i++) {
    final date = today.addDays(i);
    final plan = focusFor(dated, date).plan;
    if (plan == null) break;
    final text = tripPostcardTextFor(plan, date);
    if (text == null) break;
    final dayNumber = plan.dayNumber(date);
    final underway = dayNumber != null;
    days.add(
      CountdownWidgetDay(
        date: date,
        tripId: plan.id,
        heading: underway ? 'ON YOUR TRIP' : 'NEXT ADVENTURE',
        eyebrow: underway ? 'DAY $dayNumber OF ${plan.dayCount}' : 'NEXT TRIP',
        days: text.days,
        daysLabel: text.daysLabel,
        place: text.place,
        dates: text.dates,
        shortDates: formatDayMonthRange(plan.start!, plan.end!),
        semanticLabel: text.semanticLabel,
        travi: underway ? TraviPeek.wave : countdownReactionFor(date.daysUntil(plan.start!)),
      ),
    );
  }
  return days;
}

/// What the widget shows with no trip to count to: the newest holiday
/// still waiting for its dates (as Today keeps it in view), else an
/// invitation to plan one.
CountdownWidgetIdle countdownWidgetIdle(List<TripPlan> plans, LocalDate today) {
  final undated = focusFor(plans.where((p) => !p.hasDates).toList(), today).undated;
  if (undated != null) {
    final title = undated.trip.title.trim().isEmpty ? 'Your trip' : undated.trip.title.trim();
    return CountdownWidgetIdle(
      heading: 'NEXT ADVENTURE',
      eyebrow: 'NEXT TRIP',
      title: title,
      message: 'Dates to come',
      semanticLabel: '$title, dates to come.',
      tripId: undated.id,
    );
  }
  return const CountdownWidgetIdle(
    heading: 'NEXT ADVENTURE',
    eyebrow: 'NEXT TRIP',
    title: 'Where to next?',
    message: 'Plan a trip',
    semanticLabel: 'No trips coming up. Plan your next trip in Travary.',
  );
}

/// The art a trip's widget is drawn with, as files in the widget's folder
/// (names relative to it). Null where the trip has none, and the widget
/// uses the idle art or a plain stand-in.
typedef CountdownWidgetArt = ({String? portrait, String? landscape, String? tag, String? linen, int ink, int paper});

/// Bumped when the file's shape changes; the widget ignores a version it
/// doesn't know rather than misreading it.
const countdownWidgetVersion = 1;

/// The file the widget reads (`countdown.json`): the days, the idle state,
/// each trip's art, Travi's stills and the fonts. [generated] is when the
/// app wrote it (on the phone's clock, for diagnostics only).
Map<String, Object?> countdownWidgetJson({
  required List<CountdownWidgetDay> days,
  required CountdownWidgetIdle idle,
  required Map<String, CountdownWidgetArt> trips,
  required CountdownWidgetArt idleArt,
  required Map<TraviPeek, String> travi,
  required Map<String, String> fonts,
  required DateTime generated,
}) {
  Map<String, Object?> art(CountdownWidgetArt a) => {
    'portrait': a.portrait,
    'landscape': a.landscape,
    'tag': a.tag,
    'linen': a.linen,
    'ink': _hex(a.ink),
    'paper': _hex(a.paper),
  };
  return {
    'version': countdownWidgetVersion,
    'generated': generated.toIso8601String(),
    'traviUntilHour': countdownWidgetTraviUntilHour,
    'days': {for (final day in days) day.date.toIso(): day.toJson()},
    'idle': {...idle.toJson(), 'art': art(idleArt)},
    'trips': {for (final entry in trips.entries) entry.key: art(entry.value)},
    'travi': {
      for (final entry in travi.entries)
        entry.key.name: {
          'file': entry.value,
          'box': [
            traviPeeks[entry.key]!.still.box.left,
            traviPeeks[entry.key]!.still.box.top,
            traviPeeks[entry.key]!.still.box.width,
            traviPeeks[entry.key]!.still.box.height,
          ],
        },
    },
    'traviCanvas': traviCameoCanvas,
    'fonts': fonts,
  };
}

/// `#RRGGBB` for a 32-bit colour (alpha dropped: the widget's inks are
/// opaque).
String _hex(int argb) => '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// The link a tap on the widget opens: the trip it shows, or Today.
Uri countdownWidgetLink(String? tripId) => tripId == null
    ? Uri(scheme: 'travary', host: 'today')
    : Uri(scheme: 'travary', host: 'trip', pathSegments: [tripId]);

/// What a widget link asks to open: a trip's ID, or `''` for Today. Null
/// when [link] isn't a widget link.
String? countdownWidgetTarget(Uri link) {
  if (link.scheme != 'travary') return null;
  if (link.host == 'today') return '';
  if (link.host != 'trip') return null;
  final segments = link.pathSegments.where((s) => s.isNotEmpty).toList();
  return segments.length == 1 ? segments.single : null;
}
