import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:typed_data';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    
    try {
        await androidPlugin?.requestExactAlarmsPermission();
    } catch (e) {
        // Permission error handling
    }

    tz.initializeTimeZones();
    // Defaulting to Asia/Kolkata for the user
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  }

  static Future<void> scheduleDailyNotifications() async {
    await _notifications.cancelAll();

    final now = tz.TZDateTime.now(tz.local);

    final androidDetails = const AndroidNotificationDetails(
      'arise_daily_id',
      'System Daily Notifications',
      channelDescription: 'Daily reminders for quests and dungeons',
      importance: Importance.max,
      priority: Priority.max,
      color: Color(0xFF00FFFF),
    );

    final details = NotificationDetails(android: androidDetails);

    // 05:00 AM Notification
    var scheduledStartTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, 5);
    if (scheduledStartTime.isBefore(now)) {
      scheduledStartTime = scheduledStartTime.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      101,
      'DAILY QUESTS ASSIGNED',
      'The System has assigned your core training. Courage of the weak.',
      scheduledStartTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // 07:00 PM Notification
    var scheduledDungeonTime = tz.TZDateTime(tz.local, now.year, now.month, now.day, 19);
    if (scheduledDungeonTime.isBefore(now)) {
      scheduledDungeonTime = scheduledDungeonTime.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      102,
      'DAILY DUNGEON OPENED',
      'The gate is open. High-tier rewards detected.',
      scheduledDungeonTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
