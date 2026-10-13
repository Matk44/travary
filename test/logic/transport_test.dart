import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';
import 'package:travary/logic/card_text.dart';
import 'package:travary/logic/day_plan.dart';
import 'package:travary/logic/transport.dart';

import '../helpers.dart';

void main() {
  Booking transport(String title, {LocalDate? until, ClockTime? at, ClockTime? arrives, String? company}) => booking(
    't',
    BookingKind.transport,
    d(11, 3),
    title: title,
    endDate: until,
    at: at,
    until: arrives,
    details: {DetailKeys.company: ?company},
  );

  final sleeper = transport(
    'Tokyo to Sapporo',
    until: d(11, 4),
    at: const ClockTime(21, 0),
    arrives: const ClockTime(7, 0),
  );
  final pass = transport('Japan Rail Pass', until: d(11, 10), at: const ClockTime(9, 0));
  final car = transport('Car hire', until: d(11, 10), at: const ClockTime(10, 0), company: 'Alamo');

  test('a hire car, a journey or a pass', () {
    expect(transportSortOf(car), TransportSort.hire);
    expect(transportSortOf(transport('Alamo', until: d(11, 10))), TransportSort.hire);
    expect(transportSortOf(transport('Car hire Orlando to Miami', until: d(11, 10))), TransportSort.hire);
    expect(transportSortOf(sleeper), TransportSort.journey);
    expect(transportSortOf(transport('Airport transfer')), TransportSort.journey);
    expect(transportSortOf(transport('Night train', until: d(11, 4))), TransportSort.journey);
    expect(transportSortOf(pass), TransportSort.pass);
    expect(transportSortOf(transport('Eurail Global', until: d(11, 20))), TransportSort.pass);
    expect(transportSortOf(transport('Transport', until: d(11, 6))), TransportSort.hire, reason: 'the usual one');
  });

  test('each reads its own way at its two ends', () {
    expect(bookingEvents(car), (start: 'Pick-up', end: 'Drop-off'));
    expect(bookingEvents(sleeper), (start: 'Departs', end: 'Arrives'));
    expect(bookingEvents(pass), (start: 'Starts', end: 'Ends'));
    expect(ongoingText(pass, d(11, 5)).subtitle, 'Ends in 5 days');
    expect(ongoingCardText(pass, d(11, 5)).footnote, 'ENDS IN 5 DAYS');
  });

  test('a sleeper train that has left is finished, not held like a hire car or a pass', () {
    final evening = DateTime(2026, 11, 3, 22);
    final plan = buildDayPlan(d(11, 3), [sleeper, pass, car], evening);
    expect(plan.entries.map((e) => (e.booking, e.role)), [(sleeper, EntryRole.start)]);
    expect(cardTextForEntry(plan.entries.single).eyebrow, 'DEPARTS');
    expect(plan.ongoing, containsAll([pass, car]));
    final morning = buildDayPlan(d(11, 4), [sleeper], DateTime(2026, 11, 4, 6));
    expect(cardTextForEntry(morning.entries.single).eyebrow, 'ARRIVES');
  });
}
