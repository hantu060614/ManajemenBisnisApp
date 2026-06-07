import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/main_page.dart';
import '../../features/batches/presentation/pages/batches_page.dart';
import '../../features/batches/presentation/pages/batch_form_page.dart';
import '../../features/batches/presentation/pages/batch_harvest_form_page.dart';
import '../../features/cashflow/presentation/pages/cashflow_page.dart';
import '../../features/cashflow/presentation/pages/cashflow_form_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/feed/presentation/pages/feed_list_page.dart';
import '../../features/feed/presentation/pages/feed_form_page.dart';
import '../../features/feed/presentation/pages/feed_stock_history_page.dart';
import '../../features/batches/domain/models/batch.dart';
import '../../features/cashflow/domain/models/cashflow.dart';
import '../../features/feed/domain/models/feed_log.dart';
import '../../features/health/presentation/pages/health_list_page.dart';
import '../../features/health/presentation/pages/health_form_page.dart';
import '../../features/health/domain/models/health_log.dart';
import '../../features/production/presentation/pages/production_list_page.dart';
import '../../features/production/presentation/pages/production_form_page.dart';
import '../../features/production/domain/models/production_log.dart';
import '../../features/analytics/presentation/pages/analytics_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainPage(),
      ),
      GoRoute(
        path: '/batches',
        builder: (context, state) => const BatchesPage(),
      ),
      GoRoute(
        path: '/batches/add',
        builder: (context, state) {
          final existingBatch = state.extra as Batch?;
          return BatchFormPage(existingBatch: existingBatch);
        },
      ),
      GoRoute(
        path: '/batches/harvest',
        builder: (context, state) {
          final batch = state.extra as Batch;
          return BatchHarvestFormPage(batch: batch);
        },
      ),

      GoRoute(
        path: '/cashflow',
        builder: (context, state) => const CashflowPage(),
      ),
      GoRoute(
        path: '/cashflow/add',
        builder: (context, state) {
          final existingCashflow = state.extra as Cashflow?;
          return CashflowFormPage(existingCashflow: existingCashflow);
        },
      ),
      GoRoute(
        path: '/reports',
        builder: (context, state) => const ReportsPage(),
      ),
      GoRoute(
        path: '/feed',
        builder: (context, state) => const FeedListPage(),
      ),
      GoRoute(
        path: '/feed/add',
        builder: (context, state) {
          final existingFeedLog = state.extra as FeedLog?;
          return FeedFormPage(existingFeedLog: existingFeedLog);
        },
      ),
      GoRoute(
        path: '/feed/stock-history',
        builder: (context, state) => const FeedStockHistoryPage(),
      ),
      GoRoute(
        path: '/health',
        builder: (context, state) => const HealthListPage(),
      ),
      GoRoute(
        path: '/health/add',
        builder: (context, state) {
          final existingLog = state.extra as HealthLog?;
          return HealthFormPage(existingHealthLog: existingLog);
        },
      ),
      GoRoute(
        path: '/production',
        builder: (context, state) => const ProductionListPage(),
      ),
      GoRoute(
        path: '/production/add',
        builder: (context, state) {
          final existingLog = state.extra as ProductionLog?;
          return ProductionFormPage(existingProductionLog: existingLog);
        },
      ),
      GoRoute(
        path: '/analytics',
        builder: (context, state) => const AnalyticsPage(),
      ),
    ],
  );
}
