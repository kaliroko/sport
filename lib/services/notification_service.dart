/// 通知服务
library;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

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
    required Time time,
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

    await _notifications.schedule(
      id,
      title,
      body,
      _nextInstanceOfTime(time),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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

    // 创建多个时间点
    for (final time in [
      Time(9, 0),
      Time(11, 0),
      Time(14, 0),
      Time(16, 0),
      Time(19, 0),
    ]) {
      await _notifications.schedule(
        time.hour * 100 + time.minute,
        '💧 该喝水了',
        '休息一下，喝杯水吧！',
        _nextInstanceOfTime(time),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
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

    // 工作日每隔45分钟提醒一次
    for (int hour = 8; hour <= 21; hour++) {
      for (int minute in [0, 45]) {
        if (hour == 21 && minute == 45) continue; // 避免超过21点
        await _notifications.schedule(
          hour * 100 + minute,
          '🧍 体态提醒',
          '抬头挺胸，手机举高！',
          _nextInstanceOfTime(Time(hour, minute)),
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }
  }

  /// 取消所有提醒
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// 获取下次指定时间的DateTime
  DateTime _nextInstanceOfTime(Time time) {
    final now = DateTime.now();
    var next = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // 如果今天的时间已经过去，设置为明天
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }

    return next;
  }
}
