import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // For iOS if needed
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> scheduleDailyReminders(List<String> feedingTimes) async {
    await _flutterLocalNotificationsPlugin.cancelAll(); // Reset previous alarms

    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminder',
      channelDescription: 'Pengingat aktivitas harian peternakan FarmHub',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    final now = tz.TZDateTime.now(tz.local);

    int notifId = 0;
    
    // Schedule Cek Kesehatan (Fixed at 07:00 or a default time)
    var scheduledHealth = tz.TZDateTime(tz.local, now.year, now.month, now.day, 7);
    if (scheduledHealth.isBefore(now)) scheduledHealth = scheduledHealth.add(const Duration(days: 1));
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notifId++,
      '🩺 Cek Kesehatan Ternak',
      'Waktunya inspeksi harian: periksa air & kebersihan, catat jika ada masalah.',
      scheduledHealth,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // Schedule Custom Feeding Times
    for (int i = 0; i < feedingTimes.length; i++) {
      final parts = feedingTimes[i].split(':');
      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]) ?? 8;
        final minute = int.tryParse(parts[1]) ?? 0;
        var scheduledFeed = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
        if (scheduledFeed.isBefore(now)) scheduledFeed = scheduledFeed.add(const Duration(days: 1));
        
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          notifId++,
          '🐟 Jadwal Pakan Pukul ${feedingTimes[i]}',
          'Waktunya memberi pakan ternak Anda. Jangan lupa dicatat di aplikasi!',
          scheduledFeed,
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      }
    }
  }
}
