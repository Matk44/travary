import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/date_picker.dart';

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  testWidgets('the date picker is Monday-first and day-first, whatever the phone\'s region', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTravaryTheme(),
        // A US phone: Sunday first, month first.
        locale: const Locale('en', 'US'),
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox();
          },
        ),
      ),
    );
    final us = MaterialLocalizations.of(context);
    expect(us.firstDayOfWeekIndex, 0, reason: 'the stock dialog would start on Sunday');
    expect(us.formatCompactDate(DateTime(2026, 10, 15)), '10/15/2026');

    final picked = showTravaryDatePicker(
      context,
      initialDate: DateTime(2026, 10, 14),
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2026, 12, 31),
      helpText: 'Check-in',
    );
    await tester.pumpAndSettle();
    final dialog = MaterialLocalizations.of(tester.element(find.byType(DatePickerDialog)));
    expect(dialog.firstDayOfWeekIndex, 1);
    expect(dialog.formatCompactDate(DateTime(2026, 10, 15)), '15/10/2026');
    expect(find.text('Check-in'), findsOneWidget);

    await tester.tap(find.text('15'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(await picked, DateTime(2026, 10, 15));
    expect(tester.takeException(), isNull);
  });
}
