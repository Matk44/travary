import '../domain/domain.dart';
import 'art_subjects.dart';
import 'trip_route.dart';

/// What a transport booking is. They read and behave differently: a hire
/// car is something the traveller has for days, a sleeper train is over
/// once it arrives, and a rail pass is good for days of journeys.
enum TransportSort {
  /// Picked up and dropped off, kept for days: a hire car, a campervan.
  hire,

  /// From one place to another, overnight perhaps: a train, ferry, coach
  /// or airport transfer.
  journey,

  /// Good for days of travel: a rail pass, a travel card.
  pass,
}

/// What [booking] (a transport booking) is: a pass or a hire when its name
/// or company says so ("Japan Rail Pass", "car hire"), a journey when it
/// goes somewhere ("Kyoto to Tokyo") or is a train, ferry, coach or taxi,
/// else a hire car when it lasts days (the usual one) and a journey when it
/// doesn't.
TransportSort transportSortOf(Booking booking) {
  final words = [booking.title, booking.detail(DetailKeys.company)].whereType<String>().join(' ').toLowerCase();
  if (_pass.hasMatch(words)) return TransportSort.pass;
  if (_hire.hasMatch(words)) return TransportSort.hire;
  if (routeOf(booking) != null) return TransportSort.journey;
  return switch (artSubjectFor(booking)) {
    'car' => TransportSort.hire,
    'train' || 'ferry' || 'bus' || 'taxi' => TransportSort.journey,
    _ => booking.spansDays ? TransportSort.hire : TransportSort.journey,
  };
}

/// Whether [booking] is a journey: a transport booking that goes from one
/// place to another (a sleeper train's night is spent on board).
bool isJourney(Booking booking) =>
    booking.kind == BookingKind.transport && transportSortOf(booking) == TransportSort.journey;

final _pass = RegExp(r'\b(pass|passes|eurail|interrail|railcard|travelcard|oyster|suica|pasmo|icoca)\b');
final _hire = RegExp(r'\b(hire|hired|rental|rent|campervan|motorhome|rv|alamo|hertz|avis|europcar|sixt)\b');
