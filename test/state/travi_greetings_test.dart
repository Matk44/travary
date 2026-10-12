import 'package:flutter_test/flutter_test.dart';
import 'package:travary/data/travi_greeting_record.dart';
import 'package:travary/domain/local_date.dart';
import 'package:travary/state/travi_greetings.dart';

void main() {
  const today = LocalDate(2026, 10, 10);

  test('Travi greets once a day, whoever asks first, and it\'s remembered', () async {
    final record = MemoryTraviGreetingRecord();
    final greetings = TraviGreetings(record);
    expect(await greetings.claim(today), isTrue);
    expect(await greetings.claim(today), isFalse);
    expect(record.day, today);

    // The app opens again later the same day: still greeted.
    expect(await TraviGreetings(record).claim(today), isFalse);
    // The next day he greets again.
    expect(await TraviGreetings(record).claim(const LocalDate(2026, 10, 11)), isTrue);
  });
}
