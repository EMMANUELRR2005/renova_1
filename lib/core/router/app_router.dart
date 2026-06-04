import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/mock/mock_data.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/pacientes/patients_screen.dart';
import '../../features/pacientes/nuevo_paciente_screen.dart';
import '../../features/pacientes/detalle_paciente_screen.dart';
import '../../features/pacientes/editar_paciente_screen.dart';
import '../../features/pacientes/agregar_comentario_screen.dart';
import '../../features/pacientes/nueva_consulta_screen.dart';
import '../../features/citas/appointments_screen.dart';
import '../../features/citas/calendario_citas_screen.dart';
import '../../features/expedientes/expediente_screen.dart';
import '../../features/caja/caja_screen.dart';
import '../../features/caja/cierres_historico_screen.dart';
import '../../features/terapeuta/agenda_terapeuta_screen.dart';
import '../../features/usuarios/usuarios_screen.dart';
import '../../features/reportes/reportes_screen.dart';
import '../../features/farmacia/farmacia_screen.dart';
import '../../features/farmacia/movimientos_farmacia_screen.dart';
import '../../features/farmacia/alertas_farmacia_screen.dart';
import '../../features/boutique/boutique_screen.dart';
import '../../features/boutique/movimientos_boutique_screen.dart';

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
      // ── Pacientes ─────────────────────────────────────────────────────────
      GoRoute(
        path: '/pacientes',
        builder: (context, state) => const PatientsScreen(),
      ),
      GoRoute(
        path: '/pacientes/nuevo',
        builder: (context, state) => const NuevoPacienteScreen(),
      ),
      GoRoute(
        path: '/pacientes/detalle',
        builder: (context, state) => const DetallePacienteScreen(),
      ),
      GoRoute(
        path: '/pacientes/editar',
        builder: (context, state) => const EditarPacienteScreen(),
      ),
      GoRoute(
        path: '/pacientes/comentario',
        builder: (context, state) => const AgregarComentarioScreen(),
      ),
      GoRoute(
        path: '/pacientes/consulta',
        builder: (context, state) => const NuevaConsultaScreen(),
      ),
      // ── Otras secciones ───────────────────────────────────────────────────
      GoRoute(
        path: '/citas',
        builder: (context, state) => const AppointmentsScreen(),
      ),
      GoRoute(
        path: '/citas/calendario',
        builder: (context, state) => const CalendarioCitasScreen(),
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
        path: '/caja/cierres',
        builder: (context, state) => const CierresHistoricoScreen(),
      ),
      GoRoute(
        path: '/agenda-terapeuta',
        builder: (context, state) => const AgendaTerapeutaScreen(),
      ),
      GoRoute(
        path: '/usuarios',
        builder: (context, state) => const UsuariosScreen(),
      ),
      GoRoute(
        path: '/reportes',
        builder: (context, state) => const ReportesScreen(),
      ),
      // ── Farmacia ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/farmacia',
        builder: (context, state) => const FarmaciaScreen(),
      ),
      GoRoute(
        path: '/farmacia/movimientos',
        builder: (context, state) => const MovimientosFarmaciaScreen(),
      ),
      GoRoute(
        path: '/farmacia/alertas',
        builder: (context, state) => const AlertasFarmaciaScreen(),
      ),
      // ── Boutique ──────────────────────────────────────────────────────────
      GoRoute(
        path: '/boutique',
        builder: (context, state) => const BoutiqueScreen(),
      ),
      GoRoute(
        path: '/boutique/movimientos',
        builder: (context, state) => const MovimientosBoutiqueScreen(),
      ),
    ],
    redirect: (context, state) {
      final path = state.uri.path;

      if (!isAuthenticated && path != '/login') return '/login';
      if (isAuthenticated && path == '/login') return _getRutaInicial(rol);

      if (isAuthenticated && rol != null) {
        if (path == '/agenda-terapeuta' && rol != RolUsuario.terapeuta) {
          return _getRutaInicial(rol);
        }
        // Caja solo para secretaria
        if (path == '/caja' && rol != RolUsuario.secretaria_recepcion) {
          return _getRutaInicial(rol);
        }
        // Histórico de cierres: secretaria y administradora
        if (path == '/caja/cierres' &&
            rol != RolUsuario.secretaria_recepcion &&
            rol != RolUsuario.administradora) {
          return _getRutaInicial(rol);
        }
        // Reportes solo para administradora
        if (path == '/reportes' && rol != RolUsuario.administradora) {
          return _getRutaInicial(rol);
        }
        // Farmacia solo para administradora y farmaceutica
        if (path.startsWith('/farmacia') &&
            rol != RolUsuario.administradora &&
            rol != RolUsuario.farmaceutica) {
          return _getRutaInicial(rol);
        }
        // Boutique solo para administradora y boutique
        if (path.startsWith('/boutique') &&
            rol != RolUsuario.administradora &&
            rol != RolUsuario.boutique) {
          return _getRutaInicial(rol);
        }
        // Dashboard y Usuarios solo para administradora
        if ((path == '/usuarios' || path == '/dashboard') &&
            rol != RolUsuario.administradora) {
          return _getRutaInicial(rol);
        }
        // Expedientes para enfermera y doctora
        if (path == '/expedientes' &&
            rol != RolUsuario.enfermera &&
            rol != RolUsuario.doctora) {
          return _getRutaInicial(rol);
        }
        // Citas para secretaria y doctora
        if (path == '/citas' &&
            rol != RolUsuario.secretaria_recepcion &&
            rol != RolUsuario.doctora) {
          return _getRutaInicial(rol);
        }
        // Agenda/calendario: secretaria, doctora, enfermera y administradora
        if (path == '/citas/calendario' &&
            rol != RolUsuario.secretaria_recepcion &&
            rol != RolUsuario.doctora &&
            rol != RolUsuario.enfermera &&
            rol != RolUsuario.administradora) {
          return _getRutaInicial(rol);
        }
        // Solo secretaria puede acceder a nuevo/editar
        if ((path == '/pacientes/nuevo' || path == '/pacientes/editar') &&
            rol != RolUsuario.secretaria_recepcion) {
          return '/pacientes';
        }
        // Solo secretaria puede agregar comentarios
        if (path == '/pacientes/comentario' &&
            rol != RolUsuario.secretaria_recepcion) {
          return '/pacientes';
        }
        // Solo doctora y enfermera pueden agregar consultas
        if (path == '/pacientes/consulta' &&
            rol != RolUsuario.doctora &&
            rol != RolUsuario.enfermera) {
          return '/pacientes';
        }
        // /pacientes y sus sub-rutas: todos excepto terapeuta
        if (path.startsWith('/pacientes') && rol == RolUsuario.terapeuta) {
          return _getRutaInicial(rol);
        }
      }

      return null;
    },
  );
});

String _getRutaInicial(RolUsuario? rol) {
  switch (rol) {
    case RolUsuario.administradora:
      return '/dashboard';
    case RolUsuario.enfermera:
    case RolUsuario.secretaria_recepcion:
    case RolUsuario.doctora:
      return '/pacientes';
    case RolUsuario.terapeuta:
      return '/agenda-terapeuta';
    case RolUsuario.farmaceutica:
      return '/farmacia';
    case RolUsuario.boutique:
      return '/boutique';
    case null:
      return '/login';
  }
}
