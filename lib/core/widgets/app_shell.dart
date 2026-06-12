import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../utils/app_exit.dart';
import '../../data/mock/providers.dart';
import '../../data/services/notificacion_service.dart';
import '../theme/app_theme.dart';
import 'sidebar_item.dart';
import '../../data/mock/mock_data.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  final int selectedIndex;
  final Function(int) onNavigate;
  final Widget? floatingActionButton;

  const AppShell({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onNavigate,
    this.floatingActionButton,
  });

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
                  padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/logo_renova.png',
                          height: 56,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Clínica Renova',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: GoogleFonts.dmSans().fontFamily,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Chip de rol (acento dorado)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          _getRolLabel(rol),
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Tarjeta de usuario
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.accent,
                        child: Text(
                          (usuarioActivo?.avatarIniciales.isNotEmpty ?? false)
                              ? usuarioActivo!.avatarIniciales
                              : (usuarioActivo?.nombre.isNotEmpty ?? false)
                                  ? usuarioActivo!.nombre[0].toUpperCase()
                                  : 'U',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              usuarioActivo?.nombre ?? 'Usuario',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              usuarioActivo?.email ?? '',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _NotificacionBell(usuarioId: usuarioActivo?.id ?? ''),
                const SizedBox(height: 4),
                Divider(color: Colors.white.withValues(alpha: 0.1)),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: _buildSidebarItems(context, ref, rol, onNavigate, selectedIndex),
                  ),
                ),
              ],
            ),
          ),
          // MAIN CONTENT (sin barra superior duplicada: solo el contenido,
          // cuyo header lo aporta cada pantalla)
          Expanded(
            child: Container(
              color: AppColors.bgGeneral,
              child: child,
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
          icon: Icons.dashboard_rounded,
          label: 'Dashboard',
          isActive: selectedIndex == 0,
          onTap: () {
            onNavigate(0);
            context.go('/dashboard');
          },
        ),
        SidebarItem(
          icon: Icons.manage_accounts_rounded,
          label: 'Usuarios',
          isActive: selectedIndex == 1,
          onTap: () {
            onNavigate(1);
            context.go('/usuarios');
          },
        ),
        SidebarItem(
          icon: Icons.bar_chart_rounded,
          label: 'Reportes',
          isActive: selectedIndex == 2,
          onTap: () {
            onNavigate(2);
            context.go('/reportes');
          },
        ),
        SidebarItem(
          icon: Icons.local_pharmacy_rounded,
          label: 'Farmacia',
          isActive: selectedIndex == 3,
          badgeCount: alertasFarmacia,
          onTap: () {
            onNavigate(3);
            context.go('/farmacia');
          },
        ),
        SidebarItem(
          icon: Icons.event_note_rounded,
          label: 'Agenda',
          isActive: selectedIndex == 4,
          onTap: () {
            onNavigate(4);
            context.go('/citas/calendario');
          },
        ),
        SidebarItem(
          icon: Icons.receipt_long_rounded,
          label: 'Cierres Caja',
          isActive: selectedIndex == 5,
          onTap: () {
            onNavigate(5);
            context.go('/caja/cierres');
          },
        ),
        SidebarItem(
          icon: Icons.checkroom_rounded,
          label: 'Boutique',
          isActive: selectedIndex == 6,
          onTap: () {
            onNavigate(6);
            context.go('/boutique');
          },
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: Color(0xFF1A3F5C)),
        ),
      ]);
    }
    // BOUTIQUE: Inventario, Movimientos
    else if (rol == RolUsuario.boutique) {
      items.addAll([
        SidebarItem(
          icon: Icons.checkroom_rounded,
          label: 'Inventario',
          isActive: selectedIndex == 0,
          onTap: () {
            onNavigate(0);
            context.go('/boutique');
          },
        ),
        SidebarItem(
          icon: Icons.swap_horiz_rounded,
          label: 'Movimientos',
          isActive: selectedIndex == 1,
          onTap: () {
            onNavigate(1);
            context.go('/boutique/movimientos');
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
          icon: Icons.inventory_2_rounded,
          label: 'Inventario',
          isActive: selectedIndex == 0,
          badgeCount: alertasFarmacia,
          onTap: () {
            onNavigate(0);
            context.go('/farmacia');
          },
        ),
        SidebarItem(
          icon: Icons.swap_horiz_rounded,
          label: 'Movimientos',
          isActive: selectedIndex == 1,
          onTap: () {
            onNavigate(1);
            context.go('/farmacia/movimientos');
          },
        ),
        SidebarItem(
          icon: Icons.warning_amber_rounded,
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
          icon: Icons.people_alt_rounded,
          label: 'Pacientes',
          isActive: selectedIndex == 0,
          onTap: () {
            onNavigate(0);
            context.go('/pacientes');
          },
        ),
        SidebarItem(
          icon: Icons.calendar_month_rounded,
          label: 'Citas',
          isActive: selectedIndex == 1,
          onTap: () {
            onNavigate(1);
            context.go('/citas');
          },
        ),
        SidebarItem(
          icon: Icons.point_of_sale_rounded,
          label: 'Caja',
          isActive: selectedIndex == 2,
          onTap: () {
            onNavigate(2);
            context.go('/caja');
          },
        ),
        SidebarItem(
          icon: Icons.event_note_rounded,
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
          icon: Icons.people_alt_rounded,
          label: 'Pacientes',
          isActive: selectedIndex == 0,
          onTap: () {
            onNavigate(0);
            context.go('/pacientes');
          },
        ),
        SidebarItem(
          icon: Icons.folder_open_rounded,
          label: 'Expedientes',
          isActive: selectedIndex == 1,
          onTap: () {
            onNavigate(1);
            context.go('/expedientes');
          },
        ),
        SidebarItem(
          icon: Icons.event_note_rounded,
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
          icon: Icons.people_alt_rounded,
          label: 'Pacientes',
          isActive: selectedIndex == 0,
          onTap: () {
            onNavigate(0);
            context.go('/pacientes');
          },
        ),
        SidebarItem(
          icon: Icons.calendar_month_rounded,
          label: 'Mis Citas',
          isActive: selectedIndex == 1,
          onTap: () {
            onNavigate(1);
            context.go('/citas');
          },
        ),
        SidebarItem(
          icon: Icons.folder_open_rounded,
          label: 'Expedientes',
          isActive: selectedIndex == 2,
          onTap: () {
            onNavigate(2);
            context.go('/expedientes');
          },
        ),
        SidebarItem(
          icon: Icons.event_note_rounded,
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
          icon: Icons.calendar_month_rounded,
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

    // Cerrar sesión (todos los roles) — Salir vive únicamente en el login.
    items.add(
      SidebarItem(
        icon: Icons.logout_rounded,
        label: 'Cerrar sesión',
        isActive: false,
        onTap: () async {
          await ref.read(logoutProvider)();
        },
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
      case RolUsuario.boutique:
        return 'Boutique';
      case null:
        return 'Sin rol';
    }
  }
}

// Provider para el índice seleccionado del sidebar
final selectedSidebarIndexProvider = StateProvider<int>((ref) {
  return 0;
});

// ── Campana de notificaciones (sidebar) ────────────────────────────────────

class _NotificacionBell extends ConsumerWidget {
  final String usuarioId;
  const _NotificacionBell({required this.usuarioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (usuarioId.isEmpty) return const SizedBox.shrink();
    final totalAsync = ref.watch(notificacionesNoLeidasProvider);
    final total = totalAsync.asData?.value ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _abrirPanel(context, ref),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  const Icon(Icons.notifications_outlined,
                      color: Colors.white, size: 20),
                  if (total > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                            color: Colors.redAccent, shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            total > 9 ? '9+' : '$total',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Notificaciones',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12),
                ),
              ),
              if (total > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('$total',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirPanel(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PanelNotificaciones(usuarioId: usuarioId),
    );
  }
}

class _PanelNotificaciones extends StatelessWidget {
  final String usuarioId;
  const _PanelNotificaciones({required this.usuarioId});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.65,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Notificaciones',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary)),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      NotificacionService().marcarTodasLeidas(usuarioId),
                  child: const Text('Marcar todas como leídas'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: NotificacionService().streamNotificaciones(usuarioId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                // Ordenar por fecha descendente en cliente.
                docs.sort((a, b) {
                  final fa = a.data()['fecha'];
                  final fb = b.data()['fecha'];
                  if (fa == null) return 1;
                  if (fb == null) return -1;
                  return (fb as Timestamp)
                      .compareTo(fa as Timestamp);
                });
                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Sin notificaciones',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data();
                    final leida = (data['leida'] as bool?) ?? false;
                    return ListTile(
                      tileColor: leida
                          ? null
                          : AppColors.primary.withValues(alpha: 0.05),
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: leida
                              ? Colors.grey[100]
                              : AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.calendar_month,
                            color:
                                leida ? Colors.grey : AppColors.primary,
                            size: 20),
                      ),
                      title: Text(
                        data['titulo'] ?? '',
                        style: TextStyle(
                            fontWeight: leida
                                ? FontWeight.normal
                                : FontWeight.bold,
                            fontSize: 13),
                      ),
                      subtitle: Text(
                        data['mensaje'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        if (!leida) {
                          NotificacionService()
                              .marcarLeida(docs[i].id);
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
