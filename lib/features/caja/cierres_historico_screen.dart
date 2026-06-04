import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/widgets_comunes.dart';
import '../../data/mock/mock_data.dart';
import '../../data/services/cierre_service.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'cierre_caja_pdf.dart';

final _cierreServiceProvider = Provider((ref) => CierreService());

final cierresStreamProvider = StreamProvider<List<CierreCaja>>((ref) {
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();
  return ref.watch(_cierreServiceProvider).streamCierres();
});

/// Histórico de cierres de caja (administradora) / consulta (secretaria).
class CierresHistoricoScreen extends ConsumerWidget {
  const CierresHistoricoScreen({super.key});

  int _sidebarIndex(RolUsuario? rol) {
    switch (rol) {
      case RolUsuario.administradora:
        return 5;
      case RolUsuario.secretaria_recepcion:
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rol = ref.watch(usuarioActivoProvider)?.rol;
    final cierresAsync = ref.watch(cierresStreamProvider);

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
                if (rol == RolUsuario.secretaria_recepcion)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/caja'),
                  ),
                Text(
                  'Histórico de Cierres de Caja',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: GoogleFonts.dmSans().fontFamily,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            cierresAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e',
                  style: const TextStyle(color: AppColors.danger)),
              data: (cierres) {
                if (cierres.isEmpty) {
                  return _vacio();
                }
                return _buildTabla(cierres);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _vacio() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
          boxShadow: kSombraSuave,
        ),
        child: const Center(
          child: Text('Aún no se han realizado cierres de caja',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );

  Widget _buildTabla(List<CierreCaja> cierres) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: kSombraSuave,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.bgGeneral,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: const Row(
              children: [
                _Cell('Fecha', flex: 3, header: true),
                _Cell('Responsable', flex: 3, header: true),
                _Cell('Efectivo', flex: 2, header: true),
                _Cell('Tarjeta', flex: 2, header: true),
                _Cell('Visa', flex: 2, header: true),
                _Cell('Total', flex: 2, header: true),
                _Cell('Trans.', flex: 1, header: true),
                _Cell('PDF', flex: 1, header: true),
              ],
            ),
          ),
          ...cierres.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            final fecha = DateFormat('dd/MM/yyyy').format(c.fecha);
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: i.isEven
                    ? Colors.white
                    : AppColors.bgGeneral.withValues(alpha: 0.4),
                border: const Border(
                    bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  _Cell(fecha, flex: 3),
                  _Cell(c.nombreSecretaria, flex: 3),
                  _Cell('Q ${c.totalEfectivo.toStringAsFixed(2)}', flex: 2),
                  _Cell('Q ${c.totalTarjeta.toStringAsFixed(2)}', flex: 2),
                  _Cell('Q ${c.totalVisaCuotas.toStringAsFixed(2)}', flex: 2),
                  _Cell('Q ${c.totalGeneral.toStringAsFixed(2)}',
                      flex: 2, bold: true),
                  _Cell('${c.cantidadTransacciones}', flex: 1),
                  Expanded(
                    flex: 1,
                    child: IconButton(
                      icon: const Icon(Icons.picture_as_pdf,
                          size: 18, color: AppColors.primary),
                      tooltip: 'Ver PDF',
                      onPressed: () => CierreCajaPDF.generarYMostrar(c),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final int flex;
  final bool header;
  final bool bold;
  const _Cell(this.text,
      {required this.flex, this.header = false, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: header ? 11 : 12,
          fontWeight: (header || bold) ? FontWeight.w600 : FontWeight.normal,
          color: header ? AppColors.textPrimary : null,
        ),
      ),
    );
  }
}
