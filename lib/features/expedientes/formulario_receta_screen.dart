import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/mock/mock_data.dart' hide Medicamento;
import '../../data/services/farmacia_service.dart';
import '../../data/services/receta_service.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'receta_pdf.dart';

/// Abre el formulario de nueva receta para [paciente].
void mostrarFormularioReceta(BuildContext context, Paciente paciente) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _FormularioRecetaDialog(paciente: paciente),
  );
}

/// Línea de medicamento dentro del formulario de receta.
class _LineaMed {
  final TextEditingController nombre = TextEditingController();
  final TextEditingController dosis = TextEditingController();
  final TextEditingController frecuencia = TextEditingController();
  final TextEditingController duracion = TextEditingController();
  final TextEditingController instrucciones = TextEditingController();

  void dispose() {
    nombre.dispose();
    dosis.dispose();
    frecuencia.dispose();
    duracion.dispose();
    instrucciones.dispose();
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre.text.trim(),
        'dosis': dosis.text.trim(),
        'frecuencia': frecuencia.text.trim(),
        'duracion': duracion.text.trim(),
        'instrucciones': instrucciones.text.trim(),
      };
}

class _FormularioRecetaDialog extends ConsumerStatefulWidget {
  final Paciente paciente;
  const _FormularioRecetaDialog({required this.paciente});

  @override
  ConsumerState<_FormularioRecetaDialog> createState() =>
      _FormularioRecetaDialogState();
}

class _FormularioRecetaDialogState
    extends ConsumerState<_FormularioRecetaDialog> {
  final _diagnosticoCtrl = TextEditingController();
  final _indicacionesCtrl = TextEditingController();
  final List<_LineaMed> _medicamentos = [_LineaMed()];
  DateTime? _proximaCita;
  bool _guardando = false;

  List<Medicamento> _inventario = [];

  @override
  void initState() {
    super.initState();
    _cargarInventario();
  }

  Future<void> _cargarInventario() async {
    try {
      final meds = await FarmaciaService().getMedicamentos();
      if (mounted) setState(() => _inventario = meds);
    } catch (_) {
      // El buscador simplemente no sugerirá nada.
    }
  }

  @override
  void dispose() {
    _diagnosticoCtrl.dispose();
    _indicacionesCtrl.dispose();
    for (final m in _medicamentos) {
      m.dispose();
    }
    super.dispose();
  }

  void _agregarMedicamento() {
    setState(() => _medicamentos.add(_LineaMed()));
  }

  void _quitarMedicamento(int index) {
    if (_medicamentos.length > 1) {
      setState(() {
        _medicamentos[index].dispose();
        _medicamentos.removeAt(index);
      });
    }
  }

  Future<void> _seleccionarProximaCita() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _proximaCita ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _proximaCita = picked);
  }

  Future<void> _generar() async {
    final medsValidos = _medicamentos
        .where((m) => m.nombre.text.trim().isNotEmpty)
        .toList();

    if (medsValidos.isEmpty) {
      _error('Agrega al menos un medicamento con nombre');
      return;
    }

    setState(() => _guardando = true);
    try {
      final usuario = ref.read(usuarioActivoProvider);
      final service = RecetaService();
      final numero = await service.generarNumeroReceta();
      final medicamentosMap =
          medsValidos.map((m) => m.toMap()).toList();
      final proximaStr = _proximaCita != null
          ? DateFormat('dd/MM/yyyy').format(_proximaCita!)
          : null;

      await service.guardarReceta(
        pacienteId: widget.paciente.id,
        nombrePaciente: widget.paciente.nombreCompleto,
        numeroReceta: numero,
        diagnostico: _diagnosticoCtrl.text.trim(),
        medicamentos: medicamentosMap,
        indicaciones: _indicacionesCtrl.text.trim(),
        proximaCita: proximaStr,
        doctoraUid: usuario?.id ?? '',
        nombreDoctora: usuario?.nombre ?? '',
      );

      await _mostrarPdf(numero, medicamentosMap, proximaStr, usuario?.nombre ?? '');

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Receta $numero generada y guardada en el historial'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        _error('Error al generar la receta: $e');
      }
    }
  }

  Future<void> _mostrarPdf(
    String numero,
    List<Map<String, dynamic>> medicamentos,
    String? proximaStr,
    String nombreDoctora,
  ) async {
    await RecetaPDFHelper.generar(
      paciente: widget.paciente,
      numeroReceta: numero,
      diagnostico: _diagnosticoCtrl.text.trim(),
      medicamentos: medicamentos,
      indicaciones: _indicacionesCtrl.text.trim(),
      proximaCita: proximaStr,
      nombreDoctora: nombreDoctora,
    );
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.paciente;
    return Dialog(
      child: Container(
        width: 720,
        constraints: const BoxConstraints(maxHeight: 760),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Nueva Receta Médica',
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
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Datos del paciente (auto)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.nombreCompleto,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(
                            'Edad: ${p.edad} años · '
                            '${p.tipoIdentificacion}: ${p.numeroIdentificacion.isEmpty ? '—' : p.numeroIdentificacion}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _label('Diagnóstico'),
                    TextField(
                      controller: _diagnosticoCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Diagnóstico del paciente...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        _label('Medicamentos'),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _agregarMedicamento,
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text('Agregar medicamento'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._medicamentos.asMap().entries.map(
                        (e) => _buildMedCard(e.key, e.value)),

                    const SizedBox(height: 16),
                    _label('Indicaciones generales'),
                    TextField(
                      controller: _indicacionesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Reposo, hidratación, etc...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label('Próxima cita (opcional)'),
                    InkWell(
                      onTap: _seleccionarProximaCita,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(_proximaCita == null
                                ? 'Sin próxima cita'
                                : DateFormat('dd/MM/yyyy').format(_proximaCita!)),
                            if (_proximaCita != null) ...[
                              const Spacer(),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () =>
                                    setState(() => _proximaCita = null),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _guardando ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _guardando ? null : _generar,
                  icon: _guardando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.picture_as_pdf, size: 18),
                  label: Text(_guardando ? 'Generando...' : 'Generar Receta'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedCard(int index, _LineaMed med) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Medicamento ${index + 1}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                if (_medicamentos.length > 1)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.danger, size: 20),
                    onPressed: () => _quitarMedicamento(index),
                  ),
              ],
            ),
            // Buscador conectado al inventario
            Autocomplete<Medicamento>(
              optionsBuilder: (value) {
                final q = value.text.trim().toLowerCase();
                if (q.isEmpty) return const Iterable<Medicamento>.empty();
                return _inventario.where((m) =>
                    m.nombre.toLowerCase().contains(q) ||
                    m.nombreGenerico.toLowerCase().contains(q));
              },
              displayStringForOption: (m) => m.nombre,
              fieldViewBuilder:
                  (context, controller, focusNode, onSubmit) {
                // Mantener sincronizado el controller del Autocomplete con la línea.
                controller.text = med.nombre.text;
                controller.selection = TextSelection.collapsed(
                    offset: controller.text.length);
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del medicamento *',
                    hintText: 'Buscar en inventario o escribir...',
                    prefixIcon: Icon(Icons.medication, size: 18),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => med.nombre.text = v,
                );
              },
              onSelected: (m) {
                setState(() {
                  med.nombre.text = m.nombre;
                  if (med.dosis.text.isEmpty && m.presentacion.isNotEmpty) {
                    med.dosis.text = m.presentacion;
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _campo('Dosis', med.dosis, 'Ej: 500mg'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _campo('Frecuencia', med.frecuencia, 'Ej: cada 8h'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _campo('Duración', med.duracion, 'Ej: 7 días'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _campo('Instrucciones especiales (opcional)', med.instrucciones,
                'Con alimentos, etc.'),
          ],
        ),
      ),
    );
  }

  Widget _campo(String label, TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary)),
      );
}

/// Pequeño helper para invocar el PDF de receta a partir de un [Paciente].
class RecetaPDFHelper {
  static Future<void> generar({
    required Paciente paciente,
    required String numeroReceta,
    required String diagnostico,
    required List<Map<String, dynamic>> medicamentos,
    required String indicaciones,
    String? proximaCita,
    required String nombreDoctora,
  }) async {
    await RecetaPDF.generarYMostrar(
      nombrePaciente: paciente.nombreCompleto,
      edadPaciente: paciente.edad,
      identificacionPaciente: paciente.numeroIdentificacion.isEmpty
          ? '—'
          : paciente.numeroIdentificacion,
      nombreDoctora: nombreDoctora,
      diagnostico: diagnostico,
      medicamentos: medicamentos,
      indicaciones: indicaciones,
      proximaCita: proximaCita,
      numeroReceta: numeroReceta,
    );
  }
}
