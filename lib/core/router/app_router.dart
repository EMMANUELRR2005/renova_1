import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock/mock_data.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/pacientes/patients_screen.dart';
import '../../features/citas/appointments_screen.dart';
import '../../features/expedientes/expediente_screen.dart';
import '../../features/caja/caja_screen.dart';
import '../../features/terapeuta/agenda_terapeuta_screen.dart';
import '../../features/usuarios/usuarios_screen.dart';

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
  final usuarioActivo = ref.watch(usuarioActivoProvider);
  final rol = usuarioActivo?.rol;

  return GoRouter(
    refreshListenable: authStateNotifier,
    initialLocation: isAuthenticated ? _getRutaInicial(rol) : '/login',
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
      GoRoute(
        path: '/expedientes',
        builder: (context, state) => const ExpedienteScreen(),
      ),
      GoRoute(
        path: '/caja',
        builder: (context, state) => const CajaScreen(),
      ),
      GoRoute(
        path: '/agenda-terapeuta',
        builder: (context, state) => const AgendaTerapeutaScreen(),
      ),
      GoRoute(
        path: '/usuarios',
        builder: (context, state) => const UsuariosScreen(),
      ),
    ],
    redirect: (context, state) {
      final path = state.uri.path;

      // Si no está autenticado, ir a login
      if (!isAuthenticated && path != '/login') {
        return '/login';
      }

      // Si está autenticado y va a login, redirigir a ruta inicial según rol
      if (isAuthenticated && path == '/login') {
        return _getRutaInicial(rol);
      }

      // Validar permisos según rol
      if (isAuthenticated && rol != null) {
        // Solo terapeuta puede acceder a /agenda-terapeuta
        if (path == '/agenda-terapeuta' && rol != RolUsuario.terapeuta) {
          return _getRutaInicial(rol);
        }

        // Solo administradora puede acceder a /caja y /usuarios
        if ((path == '/caja' || path == '/usuarios') &&
            rol != RolUsuario.administradora) {
          return _getRutaInicial(rol);
        }

        // Solo administradora puede acceder a /dashboard
        if (path == '/dashboard' && rol != RolUsuario.administradora) {
          return _getRutaInicial(rol);
        }

        // Administradora y enfermera pueden acceder a /pacientes, /citas, /expedientes
        if ((path == '/pacientes' ||
                path == '/citas' ||
                path == '/expedientes') &&
            (rol != RolUsuario.administradora &&
                rol != RolUsuario.enfermera)) {
          return _getRutaInicial(rol);
        }
      }

      return null;
    },
  );
});

/// Retorna la ruta inicial según el rol del usuario
String _getRutaInicial(RolUsuario? rol) {
  switch (rol) {
    case RolUsuario.administradora:
      return '/dashboard';
    case RolUsuario.enfermera:
      return '/pacientes';
    case RolUsuario.terapeuta:
      return '/agenda-terapeuta';
    case null:
      return '/login';
  }
}
