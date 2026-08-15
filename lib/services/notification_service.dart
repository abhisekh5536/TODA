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

  static bool _initialized = false;

  /// Must be called once in main() — MUST be awaited.
  /// Call [initWithTimezone] after this to set the correct device timezone.
  static Future<void> init() async {
    tz.initializeTimeZones();
    // Default to Asia/Kolkata; will be overridden by initWithTimezone()
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

  /// Set the device's actual timezone. Call once after platform is ready.
  /// Accepts a timezone name like 'Asia/Kolkata', 'America/New_York', etc.
  static void setTimezone(String timezoneName) {
    try {
      final location = tz.getLocation(timezoneName);
      tz.setLocalLocation(location);
      debugPrint('[TODA] Timezone set to $timezoneName');
    } catch (e) {
      debugPrint('[TODA] Failed to set timezone $timezoneName: $e');
      // Fall back to Asia/Kolkata
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    }
  }

  /// Whether the service has been initialized.
  static bool get isInitialized => _initialized;

  /// Request all needed permissions.
  /// Call once after the first frame renders (so the permission dialog has a UI).
  static Future<bool> requestPermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) return true;

    // iOS — handled by DarwinInitializationSettings requestAlertPermission etc.
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

    // Android 13+ — POST_NOTIFICATIONS
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;

    final granted = await android.requestNotificationsPermission() ?? false;
    debugPrint('[TODA] POST_NOTIFICATIONS granted: $granted');

    if (!granted) {
      debugPrint(
          '[TODA] Notification permission NOT granted — reminders will not work');
    }

    return granted;
  }

  /// Check Android 12+ exact alarm capability.
  /// If the device cannot schedule exact alarms, log a warning.
  static Future<bool> checkExactAlarmSupport() async {
    if (!Platform.isAndroid) return true;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;

    final canSchedule =
        await android.canScheduleExactNotifications() ?? true;
    if (!canSchedule) {
      debugPrint(
          '[TODA] Exact alarm not available — notifications may be inexact');
    }
    return canSchedule;
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
    if (reminderTime.isBefore(now)) {
      debugPrint(
          '[TODA] Skipping notification for "$title" — reminder time is in the past');
      return null;
    }

    final scheduledDate = tz.TZDateTime.from(reminderTime, tz.local);
    final notifId = todoId.hashCode.abs();

    debugPrint(
        '[TODA] Scheduling notification #$notifId for "$title" at $scheduledDate');

    final androidDetails = AndroidNotificationDetails(
      'toda_reminders', // channel id
      'Task Reminders', // channel name
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

    // Use allowWhileIdle for reliability — fires even in Doze mode
    final androidScheduleMode = await _resolveScheduleMode();

    try {
      await _plugin.zonedSchedule(
        notifId,
        'Almost time!',
        _buildBody(title, dueDateTime),
        scheduledDate,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: androidScheduleMode,
        matchDateTimeComponents: null,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('[TODA] Notification #$notifId scheduled (mode: $androidScheduleMode)');
    } catch (e) {
      debugPrint('[TODA] Failed to schedule notification: $e');
      // Fallback: try with inexact mode if exact fails (e.g. permission denied)
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
        debugPrint('[TODA] Notification #$notifId scheduled (inexact fallback)');
      } catch (e2) {
        debugPrint('[TODA] Fallback also failed: $e2');
        return null;
      }
    }

    return notifId;
  }

  /// Determine the best schedule mode based on device capabilities.
  static Future<AndroidScheduleMode> _resolveScheduleMode() async {
    if (!Platform.isAndroid) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return AndroidScheduleMode.inexactAllowWhileIdle;
    }

    final canExact = await android.canScheduleExactNotifications() ?? false;
    if (canExact) {
      return AndroidScheduleMode.allowWhileIdle;
    }

    debugPrint('[TODA] Exact alarm not permitted — using inexact mode');
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  /// Cancel a scheduled reminder by todoId.
  static Future<void> cancelReminder(String todoId) async {
    final notifId = todoId.hashCode.abs();
    await _plugin.cancel(notifId);
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
    final dueDay =
        DateTime(dueDateTime.year, dueDateTime.month, dueDateTime.day);

    String timeStr = '$hour12:$minute $period';
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
