/// 通知服务
library;

import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notifications.initialize(initializationSettings);

    // 请求通知权限
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  /// 请求精确闹钟权限（Android 13+）
  Future<void> requestExactAlarmPermission() async {
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  /// 安排每日提醒
  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required DateTime time,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'daily_reminder',
      '每日提醒',
      channelDescription: '每日打卡提醒',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'daily_reminder',
        '每日提醒',
        description: '每日打卡提醒',
        importance: Importance.high,
      ));

    final scheduledDate = tz.TZDateTime.from(time, tz.local);
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// 安排喝水提醒
  Future<void> scheduleWaterReminder(int hour, int minute) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'water_reminder',
      '喝水提醒',
      channelDescription: '定时喝水提醒',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'water_reminder',
        '喝水提醒',
        description: '定时喝水提醒',
        importance: Importance.high,
      ));

    final now = tz.TZDateTime.now(tz.local);
    final times = [
      _makeTZDateTime(now, 9, 0),
      _makeTZDateTime(now, 11, 0),
      _makeTZDateTime(now, 14, 0),
      _makeTZDateTime(now, 16, 0),
      _makeTZDateTime(now, 19, 0),
    ];

    for (var i = 0; i < times.length; i++) {
      await _notifications.zonedSchedule(
        hour * 100 + minute + i,
        '💧 该喝水了',
        '休息一下，喝杯水吧！',
        times[i],
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static tz.TZDateTime _makeTZDateTime(tz.TZDateTime now, int hour, int minute) {
    var dt = tz.TZDateTime(now.timeZoneLocation, now.year, now.month, now.day, hour, minute, 0);
    if (dt.isBefore(now)) {
      dt = dt.add(const Duration(days: 1));
    }
    return dt;
  }

  /// 安排体态提醒（每45分钟）
  Future<void> schedulePostureReminder() async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'posture_reminder',
      '体态提醒',
      channelDescription: '定时体态提醒',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'posture_reminder',
        '体态提醒',
        description: '定时体态提醒',
        importance: Importance.high,
      ));

    final now = tz.TZDateTime.now(tz.local);
    var id = 1000;
    for (int hour = 8; hour <= 21; hour++) {
      for (int minute in [0, 45]) {
        if (hour == 21 && minute == 45) continue;
        final scheduledDate = _makeTZDateTime(now, hour, minute);
        await _notifications.zonedSchedule(
          id++,
          '🧍 体态提醒',
          '抬头挺胸，手机举高！',
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  /// 取消所有提醒
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

}
