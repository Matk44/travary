import 'dart:io';

import 'package:path/path.dart' as p;

import 'pack_builder.dart';
import 'webp_converter.dart';

/// What converting the bundled art did.
class BundledWebpReport {
  const BundledWebpReport({required this.files, required this.bytesBefore, required this.bytesAfter});

  /// The converted pictures, as paths from the project folder.
  final List<String> files;
  final int bytesBefore;
  final int bytesAfter;
}

/// The folders and files `pubspec.yaml` bundles, as listed under `assets:`
/// (a folder ends with `/`, and bundles only the files directly in it).
List<String> bundledAssetEntries(File pubspec) {
  final lines = pubspec.readAsLinesSync();
  final start = lines.indexWhere((line) => line.trim() == 'assets:');
  if (start < 0) throw PublishException('No assets: list in ${pubspec.path}.');
  return [
    for (final line
        in lines
            .skip(start + 1)
            .takeWhile((line) => line.trim().isEmpty || line.trim().startsWith('#') || line.trim().startsWith('- ')))
      if (RegExp(r'^\s*-\s+(\S+)\s*$').firstMatch(line) case final match?) match.group(1)!,
  ];
}

/// Re-encodes the app's bundled PNG pictures as WebP, so the store download
/// stays small: each `.png` that `pubspec.yaml` bundles (in a listed folder,
/// or listed itself) becomes a `.webp` of the same pixel size beside it
/// (`assets/art/common/linen.png` → `linen.webp`), encoded exactly like the
/// art packs' (see [encodeWebp]), and the PNG master moves to [masters] at
/// the same path without the leading `assets/`
/// (`art_masters/bundled/art/common/linen.png`), where nothing bundles it.
///
/// Bundled art is looked up by name without its extension, so nothing else
/// changes. Pictures that are already WebP, and PNGs that aren't bundled
/// (the app icon sources), are left alone. Run it on new bundled art; edit
/// the master, never the WebP. A PNG dropped beside a picture that is
/// already there is a revised master: with [replace] it takes the master's
/// place and the WebP is made again, else that is refused.
Future<BundledWebpReport> convertBundledArtToWebp({
  required Directory project,
  required Directory masters,
  bool dryRun = false,
  bool replace = false,
  String cwebp = 'cwebp',
}) async {
  final pubspec = File(p.join(project.path, 'pubspec.yaml'));
  if (!pubspec.existsSync()) throw PublishException('No pubspec.yaml in ${project.path}.');
  final pngs = <File>[];
  for (final entry in bundledAssetEntries(pubspec)) {
    final path = p.join(project.path, entry);
    if (entry.endsWith('/')) {
      final folder = Directory(path);
      if (!folder.existsSync()) continue;
      pngs.addAll(folder.listSync(followLinks: false).whereType<File>().where(_isPng));
    } else if (_isPng(File(path)) && File(path).existsSync()) {
      pngs.add(File(path));
    }
  }
  pngs.sort((a, b) => a.path.compareTo(b.path));

  // Check everything before touching anything, so a refusal leaves nothing half converted.
  final jobs = <({File png, File webp, File master, String relative})>[];
  for (final png in pngs) {
    final relative = p.relative(png.path, from: project.path);
    final webp = File('${png.path.substring(0, png.path.length - '.png'.length)}.webp');
    final master = File(
      p.join(
        masters.path,
        relative.startsWith('assets${p.separator}') ? relative.substring('assets/'.length) : relative,
      ),
    );
    if (!replace && webp.existsSync()) throw PublishException('$relative: ${p.basename(webp.path)} already exists.');
    if (!replace && master.existsSync()) throw PublishException('$relative: a master is already in ${masters.path}.');
    jobs.add((png: png, webp: webp, master: master, relative: relative));
  }

  var before = 0;
  var after = 0;
  for (final job in jobs) {
    before += job.png.lengthSync();
    if (dryRun) continue;
    await encodeWebp(png: job.png, webp: job.webp, label: job.relative, cwebp: cwebp);
    after += job.webp.lengthSync();
    job.master.parent.createSync(recursive: true);
    job.png.renameSync(job.master.path);
  }
  return BundledWebpReport(files: [for (final job in jobs) job.relative], bytesBefore: before, bytesAfter: after);
}

bool _isPng(File file) => file.path.toLowerCase().endsWith('.png');
