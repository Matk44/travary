import 'booking.dart';

/// A booking read by Smart Import, waiting for the traveller to check it.
///
/// [booking] has no id or trip yet. [uncertain] names the fields the reader
/// wasn't sure about ("startTime", "details.seats", ...), so the form can
/// highlight them.
class BookingDraft {
  const BookingDraft(this.booking, {this.uncertain = const {}});

  final Booking booking;
  final Set<String> uncertain;

  /// Fields the form always asks the traveller to check on an import.
  /// Dates and times are the ones a wrong reading hurts most.
  static const alwaysCheck = {'startDate', 'startTime', 'endDate', 'endTime'};

  Set<String> get highlight => {...uncertain, ...alwaysCheck};
}
