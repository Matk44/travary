import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart' show getCrc32;

/// One entry of a hand-made (possibly malicious) zip.
class RawEntry {
  RawEntry(
    this.name,
    List<int> content, {
    this.deflate = false,
    this.declaredSize,
    this.madeBy = 20,
    this.externalAttributes = 0,
    this.flags = 0,
    this.method,
    this.localName,
  }) : content = Uint8List.fromList(content);

  final String name;
  final Uint8List content;
  final bool deflate;

  /// Lie about the uncompressed size (zip bombs).
  final int? declaredSize;
  final int madeBy;
  final int externalAttributes;
  final int flags;

  /// Force a compression method number.
  final int? method;

  /// A different name in the local header than in the directory.
  final String? localName;
}

/// Builds a zip exactly as described, including lies a real tool wouldn't
/// write. [overlapSecond] makes the second entry's directory record point
/// at the first entry's data.
Uint8List rawZip(List<RawEntry> entries, {bool overlapSecond = false, int? entryCountOverride}) {
  final out = BytesBuilder();
  final central = BytesBuilder();
  final offsets = <int>[];
  for (final entry in entries) {
    final data = entry.deflate ? ZLibEncoder(raw: true).convert(entry.content) : entry.content;
    final method = entry.method ?? (entry.deflate ? 8 : 0);
    final crc = getCrc32(entry.content);
    final size = entry.declaredSize ?? entry.content.length;
    final name = entry.name.codeUnits;
    final localName = (entry.localName ?? entry.name).codeUnits;
    offsets.add(out.length);
    final offset = overlapSecond && offsets.length == 2 ? offsets.first : out.length;
    final local = ByteData(30)
      ..setUint32(0, 0x04034b50, Endian.little)
      ..setUint16(4, 20, Endian.little)
      ..setUint16(6, entry.flags, Endian.little)
      ..setUint16(8, method, Endian.little)
      ..setUint16(12, 0x21, Endian.little)
      ..setUint32(14, crc, Endian.little)
      ..setUint32(18, data.length, Endian.little)
      ..setUint32(22, size, Endian.little)
      ..setUint16(26, localName.length, Endian.little);
    out
      ..add(local.buffer.asUint8List())
      ..add(localName)
      ..add(data);
    final header = ByteData(46)
      ..setUint32(0, 0x02014b50, Endian.little)
      ..setUint16(4, entry.madeBy, Endian.little)
      ..setUint16(6, 20, Endian.little)
      ..setUint16(8, entry.flags, Endian.little)
      ..setUint16(10, method, Endian.little)
      ..setUint16(14, 0x21, Endian.little)
      ..setUint32(16, crc, Endian.little)
      ..setUint32(20, data.length, Endian.little)
      ..setUint32(24, size, Endian.little)
      ..setUint16(28, name.length, Endian.little)
      ..setUint32(38, entry.externalAttributes, Endian.little)
      ..setUint32(42, offset, Endian.little);
    central
      ..add(header.buffer.asUint8List())
      ..add(name);
  }
  final directory = central.takeBytes();
  final directoryOffset = out.length;
  out.add(directory);
  final count = entryCountOverride ?? entries.length;
  final end = ByteData(22)
    ..setUint32(0, 0x06054b50, Endian.little)
    ..setUint16(8, count, Endian.little)
    ..setUint16(10, count, Endian.little)
    ..setUint32(12, directory.length, Endian.little)
    ..setUint32(16, directoryOffset, Endian.little);
  out.add(end.buffer.asUint8List());
  return out.takeBytes();
}
