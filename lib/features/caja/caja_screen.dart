import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../data/mock/providers.dart';
import '../../data/services/venta_service.dart';
import '../../data/services/catalogo_service.dart';
import '../../data/services/paciente_service.dart';
import '../../data/mock/mock_data.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'factura_pdf.dart';

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

  List<ItemVenta> _items = [];
  String? _clinicaId;
  String? _clinicaNombre;

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

  double get _subtotal => _items.fold(0, (sum, item) => sum + item.monto);
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
    _referenciaController.dispose();
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
      if (mounted) {
        setState(() {
          _servicios = servicios;
          _clinicas = clinicas;
          _cargandoCatalogos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _cargandoCatalogos = false);
      }
    }
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
          'Seleccionar Paciente',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Buscar por nombre o teléfono',
            prefixIcon: Icon(Icons.search),
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
        ],
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
          value: _clinicaId,
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
                    value: item.servicioId.isEmpty ? null : item.servicioId,
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
              _ConfirmRow('Paciente', _pacienteSeleccionado?.nombreCompleto ?? ''),
              _ConfirmRow('NIT', _nitController.text.isEmpty ? 'CF' : _nitController.text),
              _ConfirmRow('Clínica', _clinicaNombre ?? ''),
              const Divider(),
              const Text(
                'Servicios:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ..._items.map((item) => Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check, size: 16, color: AppColors.success),
                        const SizedBox(width: 8),
                        Expanded(child: Text(item.servicio)),
                        Text(
                          'Q ${item.monto.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )),
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
        return _pacienteSeleccionado != null;
      case 2:
        return _clinicaId != null &&
            _items.isNotEmpty &&
            _items.every((item) => item.servicioId.isNotEmpty && item.monto > 0);
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
      final correlativo = await VentaService().generarCorrelativo();

      for (var item in _items) {
        item.clinicaId = _clinicaId ?? '';
        item.clinica = _clinicaNombre ?? '';
      }

      final venta = Venta(
        id: '',
        pacienteId: _pacienteSeleccionado!.id,
        nombrePaciente: _pacienteSeleccionado!.nombreCompleto,
        telefonoPaciente: _pacienteSeleccionado!.telefono,
        nitCliente: _nitController.text.trim().isEmpty ? 'CF' : _nitController.text.trim(),
        items: _items,
        servicio: _items.first.servicio,
        servicioId: _items.first.servicioId,
        clinica: _clinicaNombre ?? '',
        clinicaId: _clinicaId ?? '',
        descripcion: _items.map((i) => i.descripcion).where((d) => d.isNotEmpty).join(', '),
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
      );

      await VentaService().crearVenta(venta);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onCobroCreado();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cobro registrado: $correlativo'),
            backgroundColor: AppColors.success,
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
