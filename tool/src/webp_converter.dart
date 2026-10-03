import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:travary/data/image_header.dart';

import 'pack_builder.dart';

/// What converting one pack source did.
class WebpReport {
  const WebpReport({required this.converted, required this.bytesBefore, required this.bytesAfter});

  final int converted;
  final int bytesBefore;
  final int bytesAfter;
}

/// Re-encodes a pack source's PNG pictures as WebP, so packs download in a
/// fraction of the size: each `.png` that `pack.json` declares becomes a
/// `.webp` of the same size beside it, `pack.json` names the new file (and
/// is otherwise left exactly as written), and the PNG original moves to
/// [originals]`/<pack-id>/` (never built or published).
///
/// Colour is lossy at a high quality; transparency is kept exactly, so
/// windows, deckled edges and shadows stay clean. Needs `cwebp`
/// (`brew install webp`).
Future<WebpReport> convertSourceToWebp({
  required Directory source,
  required Directory originals,
  bool dryRun = false,
  String cwebp = 'cwebp',
}) async {
  final manifestFile = File(p.join(source.path, 'pack.json'));
  if (!manifestFile.existsSync()) throw PublishException('No pack.json in ${source.path}.');
  var manifestText = manifestFile.readAsStringSync();
  final manifest = jsonDecode(manifestText) as Map<String, Object?>;
  final packId = manifest['packId'] as String? ?? p.basename(source.path);
  final files = [
    for (final asset in manifest['assets'] as List? ?? const [])
      if (asset is Map && asset['file'] is String && (asset['file'] as String).endsWith('.png'))
        asset['file'] as String,
  ];

  var before = 0;
  var after = 0;
  for (final file in files) {
    final png = File(p.join(source.path, file));
    if (!png.existsSync()) throw PublishException('$packId: $file is declared but missing.');
    final webpName = '${file.substring(0, file.length - '.png'.length)}.webp';
    final webp = File(p.join(source.path, webpName));
    if (webp.existsSync()) throw PublishException('$packId: $webpName already exists.');
    before += png.lengthSync();
    if (dryRun) continue;

    final result = await Process.run(cwebp, [
      '-quiet', '-q', '88', '-alpha_q', '100', '-m', '6', '-sharp_yuv', '-metadata', 'none', //
      png.path, '-o', webp.path,
    ]);
    if (result.exitCode != 0) {
      throw PublishException('$packId: cwebp failed on $file: ${result.stderr}'.trim());
    }
    final was = readImageInfo(png.readAsBytesSync());
    final now = readImageInfo(webp.readAsBytesSync());
    if (now == null ||
        now.type != ImageType.webp ||
        was == null ||
        now.width != was.width ||
        now.height != was.height) {
      webp.deleteSync();
      throw PublishException('$packId: $webpName came out wrong; $file is unchanged.');
    }
    after += webp.lengthSync();

    final original = File(p.join(originals.path, packId, file));
    original.parent.createSync(recursive: true);
    png.renameSync(original.path);
    manifestText = manifestText.replaceAll('"$file"', '"$webpName"');
  }
  if (!dryRun && files.isNotEmpty) manifestFile.writeAsStringSync(manifestText);
  return WebpReport(converted: files.length, bytesBefore: before, bytesAfter: after);
}
