import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../design/trip_chrome.dart';
import '../state/travel_store.dart';

/// Gives everything below it the focused trip's palette and interface art
/// (the trip Today shows), refreshed when packs install or the trip changes.
class TripChromeScope extends StatelessWidget {
  const TripChromeScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<TravelStore>();
    final plan = store.focus.plan;
    return TravaryChrome(colors: TripColors.of(store.paletteFor(plan)), slots: store.chromeArtFor(plan), child: child);
  }
}
