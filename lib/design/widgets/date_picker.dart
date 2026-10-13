import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// The day-first, Monday-first calendar the rest of the app uses
/// (`calendarWeeks`, "14 Oct"): the platform's own date dialog would follow
/// the phone's region (Sunday first, month first). Its colours come from
/// the app theme (`buildTravaryTheme`).
Future<DateTime?> showTravaryDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTime? currentDate,
  String? helpText,
}) => showDatePicker(
  context: context,
  initialDate: initialDate,
  firstDate: firstDate,
  lastDate: lastDate,
  currentDate: currentDate,
  helpText: helpText,
  builder: (context, child) =>
      Localizations.override(context: context, delegates: const [_DayFirstDelegate()], child: child),
);

/// The app's English with its dates: the week starts on Monday and days
/// come before months, like every date the app writes ([formatDayShort]).
class _DayFirstLocalizations extends DefaultMaterialLocalizations {
  const _DayFirstLocalizations();

  static final _compact = DateFormat('dd/MM/y');

  @override
  int get firstDayOfWeekIndex => 1;

  /// The picker's heading for the chosen day: "Wed 14 Oct".
  @override
  String formatMediumDate(DateTime date) => DateFormat('EEE d MMM').format(date);

  @override
  String formatShortDate(DateTime date) => DateFormat('d MMM y').format(date);

  @override
  String formatFullDate(DateTime date) => DateFormat('EEEE, d MMMM y').format(date);

  /// What typing a date asks for and shows: "14/10/2026".
  @override
  String formatCompactDate(DateTime date) => _compact.format(date);

  @override
  String get dateHelpText => 'dd/mm/yyyy';

  @override
  DateTime? parseCompactDate(String? inputString) {
    if (inputString == null) return null;
    try {
      return _compact.parseStrict(inputString);
    } on FormatException {
      return null;
    }
  }
}

class _DayFirstDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _DayFirstDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) => SynchronousFuture(const _DayFirstLocalizations());

  @override
  bool shouldReload(_DayFirstDelegate old) => false;
}
