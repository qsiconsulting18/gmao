import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/scan_screen.dart';
import '../screens/equipment_detail_screen.dart';
import '../screens/report_fault_screen.dart';
import '../screens/ticket_detail_screen.dart';
import '../screens/close_intervention_screen.dart';
import '../models/equipment.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _AuthListenable(ref),
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loggingIn = state.matchedLocation == '/login';

      if (auth.checking) return null;
      if (!auth.isAuthenticated && !loggingIn) return '/login';
      if (auth.isAuthenticated && loggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/scan', builder: (context, state) => const ScanScreen()),
      GoRoute(
        path: '/equipment/:qrToken',
        builder: (context, state) => EquipmentDetailScreen(qrToken: state.pathParameters['qrToken']!),
      ),
      GoRoute(
        path: '/report-fault',
        builder: (context, state) => ReportFaultScreen(equipment: state.extra as Equipment),
      ),
      GoRoute(
        path: '/tickets/:id',
        builder: (context, state) => TicketDetailScreen(ticketId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/close-intervention',
        builder: (context, state) => CloseInterventionScreen(extra: state.extra as Map<String, dynamic>),
      ),
    ],
  );
});

/// Bridges Riverpod's auth state to go_router's Listenable-based refresh API.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authProvider, (_, _) => notifyListeners());
  }
}
