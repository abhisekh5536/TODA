import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Manages all local notification logic for TODA.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Must be called once in main() — MUST be awaited.
  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

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

    _initialized = true;
    debugPrint('[TODA] NotificationService initialized');
  }

  /// Whether the service has been initialized.
  static bool get isInitialized => _initialized;

  /// Request Android 13+ POST_NOTIFICATIONS permission.
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

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;

    final granted = await android.requestNotificationsPermission() ?? false;
    debugPrint('[TODA] POST_NOTIFICATIONS granted: $granted');
    return granted;
  }

  /// Schedule a "10 minutes before" reminder for a task.
  static Future<int?> scheduleReminder({
    required String todoId,
    required String title,
    required DateTime dueDateTime,
  }) async {
    await cancelReminder(todoId);

    final reminderTime = dueDateTime.subtract(const Duration(minutes: 10));
    if (reminderTime.isBefore(DateTime.now())) {
      debugPrint('[TODA] Skipping "$title" — reminder time is in the past');
      return null;
    }

    final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);
    final notifId = todoId.hashCode.abs();

    debugPrint('[TODA] Scheduling #$notifId for "$title" at $scheduledDate');

    final androidDetails = AndroidNotificationDetails(
      'toda_reminders',
      'Task Reminders',
      channelDescription:
          'Reminds you 10 minutes before a task is due',
      importance: Importance.high,
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
      debugPrint('[TODA] #$notifId scheduled OK');
    } catch (e) {
      debugPrint('[TODA] Schedule failed: $e');
      return null;
    }

    return notifId;
  }

  /// Cancel a scheduled reminder by todoId.
  static Future<void> cancelReminder(String todoId) async {
    await _plugin.cancel(todoId.hashCode.abs());
  }

  /// Cancel all pending notifications.
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static void _onTap(NotificationResponse response) {
    debugPrint('[TODA] Notification tapped: ${response.payload}');
  }

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
