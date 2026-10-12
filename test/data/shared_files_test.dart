import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/shared_files.dart';
import 'package:travary/state/share_inbox.dart';

void main() {
  test('only PDFs and images are read; the first one wins', () {
    expect(firstBookingFile(['/a/notes.txt', 'file:///b/Booking%20Ref.pdf', '/c/x.png']), (
      path: '/b/Booking Ref.pdf',
      name: 'Booking Ref.pdf',
    ));
    expect(firstBookingFile(['/a/IMG_1.HEIC'])?.name, 'IMG_1.HEIC');
    expect(firstBookingFile(['/a/clip.mov', '/a/archive.zip']), isNull);
  });

  test('the inbox keeps the newest share until home takes it, once', () async {
    final files = MemorySharedFiles()..initial = (path: '/s/first.pdf', name: 'first.pdf');
    final inbox = ShareInbox(files);
    await inbox.start();
    expect(inbox.hasWaiting, isTrue);
    files.share((path: '/s/second.png', name: 'second.png'));
    await pumpEventQueue();
    final taken = inbox.take();
    expect(taken?.name, 'second.png');
    expect(inbox.take(), isNull);
    await inbox.done(taken!);
    expect(files.finished, [taken]);
    inbox.dispose();
  });
}
