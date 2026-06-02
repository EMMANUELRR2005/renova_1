import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../data/mock/mock_data.dart' hide Medicamento;
import '../../data/mock/providers.dart';
import '../../data/services/farmacia_service.dart';
import '../../features/auth/providers/auth_provider.dart';

class MovimientosFarmaciaScreen extends ConsumerWidget {
  const MovimientosFarmaciaScreen({super.key});

  int _sidebarIndex(RolUsuario? rol) =>
      rol == RolUsuario.administradora ? 3 : 1;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rol = ref.watch(usuarioActivoProvider)?.rol;
    final movsAsync = ref.watch(movimientosFarmaciaStreamProvider);

    return AppShell(
      selectedIndex: _sidebarIndex(rol),
      onNavigate: (_) {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Movimientos de Farmacia',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: GoogleFonts.dmSans().fontFamily,
              ),
            ),
            const SizedBox(height: 16),
            movsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text('Error: $e',
                  style: const TextStyle(color: AppColors.danger)),
              data: (movs) {
                if (movs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('No hay movimientos registrados',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ),
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: movs
                        .map((m) => _MovimientoRow(mov: m))
                        .toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MovimientoRow extends StatelessWidget {
  final MovimientoFarmacia mov;
  const _MovimientoRow({required this.mov});

  @override
  Widget build(BuildContext context) {
    final color = _tipoColor(mov.tipo);
    final fecha = mov.fecha;
    final fechaStr = fecha == null
        ? '—'
        : '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} ${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(_tipoLabel(mov.tipo),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mov.nombreMedicamento,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(
                  '${mov.cantidadAnterior} → ${mov.cantidadNueva}'
                  '${mov.motivo.isNotEmpty ? '  ·  ${mov.motivo}' : ''}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${mov.tipo == 'venta' || mov.tipo == 'salida' ? '-' : '+'}${mov.cantidad}',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: color),
              ),
              Text(fechaStr,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textSecondary)),
              if (mov.nombreResponsable.isNotEmpty)
                Text(mov.nombreResponsable,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Color _tipoColor(String tipo) {
    switch (tipo) {
      case 'entrada':
        return AppColors.success;
      case 'venta':
      case 'salida':
        return AppColors.danger;
      case 'ajuste':
        return AppColors.warning;
      default:
        return AppColors.neutral;
    }
  }

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'entrada':
        return 'ENTRADA';
      case 'salida':
        return 'SALIDA';
      case 'venta':
        return 'VENTA';
      case 'ajuste':
        return 'AJUSTE';
      default:
        return tipo.toUpperCase();
    }
  }
}
