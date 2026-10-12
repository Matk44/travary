import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../logic/reminders.dart';

/// Sets Travary's reminders on this phone (`logic/reminders.dart`): local
/// notifications, nothing sent to a server.
abstract interface class ReminderScheduler {
  /// Whether this phone lets Travary show notifications.
  Future<bool> allowed();

  /// The system's prompt (it shows once). Returns whether they're allowed.
  Future<bool> ask();

  /// Replaces every reminder still to show with [reminders], on the phone's
  /// clock as it is now.
  Future<void> setAll(List<Reminder> reminders);

  /// What a reminder tapped to open the app from cold opens, once.
  Future<String?> takeLaunch();

  /// What reminders tapped while the app was running open.
  Stream<String> get tapped;
}

/// flutter_local_notifications. Each [setAll] reads the phone's time zone
/// again, so a reminder lands on the local clock of wherever it is.
class LocalReminderScheduler implements ReminderScheduler {
  LocalReminderScheduler({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _taps = StreamController<String>.broadcast();
  Future<void>? _ready;
  bool _launchTaken = false;

  static const _channel = AndroidNotificationDetails(
    'reminders',
    'Reminders',
    channelDescription: 'Your day\'s plan each morning of a trip, and a nudge before your bookings',
    icon: 'ic_stat_reminder',
  );

  // iOS shows them even while Travary is open.
  static const _darwin = DarwinNotificationDetails(presentBanner: true, presentList: true, presentSound: true);

  bool get _android => defaultTargetPlatform == TargetPlatform.android;

  Future<void> _start() => _ready ??= () async {
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_stat_reminder'),
        // Asked for on its own card, never at launch.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload case final opens?) _taps.add(opens);
      },
    );
  }();

  @override
  Future<bool> allowed() async {
    await _start();
    if (_android) {
      return await _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
    }
    final options = await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.checkPermissions();
    return options?.isEnabled ?? false;
  }

  @override
  Future<bool> ask() async {
    await _start();
    if (_android) {
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } else {
      await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
        alert: true,
        sound: true,
      );
    }
    return allowed();
  }

  @override
  Future<void> setAll(List<Reminder> reminders) async {
    await _start();
    // Where the phone is now (it may have flown since last time).
    tz.setLocalLocation(tz.getLocation((await FlutterTimezone.getLocalTimezone()).identifier));
    await _plugin.cancelAllPendingNotifications();
    for (final (i, reminder) in reminders.indexed) {
      final at = reminder.at;
      final when = tz.TZDateTime(tz.local, at.year, at.month, at.day, at.hour, at.minute, at.second);
      // Due by now (the clock moved on while they were worked out): the
      // plugin refuses the past, and one refusal mustn't lose the rest.
      if (!when.isAfter(tz.TZDateTime.now(tz.local))) continue;
      await _plugin.zonedSchedule(
        id: i + 1,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: when,
        notificationDetails: const NotificationDetails(android: _channel, iOS: _darwin),
        // A minute or two late is fine; no exact-alarm permission needed.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: reminder.opens,
      );
    }
  }

  @override
  Future<String?> takeLaunch() async {
    if (_launchTaken) return null;
    _launchTaken = true;
    await _start();
    final launch = await _plugin.getNotificationAppLaunchDetails();
    return launch?.didNotificationLaunchApp == true ? launch?.notificationResponse?.payload : null;
  }

  @override
  Stream<String> get tapped => _taps.stream;
}

/// Demo mode and tests: remembers what it was asked to set.
class MemoryReminderScheduler implements ReminderScheduler {
  MemoryReminderScheduler({this.permitted = false, this.grants = true});

  bool permitted;

  /// What the system's prompt answers.
  bool grants;
  int asked = 0;
  List<Reminder> set = const [];
  String? launch;
  final _taps = StreamController<String>.broadcast();

  @override
  Future<bool> allowed() async => permitted;

  @override
  Future<bool> ask() async {
    asked++;
    return permitted = permitted || grants;
  }

  @override
  Future<void> setAll(List<Reminder> reminders) async => set = List.unmodifiable(reminders);

  @override
  Future<String?> takeLaunch() async {
    final opens = launch;
    launch = null;
    return opens;
  }

  /// A reminder tapped.
  void tap(String opens) => _taps.add(opens);

  @override
  Stream<String> get tapped => _taps.stream;
}
