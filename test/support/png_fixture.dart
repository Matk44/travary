import 'dart:io';
import 'dart:typed_data';

/// A small RGBA PNG for the tool tests, with the things bundled art has: a
/// colour gradient, a see-through window (alpha 0) and a soft shadow
/// (alpha 128) beside opaque paper (alpha 255).
Uint8List windowedPng({int width = 64, int height = 48}) {
  final raw = BytesBuilder();
  for (var y = 0; y < height; y++) {
    raw.addByte(0); // filter: none
    for (var x = 0; x < width; x++) {
      final (r, g, b, a) = pixelAt(x, y, width, height);
      raw.add([r, g, b, a]);
    }
  }
  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 6); // RGBA
  return Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
    ..._chunk('IHDR', header.buffer.asUint8List()),
    ..._chunk('IDAT', zlib.encode(raw.toBytes())),
    ..._chunk('IEND', const []),
  ]);
}

/// What [windowedPng] draws at a pixel: the middle fifth is a window, the
/// strip under it a shadow, everything else opaque.
(int, int, int, int) pixelAt(int x, int y, int width, int height) {
  final inWindow = x >= width * 2 ~/ 5 && x < width * 3 ~/ 5 && y >= height * 2 ~/ 5 && y < height * 3 ~/ 5;
  final inShadow =
      !inWindow && x >= width * 2 ~/ 5 && x < width * 3 ~/ 5 && y >= height * 3 ~/ 5 && y < height * 4 ~/ 5;
  final alpha = inWindow ? 0 : (inShadow ? 128 : 255);
  return (x * 255 ~/ (width - 1), y * 255 ~/ (height - 1), 120, alpha);
}

List<int> _chunk(String type, List<int> data) {
  final body = [...type.codeUnits, ...data];
  final length = ByteData(4)..setUint32(0, data.length);
  final crc = ByteData(4)..setUint32(0, _crc32(body));
  return [...length.buffer.asUint8List(), ...body, ...crc.buffer.asUint8List()];
}

final _crcTable = List<int>.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = c & 1 == 1 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final byte in bytes) {
    c = _crcTable[(c ^ byte) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

/// The alpha channel of a WebP, decoded with `dwebp` (installed with
/// `cwebp`): one byte per pixel, row by row.
Uint8List webpAlpha(File webp, {String dwebp = 'dwebp'}) {
  final pam = File('${webp.path}.pam');
  final result = Process.runSync(dwebp, ['-quiet', '-pam', webp.path, '-o', pam.path]);
  if (result.exitCode != 0) throw StateError('dwebp failed: ${result.stderr}');
  final bytes = pam.readAsBytesSync();
  pam.deleteSync();
  final marker = 'ENDHDR\n'.codeUnits;
  var start = 0;
  for (var i = 0; i + marker.length <= bytes.length; i++) {
    if (List.generate(marker.length, (j) => bytes[i + j]).join(',') == marker.join(',')) {
      start = i + marker.length;
      break;
    }
  }
  final pixels = bytes.sublist(start);
  return Uint8List.fromList([for (var i = 3; i < pixels.length; i += 4) pixels[i]]);
}
