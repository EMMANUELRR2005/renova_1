import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/widgets_comunes.dart';
import '../../data/mock/mock_data.dart';
import '../../data/mock/providers.dart';
import '../../data/services/farmacia_service.dart' as farmacia;
import '../../features/auth/providers/auth_provider.dart';

class NuevaConsultaScreen extends ConsumerStatefulWidget {
  const NuevaConsultaScreen({super.key});

  @override
  ConsumerState<NuevaConsultaScreen> createState() =>
      _NuevaConsultaScreenState();
}

class _ProcedimientoRow {
  String servicioId = '';
  final nombreCtrl = TextEditingController();
  final nombreFocus = FocusNode();
  final descCtrl = TextEditingController();
  final precioCtrl = TextEditingController();

  void dispose() {
    nombreCtrl.dispose();
    nombreFocus.dispose();
    descCtrl.dispose();
    precioCtrl.dispose();
  }

  double get precio => double.tryParse(precioCtrl.text.trim()) ?? 0;

  Map<String, dynamic> toMap(String servicioNombre) => {
        'nombre': nombreCtrl.text.trim(),
        'descripcion': descCtrl.text.trim(),
        'servicio': servicioNombre,
        'servicioId': servicioId,
        'precio': precio,
        'tipo': 'servicio',
      };
}

class _NuevaConsultaScreenState extends ConsumerState<NuevaConsultaScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _guardando = false;

  // Sección 1: área del servicio y notas
  final _areaCtrl = TextEditingController();
  final _notasCajaCtrl = TextEditingController();

  // Sección 4: próxima cita
  bool _mostrarProximaCita = false;
  final _proximaCitaCtrl = TextEditingController();

  final List<_ProcedimientoRow> _procedimientos = [];
  // Medicamentos de farmacia recetados (van a caja y descuentan inventario).
  final List<Map<String, dynamic>> _medsFarmacia = [];

  List<ServicioClinica> _servicios = [];

  double get _totalProcedimientos =>
      _procedimientos.fold(0.0, (total, p) => total + p.precio);

  double get _totalMedsFarmacia =>
      _medsFarmacia.fold(0.0, (acc, m) => acc + ((m['subtotal'] as num?) ?? 0).toDouble());

  double get _totalCobro => _totalProcedimientos + _totalMedsFarmacia;

  bool get _hayItemsCobro => _procedimientos.isNotEmpty || _medsFarmacia.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _cargarServicios();
  }

  Future<void> _cargarServicios() async {
    try {
      final servicios = await ref.read(catalogoServiceProvider).getServicios();
      if (mounted) setState(() => _servicios = servicios);
    } catch (_) {
      // Si falla la carga, los procedimientos se ingresan a mano (texto libre).
    }
  }

  @override
  void dispose() {
    for (final c in [_areaCtrl, _notasCajaCtrl, _proximaCitaCtrl]) {
      c.dispose();
    }
    for (final p in _procedimientos) { p.dispose(); }
    super.dispose();
  }

  void _agregarProcedimiento() {
    setState(() => _procedimientos.add(_ProcedimientoRow()));
  }

  void _eliminarProcedimiento(int index) {
    _procedimientos[index].dispose();
    setState(() => _procedimientos.removeAt(index));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar procedimientos: nombre y precio requeridos por fila agregada.
    for (final p in _procedimientos) {
      if (p.nombreCtrl.text.trim().isEmpty) {
        _showMsg('Completa el nombre del procedimiento', error: true);
        return;
      }
      if (p.precio <= 0) {
        _showMsg('Ingresa el precio del procedimiento "${p.nombreCtrl.text.trim()}"',
            error: true);
        return;
      }
    }

    setState(() => _guardando = true);

    try {
      final usuario = ref.read(usuarioActivoProvider);
      final service = ref.read(pacienteServiceProvider);
      final pacienteId = ref.read(selectedPacienteIdProvider)!;

      final esDoctora = usuario?.rol == RolUsuario.doctora;
      final proximaCita = (_mostrarProximaCita &&
              _proximaCitaCtrl.text.trim().isNotEmpty)
          ? _proximaCitaCtrl.text.trim()
          : null;

      // ── Flujo con procedimientos/medicamentos: se envía a caja para cobro ───
      if (_hayItemsCobro) {
        final paciente = await service.getPacienteById(pacienteId);

        // Procedimientos de clínica.
        final procedimientosMap = _procedimientos.map((p) {
          final nombre = p.nombreCtrl.text.trim();
          return p.toMap(nombre);
        }).toList();

        // Medicamentos de farmacia: mapeados como procedimientos con tipo=medicamento
        // para que la caja los trate igual y pueda descontar inventario al cobrar.
        final medsFarmaciaComoProcs = _medsFarmacia.map((m) => {
              'nombre': m['nombre'],
              'descripcion':
                  'x${m['cantidad']} ${(m['presentacion'] ?? '').toString()}',
              'precio': m['subtotal'],
              'tipo': 'medicamento',
              'medicamentoId': m['medicamentoId'],
              'cantidad': m['cantidad'],
              'servicioId': '',
            }).toList();

        final todosLosProcedimientos = [
          ...procedimientosMap,
          ...medsFarmaciaComoProcs,
        ];

        await ref.read(consultaCobroServiceProvider).crearConsulta(
              pacienteId: pacienteId,
              nombrePaciente: paciente?.nombreCompleto ?? '',
              telefonoPaciente: paciente?.telefono ?? '',
              emailPaciente: paciente?.email ?? '',
              procedimientos: todosLosProcedimientos,
              totalEstimado: _totalCobro,
              doctoraId: usuario?.id ?? '',
              nombreDoctora: usuario?.nombre ?? '',
              motivo: _areaCtrl.text.trim(),
              diagnostico: '',
              tratamiento: '',
              comentarios: '',
              medicamentos: const [],
              notasPrivadas: '',
              notasParaCaja: _notasCajaCtrl.text.trim(),
              proximaCita: proximaCita,
              clinicaId: paciente?.clinicaId ?? '',
              clinica: paciente?.clinica ?? '',
              rolCreador: usuario?.rol.name ?? 'doctora',
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Consulta guardada y enviada a caja para cobro'),
              backgroundColor: AppColors.success,
            ),
          );
          context.go('/pacientes/detalle');
        }
        return;
      }

      // ── Flujo simple (sin ítems a cobrar): solo historial ─────────────────
      final entrada = HistorialConsulta(
        id: '',
        tipo: 'consulta_medica',
        motivo: _areaCtrl.text.trim(),
        comentarios: '',
        diagnostico: '',
        tratamiento: '',
        medicamentos: const [],
        doctora: esDoctora ? (usuario?.nombre ?? '') : '',
        doctoraUid: esDoctora ? (usuario?.id ?? '') : '',
        enfermera: !esDoctora ? (usuario?.nombre ?? '') : '',
        enfermeraUid: !esDoctora ? (usuario?.id ?? '') : '',
        creadoPor: usuario?.id ?? '',
        rolCreador: usuario?.rol.name ?? '',
        proximaCita: proximaCita,
      );

      await service.agregarEntradaHistorial(pacienteId, entrada);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Consulta guardada'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/pacientes/detalle');
      }
    } catch (e) {
      if (mounted) {
        _showMsg('Error al guardar. Intente de nuevo.', error: true);
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _showMsg(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.danger : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedIndex: 0,
      onNavigate: (_) {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/pacientes/detalle'),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Nuevo Servicio',
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
              // ── Sección 1: Servicio Realizado ─────────────────────────
              _SectionCard(
                title: 'Servicio Realizado',
                children: [
                  TextFormField(
                    controller: _areaCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Área / Procedimiento *',
                        hintText:
                            'Ej: Blanqueamiento dental, Limpieza profunda'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notasCajaCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Notas para secretaria / caja (opcional)'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Sección 2+3: Procedimientos y Medicamentos (→ caja) ───
              _buildSeccionCobroCaja(),
              const SizedBox(height: 16),
              // ── Sección 4: Próxima cita ───────────────────────────────
              _buildSeccionProximaCita(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_hayItemsCobro
                          ? 'Guardar y enviar a caja'
                          : 'Guardar Servicio'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sección combinada: procedimientos + medicamentos de farmacia ─────────
  Widget _buildSeccionCobroCaja() {
    return _SectionCard(
      title: 'Procedimientos y Medicamentos (se cobran en caja)',
      children: [
        // ─ Subencabezado procedimientos ─────────────────────────────────────
        _SubHeader(icon: Icons.medical_services_outlined, label: 'Procedimientos'),
        const SizedBox(height: 8),
        if (_procedimientos.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Sin procedimientos. Agrega los que realizaste.',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: GoogleFonts.dmSans().fontFamily),
            ),
          )
        else
          ..._procedimientos.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            return _buildFilaProcedimiento(i, p);
          }),
        TextButton.icon(
          onPressed: _agregarProcedimiento,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Agregar procedimiento'),
        ),

        const Divider(height: 24),

        // ─ Subencabezado medicamentos farmacia ───────────────────────────────
        _SubHeader(icon: Icons.medication_outlined, label: 'Medicamentos de Farmacia'),
        const SizedBox(height: 8),
        if (_medsFarmacia.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Sin medicamentos. Agrega los que recetaste.',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontFamily: GoogleFonts.dmSans().fontFamily),
            ),
          )
        else
          ..._medsFarmacia.asMap().entries.map((entry) {
            final i = entry.key;
            final m = entry.value;
            return _buildFilaMedFarmacia(i, m);
          }),
        TextButton.icon(
          onPressed: _abrirBuscadorFarmacia,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Agregar medicamento'),
        ),

        // ─ Total combinado ───────────────────────────────────────────────────
        if (_hayItemsCobro) ...[
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Total estimado: Q ${_totalCobro.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFilaProcedimiento(int i, _ProcedimientoRow p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Procedimiento ${i + 1}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: AppColors.danger, size: 20),
                onPressed: () => _eliminarProcedimiento(i),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          RawAutocomplete<ServicioClinica>(
            textEditingController: p.nombreCtrl,
            focusNode: p.nombreFocus,
            optionsBuilder: (TextEditingValue value) {
              if (value.text.trim().isEmpty) {
                return const Iterable<ServicioClinica>.empty();
              }
              final q = value.text.toLowerCase();
              return _servicios.where((s) => s.nombre.toLowerCase().contains(q));
            },
            displayStringForOption: (s) => s.nombre,
            onSelected: (s) {
              p.nombreCtrl.text = s.nombre;
              p.servicioId = s.id;
            },
            fieldViewBuilder: (context, textCtrl, focusNode, onSubmit) {
              return TextFormField(
                controller: textCtrl,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'Nombre del procedimiento *',
                  hintText: 'Busca en servicios o escribe',
                  isDense: true,
                ),
                onChanged: (_) => p.servicioId = '',
                onFieldSubmitted: (_) => onSubmit(),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxHeight: 200, maxWidth: 320),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: options
                          .map((s) => ListTile(
                                dense: true,
                                title: Text(s.nombre),
                                onTap: () => onSelected(s),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: p.descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción adicional',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: p.precioCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Precio *',
                    prefixText: 'Q ',
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilaMedFarmacia(int i, Map<String, dynamic> m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.medication_outlined,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m['nombre'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  'x${m['cantidad']}  ·  Q ${(m['subtotal'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.danger, size: 20),
            onPressed: () => setState(() => _medsFarmacia.removeAt(i)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionProximaCita() {
    return _SectionCard(
      title: 'Próxima Cita',
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_month, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Agendar próxima cita',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary)),
            ),
            Switch(
              value: _mostrarProximaCita,
              activeThumbColor: AppColors.primary,
              onChanged: (v) => setState(() => _mostrarProximaCita = v),
            ),
          ],
        ),
        if (_mostrarProximaCita) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _proximaCitaCtrl,
            decoration: const InputDecoration(
              labelText: 'Fecha / Indicación',
              hintText: 'Ej: 2026-07-15 o "En 2 semanas"',
              isDense: true,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _abrirBuscadorFarmacia() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _BuscadorMedicamentoSheet(
        onSeleccionado: (farmacia.Medicamento med, int cantidad) {
          setState(() {
            // Si ya está en la lista, incrementa cantidad.
            final idx = _medsFarmacia
                .indexWhere((m) => m['medicamentoId'] == med.id);
            if (idx >= 0) {
              final nuevaCantidad =
                  (_medsFarmacia[idx]['cantidad'] as int) + cantidad;
              if (nuevaCantidad <= med.cantidad) {
                _medsFarmacia[idx] = {
                  ..._medsFarmacia[idx],
                  'cantidad': nuevaCantidad,
                  'subtotal': med.precioVenta * nuevaCantidad,
                };
              }
            } else {
              _medsFarmacia.add({
                'medicamentoId': med.id,
                'nombre': med.nombre,
                'presentacion': med.presentacion,
                'cantidad': cantidad,
                'precioUnitario': med.precioVenta,
                'subtotal': med.precioVenta * cantidad,
                'tipo': 'medicamento',
                'estante': med.estante,
                'stockDisponible': med.cantidad,
              });
            }
          });
        },
      ),
    );
  }
}

// ── Subencabezado visual dentro de la sección ───────────────────────────────

class _SubHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SubHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary)),
      ],
    );
  }
}

// ── Bottom sheet: buscador de medicamentos de farmacia ───────────────────────

class _BuscadorMedicamentoSheet extends StatefulWidget {
  final void Function(farmacia.Medicamento med, int cantidad) onSeleccionado;
  const _BuscadorMedicamentoSheet({required this.onSeleccionado});

  @override
  State<_BuscadorMedicamentoSheet> createState() =>
      _BuscadorMedicamentoSheetState();
}

class _BuscadorMedicamentoSheetState
    extends State<_BuscadorMedicamentoSheet> {
  final _ctrl = TextEditingController();
  List<farmacia.Medicamento> _resultados = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargar('');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _cargar(String query) async {
    setState(() => _cargando = true);
    try {
      final todos = await farmacia.FarmaciaService().getMedicamentos();
      final q = query.trim().toLowerCase();
      setState(() {
        _resultados = todos.where((m) {
          if (m.cantidad <= 0) return false;
          if (q.isEmpty) return true;
          return m.nombre.toLowerCase().contains(q) ||
              m.nombreGenerico.toLowerCase().contains(q) ||
              m.codigoBarras.contains(query.trim());
        }).toList();
        _cargando = false;
      });
    } catch (_) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollCtrl) => Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Text('Agregar Medicamento',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontFamily: GoogleFonts.dmSans().fontFamily)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o código de barras...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: Icon(Icons.barcode_reader),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _cargar,
              onSubmitted: _cargar,
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _resultados.isEmpty
                    ? const Center(
                        child: Text('Sin resultados o sin stock disponible'))
                    : ListView.builder(
                        controller: scrollCtrl,
                        itemCount: _resultados.length,
                        itemBuilder: (_, i) {
                          final med = _resultados[i];
                          return _ItemMed(
                            med: med,
                            onAdd: (cant) {
                              widget.onSeleccionado(med, cant);
                              Navigator.of(context).pop();
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

// Fila de medicamento dentro del bottom sheet (con stepper de cantidad).
class _ItemMed extends StatefulWidget {
  final farmacia.Medicamento med;
  final void Function(int cantidad) onAdd;
  const _ItemMed({required this.med, required this.onAdd});

  @override
  State<_ItemMed> createState() => _ItemMedState();
}

class _ItemMedState extends State<_ItemMed> {
  int _cantidad = 1;

  @override
  Widget build(BuildContext context) {
    final med = widget.med;
    return ListTile(
      leading: SizedBox(
        width: 48,
        height: 48,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: med.fotoUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: med.fotoUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => _iconMed(),
                )
              : _iconMed(),
        ),
      ),
      title: Text(med.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      subtitle: Text(
        '${med.presentacion.isNotEmpty ? '${med.presentacion} · ' : ''}'
        'Stock: ${med.cantidad}  ·  Estante: ${med.estante}',
        style: const TextStyle(fontSize: 11),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Q ${med.precioVenta.toStringAsFixed(2)}',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: 13),
          ),
          const SizedBox(width: 8),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed:
                _cantidad > 1 ? () => setState(() => _cantidad--) : null,
          ),
          Text('$_cantidad',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_circle_outline,
                size: 20, color: AppColors.primary),
            onPressed: _cantidad < med.cantidad
                ? () => setState(() => _cantidad++)
                : null,
          ),
          const SizedBox(width: 4),
          ElevatedButton(
            onPressed: () => widget.onAdd(_cantidad),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Agregar',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _iconMed() => Container(
        color: Colors.grey[100],
        child: const Icon(Icons.medication_outlined,
            color: Colors.grey, size: 28),
      );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(title,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFamily: GoogleFonts.dmSans().fontFamily)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

