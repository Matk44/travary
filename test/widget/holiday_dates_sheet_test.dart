import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travary/design/tokens.dart';
import 'package:travary/design/widgets/holiday_dates_sheet.dart';
import 'package:travary/domain/domain.dart';

/// The dates sheet on small, standard and large phones with normal and
/// large text: it opens on the right month, the range fills in, and nothing
/// overflows. `TRAVARY_ONBOARDING_QA=1` renders it with the app's fonts into
/// `build/holiday_dates/`.
void main() {
  final qa = Platform.environment['TRAVARY_ONBOARDING_QA'] == '1';
  setUpAll(() async {
    TravaryText.useGoogleFonts = false;
    if (!qa) return;
    final fonts = Directory('build/visual_qa/fonts').listSync().whereType<File>();
    for (final family in ['Source Serif 4', 'Inter', 'MaterialIcons']) {
      final prefix = family == 'Source Serif 4' ? 'SourceSerif4' : family;
      final loader = FontLoader(family);
      for (final file in fonts.where((f) => f.uri.pathSegments.last.startsWith(prefix))) {
        loader.addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
      }
      await loader.load();
    }
    TravaryText.serifFamily = 'Source Serif 4';
    TravaryText.sansFamily = 'Inter';
  });
  tearDownAll(() {
    TravaryText.serifFamily = null;
    TravaryText.sansFamily = null;
  });

  const today = LocalDate(2026, 10, 9);
  HolidayDates? result;

  Future<void> open(
    WidgetTester tester, {
    required Size size,
    double scale = 1,
    LocalDate? start,
    LocalDate? end,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.reset);
    result = null;
    await tester.pumpWidget(
      MaterialApp(
        theme: qa
            ? buildTravaryTheme().copyWith(textTheme: buildTravaryTheme().textTheme.apply(fontFamily: 'Inter'))
            : buildTravaryTheme(),
        // Around the navigator, so the capture includes the sheet.
        builder: (context, child) => RepaintBoundary(
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async => result = await showHolidayDates(context, today: today, start: start, end: end),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (!qa) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary).first);
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/holiday_dates').create(recursive: true);
      await File('build/holiday_dates/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final (name, size) in [('320', Size(320, 568)), ('390', Size(390, 844)), ('430', Size(430, 932))]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets('choose a holiday: $name at ${scale}x', (tester) async {
        await open(tester, size: size, scale: scale);
        expect(find.text('October 2026'), findsOneWidget);
        for (final day in ['2026-10-16', '2026-10-23']) {
          await tester.ensureVisible(find.byKey(ValueKey('date-$day')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(ValueKey('date-$day')));
          await tester.pumpAndSettle();
        }
        expect(find.text('7 nights'), findsOneWidget);
        await capture(tester, 'dates-$name${scale == 1 ? '' : '-large'}');
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('holiday-dates-confirm')));
        await tester.pumpAndSettle();
        expect(result, (start: const LocalDate(2026, 10, 16), end: const LocalDate(2026, 10, 23)));
      });
    }
  }

  testWidgets('it opens on the holiday already chosen, and Clear starts again', (tester) async {
    await open(
      tester,
      size: const Size(390, 844),
      start: const LocalDate(2027, 3, 1),
      end: const LocalDate(2027, 3, 10),
    );
    expect(find.text('March 2027'), findsOneWidget);
    expect(find.text('9 nights'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('holiday-dates-clear')));
    await tester.pumpAndSettle();
    expect(find.text('Tap the day you leave'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
  });
}
