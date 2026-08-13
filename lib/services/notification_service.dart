import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Manages all local notification logic for TODA.
/// Professional notification styling — no generic AI look.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Must be called once in main() before runApp.
  static Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onTap,
    );
  }

  /// Request Android 13+ POST_NOTIFICATIONS permission.
  /// Call once after the first frame renders.
  static Future<bool> requestPermission() async {
    if (!Platform.isAndroid) return true;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;

    return await android.requestNotificationsPermission() ?? false;
  }

  /// Schedule a "10 minutes before" reminder for a task.
  /// Returns the notification ID used (for later cancellation).
  static Future<int?> scheduleReminder({
    required String todoId,
    required String title,
    required DateTime dueDateTime,
  }) async {
    // Cancel any existing reminder for this todo first
    await cancelReminder(todoId);

    final reminderTime = dueDateTime.subtract(const Duration(minutes: 10));
    final now = DateTime.now();

    // If the reminder time is in the past, skip scheduling
    if (reminderTime.isBefore(now)) return null;

    final local = tz.TZDateTime.from(reminderTime, tz.local);
    final notifId = todoId.hashCode.abs();

    final androidDetails = AndroidNotificationDetails(
      'toda_reminders',           // channel id
      'Task Reminders',           // channel name
      channelDescription: 'Reminds you 10 minutes before a task is due',
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

    await _plugin.zonedSchedule(
      notifId,
      'Almost time!  ⏳',
      _buildBody(title, dueDateTime),
      local,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: null,
    );

    return notifId;
  }

  /// Cancel a scheduled reminder by todoId.
  static Future<void> cancelReminder(String todoId) async {
    await _plugin.cancel(todoId.hashCode.abs());
  }

  /// Cancel all pending notifications (e.g., on logout / clear data).
  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Handle notification tap — could navigate to task detail.
  static void _onTap(NotificationResponse response) {
    debugPrint('[TODA] Notification tapped: ${response.payload}');
    // Future: navigate to the specific task detail screen
  }

  /// Build the notification body text.
  static String _buildBody(String taskTitle, DateTime dueDateTime) {
    final hour12 = dueDateTime.hour == 0
        ? 12
        : (dueDateTime.hour > 12 ? dueDateTime.hour - 12 : dueDateTime.hour);
    final minute = dueDateTime.minute.toString().padLeft(2, '0');
    final period = dueDateTime.hour >= 12 ? 'PM' : 'AM';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDateTime.year, dueDateTime.month, dueDateTime.day);

    String timeStr = '$hour12:$minute $period';
    if (dueDay == today) {
      return 'Your task is due today at $timeStr:\n« $taskTitle »';
    }
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final dateStr = '${months[dueDateTime.month - 1]} ${dueDateTime.day}';
    return 'Your task is due $dateStr at $timeStr:\n« $taskTitle »';
  }
}
