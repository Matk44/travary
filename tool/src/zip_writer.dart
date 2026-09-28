import 'dart:typed_data';

import 'package:archive/archive.dart' show getCrc32;

/// One file to put in a zip.
class ZipSource {
  const ZipSource(this.name, this.bytes);

  /// Path inside the archive (ASCII, `/`-separated).
  final String name;
  final List<int> bytes;
}

/// A reproducible zip: entries in the given order, stored uncompressed
/// (pack images are already compressed), fixed 1980-01-01 timestamps, no
/// extra fields, comments or OS-specific attributes. The same inputs give
/// the same bytes, and so the same SHA-256, on every machine.
Uint8List buildStoredZip(List<ZipSource> entries) {
  if (entries.length >= 0xFFFF) throw ArgumentError('Too many entries for a zip without ZIP64.');
  final out = BytesBuilder(copy: false);
  final central = BytesBuilder(copy: false);
  const dosDate = (0 << 9) | (1 << 5) | 1; // 1980-01-01
  const version = 20; // 2.0, MS-DOS host: no Unix modes

  for (final entry in entries) {
    final name = entry.name.codeUnits;
    if (name.isEmpty || name.any((c) => c < 0x21 || c > 0x7E)) {
      throw ArgumentError('Zip entry names must be plain ASCII: ${entry.name}');
    }
    if (entry.bytes.length >= 0xFFFFFFFF) throw ArgumentError('${entry.name} is too large for a zip without ZIP64.');
    final crc = getCrc32(entry.bytes);
    final offset = out.length;

    final local = ByteData(30)
      ..setUint32(0, 0x04034b50, Endian.little)
      ..setUint16(4, version, Endian.little)
      ..setUint16(6, 0, Endian.little) // flags
      ..setUint16(8, 0, Endian.little) // stored
      ..setUint16(10, 0, Endian.little) // time
      ..setUint16(12, dosDate, Endian.little)
      ..setUint32(14, crc, Endian.little)
      ..setUint32(18, entry.bytes.length, Endian.little)
      ..setUint32(22, entry.bytes.length, Endian.little)
      ..setUint16(26, name.length, Endian.little)
      ..setUint16(28, 0, Endian.little);
    out
      ..add(local.buffer.asUint8List())
      ..add(name)
      ..add(entry.bytes);

    final header = ByteData(46)
      ..setUint32(0, 0x02014b50, Endian.little)
      ..setUint16(4, version, Endian.little) // made by
      ..setUint16(6, version, Endian.little) // needed
      ..setUint16(8, 0, Endian.little)
      ..setUint16(10, 0, Endian.little)
      ..setUint16(12, 0, Endian.little)
      ..setUint16(14, dosDate, Endian.little)
      ..setUint32(16, crc, Endian.little)
      ..setUint32(20, entry.bytes.length, Endian.little)
      ..setUint32(24, entry.bytes.length, Endian.little)
      ..setUint16(28, name.length, Endian.little)
      ..setUint16(30, 0, Endian.little) // extra
      ..setUint16(32, 0, Endian.little) // comment
      ..setUint16(34, 0, Endian.little) // disk
      ..setUint16(36, 0, Endian.little) // internal attributes
      ..setUint32(38, 0, Endian.little) // external attributes
      ..setUint32(42, offset, Endian.little);
    central
      ..add(header.buffer.asUint8List())
      ..add(name);
  }

  final directoryOffset = out.length;
  final directory = central.takeBytes();
  out.add(directory);
  final end = ByteData(22)
    ..setUint32(0, 0x06054b50, Endian.little)
    ..setUint16(4, 0, Endian.little)
    ..setUint16(6, 0, Endian.little)
    ..setUint16(8, entries.length, Endian.little)
    ..setUint16(10, entries.length, Endian.little)
    ..setUint32(12, directory.length, Endian.little)
    ..setUint32(16, directoryOffset, Endian.little)
    ..setUint16(20, 0, Endian.little);
  out.add(end.buffer.asUint8List());
  return out.takeBytes();
}
