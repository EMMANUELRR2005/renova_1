import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../data/mock/providers.dart';
import '../../data/services/venta_service.dart';
import '../../data/services/catalogo_service.dart';
import '../../data/services/paciente_service.dart';
import '../../data/services/email_service.dart';
import '../../data/services/farmacia_service.dart';
import '../../data/services/cierre_service.dart';
import '../../data/mock/mock_data.dart' hide Medicamento;
import '../../features/auth/providers/auth_provider.dart';
import 'factura_pdf.dart';
import 'cierre_caja_pdf.dart';

class CajaScreen extends ConsumerStatefulWidget {
  const CajaScreen({super.key});

  @override
  ConsumerState<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends ConsumerState<CajaScreen> {
  Map<String, dynamic> _resumen = {
    'totalCobrado': 0.0,
    'totalEfectivo': 0.0,
    'totalTarjeta': 0.0,
    'totalVisaCuotas': 0.0,
    'transacciones': 0,
  };
  bool _cargandoResumen = true;

  @override
  void initState() {
    super.initState();
    _cargarResumen();
  }

  Future<void> _cargarResumen() async {
    try {
      final resumen = await VentaService().getResumenHoy();
      if (mounted) {
        setState(() {
          _resumen = resumen;
          _cargandoResumen = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargandoResumen = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ventasAsync = ref.watch(ventasStreamProvider);
    final filtro = ref.watch(filtroVentasProvider);

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
                  'Caja',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: GoogleFonts.dmSans().fontFamily,
                  ),
                ),
                const Spacer(),
                _buildFiltros(filtro),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go('/caja/cierres'),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('Cierres'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _realizarCierre(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.clinicalGreen,
                    side: const BorderSide(color: AppColors.clinicalGreen),
                  ),
                  icon: const Icon(Icons.lock_outline, size: 18),
                  label: const Text('Cierre de Caja'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _mostrarFormularioCobro(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuevo Cobro'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildResumenDia(),
            const SizedBox(height: 20),
            _buildListaVentas(ventasAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros(String filtroActual) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFiltroChip('Hoy', 'hoy', filtroActual),
          _buildFiltroChip('Semana', 'semana', filtroActual),
          _buildFiltroChip('Todas', 'todas', filtroActual),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String label, String value, String actual) {
    final selected = value == actual;
    return InkWell(
      onTap: () => ref.read(filtroVentasProvider.notifier).state = value,
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

  Widget _buildResumenDia() {
    if (_cargandoResumen) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      children: [
        Expanded(
          child: _ResumenCard(
            titulo: 'Total Cobrado Hoy',
            valor: 'Q ${_resumen['totalCobrado'].toStringAsFixed(2)}',
            color: AppColors.clinicalGreen,
            icono: Icons.attach_money,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ResumenCard(
            titulo: 'Efectivo',
            valor: 'Q ${_resumen['totalEfectivo'].toStringAsFixed(2)}',
            color: AppColors.success,
            icono: Icons.money,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ResumenCard(
            titulo: 'Tarjeta',
            valor: 'Q ${_resumen['totalTarjeta'].toStringAsFixed(2)}',
            color: AppColors.primary,
            icono: Icons.credit_card,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ResumenCard(
            titulo: 'Visa Cuotas',
            valor: 'Q ${_resumen['totalVisaCuotas'].toStringAsFixed(2)}',
            color: AppColors.warning,
            icono: Icons.calendar_today,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ResumenCard(
            titulo: 'Transacciones',
            valor: '${_resumen['transacciones']}',
            color: AppColors.neutral,
            icono: Icons.receipt_long,
          ),
        ),
      ],
    );
  }

  Widget _buildListaVentas(AsyncValue<List<Venta>> ventasAsync) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Ventas',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: GoogleFonts.dmSans().fontFamily,
              ),
            ),
          ),
          ventasAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: $e'),
            ),
            data: (ventas) {
              if (ventas.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No hay ventas registradas',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                );
              }
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Correlativo')),
                    DataColumn(label: Text('Paciente')),
                    DataColumn(label: Text('Servicio')),
                    DataColumn(label: Text('Monto')),
                    DataColumn(label: Text('Método')),
                    DataColumn(label: Text('Hora')),
                    DataColumn(label: Text('Estado')),
                    DataColumn(label: Text('Acciones')),
                  ],
                  rows: ventas.map((v) => _buildVentaRow(v)).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  DataRow _buildVentaRow(Venta venta) {
    return DataRow(
      cells: [
        DataCell(Text(
          venta.numeroCorrelativo,
          style: const TextStyle(fontWeight: FontWeight.w600),
        )),
        DataCell(Text(venta.nombrePaciente)),
        DataCell(Text(venta.servicio)),
        DataCell(Text(
          'Q ${venta.monto.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        )),
        DataCell(_buildMetodoBadge(venta.metodoPago)),
        DataCell(Text(
          '${venta.fechaVenta.hour.toString().padLeft(2, '0')}:${venta.fechaVenta.minute.toString().padLeft(2, '0')}',
        )),
        DataCell(_buildEstadoBadge(venta.estado)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (venta.estado == 'pagado') ...[
                IconButton(
                  icon: const Icon(Icons.receipt_long, size: 18, color: AppColors.primary),
                  tooltip: 'Generar Factura',
                  onPressed: () => FacturaPDF.generarYMostrar(venta: venta),
                ),
                IconButton(
                  icon: Icon(
                    Icons.email_outlined,
                    size: 18,
                    color: venta.emailPaciente.isNotEmpty
                        ? const Color(0xFFC9A96E)
                        : AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  tooltip: venta.emailPaciente.isNotEmpty
                      ? 'Enviar Factura por Email'
                      : 'Sin email registrado',
                  onPressed: venta.emailPaciente.isNotEmpty
                      ? () => _enviarFacturaPorEmail(venta)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.cancel, size: 18, color: AppColors.danger),
                  tooltip: 'Anular',
                  onPressed: () => _mostrarDialogAnular(venta),
                ),
              ],
            ],
          ),
        ),
      ],
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
        label = 'Visa Cuotas';
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
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(String estado) {
    Color color;
    switch (estado) {
      case 'pagado':
        color = AppColors.success;
        break;
      case 'anulado':
        color = AppColors.danger;
        break;
      default:
        color = AppColors.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _mostrarDialogAnular(Venta venta) {
    final motivoController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anular Venta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Anular la venta ${venta.numeroCorrelativo}?'),
            const SizedBox(height: 16),
            TextField(
              controller: motivoController,
              decoration: const InputDecoration(
                labelText: 'Motivo de anulación *',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (motivoController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ingresa el motivo de anulación'),
                    backgroundColor: AppColors.warning,
                  ),
                );
                return;
              }
              try {
                await VentaService().anularVenta(
                  venta.id,
                  motivoController.text.trim(),
                );
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Venta anulada'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _cargarResumen();
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Anular'),
          ),
        ],
      ),
    );
  }

  void _mostrarFormularioCobro(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _NuevoCobroDialog(
        onCobroCreado: () {
          _cargarResumen();
        },
      ),
    );
  }

  Future<void> _realizarCierre(BuildContext context) async {
    final service = CierreService();
    final usuario = ref.read(usuarioActivoProvider);

    // Mostrar loader breve mientras se consulta.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final existente = await service.getCierreDelDia();
      if (!mounted) return;
      Navigator.of(context).pop(); // cerrar loader

      if (existente != null) {
        _mostrarCierreExistente(existente);
        return;
      }

      final cierre = await service.calcularCierre(
        realizadoPor: usuario?.id ?? '',
        nombreSecretaria: usuario?.nombre ?? '',
      );
      if (!mounted) return;
      _mostrarConfirmacionCierre(cierre, service);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _mostrarCierreExistente(CierreCaja cierre) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Text('Cierre ya realizado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('El cierre de caja de hoy ya fue realizado.'),
            const SizedBox(height: 12),
            _resumenCierreRow('Total cobrado',
                'Q ${cierre.totalGeneral.toStringAsFixed(2)}'),
            _resumenCierreRow(
                'Transacciones', '${cierre.cantidadTransacciones}'),
            _resumenCierreRow('Responsable', cierre.nombreSecretaria),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              CierreCajaPDF.generarYMostrar(cierre);
            },
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('Ver PDF'),
          ),
        ],
      ),
    );
  }

  void _mostrarConfirmacionCierre(CierreCaja cierre, CierreService service) {
    bool guardando = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Realizar Cierre de Caja'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Resumen del día:'),
                const SizedBox(height: 12),
                _resumenCierreRow('Efectivo',
                    'Q ${cierre.totalEfectivo.toStringAsFixed(2)}'),
                _resumenCierreRow('Tarjeta',
                    'Q ${cierre.totalTarjeta.toStringAsFixed(2)}'),
                _resumenCierreRow('Visa Cuotas',
                    'Q ${cierre.totalVisaCuotas.toStringAsFixed(2)}'),
                const Divider(),
                _resumenCierreRow(
                    'TOTAL', 'Q ${cierre.totalGeneral.toStringAsFixed(2)}',
                    bold: true),
                _resumenCierreRow('Anulados',
                    'Q ${cierre.totalAnulados.toStringAsFixed(2)}'),
                _resumenCierreRow(
                    'Transacciones', '${cierre.cantidadTransacciones}'),
                const SizedBox(height: 8),
                const Text(
                  'Esta acción no se puede deshacer. Solo se permite un cierre por día.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  guardando ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: guardando
                  ? null
                  : () async {
                      setLocal(() => guardando = true);
                      try {
                        await service.guardarCierre(cierre);
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        await CierreCajaPDF.generarYMostrar(cierre);
                        if (mounted) {
                          _cargarResumen();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cierre de caja realizado'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        setLocal(() => guardando = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: AppColors.danger),
                          );
                        }
                      }
                    },
              child: guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Confirmar Cierre'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumenCierreRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: bold ? AppColors.primary : null)),
          Text(value,
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                  color: bold ? AppColors.primary : null)),
        ],
      ),
    );
  }

  Future<void> _enviarFacturaPorEmail(Venta venta) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Enviando factura...'),
          ],
        ),
      ),
    );

    try {
      final pdfBytes = await FacturaPDF.generarBytes(venta: venta);

      final enviado = await EmailService.enviarFactura(
        emailDestino: venta.emailPaciente,
        nombrePaciente: venta.nombrePaciente,
        numeroFactura: venta.numeroCorrelativo.replaceAll('VTA', 'FAC'),
        pdfBytes: pdfBytes,
      );

      if (mounted) Navigator.of(context).pop();

      if (enviado) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Factura enviada a ${venta.emailPaciente}'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo enviar la factura. Verifique la configuración de email.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}

class _ResumenCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;
  final IconData icono;

  const _ResumenCard({
    required this.titulo,
    required this.valor,
    required this.color,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 20,
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

class _NuevoCobroDialog extends ConsumerStatefulWidget {
  final VoidCallback onCobroCreado;

  const _NuevoCobroDialog({required this.onCobroCreado});

  @override
  ConsumerState<_NuevoCobroDialog> createState() => _NuevoCobroDialogState();
}

class _NuevoCobroDialogState extends ConsumerState<_NuevoCobroDialog> {
  int _paso = 1;

  Paciente? _pacienteSeleccionado;
  String _busqueda = '';
  List<Paciente> _pacientesFiltrados = [];
  bool _buscando = false;
  final _nitController = TextEditingController(text: 'CF');

  // Cliente: registrado (paciente) o externo.
  bool _esPaciente = true;
  final _nombreClienteController = TextEditingController();
  final _emailClienteController = TextEditingController();
  // Para paciente registrado con email: decidir si enviar factura.
  bool _enviarEmailPaciente = true;

  /// Valida el email del cliente externo (vacío = válido, es opcional).
  bool get _emailExternoValido {
    final e = _emailClienteController.text.trim();
    if (e.isEmpty) return true;
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(e);
  }

  /// Email al que se enviará la factura según el tipo de cliente y opciones.
  String get _emailFacturaResumen {
    if (_esPaciente && _pacienteSeleccionado != null) {
      final e = _pacienteSeleccionado!.email.trim();
      return (e.isNotEmpty && _enviarEmailPaciente) ? e : '';
    }
    return _emailClienteController.text.trim();
  }

  List<ItemVenta> _items = [];
  String? _clinicaId;
  String? _clinicaNombre;

  // Medicamentos del cobro
  final List<_ItemMed> _itemsMed = [];
  List<Medicamento> _todosMedicamentos = [];
  List<Medicamento> _medResultados = [];
  final _medBuscarCtrl = TextEditingController();

  String _metodoPago = 'efectivo';
  final _referenciaController = TextEditingController();
  int _cuotas = 3;

  List<ServicioClinica> _servicios = [];
  List<Clinica> _clinicas = [];
  bool _cargandoCatalogos = true;

  bool _guardando = false;

  // Controllers persistentes para campos de monto y descripción
  final List<TextEditingController> _montoControllers = [];
  final List<TextEditingController> _descControllers = [];

  double get _subtotalServicios =>
      _items.fold(0.0, (sum, item) => sum + item.monto);
  double get _subtotalMedicamentos =>
      _itemsMed.fold(0.0, (sum, m) => sum + m.subtotal);
  double get _subtotal => _subtotalServicios + _subtotalMedicamentos;
  double get _subtotalSinIva => _subtotal / 1.12;
  double get _iva => _subtotal - _subtotalSinIva;
  double get _total => _subtotal;

  @override
  void initState() {
    super.initState();
    _items = [_crearItemVacio()];
    _agregarControllers();
    _cargarCatalogos();
  }

  void _agregarControllers() {
    final montoCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    _montoControllers.add(montoCtrl);
    _descControllers.add(descCtrl);
  }

  @override
  void dispose() {
    for (var c in _montoControllers) {
      c.dispose();
    }
    for (var c in _descControllers) {
      c.dispose();
    }
    _nitController.dispose();
    _nombreClienteController.dispose();
    _emailClienteController.dispose();
    _referenciaController.dispose();
    _medBuscarCtrl.dispose();
    super.dispose();
  }

  ItemVenta _crearItemVacio() {
    return ItemVenta(
      servicioId: '',
      servicio: '',
      clinicaId: '',
      clinica: '',
      monto: 0,
    );
  }

  Future<void> _cargarCatalogos() async {
    try {
      final servicios = await CatalogoService().getServicios();
      final clinicas = await CatalogoService().getClinicas();
      final medicamentos = await FarmaciaService().getMedicamentos();
      if (mounted) {
        setState(() {
          // Eliminar duplicados por id para evitar el assertion de Dropdown
          // ('exactly one item with value').
          _servicios = _dedupPorId(servicios, (s) => s.id);
          _clinicas = _dedupPorId(clinicas, (c) => c.id);
          _todosMedicamentos = medicamentos;
          _cargandoCatalogos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargandoCatalogos = false);
      }
    }
  }

  /// Devuelve la lista sin elementos con id repetido (conserva el primero).
  List<T> _dedupPorId<T>(List<T> items, String Function(T) id) {
    final vistos = <String>{};
    final out = <T>[];
    for (final it in items) {
      if (vistos.add(id(it))) out.add(it);
    }
    return out;
  }

  // ── Medicamentos en el cobro ────────────────────────────────────────────

  void _buscarMedicamentos(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _medResultados = []);
      return;
    }
    setState(() {
      _medResultados = _todosMedicamentos.where((m) {
        return m.nombre.toLowerCase().contains(q) ||
            m.nombreGenerico.toLowerCase().contains(q) ||
            m.codigoBarras.contains(query.trim()) ||
            m.codigoInterno.toLowerCase().contains(q);
      }).take(6).toList();
    });
  }

  /// Llamado cuando el lector de código de barras envía el código + Enter.
  void _agregarMedicamentoPorCodigo(String codigo) {
    final cod = codigo.trim();
    if (cod.isEmpty) return;
    Medicamento? med;
    for (final m in _todosMedicamentos) {
      if (m.codigoBarras == cod) {
        med = m;
        break;
      }
    }
    if (med != null) {
      _agregarMedicamento(med);
      _medBuscarCtrl.clear();
      setState(() => _medResultados = []);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Código no encontrado: $cod'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  void _agregarMedicamento(Medicamento med) {
    // Si ya está agregado, incrementa cantidad (respetando stock).
    final idx = _itemsMed.indexWhere((i) => i.medicamentoId == med.id);
    setState(() {
      if (idx >= 0) {
        if (_itemsMed[idx].cantidad < med.cantidad) {
          _itemsMed[idx].cantidad++;
        }
      } else {
        _itemsMed.add(_ItemMed(
          medicamentoId: med.id,
          nombre: med.nombre,
          codigoBarras: med.codigoBarras,
          precioUnitario: med.precioVenta,
          stockDisponible: med.cantidad,
        ));
      }
      _medBuscarCtrl.clear();
      _medResultados = [];
    });
  }

  void _quitarMedicamento(int index) {
    setState(() => _itemsMed.removeAt(index));
  }

  Future<void> _buscarPacientes(String query) async {
    if (query.length < 2) {
      setState(() => _pacientesFiltrados = []);
      return;
    }

    setState(() => _buscando = true);
    try {
      final pacientes = await PacienteService().buscarPacientesActivos(query);
      if (mounted) {
        setState(() {
          _pacientesFiltrados = pacientes;
          _buscando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _buscando = false);
      }
    }
  }

  void _agregarItem() {
    setState(() {
      _items.add(_crearItemVacio());
      _agregarControllers();
    });
  }

  void _quitarItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
        _montoControllers[index].dispose();
        _descControllers[index].dispose();
        _montoControllers.removeAt(index);
        _descControllers.removeAt(index);
      });
    }
  }

  void _actualizarMontoDesdeController(int index) {
    if (index < _items.length && index < _montoControllers.length) {
      final valor = double.tryParse(_montoControllers[index].text) ?? 0;
      _items[index].monto = valor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Nuevo Cobro - Paso $_paso de 4',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: GoogleFonts.dmSans().fontFamily,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildProgressIndicator(),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: _buildPasoActual(),
              ),
            ),
            const SizedBox(height: 24),
            _buildBotones(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(4, (i) {
        final activo = i + 1 <= _paso;
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: activo ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPasoActual() {
    switch (_paso) {
      case 1:
        return _buildPaso1Paciente();
      case 2:
        return _buildPaso2Servicios();
      case 3:
        return _buildPaso3MetodoPago();
      case 4:
        return _buildPaso4Confirmacion();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPaso1Paciente() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cliente',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        // Toggle tipo de cliente
        Row(
          children: [
            ChoiceChip(
              label: const Text('Paciente registrado'),
              selected: _esPaciente,
              onSelected: (_) => setState(() => _esPaciente = true),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                  color: _esPaciente ? Colors.white : AppColors.textPrimary),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Cliente externo'),
              selected: !_esPaciente,
              onSelected: (_) => setState(() => _esPaciente = false),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                  color: !_esPaciente ? Colors.white : AppColors.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_esPaciente)
          _buildBusquedaPaciente()
        else
          _buildClienteExterno(),
      ],
    );
  }

  Widget _buildBusquedaPaciente() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            labelText: 'Buscar por nombre o teléfono',
            prefixIcon: Icon(Icons.person_search),
            border: OutlineInputBorder(),
          ),
          onChanged: (v) {
            setState(() => _busqueda = v);
            _buscarPacientes(v);
          },
        ),
        const SizedBox(height: 16),
        if (_buscando)
          const Center(child: CircularProgressIndicator())
        else if (_pacientesFiltrados.isEmpty && _busqueda.length >= 2)
          const Text('No se encontraron pacientes')
        else
          ...(_pacientesFiltrados.take(5).map((p) => Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      p.nombre.isNotEmpty ? p.nombre[0].toUpperCase() : '?',
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                  title: Text(p.nombreCompleto),
                  subtitle: Text(p.telefono),
                  selected: _pacienteSeleccionado?.id == p.id,
                  selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
                  onTap: () {
                    setState(() {
                      _pacienteSeleccionado = p;
                      if (p.clinicaId != null) {
                        _clinicaId = p.clinicaId;
                        _clinicaNombre = p.clinica;
                      }
                    });
                  },
                ),
              ))),
        if (_pacienteSeleccionado != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Seleccionado: ${_pacienteSeleccionado!.nombreCompleto}',
                    style: const TextStyle(color: AppColors.success),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nitController,
            decoration: const InputDecoration(
              labelText: 'NIT del cliente',
              hintText: 'CF si es consumidor final',
              border: OutlineInputBorder(),
            ),
          ),
          // Si el paciente tiene email, permitir decidir si enviar la factura.
          if (_pacienteSeleccionado!.email.trim().isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: SwitchListTile(
                title: const Text('Enviar factura por email'),
                subtitle: Text(
                  _pacienteSeleccionado!.email,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
                secondary: const Icon(Icons.email_outlined,
                    color: AppColors.primary),
                value: _enviarEmailPaciente,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _enviarEmailPaciente = v),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildClienteExterno() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nombreClienteController,
          decoration: const InputDecoration(
            labelText: 'Nombre del cliente (opcional)',
            hintText: 'Dejar vacío para venta anónima',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nitController,
          decoration: const InputDecoration(
            labelText: 'NIT (opcional)',
            hintText: 'CF si no tiene',
            prefixIcon: Icon(Icons.receipt_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        // Email (opcional): si se ingresa, la factura se envía automáticamente.
        TextField(
          controller: _emailClienteController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Email (opcional)',
            hintText: 'Para enviar la factura',
            prefixIcon: const Icon(Icons.email_outlined),
            border: const OutlineInputBorder(),
            suffixIcon: _emailClienteController.text.trim().isNotEmpty
                ? const Icon(Icons.send, color: AppColors.primary)
                : null,
            errorText: _emailExternoValido ? null : 'Ingresa un email válido',
            helperText:
                'Si ingresas un email recibirá la factura automáticamente',
            helperStyle:
                const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Todos los campos son opcionales. Si agregas email, la factura se enviará automáticamente al confirmar el cobro.',
                  style: TextStyle(fontSize: 12, color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaso2Servicios() {
    if (_cargandoCatalogos) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Servicios a Cobrar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              '${_items.length} servicio${_items.length > 1 ? 's' : ''}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 16),

        DropdownButtonFormField<String>(
          // Solo usar el value si existe en la lista (evita el assertion).
          value: _clinicas.any((c) => c.id == _clinicaId) ? _clinicaId : null,
          decoration: const InputDecoration(
            labelText: 'Clínica *',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: _clinicas
              .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre)))
              .toList(),
          onChanged: (v) {
            final clinica = _clinicas.firstWhere((c) => c.id == v);
            setState(() {
              _clinicaId = v;
              _clinicaNombre = clinica.nombre;
              for (var item in _items) {
                item.clinicaId = v!;
                item.clinica = clinica.nombre;
              }
            });
          },
        ),
        const SizedBox(height: 16),

        ..._items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildItemCard(index, item);
        }),

        const SizedBox(height: 12),

        Center(
          child: TextButton.icon(
            onPressed: _agregarItem,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('+ Agregar otro servicio'),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1E3A5F),
            ),
          ),
        ),

        const Divider(thickness: 1, height: 32),

        _buildSeccionMedicamentos(),

        const Divider(thickness: 1, height: 32),

        _buildTotales(),
      ],
    );
  }

  Widget _buildItemCard(int index, ItemVenta item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Servicio ${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                if (_items.length > 1)
                  IconButton(
                    onPressed: () => _quitarItem(index),
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    tooltip: 'Quitar servicio',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    // Solo usar el value si existe en la lista de servicios.
                    value: _servicios.any((s) => s.id == item.servicioId)
                        ? item.servicioId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Servicio *',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    hint: const Text('Selecciona'),
                    items: _servicios.map((s) {
                      return DropdownMenuItem<String>(
                        value: s.id,
                        child: Text(s.nombre, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        final servicio = _servicios.firstWhere((s) => s.id == value);
                        setState(() {
                          _items[index].servicioId = value;
                          _items[index].servicio = servicio.nombre;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _montoControllers[index],
                    decoration: const InputDecoration(
                      labelText: 'Monto (Q) *',
                      border: OutlineInputBorder(),
                      prefixText: 'Q ',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (value) {
                      _items[index].monto = double.tryParse(value) ?? 0;
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descControllers[index],
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onChanged: (value) {
                _items[index].descripcion = value;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionMedicamentos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.medication, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(
              'Medicamentos (opcional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            if (_itemsMed.isNotEmpty)
              Text(
                '${_itemsMed.length} medicamento${_itemsMed.length > 1 ? 's' : ''}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Buscador con soporte de código de barras
        TextFormField(
          controller: _medBuscarCtrl,
          decoration: const InputDecoration(
            hintText: 'Buscar medicamento o escanear código...',
            prefixIcon: Icon(Icons.search),
            suffixIcon: Icon(Icons.barcode_reader),
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: _buscarMedicamentos,
          onFieldSubmitted: _agregarMedicamentoPorCodigo,
        ),
        // Resultados de búsqueda
        if (_medResultados.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: _medResultados.map((med) {
                final agotado = med.cantidad <= 0;
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.medication_outlined,
                      color: AppColors.primary),
                  title: Text(med.nombre),
                  subtitle: Text(
                    'Estante: ${med.estante} · Stock: ${med.cantidad} · Q ${med.precioVenta.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: agotado
                      ? const Text('Agotado',
                          style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 11,
                              fontWeight: FontWeight.w600))
                      : IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: AppColors.primary),
                          onPressed: () => _agregarMedicamento(med),
                        ),
                );
              }).toList(),
            ),
          ),
        // Medicamentos agregados
        ..._itemsMed.asMap().entries.map((e) => _buildItemMedCard(e.key, e.value)),
      ],
    );
  }

  Widget _buildItemMedCard(int index, _ItemMed item) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.medication, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.nombre,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('Q ${item.precioUnitario.toStringAsFixed(2)} c/u · stock ${item.stockDisponible}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            // Stepper de cantidad
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              onPressed: item.cantidad > 1
                  ? () => setState(() => item.cantidad--)
                  : null,
            ),
            Text('${item.cantidad}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add_circle_outline, size: 20),
              onPressed: item.cantidad < item.stockDisponible
                  ? () => setState(() => item.cantidad++)
                  : null,
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 72,
              child: Text(
                'Q ${item.subtotal.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.delete_outline,
                  size: 20, color: AppColors.danger),
              onPressed: () => _quitarMedicamento(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotales() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildTotalRow('Subtotal (sin IVA):', 'Q ${_subtotalSinIva.toStringAsFixed(2)}'),
          _buildTotalRow('IVA (12%):', 'Q ${_iva.toStringAsFixed(2)}'),
          const Divider(),
          _buildTotalRow(
            'TOTAL:',
            'Q ${_total.toStringAsFixed(2)}',
            esBold: true,
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool esBold = false, double fontSize = 14}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: esBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: esBold ? FontWeight.bold : FontWeight.normal,
              color: esBold ? AppColors.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaso3MetodoPago() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Método de Pago',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _MetodoPagoCard(
                icono: Icons.money,
                titulo: 'EFECTIVO',
                seleccionado: _metodoPago == 'efectivo',
                color: AppColors.success,
                onTap: () => setState(() => _metodoPago = 'efectivo'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetodoPagoCard(
                icono: Icons.credit_card,
                titulo: 'TARJETA',
                seleccionado: _metodoPago == 'tarjeta',
                color: AppColors.primary,
                onTap: () => setState(() => _metodoPago = 'tarjeta'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetodoPagoCard(
                icono: Icons.calendar_today,
                titulo: 'VISA CUOTAS',
                seleccionado: _metodoPago == 'visa_cuotas',
                color: AppColors.warning,
                onTap: () => setState(() => _metodoPago = 'visa_cuotas'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_metodoPago == 'tarjeta' || _metodoPago == 'visa_cuotas') ...[
          TextField(
            controller: _referenciaController,
            decoration: const InputDecoration(
              labelText: 'Número de referencia',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_metodoPago == 'visa_cuotas') ...[
          DropdownButtonFormField<int>(
            value: _cuotas,
            decoration: const InputDecoration(
              labelText: 'Número de cuotas',
              border: OutlineInputBorder(),
            ),
            items: [3, 6, 9, 12, 18, 24]
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text('$c cuotas'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _cuotas = v ?? 3),
          ),
        ],
      ],
    );
  }

  Widget _buildPaso4Confirmacion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirmación',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ConfirmRow(
                _esPaciente ? 'Paciente' : 'Cliente',
                _esPaciente
                    ? (_pacienteSeleccionado?.nombreCompleto ?? '')
                    : (_nombreClienteController.text.trim().isEmpty
                        ? 'Cliente Externo'
                        : _nombreClienteController.text.trim()),
              ),
              _ConfirmRow('NIT', _nitController.text.isEmpty ? 'CF' : _nitController.text),
              if (_emailFacturaResumen.isNotEmpty)
                _ConfirmRow('Email factura', _emailFacturaResumen),
              _ConfirmRow('Clínica', _clinicaNombre ?? ''),
              const Divider(),
              const Text(
                'Servicios:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ..._items
                  .where((item) => item.servicioId.isNotEmpty && item.monto > 0)
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check,
                                size: 16, color: AppColors.success),
                            const SizedBox(width: 8),
                            Expanded(child: Text(item.servicio)),
                            Text(
                              'Q ${item.monto.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )),
              if (_itemsMed.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Medicamentos:',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ..._itemsMed.map((m) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.medication,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text('${m.nombre} (x${m.cantidad})')),
                          Text(
                            'Q ${m.subtotal.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )),
              ],
              const Divider(),
              _ConfirmRow('Subtotal', 'Q ${_subtotalSinIva.toStringAsFixed(2)}'),
              _ConfirmRow('IVA (12%)', 'Q ${_iva.toStringAsFixed(2)}'),
              _ConfirmRow('Total', 'Q ${_total.toStringAsFixed(2)}'),
              const Divider(),
              _ConfirmRow('Método', _getMetodoLabel()),
              if (_metodoPago != 'efectivo' && _referenciaController.text.isNotEmpty)
                _ConfirmRow('Referencia', _referenciaController.text),
              if (_metodoPago == 'visa_cuotas') _ConfirmRow('Cuotas', '$_cuotas'),
            ],
          ),
        ),
      ],
    );
  }

  String _getMetodoLabel() {
    switch (_metodoPago) {
      case 'efectivo':
        return 'Efectivo';
      case 'tarjeta':
        return 'Tarjeta';
      case 'visa_cuotas':
        return 'Visa Cuotas';
      default:
        return _metodoPago;
    }
  }

  Widget _buildBotones() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_paso > 1)
          TextButton(
            onPressed: () => setState(() => _paso--),
            child: const Text('Anterior'),
          ),
        const SizedBox(width: 12),
        if (_paso < 4)
          ElevatedButton(
            onPressed: _puedeAvanzar() ? () => setState(() => _paso++) : null,
            child: const Text('Siguiente'),
          )
        else
          ElevatedButton(
            onPressed: _guardando ? null : _guardarCobro,
            child: _guardando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Confirmar Cobro'),
          ),
      ],
    );
  }

  bool _puedeAvanzar() {
    switch (_paso) {
      case 1:
        // Cliente externo: datos opcionales, pero el email (si se ingresa)
        // debe ser válido. Paciente registrado requiere selección.
        if (!_esPaciente) return _emailExternoValido;
        return _pacienteSeleccionado != null;
      case 2:
        if (_clinicaId == null) return false;
        // Una fila de servicio "parcial" (servicio sin monto o viceversa) bloquea.
        final hayParcial = _items.any(
            (i) => (i.servicioId.isNotEmpty) != (i.monto > 0));
        if (hayParcial) return false;
        final serviciosValidos = _items
            .where((i) => i.servicioId.isNotEmpty && i.monto > 0)
            .toList();
        // Debe haber al menos un servicio válido o un medicamento.
        return serviciosValidos.isNotEmpty || _itemsMed.isNotEmpty;
      case 3:
        return true;
      default:
        return false;
    }
  }

  Future<void> _guardarCobro() async {
    setState(() => _guardando = true);

    try {
      final usuario = ref.read(usuarioActivoProvider);
      final farmaciaService = FarmaciaService();

      // 1. Validar stock disponible ANTES de cobrar (estado actual del inventario)
      if (_itemsMed.isNotEmpty) {
        final actuales = await farmaciaService.getMedicamentos();
        for (final m in _itemsMed) {
          Medicamento? actual;
          for (final x in actuales) {
            if (x.id == m.medicamentoId) {
              actual = x;
              break;
            }
          }
          final disponible = actual?.cantidad ?? 0;
          if (disponible < m.cantidad) {
            setState(() => _guardando = false);
            _mostrarErrorStock(m.nombre, disponible);
            return;
          }
        }
      }

      final correlativo = await VentaService().generarCorrelativo();

      // 2. Construir items combinados (servicios válidos + medicamentos)
      final serviciosValidos = _items
          .where((i) => i.servicioId.isNotEmpty && i.monto > 0)
          .toList();
      for (var item in serviciosValidos) {
        item.clinicaId = _clinicaId ?? '';
        item.clinica = _clinicaNombre ?? '';
      }
      final medComoItems = _itemsMed
          .map((m) => ItemVenta(
                servicioId: m.medicamentoId,
                servicio: '${m.nombre} (x${m.cantidad})',
                clinicaId: _clinicaId ?? '',
                clinica: _clinicaNombre ?? '',
                descripcion: 'Medicamento',
                monto: m.subtotal,
              ))
          .toList();
      final itemsCombinados = [...serviciosValidos, ...medComoItems];

      // Datos del cliente: paciente registrado o cliente externo.
      final esPacienteReg = _esPaciente && _pacienteSeleccionado != null;
      final String pacienteId;
      final String nombreCliente;
      final String telefonoCliente;
      final String emailCliente;
      if (esPacienteReg) {
        pacienteId = _pacienteSeleccionado!.id;
        nombreCliente = _pacienteSeleccionado!.nombreCompleto;
        telefonoCliente = _pacienteSeleccionado!.telefono;
        emailCliente = _pacienteSeleccionado!.email;
      } else {
        pacienteId = '';
        nombreCliente = _nombreClienteController.text.trim().isEmpty
            ? 'Cliente Externo'
            : _nombreClienteController.text.trim();
        telefonoCliente = '';
        emailCliente = _emailClienteController.text.trim();
      }

      // Tipo de venta para reportes.
      final hayServicios = serviciosValidos.isNotEmpty;
      final hayMeds = _itemsMed.isNotEmpty;
      final tipoVenta = hayServicios && hayMeds
          ? 'mixta'
          : (hayMeds ? 'farmacia' : 'servicio');

      final venta = Venta(
        id: '',
        pacienteId: pacienteId,
        nombrePaciente: nombreCliente,
        telefonoPaciente: telefonoCliente,
        emailPaciente: emailCliente,
        nitCliente: _nitController.text.trim().isEmpty ? 'CF' : _nitController.text.trim(),
        items: itemsCombinados,
        servicio: itemsCombinados.first.servicio,
        servicioId: itemsCombinados.first.servicioId,
        clinica: _clinicaNombre ?? '',
        clinicaId: _clinicaId ?? '',
        descripcion: itemsCombinados.map((i) => i.descripcion).where((d) => d.isNotEmpty).join(', '),
        subtotalSinIva: _subtotalSinIva,
        iva: _iva,
        monto: _total,
        metodoPago: _metodoPago,
        cuotas: _metodoPago == 'visa_cuotas' ? _cuotas : 0,
        referencia: _referenciaController.text,
        estado: 'pagado',
        cobradoPor: usuario?.id ?? '',
        nombreSecretaria: usuario?.nombre ?? '',
        fechaVenta: DateTime.now(),
        numeroCorrelativo: correlativo,
        esPacienteRegistrado: esPacienteReg,
        tipoVenta: tipoVenta,
      );

      final ventaId = await VentaService().crearVenta(venta);

      // 3. Descontar medicamentos del inventario (transacción atómica por ítem)
      for (final m in _itemsMed) {
        await farmaciaService.descontarPorVenta(
          medicamentoId: m.medicamentoId,
          nombreMedicamento: m.nombre,
          cantidad: m.cantidad,
          ventaId: ventaId,
          uid: usuario?.id ?? '',
          nombreResponsable: usuario?.nombre ?? '',
        );
      }

      // 4. Guardar en historial SOLO si es paciente registrado (el cliente
      //    externo no tiene documento de paciente).
      if (esPacienteReg) {
        await _guardarEnHistorialPaciente(
          ventaId: ventaId,
          correlativo: correlativo,
          items: itemsCombinados,
          usuario: usuario,
        );
      }

      // 5. Enviar factura automáticamente si hay email:
      //    - cliente externo: siempre que haya email.
      //    - paciente registrado: solo si el switch está activado.
      final debeEnviar = emailCliente.isNotEmpty &&
          (!esPacienteReg || _enviarEmailPaciente);
      bool emailEnviado = false;
      if (debeEnviar) {
        try {
          final pdfBytes = await FacturaPDF.generarBytes(venta: venta);
          emailEnviado = await EmailService.enviarFactura(
            emailDestino: emailCliente,
            nombrePaciente: nombreCliente,
            numeroFactura: correlativo.replaceAll('VTA', 'FAC'),
            pdfBytes: pdfBytes,
          );
        } catch (_) {
          // No bloquear el flujo: la venta ya quedó guardada.
          emailEnviado = false;
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onCobroCreado();
        final String mensaje;
        final Color colorMensaje;
        if (emailEnviado) {
          mensaje = 'Cobro registrado: $correlativo · Factura enviada a $emailCliente';
          colorMensaje = AppColors.success;
        } else if (debeEnviar) {
          mensaje = 'Cobro registrado: $correlativo · No se pudo enviar el email';
          colorMensaje = AppColors.warning;
        } else {
          mensaje = 'Cobro registrado: $correlativo';
          colorMensaje = AppColors.success;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: colorMensaje,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _mostrarErrorStock(String nombre, int disponible) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Stock insuficiente de $nombre. Disponible: $disponible unidades'),
        backgroundColor: AppColors.danger,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Ver inventario',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<void> _guardarEnHistorialPaciente({
    required String ventaId,
    required String correlativo,
    required List<ItemVenta> items,
    required usuario,
  }) async {
    final pacienteId = _pacienteSeleccionado!.id;

    await FirebaseFirestore.instance
        .collection('pacientes')
        .doc(pacienteId)
        .collection('historial')
        .add({
      'tipo': 'servicio_cobrado',
      'fecha': FieldValue.serverTimestamp(),
      'items': items
          .map((item) => {
                'servicio': item.servicio,
                'servicioId': item.servicioId,
                'descripcion': item.descripcion,
                'monto': item.monto,
                'clinica': item.clinica,
              })
          .toList(),
      'montoTotal': _total,
      'metodoPago': _metodoPago,
      'numeroVenta': correlativo,
      'ventaId': ventaId,
      'registradoPor': usuario?.id ?? '',
      'nombreSecretaria': usuario?.nombre ?? '',
      'clinica': _clinicaNombre ?? '',
    });
  }
}

class _MetodoPagoCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final bool seleccionado;
  final Color color;
  final VoidCallback onTap;

  const _MetodoPagoCard({
    required this.icono,
    required this.titulo,
    required this.seleccionado,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: seleccionado ? color.withValues(alpha: 0.1) : AppColors.card,
          border: Border.all(
            color: seleccionado ? color : AppColors.border,
            width: seleccionado ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icono,
              size: 40,
              color: seleccionado ? color : AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: seleccionado ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Línea de medicamento dentro de un cobro (para descontar inventario).
class _ItemMed {
  final String medicamentoId;
  final String nombre;
  final String codigoBarras;
  final double precioUnitario;
  final int stockDisponible;
  int cantidad;

  _ItemMed({
    required this.medicamentoId,
    required this.nombre,
    required this.codigoBarras,
    required this.precioUnitario,
    required this.stockDisponible,
    this.cantidad = 1,
  });

  double get subtotal => precioUnitario * cantidad;
}

class _ConfirmRow extends StatelessWidget {
  final String label;
  final String value;

  const _ConfirmRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
