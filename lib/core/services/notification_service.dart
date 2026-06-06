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

  Future<void> scheduleDailyReminder() async {
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

    // 1. Pakan Pagi (08:00)
    var scheduledPagi = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);
    if (scheduledPagi.isBefore(now)) {
      scheduledPagi = scheduledPagi.add(const Duration(days: 1));
    }
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      '🌅 Jadwal Pakan Pagi - FarmHub',
      'Waktunya memberikan pakan pagi untuk ternak Anda. Jangan lupa dicatat ya!',
      scheduledPagi,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // 2. Cek Kesehatan (09:00)
    var scheduledHealth = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    if (scheduledHealth.isBefore(now)) {
      scheduledHealth = scheduledHealth.add(const Duration(days: 1));
    }
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      1,
      '🩺 Cek Kesehatan Ternak - FarmHub',
      'Lakukan inspeksi harian: periksa air kolam / kebersihan kandang dan catat kematian / penyakit.',
      scheduledHealth,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // 3. Pakan Siang (12:00)
    var scheduledSiang = tz.TZDateTime(tz.local, now.year, now.month, now.day, 12);
    if (scheduledSiang.isBefore(now)) {
      scheduledSiang = scheduledSiang.add(const Duration(days: 1));
    }
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      2,
      '☀️ Jadwal Pakan Siang - FarmHub',
      'Saatnya pakan siang! Pastikan takaran pakan sesuai dengan berat sampling terakhir.',
      scheduledSiang,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // 4. Pakan Sore (17:00)
    var scheduledSore = tz.TZDateTime(tz.local, now.year, now.month, now.day, 17);
    if (scheduledSore.isBefore(now)) {
      scheduledSore = scheduledSore.add(const Duration(days: 1));
    }
    await _flutterLocalNotificationsPlugin.zonedSchedule(
      3,
      '🌇 Jadwal Pakan Sore - FarmHub',
      'Pemberian pakan terakhir hari ini. Selesaikan pencatatan keuangan dan produksi Anda.',
      scheduledSore,
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
