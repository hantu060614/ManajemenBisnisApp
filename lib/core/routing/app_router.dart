import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/main_page.dart';
import '../../features/batches/presentation/pages/batches_page.dart';
import '../../features/batches/presentation/pages/batch_form_page.dart';
import '../../features/batches/presentation/pages/batch_harvest_form_page.dart';
import '../../features/batches/presentation/pages/daily_log_form_page.dart';
import '../../features/cashflow/presentation/pages/cashflow_page.dart';
import '../../features/cashflow/presentation/pages/cashflow_form_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/batches/domain/models/batch.dart';
import '../../features/cashflow/domain/models/cashflow.dart';

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
        path: '/batches/daily-log',
        builder: (context, state) {
          final batch = state.extra as Batch;
          return DailyLogFormPage(batch: batch);
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
    ],
  );
}
