import 'dart:async';

import 'package:travary/design/widgets/travi_player.dart';

/// Every test file: Travi shows key frames without films or holds, so
/// screens settle (`test/widget/travi_player_test.dart` plays them).
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TraviPlayer.playback = false;
  await testMain();
}
