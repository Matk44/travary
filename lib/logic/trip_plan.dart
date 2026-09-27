import '../domain/domain.dart';

enum TripPhase { upcoming, active, past }

/// A trip together with its bookings and the dates they cover.
class TripPlan {
  TripPlan(this.trip, Iterable<Booking> bookings)
    : bookings = List.unmodifiable(
        [...bookings]..sort((a, b) => a.startsAt.compareTo(b.startsAt)),
      ) {
    LocalDate? first = trip.plannedStart;
    LocalDate? last = trip.plannedEnd ?? trip.plannedStart;
    for (final booking in this.bookings) {
      first = first == null
          ? booking.startDate
          : LocalDate.min(first, booking.startDate);
      last = last == null
          ? booking.lastDate
          : LocalDate.max(last, booking.lastDate);
    }
    start = first;
    end = last;
  }

  final Trip trip;
  final List<Booking> bookings;

  /// First and last day of the trip. Null for a trip with no dates yet.
  late final LocalDate? start;
  late final LocalDate? end;

  String get id => trip.id;
  bool get hasDates => start != null;
  int get dayCount => hasDates ? start!.daysUntil(end!) + 1 : 0;

  List<LocalDate> get days => [
    for (var i = 0; i < dayCount; i++) start!.addDays(i),
  ];

  bool contains(LocalDate date) =>
      hasDates && !date.isBefore(start!) && !date.isAfter(end!);

  /// 1-based day number of [date] within the trip, or null if outside it.
  int? dayNumber(LocalDate date) =>
      contains(date) ? start!.daysUntil(date) + 1 : null;

  TripPhase phaseOn(LocalDate today) {
    if (!hasDates || start!.isAfter(today)) return TripPhase.upcoming;
    if (end!.isBefore(today)) return TripPhase.past;
    return TripPhase.active;
  }
}

/// Builds plans for every trip, ordered by start date (undated trips last).
List<TripPlan> buildTripPlans(List<Trip> trips, List<Booking> bookings) {
  final byTrip = <String, List<Booking>>{};
  for (final booking in bookings) {
    byTrip.putIfAbsent(booking.tripId, () => []).add(booking);
  }
  final plans = [for (final t in trips) TripPlan(t, byTrip[t.id] ?? const [])];
  plans.sort((a, b) {
    if (a.start == null || b.start == null) {
      return (a.start == null ? 1 : 0) - (b.start == null ? 1 : 0);
    }
    return a.start!.compareTo(b.start!);
  });
  return plans;
}

/// What the Today screen should focus on.
class TodayFocus {
  const TodayFocus({this.plan, required this.day, this.daysUntilStart});

  /// The trip being shown: the one happening now, else the next one.
  final TripPlan? plan;

  /// The day to open on: today during a trip, else the trip's first day.
  final LocalDate day;

  /// Set when [plan] hasn't started yet.
  final int? daysUntilStart;

  bool get isCountdown => daysUntilStart != null;
}

TodayFocus focusFor(List<TripPlan> plans, LocalDate today) {
  final dated = plans.where((p) => p.hasDates).toList();
  final active = dated.where((p) => p.phaseOn(today) == TripPhase.active);
  if (active.isNotEmpty) return TodayFocus(plan: active.first, day: today);

  final upcoming = dated.where((p) => p.phaseOn(today) == TripPhase.upcoming);
  if (upcoming.isNotEmpty) {
    final next = upcoming.first;
    return TodayFocus(
      plan: next,
      day: next.start!,
      daysUntilStart: today.daysUntil(next.start!),
    );
  }
  return TodayFocus(day: today);
}
