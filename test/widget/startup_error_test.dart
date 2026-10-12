import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travary/app/app.dart';
import 'package:travary/design/tokens.dart';

void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);

  testWidgets('a start that failed (no signal on the first open) can be tried again', (tester) async {
    var tries = 0;
    await tester.pumpWidget(
      StartupErrorApp(
        message: 'Travary needs the internet the first time it opens.',
        hint: 'Connect to Wi-Fi or mobile data and try again.',
        onRetry: () async => tries++,
      ),
    );
    expect(find.text('Travary needs the internet the first time it opens.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('startup-retry')));
    await tester.pump();
    expect(tries, 1);
  });
}
