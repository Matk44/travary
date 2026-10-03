import 'package:flutter_test/flutter_test.dart';
import 'package:travary/design/widgets/nav_bar.dart';

/// Opens a home tab by its nav label, without the slide.
///
/// Tapping a tab slides the pages through every tab in between (and paints
/// them). Tests that only want the tab on screen use this instead: with
/// reduced motion the pages jump straight there, the same settled result.
/// `tab_transition_test.dart` covers the slide itself.
Future<void> openTab(WidgetTester tester, String label) async {
  tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  await tester.pump(); // the app hears about it on the next frame
  await tester.tap(find.descendant(of: find.byType(TravaryNavBar), matching: find.bySemanticsLabel(label)));
  await tester.pumpAndSettle();
  tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
  await tester.pumpAndSettle();
}
