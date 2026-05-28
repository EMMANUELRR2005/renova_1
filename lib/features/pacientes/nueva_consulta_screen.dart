import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../data/mock/mock_data.dart';
import '../../data/mock/providers.dart';
import '../../features/auth/providers/auth_provider.dart';

class NuevaConsultaScreen extends ConsumerStatefulWidget {
  const NuevaConsultaScreen({super.key});

  @override
  ConsumerState<NuevaConsultaScreen> createState() =>
      _NuevaConsultaScreenState();
}

class _MedicamentoRow {
  final nombreCtrl = TextEditingController();
  final dosisCtrl = TextEditingController();
  final frecuenciaCtrl = TextEditingController();
  final duracionCtrl = TextEditingController();

  void dispose() {
    nombreCtrl.dispose();
    dosisCtrl.dispose();
    frecuenciaCtrl.dispose();
    duracionCtrl.dispose();
  }

  bool get vacio =>
      nombreCtrl.text.trim().isEmpty &&
      dosisCtrl.text.trim().isEmpty &&
      frecuenciaCtrl.text.trim().isEmpty &&
      duracionCtrl.text.trim().isEmpty;

  Medicamento toMedicamento() => Medicamento(
        nombre: nombreCtrl.text.trim(),
        dosis: dosisCtrl.text.trim(),
        frecuencia: frecuenciaCtrl.text.trim(),
        duracion: duracionCtrl.text.trim(),
      );
}

class _NuevaConsultaScreenState extends ConsumerState<NuevaConsultaScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _guardando = false;

  final _motivoCtrl = TextEditingController();
  final _sintomasCtrl = TextEditingController();
  final _diagnosticoCtrl = TextEditingController();
  final _tratamientoCtrl = TextEditingController();
  final _comentariosCtrl = TextEditingController();
  final _proximaCitaCtrl = TextEditingController();

  final List<_MedicamentoRow> _medicamentos = [];

  @override
  void dispose() {
    for (final c in [
      _motivoCtrl, _sintomasCtrl, _diagnosticoCtrl,
      _tratamientoCtrl, _comentariosCtrl, _proximaCitaCtrl,
    ]) { c.dispose(); }
    for (final m in _medicamentos) { m.dispose(); }
    super.dispose();
  }

  void _agregarMedicamento() {
    setState(() => _medicamentos.add(_MedicamentoRow()));
  }

  void _eliminarMedicamento(int index) {
    _medicamentos[index].dispose();
    setState(() => _medicamentos.removeAt(index));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    // Validar medicamentos no vacíos a medias
    for (final m in _medicamentos) {
      if (!m.vacio && m.nombreCtrl.text.trim().isEmpty) {
        _showMsg('Completa el nombre del medicamento', error: true);
        return;
      }
    }

    setState(() => _guardando = true);

    try {
      final usuario = ref.read(usuarioActivoProvider);
      final service = ref.read(pacienteServiceProvider);
      final pacienteId = ref.read(selectedPacienteIdProvider)!;

      final meds = _medicamentos
          .where((m) => !m.vacio)
          .map((m) => m.toMedicamento())
          .toList();

      final esDoctora = usuario?.rol == RolUsuario.doctora;

      final entrada = HistorialConsulta(
        id: '',
        tipo: 'consulta',
        motivo: _motivoCtrl.text.trim(),
        comentarios: '${_sintomasCtrl.text.trim()}\n${_comentariosCtrl.text.trim()}'.trim(),
        diagnostico: _diagnosticoCtrl.text.trim(),
        tratamiento: _tratamientoCtrl.text.trim(),
        medicamentos: meds,
        doctora: esDoctora ? (usuario?.nombre ?? '') : '',
        doctoraUid: esDoctora ? (usuario?.id ?? '') : '',
        enfermera: !esDoctora ? (usuario?.nombre ?? '') : '',
        enfermeraUid: !esDoctora ? (usuario?.id ?? '') : '',
        creadoPor: usuario?.id ?? '',
        rolCreador: usuario?.rol.name ?? '',
        proximaCita: _proximaCitaCtrl.text.trim().isEmpty
            ? null
            : _proximaCitaCtrl.text.trim(),
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
                    'Nueva Consulta Médica',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontFamily: GoogleFonts.dmSans().fontFamily,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // ── Consulta ──────────────────────────────────────────────
              _SectionCard(
                title: 'Datos de la Consulta',
                children: [
                  TextFormField(
                    controller: _motivoCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Motivo de la consulta *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _sintomasCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: 'Síntomas observados'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _diagnosticoCtrl,
                    maxLines: 2,
                    decoration:
                        const InputDecoration(labelText: 'Diagnóstico *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tratamientoCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                        labelText: 'Tratamiento prescrito *'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Medicamentos ──────────────────────────────────────────
              _SectionCard(
                title: 'Medicamentos',
                children: [
                  if (_medicamentos.isEmpty)
                    Text(
                      'No hay medicamentos agregados',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontFamily: GoogleFonts.dmSans().fontFamily),
                    )
                  else ...[
                    // Encabezados de columnas
                    Row(
                      children: [
                        _MedHeader('Medicamento', flex: 3),
                        _MedHeader('Dosis', flex: 2),
                        _MedHeader('Frecuencia', flex: 2),
                        _MedHeader('Días', flex: 2),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ..._medicamentos.asMap().entries.map((entry) {
                      final i = entry.key;
                      final m = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: m.nombreCtrl,
                                decoration: const InputDecoration(
                                    hintText: 'Nombre',
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: m.dosisCtrl,
                                decoration: const InputDecoration(
                                    hintText: 'Dosis',
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: m.frecuenciaCtrl,
                                decoration: const InputDecoration(
                                    hintText: 'Frecuencia',
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8)),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: m.duracionCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    hintText: 'Días',
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 8)),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: AppColors.danger, size: 20),
                              onPressed: () => _eliminarMedicamento(i),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _agregarMedicamento,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Agregar medicamento'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ── Notas adicionales ─────────────────────────────────────
              _SectionCard(
                title: 'Notas Adicionales',
                children: [
                  TextFormField(
                    controller: _comentariosCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                        labelText: 'Comentarios adicionales'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _proximaCitaCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Próxima cita (opcional)',
                      hintText: 'Ej: 2026-06-15 o "En 2 semanas"',
                    ),
                  ),
                ],
              ),
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
                      : const Text('Guardar Consulta'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

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

class _MedHeader extends StatelessWidget {
  final String label;
  final int flex;
  const _MedHeader(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(label,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary)),
    );
  }
}
