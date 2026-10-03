import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travary/design/tokens.dart';

import '../support/documents_stamps.dart';
import '../support/open_tab.dart';

/// The Documents tab on its scenic stamps, as goldens: Orlando (the
/// approved concept, docs/mockups/documents-themed-v2/02-collectible-
/// scenic-stamps.png) and the Lake District (another destination: its own
/// stamp, place name and scenes). Rendered with the test font, so they are
/// stable; `tool/visual_qa.sh` renders the same screens with the app's
/// fonts. Update with `flutter test --update-goldens test/widget/documents_golden_test.dart`.
void main() {
  setUpAll(() => TravaryText.useGoogleFonts = false);
  final catalog = catalogWithStamps();

  Future<void> pumpDocuments(WidgetTester tester, DateTime now) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2;
    tester.view.padding = const FakeViewPadding(bottom: 34 * 2);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34 * 2);
    addTearDown(tester.view.reset);
    Future<void> open() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('documents'),
          child: documentsApp(catalog: catalog, now: now),
        ),
      );
      await tester.pumpAndSettle();
      await openTab(tester, 'Documents');
    }

    await open();
    await decodePictures(tester);
    await open();
  }

  testWidgets('Orlando', (tester) async {
    await pumpDocuments(tester, documentsNow);
    await expectLater(find.byKey(const ValueKey('documents')), matchesGoldenFile('goldens/documents_orlando.png'));
  });

  testWidgets('the Lake District', (tester) async {
    await pumpDocuments(tester, lakesNow);
    await expectLater(
      find.byKey(const ValueKey('documents')),
      matchesGoldenFile('goldens/documents_lake_district.png'),
    );
  });
}
