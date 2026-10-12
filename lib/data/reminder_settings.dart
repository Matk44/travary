import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Reminders on this phone, whoever is signed in: whether they're on, and
/// whether the offer to turn them on was turned down.
typedef ReminderChoice = ({bool on, bool declined});

abstract interface class ReminderSettings {
  Future<ReminderChoice> load();
  Future<void> save(ReminderChoice choice);
}

class LocalReminderSettings implements ReminderSettings {
  LocalReminderSettings({Directory? directory}) : _directory = directory;
  Directory? _directory;

  Future<File> _file() async {
    final directory = _directory ??= Directory(p.join((await getApplicationSupportDirectory()).path, 'reminders'));
    return File(p.join(directory.path, 'settings.json'));
  }

  @override
  Future<ReminderChoice> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return (on: false, declined: false);
      final json = jsonDecode(await file.readAsString());
      return (on: json is Map && json['on'] == true, declined: json is Map && json['declined'] == true);
    } catch (_) {
      // Unreadable: off, and offered again, which is harmless.
      return (on: false, declined: false);
    }
  }

  @override
  Future<void> save(ReminderChoice choice) async {
    try {
      final file = await _file();
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode({'on': choice.on, 'declined': choice.declined}), flush: true);
    } catch (_) {
      // Not saved: at worst the choice is asked again.
    }
  }
}

class MemoryReminderSettings implements ReminderSettings {
  MemoryReminderSettings([this.choice = (on: false, declined: false)]);
  ReminderChoice choice;

  @override
  Future<ReminderChoice> load() async => choice;

  @override
  Future<void> save(ReminderChoice choice) async => this.choice = choice;
}
