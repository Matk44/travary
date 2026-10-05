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

  group('the time rail', () {
    test('a stop is its time over am or pm, with its status', () {
      final plan = buildDayPlan(today, [
        booking('park', BookingKind.attraction, today, title: 'Magic Kingdom', at: const ClockTime(9, 0)),
        booking('lunch', BookingKind.dining, today, title: 'Be Our Guest Restaurant', at: const ClockTime(12, 30)),
        booking('dinner', BookingKind.dining, today, title: 'Ohana', at: const ClockTime(19, 15)),
        booking('midnight', BookingKind.note, today, title: 'Fireworks', at: const ClockTime(0, 5)),
      ], DateTime(2026, 10, 14, 10));
      final stops = [for (final entry in plan.entries) timelineStopFor(entry)!];
      expect(
        [for (final s in stops) (s.time, s.period)],
        [('12:05', 'am'), ('9:00', 'am'), ('12:30', 'pm'), ('7:15', 'pm')],
      );
      expect(
        [for (final s in stops) s.status],
        [EntryStatus.done, EntryStatus.now, EntryStatus.upcoming, EntryStatus.upcoming],
      );
    });

    test('an all-day entry has no stop', () {
      final plan = buildDayPlan(today, [
        booking('allday', BookingKind.attraction, today, title: 'Water park'),
      ], DateTime(2026, 10, 14, 8));
      expect(timelineStopFor(plan.entries.single), isNull);
    });

    test('a stay is on the rail at check-in, then at check-out', () {
      final hotel = booking(
        'h',
        BookingKind.stay,
        today,
        at: const ClockTime(15, 0),
        endDate: d(10, 16),
        until: const ClockTime(11, 0),
      );
      final checkIn = buildDayPlan(today, [hotel], DateTime(2026, 10, 14, 6)).entries.single;
      final checkOut = buildDayPlan(d(10, 16), [hotel], DateTime(2026, 10, 14, 6)).entries.single;
      expect((timelineStopFor(checkIn)!.time, timelineStopFor(checkIn)!.period), ('3:00', 'pm'));
      expect((timelineStopFor(checkOut)!.time, timelineStopFor(checkOut)!.period), ('11:00', 'am'));
    });
  });

  test('a Documents row sums a booking up in one line: its kind, then its reference, detail or place', () {
    final lunch = booking(
      'lunch',
      BookingKind.dining,
      today,
      at: const ClockTime(12, 30),
      reference: 'ST-4412',
      details: {DetailKeys.partySize: '4'},
    );
    final dinner = booking(
      'dinner',
      BookingKind.dining,
      today,
      at: const ClockTime(19, 15),
      details: {DetailKeys.partySize: '4'},
    );
    final walk = booking('walk', BookingKind.activity, today, location: 'Kissimmee Boat Dock');
    expect(cardTextForList(lunch).summary, 'Lunch · ST-4412');
    expect(cardTextForList(dinner).summary, 'Dinner · Table for 4');
    expect(cardTextForList(walk).summary, 'Activity · Kissimmee Boat Dock');
    expect(const CardText(eyebrow: '', title: 'x').summary, isNull);
    expect(const CardText(eyebrow: 'NOTE', title: 'x').summary, 'Note');
  });

  test('a Documents row sets its date on two lines for the postmark', () {
    final text = cardTextForList(booking('b', BookingKind.activity, d(9, 26)));
    expect((text.day, text.month), ('26', 'Sep'));
    expect(text.when, '26 Sep');
  });

  test('short clock and weather wording', () {
    expect(formatClockShort(const ClockTime(9, 0)), '9:00');
    expect(formatClockShort(const ClockTime(12, 30)), '12:30');
    expect(formatClockShort(const ClockTime(19, 15)), '7:15');
    expect(formatClockShort(const ClockTime(0, 5)), '12:05');
    expect(formatWeather(const WeatherReport(temperature: 28, condition: WeatherCondition.sunny)), '28° Sunny');
    expect(formatWeather(const WeatherReport(temperature: -3, condition: WeatherCondition.snow)), '-3° Snow');
  });

  group('a row of the trip\'s plan', () {
    test('flights lead with the flight number, then the time', () {
      final text = cardTextForLedger(
        booking(
          'out',
          BookingKind.flight,
          d(10, 11),
          title: 'Sydney to Tokyo',
          at: const ClockTime(20, 55),
          details: {DetailKeys.flightNumber: 'qf 25'},
        ),
      );
      expect(text.day, '11');
      expect(text.month, 'OCT');
      expect(text.title, 'Sydney to Tokyo');
      expect(text.detail, 'QF 25 · 8:55pm');
    });

    test('stays give their nights', () {
      final text = cardTextForLedger(
        booking('kyoto', BookingKind.stay, d(10, 12), title: 'Kyoto House', endDate: d(10, 14)),
      );
      expect(text.detail, '12–14 Oct · 2 nights');
    });

    test('everything else: the time and its detail; a second row that day leaves the date out', () {
      final museum = booking(
        'museum',
        BookingKind.attraction,
        d(10, 13),
        title: 'Kyoto Railway Museum',
        at: const ClockTime(10, 0),
        details: {DetailKeys.guests: '2'},
      );
      expect(cardTextForLedger(museum).detail, '10:00am · 2 tickets');
      final second = cardTextForLedger(museum, showDate: false);
      expect(second.day, isNull);
      expect(second.month, isNull);
      expect(cardTextForLedger(booking('n', BookingKind.note, d(10, 13), title: 'Rail pass')).detail, 'Note');
    });
  });
}
