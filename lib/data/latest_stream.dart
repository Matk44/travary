import 'dart:async';

/// A stream that starts with the current value, then follows [updates].
///
/// It subscribes to [updates] the moment it's listened to, so nothing
/// emitted in between is lost (an `async*` generator with `yield*` can miss
/// events sent before it reaches the `yield*`).
Stream<T> startWith<T>(T Function() current, Stream<T> updates) {
  late final StreamController<T> controller;
  StreamSubscription<T>? subscription;
  controller = StreamController<T>(
    onListen: () {
      controller.add(current());
      subscription = updates.listen(controller.add, onError: controller.addError);
    },
    onCancel: () => subscription?.cancel(),
  );
  return controller.stream;
}
