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
        print("Notification Tap: ${details.id}");
      },
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    
    try {
        await androidPlugin?.requestExactAlarmsPermission();
    } catch (e) {
        print("Permission check: $e");
    }

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    
    print("OnePlus 12R System: READY (IST Mode)");
  }

  // ✅ TEST: Fire in 10 Seconds
  static Future<void> scheduleDailyNotifications() async {
    await _notifications.cancelAll();

    final now = tz.TZDateTime.now(tz.local);
    final scheduledTime = now.add(const Duration(seconds: 10)); // 10s Window
    
    print("Phone Clock: $now");
    print("Target Alarm: $scheduledTime (+10s)");

    try {
      // Create a notification details object that looks like a high-priority call
      final androidDetails = AndroidNotificationDetails(
        'protocol_omega_v12', // Fresh ID
        'Core Internal Alarms',
        channelDescription: 'Used for critical system synchronization',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.call, // CRITICAL: Hardest to block
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
        enableLights: true,
        color: const Color.fromARGB(255, 255, 0, 0),
        visibility: NotificationVisibility.public,
        ongoing: false,
        autoCancel: true,
        showWhen: true,
      );

      await _notifications.zonedSchedule(
        id: 1234,
        title: 'ARISE: PROTOCOL ALPHA',
        body: 'Synchronization established. Discipline verified.',
        scheduledDate: scheduledTime,
        notificationDetails: NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      final pending = await _notifications.pendingNotificationRequests();
      print("VERIFICATION: Pending in Queue = ${pending.length}");
      
      // FIRE ONE NOW JUST TO TEST THE CHANNEL
      print("Sending immediate channel test...");
      await _notifications.show(
        id: 999,
        title: 'ARISE: Channel Test',
        body: 'Testing local notification pipeline...',
        notificationDetails: NotificationDetails(android: androidDetails),
      );

    } catch (e) {
      print("Scheduling Failed: $e");
    }
  }
}