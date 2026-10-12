import '../domain/domain.dart';
import 'trip_plan.dart';

/// How family sharing is offered where it's useful: the trip's own bookings
/// say how many are going ("4 tickets", "Table for 4"), so a trip only one
/// person is on can say who else needs the plan and the tickets.

/// The most people any of [plan]'s bookings is for (guests at a hotel or on
/// tickets, a table's party, seats on a flight). Null when nothing says
/// more than one.
int? travellingParty(TripPlan plan) {
  var most = 1;
  for (final booking in plan.bookings) {
    final counts = [
      int.tryParse(booking.detail(DetailKeys.guests) ?? ''),
      int.tryParse(booking.detail(DetailKeys.partySize) ?? ''),
      _seatCount(booking.detail(DetailKeys.seats)),
    ];
    for (final count in counts) {
      if (count != null && count > most && count <= 20) most = count;
    }
  }
  return most > 1 ? most : null;
}

/// "12A, 12B, 12C" is three seats; a lone "12A" one.
int? _seatCount(String? seats) {
  if (seats == null) return null;
  final parts = seats.split(RegExp(r'[,/&]|\band\b')).where((s) => s.trim().isNotEmpty).length;
  return parts == 0 ? null : parts;
}

/// Under "Who's coming": everyone on the trip, or with only the organiser
/// on it, who the bookings say is coming too.
String travellersLine(TripPlan plan, List<String> names) {
  if (plan.trip.memberIds.length > 1) return names.join(', ');
  final party = travellingParty(plan);
  return party == null ? 'Just you so far' : 'Tickets for $party: give everyone theirs';
}

/// On a packing list nobody else is on yet.
const packTogetherTitle = 'Pack together';
const packTogetherDetail = 'Invite the family to tick the same list on their phones';
