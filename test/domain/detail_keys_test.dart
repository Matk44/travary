import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:travary/domain/domain.dart';

void main() {
  test('every detail a booking form asks for, Smart Import can fill', () {
    final schema = File('functions/src/bookingSchema.ts').readAsStringSync();
    final listed = RegExp(r"DETAIL_KEYS = \[([^\]]*)\]").firstMatch(schema)!.group(1)!;
    final server = {for (final match in RegExp(r"'(\w+)'").allMatches(listed)) match.group(1)!};
    final asked = {
      for (final kind in BookingKind.values)
        for (final field in kind.spec.fields) field.key,
    };
    expect(server, containsAll(asked));
  });
}
