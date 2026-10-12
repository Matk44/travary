import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/sharing_pitch.dart';
import 'package:travary/logic/trip_plan.dart';

import '../helpers.dart';

void main() {
  TripPlan planOf(List<Booking> bookings, {List<String> members = const ['me']}) {
    final base = trip('t', plannedStart: d(10, 11), plannedEnd: d(10, 18));
    return TripPlan(
      Trip(
        id: base.id,
        title: base.title,
        plannedStart: base.plannedStart,
        plannedEnd: base.plannedEnd,
        ownerId: 'me',
        memberIds: members,
        createdAt: base.createdAt,
        updatedAt: base.updatedAt,
      ),
      bookings,
    );
  }

  test('the bookings say how many are going: guests, a table, seats', () {
    expect(travellingParty(planOf(const [])), isNull);
    expect(
      travellingParty(
        planOf([
          booking('h', BookingKind.stay, d(10, 11), details: {DetailKeys.guests: '1'}),
        ]),
      ),
      isNull,
    );
    expect(
      travellingParty(
        planOf([
          booking('h', BookingKind.stay, d(10, 11), details: {DetailKeys.guests: '2'}),
          booking('d', BookingKind.dining, d(10, 12), details: {DetailKeys.partySize: '4'}),
        ]),
      ),
      4,
    );
    expect(
      travellingParty(
        planOf([
          booking('f', BookingKind.flight, d(10, 11), details: {DetailKeys.seats: '12A, 12B, 12C'}),
        ]),
      ),
      3,
    );
  });

  test('"Who\'s coming" says who else needs the tickets, until they\'re on the trip', () {
    final four = [
      booking('t', BookingKind.attraction, d(10, 12), details: {DetailKeys.guests: '4'}),
    ];
    expect(travellersLine(planOf(const []), ['You']), 'Just you so far');
    expect(travellersLine(planOf(four), ['You']), 'Tickets for 4: give everyone theirs');
    expect(travellersLine(planOf(four, members: ['me', 'sam']), ['You', 'Sam']), 'You, Sam');
  });
}
