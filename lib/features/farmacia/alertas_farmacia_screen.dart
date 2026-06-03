import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/permisos.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../data/mock/mock_data.dart' hide Medicamento;
import '../../data/mock/providers.dart';
import '../../data/services/farmacia_service.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Pantalla dedicada de alertas de inventario de farmacia.
class AlertasFarmaciaScreen extends ConsumerWidget {
  const AlertasFarmaciaScreen({super.key});

  // Admin: resalta "Farmacia" (3). Farmacéutica: resalta "Alertas" (2).
  int _sidebarIndex(RolUsuario? rol) =>
      rol == RolUsuario.administradora ? 3 : 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rol = ref.watch(usuarioActivoProvider)?.rol;
    final alertas = ref.watch(alertasFarmaciaProvider);
    final puedeEliminar = Permisos.puedeGestionarMedicamentos(rol);

    return AppShell(
      selectedIndex: _sidebarIndex(rol),
      onNavigate: (_) {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.go('/farmacia'),
                ),
                const SizedBox(width: 4),
                Text(
                  'Alertas de Inventario',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: GoogleFonts.dmSans().fontFamily,
                  ),
                ),
                const Spacer(),
                if (alertas.hayAlertas)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${alertas.total} alerta${alertas.total == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            if (!alertas.hayAlertas)
              _todoBien()
            else ...[
              if (alertas.vencidos.isNotEmpty)
                _SeccionVencidos(
                  items: alertas.vencidos,
                  puedeEliminar: puedeEliminar,
                  onEliminar: (m) =>
                      _confirmarEliminarVencido(context, ref, m),
                ),
              if (alertas.sinStock.isNotEmpty)
                _Seccion(
                  titulo: '🔴 Sin Stock',
                  color: AppColors.danger,
                  items: alertas.sinStock,
                  mensaje: (m) =>
                      'AGOTADO · Estante: ${m.estante.isEmpty ? '—' : m.estante}',
                ),
              if (alertas.stockBajo.isNotEmpty)
                _Seccion(
                  titulo: '🟡 Stock Bajo',
                  color: AppColors.warning,
                  items: alertas.stockBajo,
                  mensaje: (m) =>
                      '${m.cantidad} ${m.unidad} (mínimo: ${m.cantidadMinima})',
                ),
              if (alertas.porVencer.isNotEmpty)
                _Seccion(
                  titulo: '⚠️ Próximos a Vencer',
                  color: const Color(0xFFB8860B),
                  items: alertas.porVencer,
                  mensaje: (m) {
                    final dias = diasParaVencer(m) ?? 0;
                    if (dias < 0) {
                      return 'VENCIDO hace ${dias.abs()} días (${m.fechaVencimiento})';
                    }
                    return 'Vence en $dias días (${m.fechaVencimiento})';
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarEliminarVencido(
      BuildContext context, WidgetRef ref, Medicamento med) async {
    final dias = (diasParaVencer(med) ?? 0).abs();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.danger),
            SizedBox(width: 8),
            Expanded(child: Text('Eliminar medicamento vencido')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Eliminar "${med.nombre}"?',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Venció hace $dias días\n'
              'Stock a eliminar: ${med.cantidad} ${med.unidad}\n'
              'Estante: ${med.estante.isEmpty ? '—' : med.estante}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            const Text('⚠️ Esta acción no se puede deshacer.',
                style: TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete, color: Colors.white, size: 18),
            label: const Text('Sí, eliminar',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      final usuario = ref.read(usuarioActivoProvider);
      await ref.read(farmaciaServiceProvider).eliminarMedicamentoVencido(
            med,
            uid: usuario?.id ?? '',
            nombreResponsable: usuario?.nombre ?? '',
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${med.nombre} eliminado'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Widget _todoBien() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Column(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 60),
            SizedBox(height: 12),
            Text('Todo el inventario está en orden',
                style: TextStyle(
                    color: AppColors.success,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _SeccionVencidos extends StatelessWidget {
  final List<Medicamento> items;
  final bool puedeEliminar;
  final void Function(Medicamento) onEliminar;

  const _SeccionVencidos({
    required this.items,
    required this.puedeEliminar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.12),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                const Icon(Icons.dangerous, color: AppColors.danger),
                const SizedBox(width: 8),
                Text('🚫 MEDICAMENTOS VENCIDOS (${items.length})',
                    style: const TextStyle(
                        color: AppColors.danger,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
              ],
            ),
          ),
          ...items.map((m) {
            final dias = (diasParaVencer(m) ?? 0).abs();
            return ListTile(
              leading: const Icon(Icons.warning_amber,
                  color: AppColors.danger, size: 30),
              title: Text(m.nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                'Venció hace $dias días · Estante: ${m.estante.isEmpty ? '—' : m.estante} · '
                'Stock: ${m.cantidad} ${m.unidad}',
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
              trailing: puedeEliminar
                  ? ElevatedButton.icon(
                      onPressed: () => onEliminar(m),
                      icon: const Icon(Icons.delete,
                          color: Colors.white, size: 16),
                      label: const Text('Eliminar',
                          style: TextStyle(
                              color: Colors.white, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                    )
                  : null,
            );
          }),
        ],
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  final String titulo;
  final Color color;
  final List<Medicamento> items;
  final String Function(Medicamento) mensaje;

  const _Seccion({
    required this.titulo,
    required this.color,
    required this.items,
    required this.mensaje,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Text(
              '$titulo (${items.length})',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: color, fontSize: 14),
            ),
          ),
          ...items.map((m) => ListTile(
                leading: Icon(Icons.medication, color: color),
                title: Text(m.nombre,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(mensaje(m),
                    style: const TextStyle(fontSize: 12)),
                trailing: Text(
                  m.codigoInterno,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              )),
        ],
      ),
    );
  }
}
