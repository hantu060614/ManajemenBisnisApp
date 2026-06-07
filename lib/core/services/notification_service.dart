import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

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

  Future<void> initNotificationPermissions() async {
    if (!Platform.isAndroid) return;
    
    final androidImplementation = _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation == null) return;

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 33) {
      // Android 13+: Minta izin POST_NOTIFICATIONS
      await androidImplementation.requestNotificationsPermission();
    }

    if (sdkInt >= 31 && sdkInt < 34) {
      // Android 12 & 13: Minta SCHEDULE_EXACT_ALARM secara eksplisit
      final hasExactAlarm = await androidImplementation.canScheduleExactNotifications();
      if (hasExactAlarm != null && !hasExactAlarm) {
        await androidImplementation.requestExactAlarmsPermission();
      }
    }
    // Android 14+ (API 34+) sudah tercover oleh USE_EXACT_ALARM di manifest
  }

  Future<void> scheduleDailyReminders(List<String> feedingTimes, String batchName) async {
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
    
    // Schedule Cek Kesehatan
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
        var scheduledFeed = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute).subtract(const Duration(minutes: 5));
        if (scheduledFeed.isBefore(now)) scheduledFeed = scheduledFeed.add(const Duration(days: 1));
        
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          notifId++,
          '⏰ Persiapan Jadwal Pakan — $batchName',
          'Jadwal pakan pukul ${feedingTimes[i]} untuk $batchName dimulai 5 menit lagi. Siapkan pakan.',
          scheduledFeed,
          platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );

        // Simpan jadwal ke Firestore untuk reschedule saat restart
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('jadwal_notifikasi')
              .doc('feed_$notifId')
              .set({
            'id': notifId,
            'judul': '⏰ Persiapan Jadwal Pakan — $batchName',
            'isi': 'Jadwal pakan pukul ${feedingTimes[i]} untuk $batchName dimulai 5 menit lagi. Siapkan pakan.',
            'jam': hour,
            'menit': minute,
            'namaKolam': batchName,
            'isAktif': true,
          });
        }
      }
    }
  }
}
