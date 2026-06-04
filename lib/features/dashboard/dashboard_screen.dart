import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/widgets_comunes.dart';
import '../../data/services/reporte_service.dart';

const _meses = [
  'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
  'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
];
const _dorado = Color(0xFFC9A96E);
const _paleta = [
  Color(0xFF1E3A5F),
  _dorado,
  Color(0xFF3B82F6),
  Color(0xFF10B981),
  Color(0xFFF59E0B),
  Color(0xFF8B5CF6),
];

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _periodo = 'mes';
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

  String get _labelPeriodo {
    switch (_periodo) {
      case 'hoy':
        return 'Hoy';
      case 'semana':
        return 'Esta semana';
      case 'anio':
        return 'Este año';
      default:
        return 'Este mes';
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
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedIndex: 0,
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
                        _buildTabClinica(),
                        _buildTabFarmacia(),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Dashboard',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: GoogleFonts.dmSans().fontFamily,
                  )),
              Text(
                DateFormat('EEEE, d MMMM yyyy', 'es').format(DateTime.now()),
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
          Row(
            children: [
              for (final p in const [
                ('hoy', 'Hoy'),
                ('semana', 'Semana'),
                ('mes', 'Mes'),
                ('anio', 'Año'),
              ])
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _periodoBtn(p.$1, p.$2),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _periodoBtn(String value, String label) {
    final sel = _periodo == value;
    return InkWell(
      onTap: () {
        setState(() => _periodo = value);
        _cargar();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : AppColors.textSecondary)),
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

  // ── TAB CLÍNICA ───────────────────────────────────────────────────────────

  Widget _buildTabClinica() {
    final c = _clinica;
    final serie = (c['serie6'] as List?)?.cast<double>() ?? List.filled(6, 0.0);
    final meses6 = (c['meses6'] as List?)?.cast<Map>() ?? [];
    final serviciosPie = (c['serviciosPie'] as Map?)?.cast<String, int>() ?? {};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              _card('Pacientes Totales', '${c['totalPacientes'] ?? 0}',
                  '+${c['nuevosMes'] ?? 0} este mes', Icons.people_outline,
                  AppColors.primaryDark),
              _card('Citas Hoy', '${c['citasHoy'] ?? 0}',
                  '${c['pendientes'] ?? 0} pendientes ($_labelPeriodo)',
                  Icons.calendar_today_outlined, const Color(0xFF3B82F6)),
              _card('Pacientes Activos', '${c['pacientesActivos'] ?? 0}',
                  '${c['pacientesInactivos'] ?? 0} inactivos',
                  Icons.person_outline, const Color(0xFF10B981)),
              _card(
                  'Ingresos Clínica',
                  'Q ${NumberFormat('#,##0.00').format(c['ingresos'] ?? 0)}',
                  _labelPeriodo,
                  Icons.attach_money,
                  _dorado,
                  last: true),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _chartCard('Ingresos por Servicios', 'Últimos 6 meses',
                    _barChart(serie, meses6, const Color(0xFF1E3A5F))),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _chartCard('Servicios más solicitados', _labelPeriodo,
                    _pieFromCounts(serviciosPie)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _chartCard(
            'Citas por estado',
            _labelPeriodo,
            _pieCitas(c),
          ),
        ],
      ),
    );
  }

  // ── TAB FARMACIA ──────────────────────────────────────────────────────────

  Widget _buildTabFarmacia() {
    final f = _farmacia;
    final vencidos = (f['vencidos'] ?? 0) as int;
    final stockBajo = (f['stockBajo'] ?? 0) as int;
    final serie = (f['serie6'] as List?)?.cast<double>() ?? List.filled(6, 0.0);
    final meses6 = (f['meses6'] as List?)?.cast<Map>() ?? [];
    final masVendidos =
        (f['masVendidos'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final porCategoria = (f['porCategoria'] as Map?)?.cast<String, int>() ?? {};
    final stockCritico =
        (f['stockCritico'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (vencidos > 0 || stockBajo > 0)
            Container(
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
                      '⚠️ $vencidos medicamento(s) vencido(s). '
                      '$stockBajo con stock bajo.',
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/farmacia/alertas'),
                    child: const Text('Ver alertas'),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              _card('Total Medicamentos', '${f['totalMedicamentos'] ?? 0}',
                  '$stockBajo con stock bajo', Icons.medication_outlined,
                  AppColors.primaryDark),
              _card(
                  'Ventas Farmacia',
                  'Q ${NumberFormat('#,##0.00').format(f['ingresos'] ?? 0)}',
                  _labelPeriodo,
                  Icons.point_of_sale_outlined,
                  _dorado),
              _card('Unidades Vendidas', '${f['unidadesVendidas'] ?? 0}',
                  'unidades · $_labelPeriodo', Icons.shopping_bag_outlined,
                  const Color(0xFF10B981)),
              _card('Por Vencer', '${f['porVencer'] ?? 0}',
                  'en los próximos 30 días', Icons.timer_outlined,
                  AppColors.warning,
                  last: true),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _chartCard('Ingresos Farmacia', 'Últimos 6 meses',
                    _barChart(serie, meses6, _dorado)),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _chartCard('Medicamentos más vendidos', _labelPeriodo,
                    _pieMasVendidos(masVendidos)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _chartCard('Inventario por categoría', 'Medicamentos',
                    _pieFromCounts(porCategoria)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _chartCard(
                  '⚠️ Stock Crítico',
                  'Bajo el mínimo',
                  _stockCriticoList(stockCritico),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers UI ──────────────────────────────────────────────────────────

  Widget _card(String titulo, String valor, String sub, IconData icono,
      Color color,
      {bool last = false}) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(right: last ? 0 : 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: kSombraSuave,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icono, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(valor,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            fontFamily: GoogleFonts.dmSans().fontFamily)),
                    const SizedBox(height: 2),
                    Text(sub,
                        style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chartCard(String titulo, String subtitulo, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: kSombraSuave,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: GoogleFonts.dmSans().fontFamily)),
          Text(subtitulo,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _barChart(List<double> serie, List<Map> meses6, Color color) {
    double maxY = 1000;
    for (final v in serie) {
      if (v > maxY) maxY = v;
    }
    maxY = (maxY * 1.2).ceilToDouble();
    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.primaryDark,
              getTooltipItem: (g, gi, rod, ri) => BarTooltipItem(
                'Q ${NumberFormat('#,##0').format(rod.toY)}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i >= 0 && i < meses6.length) {
                    final m = meses6[i]['mes'] as int;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(_meses[m - 1],
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.textSecondary)),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 46,
                getTitlesWidget: (v, m) => Text(
                  'Q${NumberFormat.compact().format(v)}',
                  style:
                      const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                ),
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (v) =>
                const FlLine(color: AppColors.border, strokeWidth: 1, dashArray: [5, 5]),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            for (int i = 0; i < serie.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: serie[i],
                  color: color,
                  width: 26,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ]),
          ],
        ),
      ),
    );
  }

  Widget _pieFromCounts(Map<String, int> counts) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = entries.take(6).toList();
    if (top.isEmpty) return _sinDatos();
    return _pie(top.map((e) => (e.key, e.value.toDouble())).toList());
  }

  Widget _pieMasVendidos(List<Map<String, dynamic>> items) {
    if (items.isEmpty) return _sinDatos();
    return _pie(items
        .take(6)
        .map((e) => (e['nombre'] as String, (e['unidades'] as int).toDouble()))
        .toList());
  }

  Widget _pieCitas(Map<String, dynamic> c) {
    final data = <(String, double)>[
      ('Completadas', (c['completadas'] ?? 0).toDouble()),
      ('Confirmadas', (c['confirmadas'] ?? 0).toDouble()),
      ('Pendientes', (c['pendientes'] ?? 0).toDouble()),
      ('Canceladas', (c['canceladas'] ?? 0).toDouble()),
    ].where((e) => e.$2 > 0).toList();
    if (data.isEmpty) return _sinDatos();
    return _pie(data);
  }

  Widget _pie(List<(String, double)> data) {
    final total = data.fold<double>(0, (s, e) => s + e.$2);
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                for (int i = 0; i < data.length; i++)
                  PieChartSectionData(
                    color: _paleta[i % _paleta.length],
                    value: data[i].$2,
                    title: total > 0
                        ? '${(data[i].$2 / total * 100).toStringAsFixed(0)}%'
                        : '',
                    titleStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    radius: 50,
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(data.length, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: _paleta[i % _paleta.length],
                      borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(data[i].$1,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis),
                ),
                Text('${data[i].$2.toInt()}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _stockCriticoList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text('Sin medicamentos en estado crítico',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }
    return Column(
      children: items.take(8).map((m) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.warning_amber,
                  size: 16, color: AppColors.danger),
              const SizedBox(width: 8),
              Expanded(child: Text(m['nombre'] ?? '')),
              Text('${m['cantidad']}/${m['minimo']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: AppColors.danger)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _sinDatos() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
            child: Text('Sin datos',
                style: TextStyle(color: AppColors.textSecondary))),
      );
}
