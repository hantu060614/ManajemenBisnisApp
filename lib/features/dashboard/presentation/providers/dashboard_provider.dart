import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/dashboard_stats.dart';
import '../../data/repositories/dashboard_stats_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final dashboardStatsRepositoryProvider = Provider<DashboardStatsRepository>((ref) {
  return DashboardStatsRepository();
});

final dashboardProvider = StreamProvider<DashboardStats?>((ref) {
  final authState = ref.watch(authProvider);
  if (authState.userId == null) {
    return Stream.value(null);
  }
  
  final repository = ref.watch(dashboardStatsRepositoryProvider);
  return repository.getStatsStream();
});
