import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'pack_builder.dart';

/// Where published art packs go. Only the publisher writes; the app reads.
abstract interface class ArtPackBucket {
  /// The object's bytes, or null if it doesn't exist.
  Future<Uint8List?> read(String path);

  Future<bool> exists(String path);

  Future<void> write(String path, List<int> bytes, {required String contentType});

  /// A short description for logs.
  String get label;
}

/// The Firebase Storage emulator, written with its admin bypass (for local
/// development and tests only).
class EmulatorBucket implements ArtPackBucket {
  EmulatorBucket({required this.host, required this.bucket});

  /// `127.0.0.1:9199`.
  final String host;
  final String bucket;

  @override
  String get label => 'emulator $host/$bucket';

  Uri _object(String path, [Map<String, String>? query]) =>
      Uri.parse('http://$host/v0/b/$bucket/o/${Uri.encodeComponent(path)}').replace(queryParameters: query);

  @override
  Future<Uint8List?> read(String path) => _send('GET', _object(path, {'alt': 'media'}), allowMissing: true);

  @override
  Future<bool> exists(String path) async => await _send('GET', _object(path), allowMissing: true) != null;

  /// A raw upload. The emulator reads a JSON body as upload metadata and
  /// waits for more, so every body goes up as octet-stream; the app only
  /// reads the bytes.
  @override
  Future<void> write(String path, List<int> bytes, {required String contentType}) async {
    final uri = Uri.parse('http://$host/v0/b/$bucket/o').replace(queryParameters: {'name': path});
    await _send(
      'POST',
      uri,
      body: bytes,
      contentType: 'application/octet-stream',
      headers: {'X-Goog-Upload-Protocol': 'raw'},
    );
  }
}

/// Production Cloud Storage (the Firebase bucket), through the JSON API with
/// the operator's own OAuth token (`gcloud auth print-access-token`). No
/// credentials are ever stored in the repository.
class CloudStorageBucket implements ArtPackBucket {
  CloudStorageBucket({required this.bucket, required this.accessToken});

  final String bucket;
  final String accessToken;

  @override
  String get label => 'gs://$bucket';

  Uri _object(String path, [Map<String, String>? query]) => Uri.parse(
    'https://storage.googleapis.com/storage/v1/b/$bucket/o/${Uri.encodeComponent(path)}',
  ).replace(queryParameters: query);

  @override
  Future<Uint8List?> read(String path) =>
      _send('GET', _object(path, {'alt': 'media'}), token: accessToken, allowMissing: true);

  @override
  Future<bool> exists(String path) async =>
      await _send('GET', _object(path), token: accessToken, allowMissing: true) != null;

  @override
  Future<void> write(String path, List<int> bytes, {required String contentType}) async {
    final uri = Uri.parse(
      'https://storage.googleapis.com/upload/storage/v1/b/$bucket/o',
    ).replace(queryParameters: {'uploadType': 'media', 'name': path});
    await _send('POST', uri, token: accessToken, body: bytes, contentType: contentType);
  }
}

Future<Uint8List?> _send(
  String method,
  Uri uri, {
  String token = 'owner',
  List<int>? body,
  String? contentType,
  Map<String, String> headers = const {},
  bool allowMissing = false,
}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
  try {
    final request = await client.openUrl(method, uri);
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    headers.forEach(request.headers.set);
    if (body != null) {
      request.headers.contentType = ContentType.parse(contentType ?? 'application/octet-stream');
      request.contentLength = body.length;
      request.add(body);
    }
    final response = await request.close().timeout(const Duration(minutes: 2));
    final bytes = await response
        .fold<BytesBuilder>(BytesBuilder(copy: false), (b, chunk) => b..add(chunk))
        .timeout(const Duration(minutes: 2));
    if (response.statusCode == HttpStatus.notFound && allowMissing) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final text = utf8.decode(bytes.takeBytes(), allowMalformed: true);
      throw PublishException(
        '$method ${uri.path} failed (${response.statusCode}): ${text.length > 300 ? text.substring(0, 300) : text}',
      );
    }
    return bytes.takeBytes();
  } on SocketException catch (e) {
    throw PublishException('Couldn\'t reach ${uri.host}: ${e.message}');
  } on TimeoutException {
    throw PublishException('$method ${uri.path} timed out.');
  } finally {
    client.close();
  }
}
