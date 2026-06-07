import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../../../core/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ActivityState {
  final List<String> feedingTimes;
  final Set<String> completedActivities; // e.g. {'feed_0', 'feed_1', 'vaccination'}
  final String dateStr;

  ActivityState({
    required this.feedingTimes,
    required this.completedActivities,
    required this.dateStr,
  });

  ActivityState copyWith({
    List<String>? feedingTimes,
    Set<String>? completedActivities,
    String? dateStr,
  }) {
    return ActivityState(
      feedingTimes: feedingTimes ?? this.feedingTimes,
      completedActivities: completedActivities ?? this.completedActivities,
      dateStr: dateStr ?? this.dateStr,
    );
  }
}

final activityAssistantProvider = StreamNotifierProvider<ActivityNotifier, ActivityState>(() {
  return ActivityNotifier();
});

class ActivityNotifier extends StreamNotifier<ActivityState> {
  @override
  Stream<ActivityState> build() {
    final authState = ref.watch(authProvider);
    if (authState.userId == null) {
      return Stream.value(ActivityState(feedingTimes: ['08:00', '12:00', '17:00'], completedActivities: {}, dateStr: ''));
    }

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final docRef = FirebaseFirestore.instance.collection('users').doc(authState.userId).collection('settings').doc('activity_assistant');

    return docRef.snapshots().map((docSnap) {
      List<String> feedingTimes = ['08:00', '12:00', '17:00'];
      Set<String> completed = {};

      if (docSnap.exists) {
        final data = docSnap.data()!;
        if (data.containsKey('feedingTimes')) {
          feedingTimes = List<String>.from(data['feedingTimes']);
        }
        
        final lastDate = data['lastDate'] as String?;
        if (lastDate == todayStr && data.containsKey('completedActivities')) {
          completed = Set<String>.from(data['completedActivities']);
        } else if (lastDate != todayStr) {
          // Trigger reset di background
          _resetDaily(docRef, todayStr);
        }
      } else {
        _initDoc(docRef, feedingTimes, todayStr);
      }

      return ActivityState(
        feedingTimes: feedingTimes,
        completedActivities: completed,
        dateStr: todayStr,
      );
    });
  }

  Future<void> _resetDaily(DocumentReference docRef, String todayStr) async {
    await docRef.set({'lastDate': todayStr, 'completedActivities': []}, SetOptions(merge: true));
  }

  Future<void> _initDoc(DocumentReference docRef, List<String> feedingTimes, String todayStr) async {
    await docRef.set({'feedingTimes': feedingTimes, 'lastDate': todayStr, 'completedActivities': []});
  }

  Future<void> toggleActivity(String key, bool isCompleted) async {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedCompleted = Set<String>.from(currentState.completedActivities);
    if (isCompleted) {
      updatedCompleted.add(key);
    } else {
      updatedCompleted.remove(key);
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('settings').doc('activity_assistant').set({
          'completedActivities': updatedCompleted.toList(),
          'lastDate': currentState.dateStr,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // log error silently
    }
  }

  Future<void> updateSchedule(List<String> newFeedingTimes) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('settings').doc('activity_assistant').set({
          'feedingTimes': newFeedingTimes,
        }, SetOptions(merge: true));
      }
      await NotificationService().scheduleDailyReminders(newFeedingTimes, "Kolam Utama");
    } catch (e) {}
  }
}
