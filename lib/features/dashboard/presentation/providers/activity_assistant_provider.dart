import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/notification_service.dart';

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

class ActivityNotifier extends StateNotifier<AsyncValue<ActivityState>> {
  ActivityNotifier() : super(const AsyncValue.loading()) {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load feeding times. Default: 3 feeds (08:00, 12:00, 17:00)
      List<String> feedingTimes = prefs.getStringList('activity_feeding_times') ?? ['08:00', '12:00', '17:00'];
      
      // Load completed activities date and keys
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final lastDate = prefs.getString('activity_last_date') ?? '';
      
      Set<String> completed = {};
      if (lastDate == todayStr) {
        final completedList = prefs.getStringList('activity_completed_keys') ?? [];
        completed = completedList.toSet();
      } else {
        // New day: reset completed activities and save new date
        await prefs.setString('activity_last_date', todayStr);
        await prefs.setStringList('activity_completed_keys', []);
      }
      
      state = AsyncValue.data(ActivityState(
        feedingTimes: feedingTimes,
        completedActivities: completed,
        dateStr: todayStr,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
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

    state = AsyncValue.data(AsyncValue.data(currentState.copyWith(completedActivities: updatedCompleted)).value!);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('activity_completed_keys', updatedCompleted.toList());
    } catch (e) {
      // log error silently
    }
  }

  Future<void> updateSchedule(List<String> newFeedingTimes) async {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(AsyncValue.data(currentState.copyWith(feedingTimes: newFeedingTimes)).value!);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('activity_feeding_times', newFeedingTimes);
      await NotificationService().scheduleDailyReminders(newFeedingTimes);
    } catch (e) {
      // log error
    }
  }
}

final activityAssistantProvider = StateNotifierProvider<ActivityNotifier, AsyncValue<ActivityState>>((ref) {
  return ActivityNotifier();
});
