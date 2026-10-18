import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// What this phone has done about the home-screen countdown widget, whoever
/// is signed in: whether the offer on Today was turned down, and whether the
/// widget has ever been seen on the home screen.
typedef CountdownWidgetChoice = ({bool declined, bool everAdded});

abstract interface class CountdownWidgetSettings {
  Future<CountdownWidgetChoice> load();
  Future<void> save(CountdownWidgetChoice choice);
}

class LocalCountdownWidgetSettings implements CountdownWidgetSettings {
  LocalCountdownWidgetSettings({Directory? directory}) : _directory = directory;
  Directory? _directory;

  Future<File> _file() async {
    final directory = _directory ??= Directory(p.join((await getApplicationSupportDirectory()).path, 'widget'));
    return File(p.join(directory.path, 'settings.json'));
  }

  @override
  Future<CountdownWidgetChoice> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) return (declined: false, everAdded: false);
      final json = jsonDecode(await file.readAsString());
      return (declined: json is Map && json['declined'] == true, everAdded: json is Map && json['everAdded'] == true);
    } catch (_) {
      // Unreadable: offered again, which is harmless.
      return (declined: false, everAdded: false);
    }
  }

  @override
  Future<void> save(CountdownWidgetChoice choice) async {
    try {
      final file = await _file();
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode({'declined': choice.declined, 'everAdded': choice.everAdded}), flush: true);
    } catch (_) {
      // Not saved: at worst the offer comes back.
    }
  }
}

class MemoryCountdownWidgetSettings implements CountdownWidgetSettings {
  MemoryCountdownWidgetSettings([this.choice = (declined: false, everAdded: false)]);
  CountdownWidgetChoice choice;

  @override
  Future<CountdownWidgetChoice> load() async => choice;

  @override
  Future<void> save(CountdownWidgetChoice choice) async => this.choice = choice;
}
