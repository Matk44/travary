import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart' show getCrc32;
import 'package:path/path.dart' as p;

import 'art_pack_catalog.dart';
import 'image_header.dart';

/// Extracts a downloaded art-pack zip, trusting nothing in it.
///
/// The whole central directory is read and checked before a single byte is
/// inflated: entry count and total size must equal the catalog's figures
/// (themselves capped by [ArtPackLimits]); every path must be a plain
/// `pack.json` or `<folder>/<name>.<png|webp|jpg|jpeg>`; no directories,
/// symlinks, devices, encryption, ZIP64, multi-disk archives, duplicate
/// names or overlapping entries. Each entry is then inflated as a stream
/// that stops the moment it exceeds its declared size, and must match its
/// CRC-32 and (for images) the signature its extension promises.
///
/// Files go only into [staging]. Throws [ArtPackFormatException]; the
/// caller removes [staging] on any failure. Returns path → size.
Future<Map<String, int>> extractArtPackArchive(
  File zip,
  Directory staging, {
  required int expectedFileCount,
  required int expectedUncompressedBytes,
}) async {
  final maxEntries = math.min(expectedFileCount, ArtPackLimits.maxFileCount);
  final maxTotal = math.min(expectedUncompressedBytes, ArtPackLimits.maxUncompressedBytes);
  final raf = await zip.open();
  try {
    final length = await raf.length();
    final directory = await _readCentralDirectory(raf, length, expectedEntries: maxEntries);
    final entries = _parseEntries(directory.bytes, directory.entryCount);

    var total = 0;
    for (final entry in entries) {
      total += entry.size;
      if (total > maxTotal) throw const ArtPackFormatException('The archive expands beyond its limit.');
    }
    if (total != expectedUncompressedBytes) {
      throw const ArtPackFormatException('The archive\'s size doesn\'t match the catalog.');
    }
    if (!entries.any((e) => e.path == artPackManifestName)) {
      throw const ArtPackFormatException('The archive has no pack.json.');
    }
    await _locateData(raf, entries, centralDirectoryOffset: directory.offset);

    final stagingRoot = p.canonicalize(staging.path);
    final sizes = <String, int>{};
    for (final entry in entries) {
      final target = File(p.join(stagingRoot, entry.path));
      if (!p.isWithin(stagingRoot, p.canonicalize(target.path))) {
        throw ArtPackFormatException('"${entry.path}" escapes the pack.');
      }
      await target.parent.create(recursive: true);
      await _extractEntry(raf, entry, target);
      sizes[entry.path] = entry.size;
    }
    return sizes;
  } on FormatException catch (e) {
    throw ArtPackFormatException('The archive is damaged (${e.message}).');
  } finally {
    await raf.close();
  }
}

class _Directory {
  const _Directory(this.bytes, this.offset, this.entryCount);

  final Uint8List bytes;
  final int offset;
  final int entryCount;
}

class _Entry {
  _Entry({
    required this.path,
    required this.nameBytes,
    required this.method,
    required this.crc,
    required this.compressedSize,
    required this.size,
    required this.localHeaderOffset,
  });

  final String path;
  final List<int> nameBytes;

  /// 0 stored, 8 deflate.
  final int method;
  final int crc;
  final int compressedSize;
  final int size;
  final int localHeaderOffset;
  int dataOffset = 0;
}

const _eocdSignature = 0x06054b50;
const _centralSignature = 0x02014b50;
const _localSignature = 0x04034b50;
const _eocdSize = 22;
const _maxCentralDirectoryBytes = 8 * 1024 * 1024;

Future<_Directory> _readCentralDirectory(RandomAccessFile raf, int length, {required int expectedEntries}) async {
  if (length < _eocdSize) throw const ArtPackFormatException('Not a zip archive.');
  final tailSize = math.min(length, _eocdSize + 0xFFFF);
  await raf.setPosition(length - tailSize);
  final tail = await raf.read(tailSize);
  final view = ByteData.sublistView(tail);
  var eocd = -1;
  for (var i = tail.length - _eocdSize; i >= 0; i--) {
    // The record must end the file exactly (after its own comment).
    if (view.getUint32(i, Endian.little) == _eocdSignature &&
        i + _eocdSize + view.getUint16(i + 20, Endian.little) == tail.length) {
      eocd = i;
      break;
    }
  }
  if (eocd < 0) throw const ArtPackFormatException('Not a zip archive.');

  final disk = view.getUint16(eocd + 4, Endian.little);
  final directoryDisk = view.getUint16(eocd + 6, Endian.little);
  final entriesHere = view.getUint16(eocd + 8, Endian.little);
  final entries = view.getUint16(eocd + 10, Endian.little);
  final size = view.getUint32(eocd + 12, Endian.little);
  final offset = view.getUint32(eocd + 16, Endian.little);
  if (disk != 0 || directoryDisk != 0 || entriesHere != entries) {
    throw const ArtPackFormatException('Multi-part archives aren\'t allowed.');
  }
  if (entries == 0xFFFF || size == 0xFFFFFFFF || offset == 0xFFFFFFFF) {
    throw const ArtPackFormatException('ZIP64 archives aren\'t allowed.');
  }
  if (entries != expectedEntries) {
    throw ArtPackFormatException('The archive has $entries files; the catalog says $expectedEntries.');
  }
  final eocdOffset = length - tailSize + eocd;
  if (size > _maxCentralDirectoryBytes || offset + size != eocdOffset) {
    throw const ArtPackFormatException('The archive\'s directory is malformed.');
  }
  await raf.setPosition(offset);
  final bytes = await raf.read(size);
  if (bytes.length != size) throw const ArtPackFormatException('The archive is truncated.');
  return _Directory(bytes, offset, entries);
}

List<_Entry> _parseEntries(Uint8List directory, int count) {
  final view = ByteData.sublistView(directory);
  final entries = <_Entry>[];
  final seen = <String>{};
  var pos = 0;
  for (var i = 0; i < count; i++) {
    if (pos + 46 > directory.length || view.getUint32(pos, Endian.little) != _centralSignature) {
      throw const ArtPackFormatException('The archive\'s directory is malformed.');
    }
    final madeBy = view.getUint16(pos + 4, Endian.little);
    final flags = view.getUint16(pos + 8, Endian.little);
    final method = view.getUint16(pos + 10, Endian.little);
    final crc = view.getUint32(pos + 16, Endian.little);
    final compressedSize = view.getUint32(pos + 20, Endian.little);
    final size = view.getUint32(pos + 24, Endian.little);
    final nameLength = view.getUint16(pos + 28, Endian.little);
    final extraLength = view.getUint16(pos + 30, Endian.little);
    final commentLength = view.getUint16(pos + 32, Endian.little);
    final diskStart = view.getUint16(pos + 34, Endian.little);
    final external = view.getUint32(pos + 38, Endian.little);
    final localOffset = view.getUint32(pos + 42, Endian.little);
    final nameEnd = pos + 46 + nameLength;
    if (nameEnd + extraLength + commentLength > directory.length) {
      throw const ArtPackFormatException('The archive\'s directory is malformed.');
    }
    final nameBytes = directory.sublist(pos + 46, nameEnd);
    pos = nameEnd + extraLength + commentLength;

    // Plain ASCII names only; the path rules below narrow them further.
    if (nameBytes.isEmpty || nameBytes.any((b) => b < 0x21 || b > 0x7E)) {
      throw const ArtPackFormatException('An archive entry has an unusable name.');
    }
    final name = String.fromCharCodes(nameBytes);
    if (flags & 0x2041 != 0) throw ArtPackFormatException('"$name" is encrypted.');
    if (method != 0 && method != 8) throw ArtPackFormatException('"$name" uses an unsupported compression.');
    if (diskStart != 0) throw const ArtPackFormatException('Multi-part archives aren\'t allowed.');
    if (size == 0xFFFFFFFF || compressedSize == 0xFFFFFFFF || localOffset == 0xFFFFFFFF) {
      throw const ArtPackFormatException('ZIP64 archives aren\'t allowed.');
    }
    if (name.endsWith('/')) throw ArtPackFormatException('"$name" is a directory entry.');
    final host = madeBy >> 8;
    if (host == 3) {
      // Unix: only regular files (a symlink is 0xA000, a directory 0x4000).
      final type = (external >> 16) & 0xF000;
      if (type != 0 && type != 0x8000) throw ArtPackFormatException('"$name" is not a regular file (symlink?).');
    } else if (external & 0x10 != 0) {
      throw ArtPackFormatException('"$name" is a directory entry.');
    }
    final path = validateArtPackPath(name);
    if (!seen.add(path)) throw ArtPackFormatException('"$path" appears twice.');
    if (method == 0 && compressedSize != size) throw ArtPackFormatException('"$path" has inconsistent sizes.');
    entries.add(
      _Entry(
        path: path,
        nameBytes: nameBytes,
        method: method,
        crc: crc,
        compressedSize: compressedSize,
        size: size,
        localHeaderOffset: localOffset,
      ),
    );
  }
  if (pos != directory.length) throw const ArtPackFormatException('The archive\'s directory is malformed.');
  return entries;
}

/// Checks each local header against the directory and that no two entries'
/// data overlap (overlapping entries are a classic zip bomb).
Future<void> _locateData(RandomAccessFile raf, List<_Entry> entries, {required int centralDirectoryOffset}) async {
  final ordered = [...entries]..sort((a, b) => a.localHeaderOffset.compareTo(b.localHeaderOffset));
  var previousEnd = 0;
  for (final entry in ordered) {
    if (entry.localHeaderOffset < previousEnd) throw const ArtPackFormatException('Archive entries overlap.');
    await raf.setPosition(entry.localHeaderOffset);
    final header = await raf.read(30);
    if (header.length != 30) throw const ArtPackFormatException('The archive is truncated.');
    final view = ByteData.sublistView(header);
    if (view.getUint32(0, Endian.little) != _localSignature) {
      throw const ArtPackFormatException('The archive\'s entries are malformed.');
    }
    final flags = view.getUint16(6, Endian.little);
    final method = view.getUint16(8, Endian.little);
    final nameLength = view.getUint16(26, Endian.little);
    final extraLength = view.getUint16(28, Endian.little);
    if (flags & 0x2041 != 0 || method != entry.method) {
      throw ArtPackFormatException('"${entry.path}" doesn\'t match the archive directory.');
    }
    final name = await raf.read(nameLength);
    if (!_sameBytes(name, entry.nameBytes)) {
      throw ArtPackFormatException('"${entry.path}" doesn\'t match the archive directory.');
    }
    entry.dataOffset = entry.localHeaderOffset + 30 + nameLength + extraLength;
    final dataEnd = entry.dataOffset + entry.compressedSize;
    if (dataEnd > centralDirectoryOffset) throw const ArtPackFormatException('The archive is truncated.');
    previousEnd = dataEnd;
  }
}

Future<void> _extractEntry(RandomAccessFile raf, _Entry entry, File target) async {
  final out = await target.open(mode: FileMode.writeOnly);
  final sink = _BoundedSink(out, entry.size, entry.path);
  try {
    await raf.setPosition(entry.dataOffset);
    final input = entry.method == 8 ? ZLibDecoder(raw: true).startChunkedConversion(sink) : sink;
    var remaining = entry.compressedSize;
    while (remaining > 0) {
      // Small reads: one deflate chunk can't balloon far before the check.
      final chunk = await raf.read(math.min(16 * 1024, remaining));
      if (chunk.isEmpty) throw ArtPackFormatException('"${entry.path}" is truncated.');
      remaining -= chunk.length;
      input.add(chunk);
    }
    input.close();
  } finally {
    await out.close();
  }
  if (sink.written != entry.size) throw ArtPackFormatException('"${entry.path}" has the wrong size.');
  if (sink.crc != entry.crc) throw ArtPackFormatException('"${entry.path}" is corrupt (CRC mismatch).');
  if (entry.path != artPackManifestName) {
    final expected = ImageType.forExtension(p.extension(entry.path).substring(1));
    if (sniffImageType(sink.head) != expected) {
      throw ArtPackFormatException('"${entry.path}" is not really a ${expected?.name} image.');
    }
  }
}

/// Writes inflated bytes, refusing anything beyond [limit].
class _BoundedSink implements Sink<List<int>> {
  _BoundedSink(this._out, this.limit, this.path);

  final RandomAccessFile _out;
  final int limit;
  final String path;
  int written = 0;
  int crc = 0;

  /// The first bytes, to check the image signature.
  final head = <int>[];

  @override
  void add(List<int> chunk) {
    written += chunk.length;
    if (written > limit) throw ArtPackFormatException('"$path" expands beyond its declared size.');
    crc = getCrc32(chunk, crc);
    if (head.length < 16) head.addAll(chunk.take(16 - head.length));
    _out.writeFromSync(chunk);
  }

  @override
  void close() {}
}

bool _sameBytes(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
