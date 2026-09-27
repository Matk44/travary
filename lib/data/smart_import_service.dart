import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../domain/domain.dart';

/// What Smart Import found in a file.
class SmartImportResult {
  const SmartImportResult(this.drafts, {this.warning});

  final List<BookingDraft> drafts;

  /// A short note from the reader, e.g. "Part of the page was cut off".
  final String? warning;
}

/// A problem worth showing the traveller as-is.
class SmartImportException implements Exception {
  const SmartImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reads a screenshot, photo or PDF of a booking into draft bookings.
abstract interface class SmartImportService {
  Future<SmartImportResult> read(String path, {required LocalDate today});
}

/// Largest file sent for reading (the server allows a little more).
const smartImportMaxBytes = 14 * 1024 * 1024;

/// The media type for a file Smart Import can read, or null.
String? smartImportMimeType(String path) {
  final dot = path.lastIndexOf('.');
  final extension = dot == -1 ? '' : path.substring(dot + 1).toLowerCase();
  return switch (extension) {
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'webp' => 'image/webp',
    'heic' => 'image/heic',
    'heif' => 'image/heif',
    'pdf' => 'application/pdf',
    _ => null,
  };
}

/// Calls the `smartImport` Cloud Function (Gemini). [ensureSignedIn] makes
/// sure Firebase is ready and the traveller is signed in, even in demo mode.
class CloudSmartImportService implements SmartImportService {
  CloudSmartImportService({required this.ensureSignedIn, FirebaseFunctions? functions})
    : _functions = functions;

  final Future<void> Function() ensureSignedIn;
  final FirebaseFunctions? _functions;

  @override
  Future<SmartImportResult> read(String path, {required LocalDate today}) async {
    final mimeType = smartImportMimeType(path);
    if (mimeType == null) {
      throw const SmartImportException('Use a photo, screenshot or PDF.');
    }
    final file = File(path);
    final size = await file.length();
    if (size > smartImportMaxBytes) {
      throw const SmartImportException('That file is too big. Try a screenshot of the booking instead.');
    }

    try {
      await ensureSignedIn();
      final callable = (_functions ?? FirebaseFunctions.instance).httpsCallable(
        'smartImport',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
      );
      final response = await callable.call<Map<String, dynamic>>({
        'files': [
          {'mimeType': mimeType, 'data': base64Encode(await file.readAsBytes())},
        ],
        'today': today.toIso(),
      });
      return smartImportResultFromJson(response.data);
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) debugPrint('smartImport failed: code=${e.code} message=${e.message}');
      throw SmartImportException(
        e.message?.isNotEmpty == true && e.code != 'internal'
            ? e.message!
            : 'Smart Import had a problem. Try again shortly.',
      );
    } on SocketException {
      throw const SmartImportException('Smart Import needs an internet connection.');
    }
  }
}

/// Parses the function's response. Tolerant: anything malformed is skipped
/// (the server already validated it).
SmartImportResult smartImportResultFromJson(Map<String, dynamic> json) {
  final now = DateTime.now();
  final drafts = <BookingDraft>[];
  for (final item in json['bookings'] as List? ?? const []) {
    if (item is! Map) continue;
    final map = Map<String, Object?>.from(item);
    final startDate = LocalDate.tryParse(map['startDate']);
    if (startDate == null) continue;
    String? text(String key) {
      final value = map[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    drafts.add(
      BookingDraft(
        Booking(
          id: '',
          tripId: '',
          kind: BookingKind.fromName(text('kind')),
          title: text('title') ?? 'Booking',
          startDate: startDate,
          startTime: ClockTime.tryParse(map['startTime']),
          endDate: LocalDate.tryParse(map['endDate']),
          endTime: ClockTime.tryParse(map['endTime']),
          location: text('location'),
          reference: text('reference'),
          notes: text('notes'),
          details: {
            for (final entry in (map['details'] as Map? ?? const {}).entries)
              if (entry.value is String && (entry.value as String).isNotEmpty)
                '${entry.key}': entry.value as String,
          },
          createdAt: now,
          updatedAt: now,
        ),
        uncertain: {for (final f in map['uncertain'] as List? ?? const []) '$f'},
      ),
    );
  }
  final warning = json['warning'];
  return SmartImportResult(drafts, warning: warning is String && warning.isNotEmpty ? warning : null);
}
