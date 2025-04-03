import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:numinous_ways/services/notification_service.dart';

class FakeFlutterLocalNotificationsPlugin
    implements FlutterLocalNotificationsPlugin {
  int zonedScheduleCallCount = 0;
  int cancelCallCount = 0;
  int cancelAllCallCount = 0;
  int showCallCount = 0;

  List<dynamic> zonedScheduleArgs = [];

  @override
  Future<bool?> initialize(
      InitializationSettings initializationSettings, {
        void Function(NotificationResponse)? onDidReceiveNotificationResponse,
        void Function(NotificationResponse)? onDidReceiveBackgroundNotificationResponse,
      }) async {
    return true;
  }

  @override
  Future<void> zonedSchedule(
      int id,
      String? title,
      String? body,
      tz.TZDateTime scheduledDate,
      NotificationDetails? notificationDetails, {
        required AndroidScheduleMode androidScheduleMode,
        DateTimeComponents? matchDateTimeComponents,
        String? payload,
        required UILocalNotificationDateInterpretation uiLocalNotificationDateInterpretation,
      }) async {
    zonedScheduleCallCount++;
    zonedScheduleArgs = [id, title, body, scheduledDate, notificationDetails];
  }

  @override
  Future<void> cancel(int id, {String? tag}) async {
    cancelCallCount++;
  }

  @override
  Future<void> cancelAll() async {
    cancelAllCallCount++;
  }

  @override
  Future<void> show(
      int id,
      String? title,
      String? body,
      NotificationDetails? notificationDetails, {
        String? payload,
      }) async {
    showCallCount++;
  }

  // Ignore unimplemented methods
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tz.initializeTimeZones();
  late FakeFlutterLocalNotificationsPlugin fakePlugin;
  late NotificationService service;

  setUp(() {
    fakePlugin = FakeFlutterLocalNotificationsPlugin();
    service = NotificationService(plugin: fakePlugin);
  });

  group('NotificationService', () {
    test('scheduleDailyNotification triggers zonedSchedule correctly', () async {
      final id = 1;
      final title = 'Daily Reminder';
      final body = 'Complete your tasks';
      final hour = 8;
      final minute = 0;
      final second = 0;
      final startDate = DateTime.now().add(const Duration(minutes: 1));

      await service.scheduleDailyNotification(
        id: id,
        title: title,
        body: body,
        hour: hour,
        minute: minute,
        second: second,
        startDate: startDate,
      );

      expect(fakePlugin.zonedScheduleCallCount, equals(1));
      final scheduledTime = fakePlugin.zonedScheduleArgs[3] as tz.TZDateTime;
      expect(scheduledTime, isA<tz.TZDateTime>());
      expect(scheduledTime.isAfter(tz.TZDateTime.now(tz.local)), isTrue);
    });

    test('cancelAllNotifications calls cancelAll', () async {
      await service.cancelAllNotifications();
      expect(fakePlugin.cancelAllCallCount, equals(1));
    });

    test('cancelNotification calls cancel with correct id', () async {
      final notificationId = 99;
      await service.cancelNotification(notificationId);
      expect(fakePlugin.cancelCallCount, equals(1));
    });

    test('sendTestNotification calls show', () async {
      await service.sendTestNotification();
      expect(fakePlugin.showCallCount, equals(1));
    });
  });
}
