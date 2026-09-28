import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart' show getCrc32;
import 'package:path/path.dart' as p;
import 'package:travary/data/art_pack_catalog.dart';
import 'package:travary/data/art_pack_service.dart';

import '../../tool/src/pack_builder.dart';

/// A real, decodable PNG of one colour.
Uint8List solidPng(int width, int height, {int red = 200, int green = 120, int blue = 90}) {
  Uint8List chunk(String type, List<int> data) {
    final typeBytes = ascii.encode(type);
    final out = ByteData(12 + data.length)..setUint32(0, data.length);
    final bytes = out.buffer.asUint8List()
      ..setRange(4, 8, typeBytes)
      ..setRange(8, 8 + data.length, data);
    out.setUint32(8 + data.length, getCrc32([...typeBytes, ...data]));
    return bytes;
  }

  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8) // bit depth
    ..setUint8(9, 2) // truecolour
    ..setUint8(10, 0)
    ..setUint8(11, 0)
    ..setUint8(12, 0);
  final raw = BytesBuilder();
  for (var y = 0; y < height; y++) {
    raw.addByte(0); // no filter
    for (var x = 0; x < width; x++) {
      raw.add([red, green, blue]);
    }
  }
  return Uint8List.fromList([
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    ...chunk('IHDR', header.buffer.asUint8List()),
    ...chunk('IDAT', ZLibEncoder().convert(raw.takeBytes())),
    ...chunk('IEND', const []),
  ]);
}

/// One image in a test pack.
class TestAsset {
  const TestAsset.card(
    this.file, {
    required this.kind,
    this.theme = 'any',
    this.subject = 'generic',
    required this.group,
    this.format = 'both',
    this.width = 32,
    this.height = 24,
  }) : role = null,
       name = null;

  const TestAsset.shared(
    this.file, {
    required String this.role,
    required String this.name,
    this.width = 16,
    this.height = 16,
  }) : kind = null,
       theme = null,
       subject = null,
       group = null,
       format = null;

  final String file;
  final String? kind;
  final String? theme;
  final String? subject;
  final String? group;
  final String? format;
  final String? role;
  final String? name;
  final int width;
  final int height;

  Map<String, Object?> toJson() => role != null
      ? {'file': file, 'kind': role, 'name': name, 'width': width, 'height': height}
      : {
          'file': file,
          'kind': kind,
          'theme': theme,
          'subject': subject,
          'group': group,
          'format': format,
          'width': width,
          'height': height,
        };
}

/// Writes a pack source folder (pack.json, catalog-entry.json, images).
Future<Directory> writePackSource(
  Directory parent, {
  required String id,
  int version = 1,
  int priority = 100,
  Map<String, Object?> selectors = const {
    'themes': ['themepark'],
  },
  List<TestAsset> assets = const [
    TestAsset.card(
      'dining/themepark_generic_01_vignette.png',
      kind: 'dining',
      theme: 'themepark',
      group: 'themepark_generic_01',
      format: 'vignette',
      width: 16,
      height: 16,
    ),
  ],
  int minAppBuild = 1,
  Map<String, Object?>? palette,
}) async {
  final source = Directory(p.join(parent.path, '$id-$version'));
  await source.create(recursive: true);
  await File(p.join(source.path, 'pack.json')).writeAsString(
    jsonEncode({
      'schemaVersion': 1,
      'packId': id,
      'version': version,
      'palette': ?palette,
      'assets': [for (final asset in assets) asset.toJson()],
    }),
  );
  await File(
    p.join(source.path, 'catalog-entry.json'),
  ).writeAsString(jsonEncode({'priority': priority, 'selectors': selectors, 'minAppBuild': minAppBuild}));
  for (final asset in assets) {
    final file = File(p.join(source.path, asset.file));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(solidPng(asset.width, asset.height));
  }
  return source;
}

/// A pack built by the real publisher.
Future<BuiltPack> buildTestPack(
  Directory parent, {
  required String id,
  int version = 1,
  int priority = 100,
  Map<String, Object?> selectors = const {
    'themes': ['themepark'],
  },
  List<TestAsset>? assets,
  int minAppBuild = 1,
  Map<String, Object?>? palette,
}) async {
  final source = await writePackSource(
    parent,
    id: id,
    version: version,
    priority: priority,
    selectors: selectors,
    palette: palette,
    assets:
        assets ??
        const [
          TestAsset.card(
            'dining/themepark_generic_01_vignette.png',
            kind: 'dining',
            theme: 'themepark',
            group: 'themepark_generic_01',
            format: 'vignette',
            width: 16,
            height: 16,
          ),
        ],
    minAppBuild: minAppBuild,
  );
  return buildArtPack(source);
}

/// The handoff's example palette (Kyoto in autumn), valid.
const kyotoPalette = <String, Object?>{
  'id': 'kyoto_autumn',
  'anchors': {'ink': '#1C2A47', 'paper': '#F8F4EC'},
  'accents': ['#9B4F3F', '#C58A3A', '#647A5E', '#6A3F5F'],
  'ui': {'primary': '#6A3F5F', 'secondary': '#647A5E', 'highlight': '#C58A3A', 'onPrimary': '#F8F4EC'},
};

/// A catalog listing [packs].
Uint8List catalogBytes(List<CatalogPack> packs, {int version = 1}) => utf8.encode(
  jsonEncode({
    'schemaVersion': 1,
    'catalogVersion': version,
    'generatedAt': '2027-04-01T00:00:00Z',
    'packs': [for (final pack in packs) pack.toJson()],
  }),
);

/// Serves a catalog and archives from memory, counting what's asked for.
class FakeArtPackRemote implements ArtPackRemote {
  Uint8List? catalog;
  final archives = <String, Uint8List>{};

  /// Errors to throw, in order, before serving an archive.
  final failures = <Object>[];
  final downloads = <String>[];
  int catalogFetches = 0;
  int cancels = 0;

  /// When set, archive downloads wait for it.
  Completer<void>? gate;

  @override
  Future<Uint8List> fetchCatalog({required int maxBytes}) async {
    catalogFetches++;
    final bytes = catalog;
    if (bytes == null) throw const ArtPackRemoteException('Offline.', transient: true);
    if (bytes.length > maxBytes) throw const ArtPackFormatException('Catalog is larger than 2 MiB.');
    return bytes;
  }

  @override
  Future<void> downloadArchive(String storagePath, File target) async {
    downloads.add(storagePath);
    await gate?.future;
    if (failures.isNotEmpty) throw failures.removeAt(0);
    final bytes = archives[storagePath];
    if (bytes == null) throw const ArtPackRemoteException('Not found (object-not-found).', transient: false);
    await target.parent.create(recursive: true);
    await target.writeAsBytes(bytes, flush: true);
  }

  @override
  void cancelAll() => cancels++;

  void serve(BuiltPack pack) => archives[pack.entry.archive.storagePath] = pack.archive;
}
