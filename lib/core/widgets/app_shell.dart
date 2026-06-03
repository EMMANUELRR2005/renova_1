import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../utils/app_exit.dart';
import '../../data/mock/providers.dart';
import '../theme/app_theme.dart';
import 'sidebar_item.dart';
import '../../data/mock/mock_data.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  final int selectedIndex;
  final Function(int) onNavigate;
  final Widget? floatingActionButton;

  const AppShell({
    Key? key,
    required this.child,
    required this.selectedIndex,
    required this.onNavigate,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuarioActivo = ref.watch(usuarioActivoProvider);
    final rol = usuarioActivo?.rol;

    return PopScope(
      // Bloquear la salida de la app con el botón Atrás / gesto: solo se sale
      // confirmando en el diálogo (la sesión se mantiene activa).
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _mostrarDialogoSalir(context);
      },
      child: Scaffold(
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 220,
            color: AppColors.primaryDark,
            child: Column(
              children: [
                // Logo area
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/logo_renova.png',
                          height: 60,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Clínica Renova',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: GoogleFonts.dmSans().fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF1A3F5C)),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: _buildSidebarItems(context, ref, rol, onNavigate, selectedIndex),
                  ),
                ),
              ],
            ),
          ),
          // MAIN CONTENT
          Expanded(
            child: Column(
              children: [
                // TOPBAR
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.topbar,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/logo_renova.png',
                              height: 36,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Clínica Renova',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFamily: GoogleFonts.dmSans().fontFamily,
                            ),
                          ),
                        ],
                      ),
                      // Center - Rol actual
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getRolLabel(rol),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                            fontFamily: GoogleFonts.dmSans().fontFamily,
                          ),
                        ),
                      ),
                      // Right
                      Row(
                        children: [
                          const Text(
                            '🔔',
                            style: TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Text(
                                usuarioActivo?.avatarIniciales ?? 'RN',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            usuarioActivo?.nombre ?? 'Usuario',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                              fontFamily: GoogleFonts.dmSans().fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // CONTENT AREA
                Expanded(
                  child: Container(
                    color: AppColors.bgGeneral,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  // Diálogo de salida (mantiene la sesión activa).
  Future<void> _mostrarDialogoSalir(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: AppColors.primary),
            SizedBox(width: 8),
            Expanded(child: Text('¿Salir de la aplicación?')),
          ],
        ),
        content: const Text(
          'Tu sesión quedará activa.\n'
          'La próxima vez que abras la app entrarás directamente '
          'sin necesidad de iniciar sesión nuevamente.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          OutlinedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(),
            icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.primary),
            label: const Text('Cancelar',
                style: TextStyle(color: AppColors.primary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _salirDeApp();
            },
            icon: const Icon(Icons.exit_to_app, size: 16, color: Colors.white),
            label: const Text('Salir', style: TextStyle(color: Colors.white)),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }

  /// Cierra la app sin cerrar sesión (la sesión de Firebase queda activa).
  void _salirDeApp() => salirDeApp();

  List<Widget> _buildSidebarItems(
      BuildContext context, WidgetRef ref, RolUsuario? rol, Function(int) onNavigate, int selectedIndex) {
    final items = <Widget>[];

    // Alertas de farmacia (solo se observa para roles con acceso a farmacia).
    final int alertasFarmacia =
        (rol == RolUsuario.administradora || rol == RolUsuario.farmaceutica)
            ? ref.watch(alertasFarmaciaProvider).total
            : 0;

    // ADMINISTRADORA: Dashboard, Usuarios, Reportes
    if (rol == RolUsuario.administradora) {
      items.addAll([
        SidebarItem(
          icon: '📊',
          label: 'Dashboard',
          isActive: selectedIndex == 0,
          onTap: () {
            onNavigate(0);
            context.go('/dashboard');
          },
        ),
        SidebarItem(
          icon: '👨‍💼',
          label: 'Usuarios',
          isActive: selectedIndex == 1,
          onTap: () {
            onNavigate(1);
            context.go('/usuarios');
          },
        ),
        SidebarItem(
          icon: '📈',
          label: 'Reportes',
          isActive: selectedIndex == 2,
          onTap: () {
            onNavigate(2);
            context.go('/reportes');
          },
        ),
        SidebarItem(
          icon: '💊',
          label: 'Farmacia',
          isActive: selectedIndex == 3,
          badgeCount: alertasFarmacia,
          onTap: () {
            onNavigate(3);
            context.go('/farmacia');
          },
        ),
        SidebarItem(
          icon: '📆',
          label: 'Agenda',
          isActive: selectedIndex == 4,
          onTap: () {
            onNavigate(4);
            context.go('/citas/calendario');
          },
        ),
        SidebarItem(
          icon: '🧾',
          label: 'Cierres Caja',
          isActive: selectedIndex == 5,
          onTap: () {
            onNavigate(5);
            context.go('/caja/cierres');
          },
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: Color(0xFF1A3F5C)),
        ),
      ]);
    }
    // FARMACÉUTICA: Inventario, Movimientos
    else if (rol == RolUsuario.farmaceutica) {
      items.addAll([
        SidebarItem(
          icon: '💊',
          label: 'Inventario',
          isActive: selectedIndex == 0,
          badgeCount: alertasFarmacia,
          onTap: () {
            onNavigate(0);
            context.go('/farmacia');
          },
        ),
        SidebarItem(
          icon: '📦',
          label: 'Movimientos',
          isActive: selectedIndex == 1,
          onTap: () {
            onNavigate(1);
            context.go('/farmacia/movimientos');
          },
        ),
        SidebarItem(
          icon: '⚠️',
          label: 'Alertas',
          isActive: selectedIndex == 2,
          badgeCount: alertasFarmacia,
          onTap: () {
            onNavigate(2);
            context.go('/farmacia/alertas');
          },
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: Color(0xFF1A3F5C)),
        ),
      ]);
    }
    // SECRETARIA: Pacientes, Citas, Caja
    else if (rol == RolUsuario.secretaria_recepcion) {
      items.addAll([
        SidebarItem(
          icon: '👥',
          label: 'Pacientes',
          isActive: selectedIndex == 0,
          onTap: () {
            onNavigate(0);
            context.go('/pacientes');
          },
        ),
        SidebarItem(
          icon: '📅',
          label: 'Citas',
          isActive: selectedIndex == 1,
          onTap: () {
            onNavigate(1);
            context.go('/citas');
          },
        ),
        SidebarItem(
          icon: '💰',
          label: 'Caja',
          isActive: selectedIndex == 2,
          onTap: () {
            onNavigate(2);
            context.go('/caja');
          },
        ),
        SidebarItem(
          icon: '📆',
          label: 'Agenda',
          isActive: selectedIndex == 3,
          onTap: () {
            onNavigate(3);
            context.go('/citas/calendario');
          },
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: Color(0xFF1A3F5C)),
        ),
      ]);
    }
    // ENFERMERA: Pacientes, Expedientes
    else if (rol == RolUsuario.enfermera) {
      items.addAll([
        SidebarItem(
          icon: '👥',
          label: 'Pacientes',
          isActive: selectedIndex == 0,
          onTap: () {
            onNavigate(0);
            context.go('/pacientes');
          },
        ),
        SidebarItem(
          icon: '📋',
          label: 'Expedientes',
          isActive: selectedIndex == 1,
          onTap: () {
            onNavigate(1);
            context.go('/expedientes');
          },
        ),
        SidebarItem(
          icon: '📆',
          label: 'Agenda',
          isActive: selectedIndex == 2,
          onTap: () {
            onNavigate(2);
            context.go('/citas/calendario');
          },
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: Color(0xFF1A3F5C)),
        ),
      ]);
    }
    // DOCTORA: Pacientes, Citas (sus citas), Expedientes
    else if (rol == RolUsuario.doctora) {
      items.addAll([
        SidebarItem(
          icon: '👥',
          label: 'Pacientes',
          isActive: selectedIndex == 0,
          onTap: () {
            onNavigate(0);
            context.go('/pacientes');
          },
        ),
        SidebarItem(
          icon: '📅',
          label: 'Mis Citas',
          isActive: selectedIndex == 1,
          onTap: () {
            onNavigate(1);
            context.go('/citas');
          },
        ),
        SidebarItem(
          icon: '📋',
          label: 'Expedientes',
          isActive: selectedIndex == 2,
          onTap: () {
            onNavigate(2);
            context.go('/expedientes');
          },
        ),
        SidebarItem(
          icon: '📆',
          label: 'Agenda',
          isActive: selectedIndex == 3,
          onTap: () {
            onNavigate(3);
            context.go('/citas/calendario');
          },
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: Color(0xFF1A3F5C)),
        ),
      ]);
    }
    // TERAPEUTA: Mi Agenda
    else if (rol == RolUsuario.terapeuta) {
      items.addAll([
        SidebarItem(
          icon: '📅',
          label: 'Mi Agenda',
          isActive: selectedIndex == 0,
          onTap: () {
            onNavigate(0);
            context.go('/agenda-terapeuta');
          },
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: Color(0xFF1A3F5C)),
        ),
      ]);
    }

    // Cerrar sesión (todos los roles)
    items.add(
      SidebarItem(
        icon: '🚪',
        label: 'Cerrar sesión',
        isActive: false,
        onTap: () async {
          await ref.read(logoutProvider)();
        },
      ),
    );

    // Salir de la app (mantiene la sesión activa)
    items.add(
      SidebarItem(
        icon: '↪️',
        label: 'Salir',
        isActive: false,
        onTap: () => _mostrarDialogoSalir(context),
      ),
    );

    return items;
  }

  String _getRolLabel(RolUsuario? rol) {
    switch (rol) {
      case RolUsuario.administradora:
        return 'Administradora';
      case RolUsuario.enfermera:
        return 'Enfermera';
      case RolUsuario.terapeuta:
        return 'Terapeuta';
      case RolUsuario.secretaria_recepcion:
        return 'Secretaria';
      case RolUsuario.doctora:
        return 'Doctora';
      case RolUsuario.farmaceutica:
        return 'Farmacéutica';
      case null:
        return 'Sin rol';
    }
  }
}

// Provider para el índice seleccionado del sidebar
final selectedSidebarIndexProvider = StateProvider<int>((ref) {
  return 0;
});
