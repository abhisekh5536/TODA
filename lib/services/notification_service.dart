import 'dart:convert';
import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// SharedPreferences key prefix for storing alarm notification data
/// that the isolate callback will read.
const _kAlarmDataPrefix = 'toda_alarm_';

/// Top-level alarm callback invoked by [AndroidAlarmManager].
///
/// This runs in a **separate Dart isolate**, so it cannot access any
/// in-memory state from the main isolate.  Notification details are
/// persisted to [SharedPreferences] before scheduling and read back here.
@pragma('vm:entry-point')
Future<void> todaAlarmCallback(int alarmId) async {
  debugPrint('[TODA Alarm] Fired for #$alarmId');

  final prefs = await SharedPreferences.getInstance();
  final key = '${_kAlarmDataPrefix}$alarmId';
  final raw = prefs.getString(key);
  if (raw == null) {
    debugPrint('[TODA Alarm] No stored data for #$alarmId — skipped');
    return;
  }

  final Map<String, dynamic> details;
  try {
    details = jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    debugPrint('[TODA Alarm] Corrupt data for #$alarmId — skipped');
    await prefs.remove(key);
    return;
  }

  // Initialise the notification plugin inside this isolate.
  final plugin = FlutterLocalNotificationsPlugin();
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
  );
  await plugin.initialize(
    const InitializationSettings(android: androidInit, iOS: iosInit),
  );

  final androidDetails = AndroidNotificationDetails(
    details['channelId'] as String,
    details['channelName'] as String,
    channelDescription: details['channelDesc'] as String,
    importance: Importance.max,
    priority: Priority.high,
    showWhen: true,
    enableVibration: true,
    playSound: true,
    category: AndroidNotificationCategory.reminder,
    visibility: NotificationVisibility.public,
  );

  await plugin.show(
    alarmId,
    details['title'] as String,
    details['body'] as String,
    NotificationDetails(android: androidDetails),
    payload: details['payload'] as String?,
  );

  await prefs.remove(key);
  debugPrint('[TODA Alarm] Notification shown for #$alarmId');
}

// ─────────────────────────────────────────────────────────────────────────
/// Manages all local notification logic for TODA.
///
/// Public API ([scheduleReminder], [cancelReminder], [cancelAll]) is
/// unchanged so [TodoStore] requires no modifications.
// ─────────────────────────────────────────────────────────────────────────
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ── Initialisation ──────────────────────────────────────────────────

  /// Must be called once in [main] — **MUST be awaited**.
  static Future<void> init() async {
    tz.initializeTimeZones();
    // Do NOT hardcode a timezone.  tz.local defaults to UTC which is safe;
    // for the zonedSchedule fallback we construct TZDateTime from epoch ms
    // so the location does not matter.

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onTap,
    );

    // Initialise android_alarm_manager_plus (required before scheduling).
    if (Platform.isAndroid) {
      await AndroidAlarmManager.initialize();
    }

    _initialized = true;
    debugPrint('[TODA] NotificationService initialized');
  }

  /// Whether the service has been initialised.
  static bool get isInitialized => _initialized;

  // ── Permissions ─────────────────────────────────────────────────────

  /// Request **all** runtime permissions needed for notifications to work
  /// on the current platform.
  ///
  /// Returns `true` if the app can both show notifications **and** schedule
  /// exact alarms (Android 12+).
  static Future<bool> requestPermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      return true;
    }

    // ── Android ──
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;

    // 1. POST_NOTIFICATIONS (Android 13+)
    final notifGranted =
        await android.requestNotificationsPermission() ?? false;
    debugPrint('[TODA] POST_NOTIFICATIONS granted: $notifGranted');

    // 2. SCHEDULE_EXACT_ALARM / USE_EXACT_ALARM (Android 12+)
    final canExact = await android.canScheduleExactNotifications() ?? false;
    debugPrint('[TODA] canScheduleExactNotifications: $canExact');

    if (!canExact) {
      // On API 33+ this shows a system dialog.
      // On API 31 the user must grant it manually via Settings.
      final requested =
          await android.requestExactAlarmsPermission() ?? false;
      final canNow = await android.canScheduleExactNotifications() ?? false;
      debugPrint(
          '[TODA] requestExactAlarmsPermission returned $requested, '
          'now canSchedule=$canNow');

      if (!canNow) {
        debugPrint('[TODA] Exact alarm permission DENIED — '
            'notifications may be delayed by Android');
      }

      return notifGranted && canNow;
    }

    return notifGranted;
  }

  /// Convenience getter — can we currently schedule exact alarms?
  static Future<bool> get canScheduleExactAlarms async {
    if (!Platform.isAndroid) return true;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return (await android?.canScheduleExactNotifications()) ?? false;
  }

  // ── Scheduling ────────────────────────────────────────────────────────

  /// Schedule a "10 minutes before" reminder for a task.
  ///
  /// On Android this uses **exact** alarms via [AndroidAlarmManager] when
  /// the permission is available, falling back to [zonedSchedule] with
  /// [AndroidScheduleMode.inexactAllowWhileIdle] otherwise.
  static Future<int?> scheduleReminder({
    required String todoId,
    required String title,
    required DateTime dueDateTime,
  }) async {
    await cancelReminder(todoId);

    final reminderTime = dueDateTime.subtract(const Duration(minutes: 10));
    if (reminderTime.isBefore(DateTime.now())) {
      debugPrint('[TODA] Skipping "$title" — reminder is in the past');
      return null;
    }

    // Show immediately if less than 60 seconds away.
    if (reminderTime.difference(DateTime.now()).inSeconds < 60) {
      debugPrint('[TODA] Reminder < 60s away — showing immediately');
      await _showNow(todoId, title, dueDateTime);
      return todoId.hashCode.abs();
    }

    final notifId = todoId.hashCode.abs();
    debugPrint('[TODA] Scheduling #$notifId for "$title" '
        'at $reminderTime');

    if (Platform.isAndroid) {
      final canExact = await canScheduleExactAlarms;

      if (canExact) {
        final ok = await _scheduleExact(
          notifId: notifId,
          title: title,
          dueDateTime: dueDateTime,
          reminderTime: reminderTime,
          todoId: todoId,
        );
        if (ok) return notifId;
        debugPrint('[TODA] Exact alarm failed — falling back to inexact');
      }

      // Fallback to inexact scheduling.
      return await _scheduleInexact(
        notifId: notifId,
        title: title,
        dueDateTime: dueDateTime,
        reminderTime: reminderTime,
      );
    }

    // iOS — use zonedSchedule directly.
    return await _scheduleInexact(
      notifId: notifId,
      title: title,
      dueDateTime: dueDateTime,
      reminderTime: reminderTime,
    );
  }

  // ── Exact alarm (primary path — Android) ────────────────────────────

  static Future<bool> _scheduleExact({
    required int notifId,
    required String title,
    required DateTime dueDateTime,
    required DateTime reminderTime,
    required String todoId,
  }) async {
    // Persist notification payload so the isolate callback can read it.
    final payload = jsonEncode({
      'title': 'Almost time!',
      'body': _buildBody(title, dueDateTime),
      'channelId': 'toda_reminders',
      'channelName': 'Task Reminders',
      'channelDesc': 'Reminds you 10 minutes before a task is due',
      'payload': todoId,
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kAlarmDataPrefix$notifId', payload);

    try {
      final ok = await AndroidAlarmManager.oneShotAt(
        reminderTime,
        notifId,
        todaAlarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );
      if (ok) {
        debugPrint('[TODA] #$notifId scheduled via EXACT alarm');
        return true;
      }
    } catch (e) {
      debugPrint('[TODA] Exact alarm error: $e');
      // Clean up stored data on failure.
      await prefs.remove('$_kAlarmDataPrefix$notifId');
    }
    return false;
  }

  // ── Inexact fallback (zonedSchedule) ───────────────────────────────

  static Future<int?> _scheduleInexact({
    required int notifId,
    required String title,
    required DateTime dueDateTime,
    required DateTime reminderTime,
  }) async {
    // Build TZDateTime from epoch milliseconds (timezone-safe).
    final scheduledDate = tz.TZDateTime.fromMillisecondsSinceEpoch(
      tz.UTC,
      reminderTime.millisecondsSinceEpoch,
    );

    final androidDetails = AndroidNotificationDetails(
      'toda_reminders',
      'Task Reminders',
      channelDescription:
          'Reminds you 10 minutes before a task is due',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(
        _buildBody(title, dueDateTime),
        htmlFormatBigText: true,
        contentTitle: 'Almost time!',
        htmlFormatContentTitle: true,
        summaryText: 'TODA',
      ),
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      subtitle: 'TODA',
    );

    try {
      await _plugin.zonedSchedule(
        notifId,
        'Almost time!',
        _buildBody(title, dueDateTime),
        scheduledDate,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: null,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('[TODA] #$notifId scheduled OK (inexact fallback)');
    } catch (e) {
      debugPrint('[TODA] Inexact schedule failed: $e');
      return null;
    }

    return notifId;
  }

  // ── Show immediately (for near-term reminders) ──────────────────────

  static Future<void> _showNow(
    String todoId,
    String title,
    DateTime dueDateTime,
  ) async {
    final notifId = todoId.hashCode.abs();

    final androidDetails = AndroidNotificationDetails(
      'toda_reminders',
      'Task Reminders',
      channelDescription:
          'Reminds you 10 minutes before a task is due',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      category: AndroidNotificationCategory.reminder,
    );

    await _plugin.show(
      notifId,
      'Almost time!',
      _buildBody(title, dueDateTime),
      NotificationDetails(android: androidDetails),
      payload: todoId,
    );
  }

  // ── Cancel helpers ──────────────────────────────────────────────────

  /// Cancel a scheduled reminder by todoId.
  static Future<void> cancelReminder(String todoId) async {
    final notifId = todoId.hashCode.abs();
    await _plugin.cancel(notifId);

    if (Platform.isAndroid) {
      await AndroidAlarmManager.cancel(notifId);
    }

    // Clean up persisted payload.
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_kAlarmDataPrefix$notifId');
  }

  /// Cancel **all** pending notifications.
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();

    // Cancel all exact alarms by iterating stored IDs.
    if (Platform.isAndroid) {
      final prefs = await SharedPreferences.getInstance();
      final keys =
          prefs.getKeys().where((k) => k.startsWith(_kAlarmDataPrefix));
      for (final key in keys) {
        final id = int.tryParse(key.substring(_kAlarmDataPrefix.length));
        if (id != null) {
          await AndroidAlarmManager.cancel(id);
        }
        await prefs.remove(key);
      }
    }
  }

  // ── Tap handler ─────────────────────────────────────────────────────

  static void _onTap(NotificationResponse response) {
    debugPrint('[TODA] Notification tapped: ${response.payload}');
  }

  // ── Body text builder ───────────────────────────────────────────────

  static String _buildBody(String taskTitle, DateTime dueDateTime) {
    final hour12 = dueDateTime.hour == 0
        ? 12
        : (dueDateTime.hour > 12 ? dueDateTime.hour - 12 : dueDateTime.hour);
    final minute = dueDateTime.minute.toString().padLeft(2, '0');
    final period = dueDateTime.hour >= 12 ? 'PM' : 'AM';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay =
        DateTime(dueDateTime.year, dueDateTime.month, dueDateTime.day);

    final timeStr = '$hour12:$minute $period';
    if (dueDay == today) {
      return 'Your task is due today at $timeStr:\n\u00AB $taskTitle \u00BB';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final dateStr = '${months[dueDateTime.month - 1]} ${dueDateTime.day}';
    return 'Your task is due $dateStr at $timeStr:\n\u00AB $taskTitle \u00BB';
  }
}
