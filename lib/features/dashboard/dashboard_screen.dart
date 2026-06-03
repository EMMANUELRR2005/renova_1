import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../data/mock/providers.dart';
import '../../data/services/venta_service.dart';
import '../../data/services/cita_service.dart';
import '../../data/services/paciente_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _periodo = 'mes';
  bool _cargando = true;

  Map<String, dynamic> _resumenHoy = {};
  Map<String, dynamic> _resumenMes = {};
  List<Map<String, dynamic>> _ingresos6Meses = [];
  Map<String, int> _serviciosMes = {};
  Map<String, double> _metodosPago = {};
  List<Venta> _ultimasVentas = [];
  List<dynamic> _citasHoy = [];
  int _pacientesTotales = 0;
  int _pacientesNuevosMes = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final ventaService = VentaService();
      final citaService = CitaService();
      final pacienteService = PacienteService();

      final citasHoyStream = await citaService.streamCitasMedicasHoy().first;

      final results = await Future.wait([
        ventaService.getResumenHoy(),
        ventaService.getResumenMes(),
        ventaService.getIngresosUltimos6Meses(),
        ventaService.getServiciosPorMes(),
        ventaService.getMetodosPagoMes(),
        pacienteService.contarPacientesActivos(),
        pacienteService.contarPacientesNuevosMes(),
      ]);

      final ventasStream = await ventaService.streamTodasLasVentas().first;

      // Logs de diagnóstico
      print('═══ DIAGNÓSTICO DASHBOARD ═══');
      print('📊 Resumen Hoy: ${results[0]}');
      print('📊 Resumen Mes: ${results[1]}');
      print('📊 Ingresos 6 meses: ${results[2]}');
      print('📊 Servicios mes: ${results[3]}');
      print('📊 Métodos pago: ${results[4]}');
      print('👥 Pacientes activos: ${results[5]}');
      print('👥 Pacientes nuevos mes: ${results[6]}');
      print('📅 Citas hoy: ${citasHoyStream.length}');
      print('💰 Ventas totales: ${ventasStream.length}');
      print('═══════════════════════════════');

      if (mounted) {
        setState(() {
          _resumenHoy = results[0] as Map<String, dynamic>;
          _resumenMes = results[1] as Map<String, dynamic>;
          _ingresos6Meses = results[2] as List<Map<String, dynamic>>;
          _serviciosMes = results[3] as Map<String, int>;
          _metodosPago = results[4] as Map<String, double>;
          _pacientesTotales = results[5] as int;
          _pacientesNuevosMes = results[6] as int;
          _citasHoy = citasHoyStream;
          _ultimasVentas = ventasStream.take(5).toList();
          _cargando = false;
        });
      }
    } catch (e) {
      print('❌ ERROR DASHBOARD: $e');
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedIndex: 0,
      onNavigate: (index) {},
      child: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildBannerAlertas(),
                    _buildKPICards(),
                    const SizedBox(height: 24),
                    _buildChartsRow(),
                    const SizedBox(height: 24),
                    _buildBottomRow(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: GoogleFonts.dmSans().fontFamily,
              ),
            ),
            Text(
              DateFormat('EEEE, d MMMM yyyy', 'es').format(DateTime.now()),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontFamily: GoogleFonts.dmSans().fontFamily,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildPeriodoButton('hoy', 'Hoy'),
            const SizedBox(width: 8),
            _buildPeriodoButton('semana', 'Semana'),
            const SizedBox(width: 8),
            _buildPeriodoButton('mes', 'Mes'),
            const SizedBox(width: 8),
            _buildPeriodoButton('anio', 'Año'),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodoButton(String value, String label) {
    final seleccionado = _periodo == value;
    return InkWell(
      onTap: () => setState(() => _periodo = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: seleccionado ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: seleccionado ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBannerAlertas() {
    final alertas = ref.watch(alertasFarmaciaProvider);
    if (!alertas.hayAlertas) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hay ${alertas.total} alerta${alertas.total == 1 ? '' : 's'} en el inventario de farmacia '
              '(${alertas.sinStock.length} sin stock, ${alertas.stockBajo.length} stock bajo, '
              '${alertas.porVencer.length} por vencer).',
              style: const TextStyle(color: AppColors.danger),
            ),
          ),
          TextButton(
            onPressed: () => context.go('/farmacia/alertas'),
            child: const Text('Ver alertas'),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICards() {
    final totalHoy = _resumenHoy['totalCobrado'] ?? 0.0;
    final totalMes = _resumenMes['total'] ?? 0.0;
    final transaccionesHoy = _resumenHoy['transacciones'] ?? 0;
    final citasHoy = _citasHoy.length;

    return Row(
      children: [
        Expanded(
          child: _KPICard(
            titulo: 'Ingresos Hoy',
            valor: 'Q ${NumberFormat('#,##0.00').format(totalHoy)}',
            icono: Icons.attach_money,
            color: const Color(0xFF10B981),
            subtitulo: '${transaccionesHoy} transacciones',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _KPICard(
            titulo: 'Ingresos del Mes',
            valor: 'Q ${NumberFormat('#,##0.00').format(totalMes)}',
            icono: Icons.trending_up,
            color: const Color(0xFF3B82F6),
            subtitulo: '${_resumenMes['transacciones'] ?? 0} ventas',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _KPICard(
            titulo: 'Citas Hoy',
            valor: '$citasHoy',
            icono: Icons.calendar_today,
            color: const Color(0xFF8B5CF6),
            subtitulo: 'Programadas',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _KPICard(
            titulo: 'Pacientes',
            valor: '$_pacientesTotales',
            icono: Icons.people,
            color: const Color(0xFFF59E0B),
            subtitulo: '+$_pacientesNuevosMes este mes',
          ),
        ),
      ],
    );
  }

  Widget _buildChartsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildIngresosMensualesChart(),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildServiciosPieChart(),
        ),
      ],
    );
  }

  Widget _buildIngresosMensualesChart() {
    final meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

    double maxY = 1000;
    for (var data in _ingresos6Meses) {
      if ((data['total'] as double) > maxY) {
        maxY = data['total'] as double;
      }
    }
    maxY = (maxY * 1.2).ceilToDouble();
    if (maxY < 1000) maxY = 1000;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ingresos Mensuales',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: GoogleFonts.dmSans().fontFamily,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up, size: 14, color: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text(
                      'Últimos 6 meses',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primary,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        'Q ${NumberFormat('#,##0').format(rod.toY)}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < _ingresos6Meses.length) {
                          final mes = _ingresos6Meses[index]['mes'] as int;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              meses[mes - 1],
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          'Q${NumberFormat.compact().format(value)}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: AppColors.border,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: _ingresos6Meses.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value['total'] as double,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E3A5F), Color(0xFF3B82F6)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 28,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiciosPieChart() {
    final colores = [
      const Color(0xFF1E3A5F),
      const Color(0xFFC9A96E),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
    ];

    final serviciosOrdenados = _serviciosMes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = serviciosOrdenados.take(5).toList();

    if (top5.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text('Sin datos de servicios'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Servicios del Mes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: GoogleFonts.dmSans().fontFamily,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: top5.asMap().entries.map((entry) {
                  final index = entry.key;
                  final servicio = entry.value;
                  return PieChartSectionData(
                    color: colores[index % colores.length],
                    value: servicio.value.toDouble(),
                    title: '${servicio.value}',
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    radius: 50,
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ...top5.asMap().entries.map((entry) {
            final index = entry.key;
            final servicio = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colores[index % colores.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      servicio.key,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${servicio.value}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

  Widget _buildBottomRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildMetodosPagoChart(),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 3,
          child: _buildUltimasTransacciones(),
        ),
      ],
    );
  }

  Widget _buildMetodosPagoChart() {
    final total = _metodosPago.values.fold<double>(0, (sum, v) => sum + v);
    if (total == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(child: Text('Sin ventas este mes')),
      );
    }

    final metodos = [
      ('Efectivo', _metodosPago['efectivo'] ?? 0, const Color(0xFF10B981), Icons.money),
      ('Tarjeta', _metodosPago['tarjeta'] ?? 0, const Color(0xFF3B82F6), Icons.credit_card),
      ('Visa Cuotas', _metodosPago['visa_cuotas'] ?? 0, const Color(0xFFF59E0B), Icons.calendar_month),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Métodos de Pago',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: GoogleFonts.dmSans().fontFamily,
            ),
          ),
          const SizedBox(height: 20),
          ...metodos.map((metodo) {
            final porcentaje = total > 0 ? (metodo.$2 / total * 100) : 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(metodo.$4, size: 18, color: metodo.$3),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          metodo.$1,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        'Q ${NumberFormat('#,##0').format(metodo.$2)}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: metodo.$3.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: porcentaje / 100,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: metodo.$3,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${porcentaje.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
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

  Widget _buildUltimasTransacciones() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Últimas Transacciones',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: GoogleFonts.dmSans().fontFamily,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Ver todas'),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.bgGeneral,
            child: const Row(
              children: [
                Expanded(flex: 2, child: Text('Paciente', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(flex: 2, child: Text('Servicio', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(child: Text('Monto', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(child: Text('Método', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                Expanded(child: Text('Estado', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          if (_ultimasVentas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('Sin transacciones recientes')),
            )
          else
            ..._ultimasVentas.asMap().entries.map((entry) {
              final index = entry.key;
              final venta = entry.value;
              final isEven = index % 2 == 0;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: isEven ? Colors.white : const Color(0xFFFAFBFC),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        venta.nombrePaciente,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        venta.serviciosResumen,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Q${venta.monto.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: _buildMetodoBadge(venta.metodoPago),
                    ),
                    Expanded(
                      child: _buildEstadoBadge(venta.estado),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMetodoBadge(String metodo) {
    Color color;
    String label;
    IconData icon;

    switch (metodo) {
      case 'efectivo':
        color = const Color(0xFF10B981);
        label = 'Efectivo';
        icon = Icons.money;
        break;
      case 'tarjeta':
        color = const Color(0xFF3B82F6);
        label = 'Tarjeta';
        icon = Icons.credit_card;
        break;
      case 'visa_cuotas':
        color = const Color(0xFFF59E0B);
        label = 'Cuotas';
        icon = Icons.calendar_month;
        break;
      default:
        color = AppColors.textSecondary;
        label = metodo;
        icon = Icons.payment;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }

  Widget _buildEstadoBadge(String estado) {
    Color bgColor;
    Color textColor;
    String label;

    switch (estado) {
      case 'pagado':
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.1);
        textColor = const Color(0xFF10B981);
        label = 'Pagado';
        break;
      case 'anulado':
        bgColor = const Color(0xFFEF4444).withValues(alpha: 0.1);
        textColor = const Color(0xFFEF4444);
        label = 'Anulado';
        break;
      default:
        bgColor = AppColors.border;
        textColor = AppColors.textSecondary;
        label = estado;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _KPICard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;
  final String subtitulo;

  const _KPICard({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.color,
    required this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icono, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: GoogleFonts.dmSans().fontFamily,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: GoogleFonts.dmSans().fontFamily,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitulo,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
