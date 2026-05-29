import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../data/services/reporte_service.dart';

class ReportesScreen extends ConsumerStatefulWidget {
  const ReportesScreen({super.key});

  @override
  ConsumerState<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends ConsumerState<ReportesScreen> {
  String _filtro = 'mes';
  bool _cargando = true;

  Map<String, dynamic> _resumenGeneral = {};
  Map<String, dynamic> _ventasPorMetodo = {};
  List<Map<String, dynamic>> _serviciosMasVendidos = [];
  List<Map<String, dynamic>> _pacientesPorClinica = [];
  List<Map<String, dynamic>> _ultimasVentas = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);

    try {
      final service = ReporteService();
      DateTime? desde;
      DateTime? hasta;

      switch (_filtro) {
        case 'hoy':
          final hoy = DateTime.now();
          desde = DateTime(hoy.year, hoy.month, hoy.day);
          hasta = desde.add(const Duration(days: 1));
          break;
        case 'semana':
          final hoy = DateTime.now();
          desde = hoy.subtract(Duration(days: hoy.weekday - 1));
          desde = DateTime(desde.year, desde.month, desde.day);
          hasta = desde.add(const Duration(days: 7));
          break;
        case 'mes':
        default:
          final hoy = DateTime.now();
          desde = DateTime(hoy.year, hoy.month, 1);
          hasta = DateTime(hoy.year, hoy.month + 1, 1);
          break;
      }

      final futures = await Future.wait([
        service.getResumenGeneral(desde: desde, hasta: hasta),
        service.getVentasPorMetodo(desde: desde, hasta: hasta),
        service.getServiciosMasVendidos(desde: desde, hasta: hasta),
        service.getPacientesPorClinica(),
        service.getUltimasVentas(),
      ]);

      if (mounted) {
        setState(() {
          _resumenGeneral = futures[0] as Map<String, dynamic>;
          _ventasPorMetodo = futures[1] as Map<String, dynamic>;
          _serviciosMasVendidos = futures[2] as List<Map<String, dynamic>>;
          _pacientesPorClinica = futures[3] as List<Map<String, dynamic>>;
          _ultimasVentas = futures[4] as List<Map<String, dynamic>>;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando reportes: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedIndex: 2,
      onNavigate: (index) {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Reportes',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: GoogleFonts.dmSans().fontFamily,
                  ),
                ),
                const Spacer(),
                _buildFiltros(),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Actualizar',
                  onPressed: _cargarDatos,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_cargando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(64),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              _buildResumenGeneral(),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildVentasPorMetodo()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildServiciosMasVendidos()),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildPacientesPorClinica()),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _buildUltimasVentas()),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFiltroChip('Hoy', 'hoy'),
          _buildFiltroChip('Semana', 'semana'),
          _buildFiltroChip('Mes', 'mes'),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String label, String value) {
    final selected = value == _filtro;
    return InkWell(
      onTap: () {
        setState(() => _filtro = value);
        _cargarDatos();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildResumenGeneral() {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            titulo: 'Total Pacientes',
            valor: '${_resumenGeneral['totalPacientes'] ?? 0}',
            icono: Icons.people,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            titulo: 'Pacientes Activos',
            valor: '${_resumenGeneral['pacientesActivos'] ?? 0}',
            icono: Icons.person_pin,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            titulo: 'Citas Hoy',
            valor: '${_resumenGeneral['citasHoy'] ?? 0}',
            icono: Icons.calendar_today,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            titulo: 'Total Ventas',
            valor: 'Q ${(_resumenGeneral['totalVentas'] ?? 0.0).toStringAsFixed(2)}',
            icono: Icons.monetization_on,
            color: AppColors.clinicalGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            titulo: 'Ingresos del Mes',
            valor: 'Q ${(_resumenGeneral['ingresosMes'] ?? 0.0).toStringAsFixed(2)}',
            icono: Icons.trending_up,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            titulo: 'Servicios Realizados',
            valor: '${_resumenGeneral['serviciosRealizados'] ?? 0}',
            icono: Icons.medical_services,
            color: AppColors.neutral,
          ),
        ),
      ],
    );
  }

  Widget _buildVentasPorMetodo() {
    final efectivo = _ventasPorMetodo['efectivo'] as Map<String, dynamic>? ?? {};
    final tarjeta = _ventasPorMetodo['tarjeta'] as Map<String, dynamic>? ?? {};
    final visaCuotas = _ventasPorMetodo['visa_cuotas'] as Map<String, dynamic>? ?? {};
    final total = _ventasPorMetodo['total'] ?? 0.0;

    return _SeccionCard(
      titulo: 'Ventas por Método de Pago',
      child: Column(
        children: [
          _MetodoPagoRow(
            'Efectivo',
            efectivo['monto'] ?? 0.0,
            efectivo['count'] ?? 0,
            AppColors.success,
          ),
          _MetodoPagoRow(
            'Tarjeta',
            tarjeta['monto'] ?? 0.0,
            tarjeta['count'] ?? 0,
            AppColors.primary,
          ),
          _MetodoPagoRow(
            'Visa Cuotas',
            visaCuotas['monto'] ?? 0.0,
            visaCuotas['count'] ?? 0,
            AppColors.warning,
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                'Q ${(total as double).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiciosMasVendidos() {
    return _SeccionCard(
      titulo: 'Servicios Más Vendidos',
      child: _serviciosMasVendidos.isEmpty
          ? const Center(
              child: Text(
                'Sin datos',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : Column(
              children: _serviciosMasVendidos.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(item['servicio'] ?? ''),
                      ),
                      Text(
                        '${item['cantidad']} atenciones',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildPacientesPorClinica() {
    return _SeccionCard(
      titulo: 'Pacientes por Clínica',
      child: _pacientesPorClinica.isEmpty
          ? const Center(
              child: Text(
                'Sin datos',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : Column(
              children: _pacientesPorClinica.map((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.local_hospital,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(item['clinica'] ?? ''),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${item['cantidad']} pacientes',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildUltimasVentas() {
    return _SeccionCard(
      titulo: 'Últimas Ventas',
      child: _ultimasVentas.isEmpty
          ? const Center(
              child: Text(
                'Sin ventas registradas',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Fecha')),
                  DataColumn(label: Text('Paciente')),
                  DataColumn(label: Text('Servicio')),
                  DataColumn(label: Text('Monto')),
                  DataColumn(label: Text('Método')),
                ],
                rows: _ultimasVentas.map((v) {
                  final fecha = v['fecha'] as DateTime;
                  return DataRow(cells: [
                    DataCell(Text(
                      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}',
                    )),
                    DataCell(Text(v['paciente'] ?? '')),
                    DataCell(Text(v['servicio'] ?? '')),
                    DataCell(Text('Q ${(v['monto'] as double).toStringAsFixed(2)}')),
                    DataCell(_buildMetodoBadge(v['metodoPago'] ?? '')),
                  ]);
                }).toList(),
              ),
            ),
    );
  }

  Widget _buildMetodoBadge(String metodo) {
    Color color;
    String label;
    switch (metodo) {
      case 'efectivo':
        color = AppColors.success;
        label = 'Efectivo';
        break;
      case 'tarjeta':
        color = AppColors.primary;
        label = 'Tarjeta';
        break;
      case 'visa_cuotas':
        color = AppColors.warning;
        label = 'Visa';
        break;
      default:
        color = AppColors.neutral;
        label = metodo;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;

  const _KpiCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: GoogleFonts.dmSans().fontFamily,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionCard extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _SeccionCard({
    required this.titulo,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              fontFamily: GoogleFonts.dmSans().fontFamily,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MetodoPagoRow extends StatelessWidget {
  final String label;
  final double monto;
  final int count;
  final Color color;

  const _MetodoPagoRow(this.label, this.monto, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            'Q ${monto.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Text(
            '($count ventas)',
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
