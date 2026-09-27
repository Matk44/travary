/// A calendar date with no time zone attached.
///
/// Bookings are stored in "floating" local time: exactly what is printed on
/// the ticket. The phone switches to the destination's time zone on arrival,
/// so comparing floating times against the device clock is correct on the
/// trip itself, which is when it matters.
class LocalDate implements Comparable<LocalDate> {
  const LocalDate(this.year, this.month, this.day);

  factory LocalDate.fromDateTime(DateTime dateTime) =>
      LocalDate(dateTime.year, dateTime.month, dateTime.day);

  /// Parses `yyyy-MM-dd`.
  factory LocalDate.parse(String iso) {
    final parts = iso.split('-');
    return LocalDate(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static LocalDate? tryParse(Object? value) {
    if (value is! String || value.isEmpty) return null;
    try {
      return LocalDate.parse(value);
    } on FormatException {
      return null;
    }
  }

  final int year;
  final int month;
  final int day;

  // UTC avoids daylight-saving gaps when counting days.
  DateTime get _utc => DateTime.utc(year, month, day);

  /// 1 = Monday ... 7 = Sunday.
  int get weekday => _utc.weekday;

  DateTime toDateTime([ClockTime? time]) =>
      DateTime(year, month, day, time?.hour ?? 0, time?.minute ?? 0);

  LocalDate addDays(int days) =>
      LocalDate.fromDateTime(DateTime.utc(year, month, day + days));

  /// Whole days from this date to [other] (negative if [other] is earlier).
  int daysUntil(LocalDate other) => other._utc.difference(_utc).inDays;

  bool isBefore(LocalDate other) => compareTo(other) < 0;
  bool isAfter(LocalDate other) => compareTo(other) > 0;

  static LocalDate min(LocalDate a, LocalDate b) => a.isBefore(b) ? a : b;
  static LocalDate max(LocalDate a, LocalDate b) => a.isAfter(b) ? a : b;

  String toIso() =>
      '${year.toString().padLeft(4, '0')}-${_two(month)}-${_two(day)}';

  @override
  int compareTo(LocalDate other) {
    if (year != other.year) return year - other.year;
    if (month != other.month) return month - other.month;
    return day - other.day;
  }

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIso();
}

/// A wall-clock time of day (no date, no time zone).
class ClockTime implements Comparable<ClockTime> {
  const ClockTime(this.hour, this.minute);

  factory ClockTime.fromDateTime(DateTime dateTime) =>
      ClockTime(dateTime.hour, dateTime.minute);

  /// Parses `HH:mm`.
  factory ClockTime.parse(String value) {
    final parts = value.split(':');
    return ClockTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  static ClockTime? tryParse(Object? value) {
    if (value is! String || value.isEmpty) return null;
    try {
      return ClockTime.parse(value);
    } on FormatException {
      return null;
    }
  }

  final int hour;
  final int minute;

  int get minutesOfDay => hour * 60 + minute;

  String toIso() => '${_two(hour)}:${_two(minute)}';

  @override
  int compareTo(ClockTime other) => minutesOfDay - other.minutesOfDay;

  @override
  bool operator ==(Object other) =>
      other is ClockTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => toIso();
}

String _two(int value) => value.toString().padLeft(2, '0');
