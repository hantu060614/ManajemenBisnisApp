import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('Locale init failed: $e');
  }
  
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init failed: $e');
  }

  runApp(
    const ProviderScope(
      child: FarmManagementApp(),
    ),
  );

  Future.microtask(() async {
    try {
      final notificationService = NotificationService();
      await notificationService.init();
      await notificationService.initNotificationPermissions();
      
      List<String> feedingTimes = ['08:00', '12:00', '17:00'];
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docSnap = await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('settings').doc('activity_assistant').get();
        if (docSnap.exists) {
          final data = docSnap.data()!;
          if (data.containsKey('feedingTimes')) {
            feedingTimes = List<String>.from(data['feedingTimes']);
          }
        }
      }
      await notificationService.scheduleDailyReminders(feedingTimes, "Kolam Utama");
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  });
}

class FarmManagementApp extends ConsumerWidget {
  const FarmManagementApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Farm Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
