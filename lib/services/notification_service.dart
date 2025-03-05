import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // Channel configuration moved to constants for easier customization
  static const String dailyReminderChannelId = 'daily_reminder_channel';
  static const String dailyReminderChannelName = 'Daily Reminders';
  static const String dailyReminderChannelDescription =
      'Daily reminder to complete course tasks';

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request permissions for Android
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
    flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    // Consolidate iOS permission request inside init()
    if (Platform.isIOS) {
      final iosImpl = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);
    }

    if (Platform.isAndroid) {
      print(
          "[NotificationService] If you're on Android 12+, enable 'Alarms & Reminders' permission in system settings.");
    }
  }

  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required int second,
    required DateTime startDate,
  }) async {
    print(
        "[NotificationService] Scheduling notification ID: $id at $hour:$minute:$second");

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      dailyReminderChannelId,
      dailyReminderChannelName,
      channelDescription: dailyReminderChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      ongoing: false,
    );

    const NotificationDetails notificationDetails =
    NotificationDetails(android: androidDetails);

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        _nextInstanceOfTime(hour, minute, second, startDate),
        notificationDetails,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print("[NotificationService] Notification scheduled successfully!");
    } catch (e) {
      print("[NotificationService] Error scheduling notification: $e");
    }
  }

  tz.TZDateTime _nextInstanceOfTime(
      int hour, int minute, int second, DateTime startDate) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
        tz.local, startDate.year, startDate.month, startDate.day, hour, minute, second);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    print("[NotificationService] Next scheduled notification: $scheduledDate");
    return scheduledDate;
  }

  Future<void> cancelAllNotifications() async {
    print("[NotificationService] Cancelling all notifications.");
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    print("[NotificationService] Cancelling notification ID: $id");
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> sendTestNotification() async {
    print("[NotificationService] Sending test notification...");
    await flutterLocalNotificationsPlugin.show(
      0,
      "Test Notification",
      "This is a test notification!",
      const NotificationDetails(
        iOS: DarwinNotificationDetails(),
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          channelDescription: 'Channel for test notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}
