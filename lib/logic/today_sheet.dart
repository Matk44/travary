import '../domain/domain.dart';
import 'trip_plan.dart';

/// Today as one sheet of pages laid side by side, dragged left for later
/// and right for earlier.
///
/// It starts at now: the first day of the trip you're on (its earlier days
/// stay a swipe back), else the next trip's countdown. It runs on through
/// every trip still to come, each one's countdown between the last day of
/// the trip before it and its own first day, and ends on where to next.
/// Past trips aren't on it: they live on the Trips tab.
sealed class TodayPage {
  const TodayPage();
}

/// A day of a trip.
final class TripDayPage extends TodayPage {
  const TripDayPage(this.plan, this.day);

  final TripPlan plan;
  final LocalDate day;

  @override
  bool operator ==(Object other) => other is TripDayPage && other.plan.id == plan.id && other.day == day;

  @override
  int get hashCode => Object.hash(plan.id, day);
}

/// A trip still to come, counting down: before its first day.
final class CountdownPage extends TodayPage {
  const CountdownPage(this.plan, {this.after});

  final TripPlan plan;

  /// The trip whose last day comes just before it on the sheet. Null when
  /// the countdown opens the sheet (Today between trips).
  final TripPlan? after;

  @override
  bool operator ==(Object other) => other is CountdownPage && other.plan.id == plan.id;

  @override
  int get hashCode => Object.hash(CountdownPage, plan.id);
}

/// After the last trip planned: where to next.
final class EndPage extends TodayPage {
  const EndPage(this.after);

  /// The last trip on the sheet.
  final TripPlan after;

  @override
  bool operator ==(Object other) => other is EndPage;

  @override
  int get hashCode => (EndPage).hashCode;
}

/// Today's pages and the one it opens on.
class TodaySheet {
  const TodaySheet(this.pages, this.opening);

  /// No trip on or coming: Today has one screen of its own, not a sheet.
  static const empty = TodaySheet([], 0);

  final List<TodayPage> pages;

  /// Today during a trip, else the next trip's countdown (or its first day
  /// when it has none).
  final int opening;

  bool get isEmpty => pages.isEmpty;

  /// Where [page] is on the sheet now, or null when it's gone (its trip's
  /// dates changed, or the trip was removed).
  int? indexOf(TodayPage page) {
    final index = pages.indexOf(page);
    return index < 0 ? null : index;
  }
}

/// The sheet for [focus] on [today]. [countsDown] says whether a trip still
/// to come has a countdown to show (its wording and a postcard); one that
/// doesn't goes straight from the trip before it to its first day.
TodaySheet todaySheetFor(
  List<TripPlan> plans,
  TodayFocus focus,
  LocalDate today, {
  required bool Function(TripPlan plan) countsDown,
}) {
  final focused = focus.plan;
  if (focused == null || !focused.hasDates) return TodaySheet.empty;
  final trips = [
    if (focused.phaseOn(today) == TripPhase.active) focused,
    ...plans.where((plan) => plan.hasDates && plan.start!.isAfter(today)),
  ];

  final pages = <TodayPage>[];
  TripPlan? before;
  for (final plan in trips) {
    if (plan.start!.isAfter(today) && countsDown(plan)) pages.add(CountdownPage(plan, after: before));
    pages.addAll([for (final day in plan.days) TripDayPage(plan, day)]);
    before = plan;
  }
  pages.add(EndPage(trips.last));

  var opening = focus.isCountdown ? pages.indexOf(CountdownPage(focused)) : -1;
  if (opening < 0) opening = pages.indexOf(TripDayPage(focused, focus.day));
  return TodaySheet(List.unmodifiable(pages), opening < 0 ? 0 : opening);
}
