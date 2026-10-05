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
    expect(formTripLine(null), 'Joins a trip by its dates');
  });

  test('ticket dates and board clocks', () {
    expect(formatTicketDate(d(10, 12)), '12 OCT 2026');
    expect(formatClock24(const ClockTime(20, 55)), '20:55');
    expect(formatClock24(const ClockTime(6, 5)), '06:05');
    expect(formatDayMonthRange(d(10, 30), d(11, 2)), '30 Oct – 2 Nov');
    expect(formatDayMonthRange(d(10, 12), d(10, 14)), '12–14 Oct');
  });
}
