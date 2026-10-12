import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/local_date.dart';

/// The last day Travi greeted the traveller on his own
/// (`logic/travi_cameos.dart`, `greetsToday`): on this phone, whoever is
/// signed in. Only a date is kept.
abstract interface class TraviGreetingRecord {
  Future<LocalDate?> load();
  Future<void> save(LocalDate day);
}

class LocalTraviGreetingRecord implements TraviGreetingRecord {
  LocalTraviGreetingRecord({Directory? directory}) : _directory = directory;
  Directory? _directory;

  Future<File> _file() async {
    final directory = _directory ??= Directory(p.join((await getApplicationSupportDirectory()).path, 'travi'));
    return File(p.join(directory.path, 'greeted.txt'));
  }

  @override
  Future<LocalDate?> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      return LocalDate.parse((await file.readAsString()).trim());
    } catch (_) {
      // Unreadable: he greets again, which is harmless.
      return null;
    }
  }

  @override
  Future<void> save(LocalDate day) async {
    try {
      final file = await _file();
      await file.parent.create(recursive: true);
      await file.writeAsString(day.toString(), flush: true);
    } catch (_) {
      // Not saved: at worst he greets once more today.
    }
  }
}

class MemoryTraviGreetingRecord implements TraviGreetingRecord {
  MemoryTraviGreetingRecord([this.day]);
  LocalDate? day;

  @override
  Future<LocalDate?> load() async => day;

  @override
  Future<void> save(LocalDate day) async => this.day = day;
}
