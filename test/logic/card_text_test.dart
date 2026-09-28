import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/card_text.dart';
import 'package:travary/logic/day_plan.dart';
import 'package:travary/logic/formatters.dart';

import '../helpers.dart';

void main() {
  final today = d(10, 14);
  DayEntry entryFor(Booking b, {EntryRole role = EntryRole.single, EntryStatus status = EntryStatus.upcoming}) =>
      DayEntry(booking: b, role: role, time: role == EntryRole.end ? b.endTime : b.startTime, status: status);

  test('dining eyebrow follows the time of day', () {
    String eyebrow(int hour) =>
        cardTextForEntry(entryFor(booking('x', BookingKind.dining, today, at: ClockTime(hour, 0)))).eyebrow;
    expect(eyebrow(8), 'BREAKFAST');
    expect(eyebrow(12), 'LUNCH');
    expect(eyebrow(19), 'DINNER');
  });

  test('the highlighted card says next up or happening now', () {
    final lunch = booking('lunch', BookingKind.dining, today, at: const ClockTime(12, 30));
    expect(cardTextForEntry(entryFor(lunch), highlighted: true).eyebrow, 'NEXT UP');
    expect(cardTextForEntry(entryFor(lunch, status: EntryStatus.now), highlighted: true).eyebrow, 'HAPPENING NOW');
  });

  test('the two ends of a stay are named', () {
    final hotel = booking(
      'hotel',
      BookingKind.stay,
      d(10, 12),
      at: const ClockTime(16, 0),
      endDate: d(10, 18),
      until: const ClockTime(11, 0),
      details: {DetailKeys.room: '2214'},
    );
    expect(cardTextForEntry(entryFor(hotel, role: EntryRole.start)).eyebrow, 'CHECK-IN');
    final checkout = cardTextForEntry(entryFor(hotel, role: EntryRole.end));
    expect(checkout.eyebrow, 'CHECK-OUT');
    expect(checkout.when, '11:00am');
    expect(checkout.stub, 'ROOM 2214');
  });

  test('tickets get an admit stub and a ticket count', () {
    final text = cardTextForEntry(
      entryFor(
        booking('park', BookingKind.attraction, today, at: const ClockTime(9, 0), details: {DetailKeys.guests: '2'}),
      ),
    );
    expect(text.stub, 'ADMIT TWO');
    expect(text.detail, '2 tickets');
    expect(text.whenAndDetail, '9:00am · 2 tickets');
  });

  test('same-day end time shows as a range', () {
    final tour = booking('tour', BookingKind.activity, today, at: const ClockTime(9, 0), until: const ClockTime(16, 0));
    expect(cardTextForEntry(entryFor(tour)).when, '9:00am – 4:00pm');
  });

  test('flight detail and seat stub', () {
    final flight = booking(
      'f',
      BookingKind.flight,
      today,
      at: const ClockTime(10, 30),
      details: {DetailKeys.flightNumber: 'BA 2037', DetailKeys.seats: '22A, 22B'},
    );
    final text = cardTextForBooking(flight);
    expect(text.detail, 'BA 2037 · Seats 22A, 22B');
    // Several seats don't fit on a stub, so it shows the flight instead.
    expect(text.stub, 'BA 2037');
  });

  test('a single seat goes on the stub', () {
    final flight = booking('f', BookingKind.flight, today, details: {DetailKeys.seats: '14a'});
    expect(cardTextForBooking(flight).stub, 'SEAT 14A');
  });

  test('review wording puts the date in the column and the time up front', () {
    final flight = booking(
      'f',
      BookingKind.flight,
      d(11, 14),
      at: const ClockTime(19, 10),
      details: {DetailKeys.flightNumber: 'SB 2168'},
    );
    final text = cardTextForReview(flight);
    expect(text.when, '14 Nov');
    expect(text.detail, '7:10pm · SB 2168');
  });

  test('ongoing wording counts down to the end', () {
    final hotel = booking(
      'hotel',
      BookingKind.stay,
      d(10, 12),
      endDate: d(10, 18),
      title: 'Lagoon Resort',
      details: {DetailKeys.room: '2214'},
    );
    final text = ongoingText(hotel, today);
    expect(text.title, 'Lagoon Resort · Room 2214');
    expect(text.subtitle, 'Check-out in 4 days');
  });

  test('describeWhen covers multi-day bookings', () {
    final hotel = booking(
      'hotel',
      BookingKind.stay,
      d(10, 12),
      at: const ClockTime(16, 0),
      endDate: d(10, 18),
      until: const ClockTime(11, 0),
    );
    expect(describeWhen(hotel), 'Mon 12 Oct · 4:00pm → Sun 18 Oct · 11:00am');
  });

  group('the hotel key card', () {
    test('names the stay, the room and the countdown', () {
      final hotel = booking(
        'hotel',
        BookingKind.stay,
        d(10, 12),
        endDate: d(10, 18),
        title: "Disney's Polynesian Resort",
        details: {DetailKeys.room: '2214'},
      );
      final text = ongoingCardText(hotel, today);
      expect(text.eyebrow, 'HOTEL');
      expect(text.title, "Disney's Polynesian Resort");
      expect(text.detail, 'Room 2214');
      expect(text.footnote, 'CHECK-OUT IN 4 DAYS');
    });

    test('says what kind of stay it is', () {
      String eyebrow(String title) =>
          ongoingCardText(booking('s', BookingKind.stay, d(10, 12), endDate: d(10, 18), title: title), today).eyebrow;
      expect(eyebrow('Lagoon Resort'), 'HOTEL');
      expect(eyebrow('Fellside Cottage'), 'COTTAGE');
      expect(eyebrow('Chalet Edelweiss'), 'CHALET');
      expect(eyebrow('Villa Rosa'), 'VILLA');
      expect(eyebrow('Lakeside Glamping'), 'CAMPSITE');
      expect(cardTextForEntry(entryFor(booking('h', BookingKind.stay, today, title: 'Grand Hotel'))).eyebrow, 'HOTEL');
    });

    test('a hire car in progress names the company and the drop-off', () {
      final car = booking(
        'car',
        BookingKind.transport,
        d(10, 12),
        endDate: d(10, 18),
        title: 'Car hire',
        details: {DetailKeys.company: 'Alamo'},
      );
      final text = ongoingCardText(car, today);
      expect((text.eyebrow, text.detail, text.footnote), ('TRANSPORT', 'Alamo', 'DROP-OFF IN 4 DAYS'));
    });
  });

  test('the featured button shows tickets when there are some to show', () {
    final withReference = booking('p', BookingKind.attraction, today, at: const ClockTime(9, 0), reference: 'MK-1');
    final bare = booking('q', BookingKind.attraction, today, at: const ClockTime(9, 0));
    expect(showsTickets(withReference), isTrue);
    expect(showsTickets(bare), isFalse);
    expect(cardTextForEntry(entryFor(withReference), highlighted: true).action, 'Show tickets');
    expect(cardTextForEntry(entryFor(bare), highlighted: true).action, 'Details');
  });

  group('the day timeline', () {
    test('lists timed stops with a short time and a word', () {
      final plan = buildDayPlan(today, [
        booking('park', BookingKind.attraction, today, title: 'Magic Kingdom', at: const ClockTime(9, 0)),
        booking('lunch', BookingKind.dining, today, title: 'Be Our Guest Restaurant', at: const ClockTime(12, 30)),
        booking('dinner', BookingKind.dining, today, title: 'Ohana', at: const ClockTime(19, 15)),
        booking('note', BookingKind.note, today, title: 'Fireworks', at: const ClockTime(21, 0)),
        booking('allday', BookingKind.attraction, today, title: 'Water park'),
      ], DateTime(2026, 10, 14, 8));
      final stops = timelineFor(plan);
      expect([for (final s in stops) (s.time, s.label)], [('9:00', 'Park'), ('12:30', 'Lunch'), ('7:15', 'Dinner')]);
      expect(stops.first.spoken, '9:00am, Park, Magic Kingdom');
      expect(stops.first.status, EntryStatus.upcoming);
    });

    test('uses the booking\'s role and subject', () {
      final hotel = booking(
        'h',
        BookingKind.stay,
        today,
        at: const ClockTime(15, 0),
        endDate: d(10, 16),
        until: const ClockTime(11, 0),
      );
      final train = booking(
        't',
        BookingKind.transport,
        today,
        title: 'London to Paris',
        at: const ClockTime(9, 1),
        details: {DetailKeys.company: 'Eurostar'},
      );
      final museum = booking('m', BookingKind.attraction, today, title: 'Science Museum', at: const ClockTime(14, 0));
      final boat = booking(
        'b',
        BookingKind.activity,
        today,
        title: 'Everglades airboat tour',
        at: const ClockTime(10, 0),
      );
      final stops = timelineFor(buildDayPlan(today, [hotel, train, museum, boat], DateTime(2026, 10, 14, 6)));
      expect([for (final s in stops) s.label], ['Train', 'Boat trip', 'Museum', 'Check-in']);
    });
  });

  test('short clock and weather wording', () {
    expect(formatClockShort(const ClockTime(9, 0)), '9:00');
    expect(formatClockShort(const ClockTime(12, 30)), '12:30');
    expect(formatClockShort(const ClockTime(19, 15)), '7:15');
    expect(formatClockShort(const ClockTime(0, 5)), '12:05');
    expect(formatWeather(const WeatherReport(temperature: 28, condition: WeatherCondition.sunny)), '28° Sunny');
    expect(formatWeather(const WeatherReport(temperature: -3, condition: WeatherCondition.snow)), '-3° Snow');
  });
}
