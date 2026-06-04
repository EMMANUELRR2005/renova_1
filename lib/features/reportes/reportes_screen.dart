import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/widgets_comunes.dart';
import '../../data/services/reporte_service.dart';

class ReportesScreen extends ConsumerStatefulWidget {
  const ReportesScreen({super.key});

  @override
  ConsumerState<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends ConsumerState<ReportesScreen> {
  String _periodo = 'mes';
  DateTimeRange? _rangoPersonalizado;
  bool _cargando = true;

  Map<String, dynamic> _clinica = {};
  Map<String, dynamic> _farmacia = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  ({DateTime desde, DateTime hasta}) _rango() {
    final hoy = DateTime.now();
    if (_periodo == 'custom' && _rangoPersonalizado != null) {
      final d = _rangoPersonalizado!.start;
      final h = _rangoPersonalizado!.end;
      return (
        desde: DateTime(d.year, d.month, d.day),
        hasta: DateTime(h.year, h.month, h.day).add(const Duration(days: 1))
      );
    }
    switch (_periodo) {
      case 'hoy':
        final d = DateTime(hoy.year, hoy.month, hoy.day);
        return (desde: d, hasta: d.add(const Duration(days: 1)));
      case 'semana':
        var d = hoy.subtract(Duration(days: hoy.weekday - 1));
        d = DateTime(d.year, d.month, d.day);
        return (desde: d, hasta: d.add(const Duration(days: 7)));
      case 'anio':
        return (desde: DateTime(hoy.year, 1, 1), hasta: DateTime(hoy.year + 1, 1, 1));
      case 'mes':
      default:
        return (
          desde: DateTime(hoy.year, hoy.month, 1),
          hasta: DateTime(hoy.year, hoy.month + 1, 1)
        );
    }
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final r = _rango();
      final service = ReporteService();
      final res = await Future.wait([
        service.getReporteClinica(desde: r.desde, hasta: r.hasta),
        service.getReporteFarmacia(desde: r.desde, hasta: r.hasta),
      ]);
      if (mounted) {
        setState(() {
          _clinica = res[0];
          _farmacia = res[1];
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error cargando reportes: $e'),
              backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _seleccionarRango() async {
    final hoy = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024, 1, 1),
      lastDate: DateTime(hoy.year + 1, 12, 31),
      initialDateRange: _rangoPersonalizado,
    );
    if (picked != null) {
      setState(() {
        _rangoPersonalizado = picked;
        _periodo = 'custom';
      });
      _cargar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedIndex: 2,
      onNavigate: (_) {},
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            const SizedBox(height: 12),
            Expanded(
              child: _cargando
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      children: [
                        _buildReportesClinica(),
                        _buildReportesFarmacia(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Reportes',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: GoogleFonts.dmSans().fontFamily,
              )),
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final p in const [
                ('hoy', 'Hoy'),
                ('semana', 'Semana'),
                ('mes', 'Mes'),
                ('anio', 'Año'),
              ])
                ChoiceChip(
                  label: Text(p.$2),
                  selected: _periodo == p.$1,
                  onSelected: (s) {
                    if (s) {
                      setState(() => _periodo = p.$1);
                      _cargar();
                    }
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                      color: _periodo == p.$1
                          ? Colors.white
                          : AppColors.textPrimary),
                ),
              OutlinedButton.icon(
                onPressed: _seleccionarRango,
                icon: const Icon(Icons.date_range, size: 16),
                label: Text(_periodo == 'custom' && _rangoPersonalizado != null
                    ? '${DateFormat('dd/MM').format(_rangoPersonalizado!.start)} - ${DateFormat('dd/MM').format(_rangoPersonalizado!.end)}'
                    : 'Personalizado'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _periodo == 'custom'
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Actualizar',
                onPressed: _cargar,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(10),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_hospital_outlined, size: 18),
                SizedBox(width: 6),
                Text('Clínica'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medication_outlined, size: 18),
                SizedBox(width: 6),
                Text('Farmacia'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── REPORTES CLÍNICA ──────────────────────────────────────────────────────

  Widget _buildReportesClinica() {
    final c = _clinica;
    final porMetodo = (c['porMetodo'] as Map?)?.cast<String, double>() ?? {};
    final porClinica = (c['porClinica'] as Map?)?.cast<String, int>() ?? {};
    final porServicio = (c['porServicio'] as Map?)?.cast<String, int>() ?? {};
    final porDoctora = (c['porDoctora'] as Map?)?.cast<String, int>() ?? {};
    final ultimas = (c['ultimas'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final citasTotal = (c['citasTotal'] ?? 0) as int;
    final canceladas = (c['canceladas'] ?? 0) as int;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Resumen financiero
          _SeccionCard(
            titulo: '1. Resumen Financiero — Servicios Médicos',
            child: Column(
              children: [
                Row(
                  children: [
                    _mini('Ingresos servicios',
                        'Q ${NumberFormat('#,##0.00').format(c['ingresos'] ?? 0)}',
                        AppColors.clinicalGreen),
                    _mini('Ventas', '${c['countVentas'] ?? 0}', AppColors.primary),
                    _mini(
                        'Ticket promedio',
                        'Q ${NumberFormat('#,##0.00').format(c['ticketPromedio'] ?? 0)}',
                        _dorado),
                  ],
                ),
                const SizedBox(height: 12),
                _metodoRow('Efectivo', porMetodo['efectivo'] ?? 0, AppColors.success),
                _metodoRow('Tarjeta', porMetodo['tarjeta'] ?? 0, AppColors.primary),
                _metodoRow(
                    'Visa Cuotas', porMetodo['visa_cuotas'] ?? 0, AppColors.warning),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 2. Estadísticas de pacientes
          _SeccionCard(
            titulo: '2. Estadísticas de Pacientes',
            child: Column(
              children: [
                Row(
                  children: [
                    _mini('Total', '${c['totalPacientes'] ?? 0}', AppColors.primary),
                    _mini('Activos', '${c['pacientesActivos'] ?? 0}', AppColors.success),
                    _mini('Inactivos', '${c['pacientesInactivos'] ?? 0}', AppColors.neutral),
                    _mini('Nuevos (mes)', '${c['nuevosMes'] ?? 0}', _dorado),
                  ],
                ),
                const SizedBox(height: 12),
                _tablaConteo('Pacientes por Clínica', porClinica, 'Clínica'),
                const SizedBox(height: 12),
                _tablaConteo('Pacientes por Servicio', porServicio, 'Servicio'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 3. Estadísticas de citas
          _SeccionCard(
            titulo: '3. Estadísticas de Citas',
            child: Column(
              children: [
                Row(
                  children: [
                    _mini('Total', '$citasTotal', AppColors.primary),
                    _mini('Completadas', '${c['completadas'] ?? 0}', AppColors.success),
                    _mini('Canceladas', '$canceladas', AppColors.danger),
                    _mini(
                        'Tasa cancelación',
                        citasTotal > 0
                            ? '${(canceladas / citasTotal * 100).toStringAsFixed(1)}%'
                            : '0%',
                        AppColors.warning),
                  ],
                ),
                const SizedBox(height: 12),
                _tablaConteo('Citas por Doctora', porDoctora, 'Doctora'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 4. Tabla detallada de ventas (servicios)
          _SeccionCard(
            titulo: '4. Detalle de Ventas — Servicios',
            child: ultimas.isEmpty
                ? _sinDatos()
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Fecha')),
                        DataColumn(label: Text('Paciente')),
                        DataColumn(label: Text('Servicio')),
                        DataColumn(label: Text('Monto')),
                        DataColumn(label: Text('Método')),
                        DataColumn(label: Text('Secretaria')),
                      ],
                      rows: ultimas.map((v) {
                        final f = v['fecha'] as DateTime;
                        return DataRow(cells: [
                          DataCell(Text(DateFormat('dd/MM/yy').format(f))),
                          DataCell(Text(v['paciente'] ?? '')),
                          DataCell(Text(v['servicio'] ?? '')),
                          DataCell(Text(
                              'Q ${(v['monto'] as double).toStringAsFixed(2)}')),
                          DataCell(_metodoBadge(v['metodoPago'] ?? '')),
                          DataCell(Text(v['secretaria'] ?? '')),
                        ]);
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── REPORTES FARMACIA ─────────────────────────────────────────────────────

  Widget _buildReportesFarmacia() {
    final f = _farmacia;
    final porMetodo = (f['porMetodo'] as Map?)?.cast<String, double>() ?? {};
    final porCategoria = (f['porCategoria'] as Map?)?.cast<String, int>() ?? {};
    final masVendidos = (f['masVendidos'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final movimientos = (f['movimientos'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final ultimas = (f['ultimas'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Resumen financiero farmacia
          _SeccionCard(
            titulo: '1. Resumen Financiero — Medicamentos',
            child: Column(
              children: [
                Row(
                  children: [
                    _mini('Ventas farmacia',
                        'Q ${NumberFormat('#,##0.00').format(f['ingresos'] ?? 0)}',
                        AppColors.clinicalGreen),
                    _mini('Transacciones', '${f['countVentas'] ?? 0}', AppColors.primary),
                    _mini(
                        'Ticket promedio',
                        'Q ${NumberFormat('#,##0.00').format(f['ticketPromedio'] ?? 0)}',
                        _dorado),
                  ],
                ),
                const SizedBox(height: 12),
                _metodoRow('Efectivo', porMetodo['efectivo'] ?? 0, AppColors.success),
                _metodoRow('Tarjeta', porMetodo['tarjeta'] ?? 0, AppColors.primary),
                _metodoRow(
                    'Visa Cuotas', porMetodo['visa_cuotas'] ?? 0, AppColors.warning),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 2. Estadísticas de inventario
          _SeccionCard(
            titulo: '2. Estadísticas de Inventario',
            child: Column(
              children: [
                Row(
                  children: [
                    _mini('Medicamentos', '${f['totalMedicamentos'] ?? 0}', AppColors.primary),
                    _mini(
                        'Valor inventario',
                        'Q ${NumberFormat('#,##0').format(f['valorInventario'] ?? 0)}',
                        AppColors.clinicalGreen),
                    _mini('Stock crítico', '${f['stockBajo'] ?? 0}', AppColors.danger),
                    _mini('Por vencer', '${f['porVencer'] ?? 0}', AppColors.warning),
                  ],
                ),
                const SizedBox(height: 12),
                _tablaConteo('Medicamentos por Categoría', porCategoria, 'Categoría'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 3. Medicamentos más vendidos
          _SeccionCard(
            titulo: '3. Medicamentos Más Vendidos',
            child: masVendidos.isEmpty
                ? _sinDatos()
                : Column(
                    children: masVendidos.asMap().entries.map((e) {
                      final i = e.key;
                      final m = e.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              child: Text('${i + 1}',
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.primary)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(m['nombre'] ?? '')),
                            Text('${m['unidades']} uds',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),
          // 4. Movimientos de inventario
          _SeccionCard(
            titulo: '4. Movimientos de Inventario',
            child: movimientos.isEmpty
                ? _sinDatos()
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Fecha')),
                        DataColumn(label: Text('Medicamento')),
                        DataColumn(label: Text('Tipo')),
                        DataColumn(label: Text('Cantidad')),
                        DataColumn(label: Text('Responsable')),
                      ],
                      rows: movimientos.map((m) {
                        final fe = m['fecha'] as DateTime;
                        return DataRow(cells: [
                          DataCell(Text(DateFormat('dd/MM/yy HH:mm').format(fe))),
                          DataCell(Text(m['medicamento'] ?? '')),
                          DataCell(_tipoMovBadge(m['tipo'] ?? '')),
                          DataCell(Text('${m['cantidad']}')),
                          DataCell(Text(m['responsable'] ?? '')),
                        ]);
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          // 5. Detalle ventas farmacia
          _SeccionCard(
            titulo: '5. Detalle de Ventas — Farmacia',
            child: ultimas.isEmpty
                ? _sinDatos()
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Fecha')),
                        DataColumn(label: Text('Cliente')),
                        DataColumn(label: Text('Medicamento')),
                        DataColumn(label: Text('Monto')),
                        DataColumn(label: Text('Método')),
                      ],
                      rows: ultimas.map((v) {
                        final fe = v['fecha'] as DateTime;
                        return DataRow(cells: [
                          DataCell(Text(DateFormat('dd/MM/yy').format(fe))),
                          DataCell(Text(v['cliente'] ?? '')),
                          DataCell(Text(v['medicamento'] ?? '')),
                          DataCell(Text(
                              'Q ${(v['monto'] as double).toStringAsFixed(2)}')),
                          DataCell(_metodoBadge(v['metodoPago'] ?? '')),
                        ]);
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _mini(String label, String valor, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(valor,
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _metodoRow(String label, double monto, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration:
                BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text('Q ${monto.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _tablaConteo(String titulo, Map<String, int> data, String colLabel) {
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        if (entries.isEmpty)
          _sinDatos()
        else
          ...entries.take(8).map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(child: Text(e.key)),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${e.value}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _metodoBadge(String metodo) {
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
          borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _tipoMovBadge(String tipo) {
    Color color;
    String label;
    switch (tipo) {
      case 'venta':
        color = AppColors.success;
        label = 'Venta';
        break;
      case 'entrada':
        color = AppColors.primary;
        label = 'Entrada';
        break;
      case 'eliminacion_vencido':
        color = AppColors.danger;
        label = 'Elim. vencido';
        break;
      case 'ajuste':
        color = AppColors.warning;
        label = 'Ajuste';
        break;
      default:
        color = AppColors.neutral;
        label = tipo;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _sinDatos() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
            child: Text('Sin datos en el período',
                style: TextStyle(color: AppColors.textSecondary))),
      );
}

const _dorado = Color(0xFFC9A96E);

class _SeccionCard extends StatelessWidget {
  final String titulo;
  final Widget child;

  const _SeccionCard({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
        boxShadow: kSombraSuave,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontFamily: GoogleFonts.dmSans().fontFamily,
              )),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
