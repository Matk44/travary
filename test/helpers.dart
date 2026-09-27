import 'package:travary/domain/domain.dart';

final _stamp = DateTime(2026, 1, 1);

LocalDate d(int month, int day) => LocalDate(2026, month, day);

Booking booking(
  String id,
  BookingKind kind,
  LocalDate date, {
  String? title,
  String tripId = 'trip',
  ClockTime? at,
  LocalDate? endDate,
  ClockTime? until,
  String? reference,
  String? location,
  Map<String, String> details = const {},
}) => Booking(
  id: id,
  tripId: tripId,
  kind: kind,
  title: title ?? id,
  startDate: date,
  startTime: at,
  endDate: endDate,
  endTime: until,
  reference: reference,
  location: location,
  details: details,
  createdAt: _stamp,
  updatedAt: _stamp,
);

Trip trip(String id, {String? title, LocalDate? plannedStart, LocalDate? plannedEnd}) => Trip(
  id: id,
  title: title ?? id,
  plannedStart: plannedStart,
  plannedEnd: plannedEnd,
  ownerId: 'me',
  memberIds: const ['me'],
  createdAt: _stamp,
  updatedAt: _stamp,
);
