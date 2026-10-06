import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/booking_form_text.dart';
import 'package:travary/logic/formatters.dart';
import 'package:travary/logic/trip_plan.dart';

import '../helpers.dart';

void main() {
  test('each kind names its own form, ticket and button', () {
    final stay = bookingFormText(BookingKind.stay);
    expect(stay.title, 'Add a stay');
    expect(stay.heading, 'YOUR STAY');
    expect(stay.button, 'Add stay');
    expect(bookingFormText(BookingKind.flight).title, 'Add a flight');
    expect(bookingFormText(BookingKind.dining).heading, 'YOUR TABLE');
    expect(bookingFormText(BookingKind.event).title, 'Add an event');
    final editing = bookingFormText(BookingKind.stay, editing: true);
    expect(editing.title, 'Edit stay');
    expect(editing.button, 'Save changes');
  });

  test('how long it lasts, between its dates', () {
    expect(bookingSpanLabel(BookingKind.stay, d(10, 12), d(10, 14)), '2 nights');
    expect(bookingSpanLabel(BookingKind.stay, d(10, 12), d(10, 13)), '1 night');
    expect(bookingSpanLabel(BookingKind.transport, d(10, 12), d(10, 14)), '3 days');
    expect(bookingSpanLabel(BookingKind.stay, d(10, 12), null), isNull);
    expect(bookingSpanLabel(BookingKind.stay, d(10, 12), d(10, 12)), isNull);
  });

  test('the trip it goes into', () {
    final japan = TripPlan(trip('jp', title: 'Japan', plannedStart: d(10, 11), plannedEnd: d(10, 30)), const []);
    expect(formTripLine(japan), 'Japan · 11–30 Oct');
    expect(formTripLine(japan, moves: true), 'Moves to Japan · 11–30 Oct');
    expect(formTripLine(null), 'Starts a new trip');
  });

  test('asking before a trip stretches well past its bookings', () {
    final tokyo = TripPlan(trip('tokyo', title: 'Tokyo'), [
      booking('out', BookingKind.flight, d(10, 11), tripId: 'tokyo'),
    ]);
    final paris = TripPlan(trip('paris', title: 'Paris'), const []);
    final add = stretchQuestion(tokyo, d(10, 20), d(10, 20));
    expect(add.title, 'Add to Tokyo?');
    expect(add.message, 'Tokyo runs 11 Oct so far. This is on 20 Oct, so the trip would run 11–20 Oct.');
    expect(add.keep, 'Add to Tokyo');
    expect(add.other, 'Start a new trip');
    final edit = stretchQuestion(tokyo, d(11, 11), d(11, 13), alternative: paris, editing: true);
    expect(edit.title, 'Keep in Tokyo?');
    expect(edit.message, 'Tokyo runs 11 Oct so far. This is on 11–13 Nov, so the trip would run 11 Oct – 13 Nov.');
    expect(edit.keep, 'Keep in Tokyo');
    expect(edit.other, 'Add to Paris');
  });

  test('where an imported booking outside its trip goes', () {
    final japan = TripPlan(trip('jp', title: 'Japan'), const []);
    final bali = TripPlan(trip('bali', title: 'Bali'), const []);
    expect(outsideTripText(japan, bali), 'Not on Japan\'s dates, so it goes to Bali');
    expect(outsideTripText(japan, null), 'Not on Japan\'s dates, so it starts a new trip');
  });

  test('ticket dates and board clocks', () {
    expect(formatTicketDate(d(10, 12)), '12 OCT 2026');
    expect(formatClock24(const ClockTime(20, 55)), '20:55');
    expect(formatClock24(const ClockTime(6, 5)), '06:05');
    expect(formatDayMonthRange(d(10, 30), d(11, 2)), '30 Oct – 2 Nov');
    expect(formatDayMonthRange(d(10, 12), d(10, 14)), '12–14 Oct');
  });
}
