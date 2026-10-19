import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/countdown_widget_art.dart';

/// A [width] × [height] PNG: opaque blue, with its top-left quarter clear.
Future<Uint8List> _picture(int width, int height) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(width / 2, 0, width / 2, height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFF2040A0),
  );
  canvas.drawRect(
    ui.Rect.fromLTWH(0, height / 2, width / 2, height / 2),
    ui.Paint()..color = const ui.Color(0xFF2040A0),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  image.dispose();
  return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
}

/// A PNG's size, read from its header.
({int width, int height}) _size(Uint8List png) {
  final header = ByteData.sublistView(png);
  expect(png.sublist(1, 4), 'PNG'.codeUnits, reason: 'a PNG');
  return (width: header.getUint32(16), height: header.getUint32(20));
}

void main() {
  test('a large portrait picture is kept in shape and brought down to the longest side', () async {
    final shrunk = await shrinkForWidget(await _picture(1200, 1500), longestSide: 1000);
    expect(_size(shrunk!), (width: 800, height: 1000));
  });

  test('a landscape picture is brought down by its width', () async {
    final size = _size((await shrinkForWidget(await _picture(1500, 1000), longestSide: 1000))!);
    expect(size.width, 1000);
    expect(size.height, closeTo(667, 1));
  });

  test('a picture already small enough is never enlarged', () async {
    final shrunk = await shrinkForWidget(await _picture(100, 60), longestSide: 1000);
    expect(_size(shrunk!), (width: 100, height: 60));
  });

  test('clear parts stay clear (the luggage tag and Travi are cut-outs)', () async {
    final shrunk = await shrinkForWidget(await _picture(600, 600), longestSide: 300);
    final image = (await (await ui.instantiateImageCodec(shrunk!)).getNextFrame()).image;
    final rgba = (await image.toByteData())!;
    int alphaAt(int x, int y) => rgba.getUint8((y * image.width + x) * 4 + 3);
    expect(alphaAt(75, 75), 0, reason: 'the clear quarter');
    expect(alphaAt(225, 75), 255, reason: 'the painted part');
    expect(alphaAt(75, 225), 255, reason: 'the painted part');
    expect(alphaAt(225, 225), 255, reason: 'the painted part');
    image.dispose();
  });

  test('a bundled WebP postcard comes out as a PNG no larger than the widget draws', () async {
    final bytes = File('assets/art/common/countdown_postcard_anywhere.webp').readAsBytesSync();
    final shrunk = await shrinkForWidget(bytes, longestSide: CountdownWidgetArtSize.portrait);
    final size = _size(shrunk!);
    expect(size.height, CountdownWidgetArtSize.portrait);
    // Still 1122 : 1402, to a pixel.
    expect(size.width, closeTo(CountdownWidgetArtSize.portrait * 1122 / 1402, 1));
  });

  test('something that is not a picture is left to be copied as it is', () async {
    expect(await shrinkForWidget(Uint8List.fromList([1, 2, 3, 4]), longestSide: 1000), isNull);
    expect(await shrinkForWidget(Uint8List(0), longestSide: 1000), isNull);
  });
}
