import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/pacientes/patients_screen.dart';
import '../../features/citas/appointments_screen.dart';

// Listener para reactividad de GoRouter
class GoRouterNotifier extends ChangeNotifier {
  void notifyListenersCustom() {
    notifyListeners();
  }
}

final _routerListenerProvider = ChangeNotifierProvider((ref) {
  final listener = GoRouterNotifier();
  ref.listen(authStateProvider, (_, __) {
    listener.notifyListeners();
  });
  return listener;
});

final goRouterProvider = Provider<GoRouter>((ref) {
  final authStateNotifier = ref.watch(_routerListenerProvider);
  final isAuthenticated = ref.watch(authStateProvider);

  return GoRouter(
    refreshListenable: authStateNotifier,
    initialLocation: isAuthenticated ? '/dashboard' : '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/pacientes',
        builder: (context, state) => const PatientsScreen(),
      ),
      GoRoute(
        path: '/citas',
        builder: (context, state) => const AppointmentsScreen(),
      ),
    ],
    redirect: (context, state) {
      if (!isAuthenticated && state.uri.path != '/login') {
        return '/login';
      }
      if (isAuthenticated && state.uri.path == '/login') {
        return '/dashboard';
      }
      return null;
    },
  );
});
