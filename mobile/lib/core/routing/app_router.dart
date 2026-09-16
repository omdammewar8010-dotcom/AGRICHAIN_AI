import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/batches/create_batch_screen.dart';
import '../../features/batches/batch_list_screen.dart';
import '../../features/tracking/live_tracking_screen.dart';
import '../../features/qr/qr_code_screen.dart';
import '../../features/qr/traceability_timeline_screen.dart';
import '../../features/risk_explanation/explainable_ai_screen.dart';
import '../../features/route_optimization/route_comparison_screen.dart';
import '../../features/ai_assistant/gemini_assistant_screen.dart';
import '../../features/simulation/hackathon_demo_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/create-batch',
        builder: (context, state) => const CreateBatchScreen(),
      ),
      GoRoute(
        path: '/batches',
        builder: (context, state) => const BatchListScreen(),
      ),
      GoRoute(
        path: '/tracking/:shipmentId',
        builder: (context, state) {
          final id = state.pathParameters['shipmentId'] ?? 'SHIP-2026-0916-01';
          return LiveTrackingScreen(shipmentId: id);
        },
      ),
      GoRoute(
        path: '/qr/:batchId',
        builder: (context, state) {
          final id = state.pathParameters['batchId'] ?? 'AGRI-2026-TOM-000124';
          return QrCodeScreen(batchId: id);
        },
      ),
      GoRoute(
        path: '/traceability/:batchId',
        builder: (context, state) {
          final id = state.pathParameters['batchId'] ?? 'AGRI-2026-TOM-000124';
          return TraceabilityTimelineScreen(batchId: id);
        },
      ),
      GoRoute(
        path: '/explainable-ai/:batchId',
        builder: (context, state) {
          final id = state.pathParameters['batchId'] ?? 'AGRI-2026-TOM-000124';
          return ExplainableAiScreen(batchId: id);
        },
      ),
      GoRoute(
        path: '/routes',
        builder: (context, state) => const RouteComparisonScreen(),
      ),
      GoRoute(
        path: '/ai-assistant',
        builder: (context, state) => const GeminiAssistantScreen(),
      ),
      GoRoute(
        path: '/simulation',
        builder: (context, state) => const HackathonDemoScreen(),
      ),
    ],
  );
}
