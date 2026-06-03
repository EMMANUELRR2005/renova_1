import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/permisos.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../data/mock/mock_data.dart';
import '../../data/mock/providers.dart';
import '../../features/auth/providers/auth_provider.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(usuarioActivoProvider);
    final rol = usuario?.rol;
    final filtro = ref.watch(filtroCitasProvider);

    // Si es doctora, ver solo sus citas asignadas
    final citasAsync = Permisos.puedeVerCitasAsignadas(rol)
        ? ref.watch(citasDoctoraStreamProvider)
        : ref.watch(citasMedicasStreamProvider);

    return AppShell(
      selectedIndex: _getSidebarIndex(rol),
      onNavigate: (index) {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Permisos.puedeVerCitasAsignadas(rol)
                      ? 'Mis Citas Asignadas'
                      : 'Gestión de Citas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: GoogleFonts.dmSans().fontFamily,
                  ),
                ),
                if (Permisos.puedeCrearCitas(rol)) ...[
                  OutlinedButton.icon(
                    onPressed: () => context.go('/citas/calendario'),
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: const Text('Vista Agenda'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => mostrarFormularioNuevaCita(context, ref),
                    child: const Text('+ Nueva Cita'),
                  ),
                ] else
                  OutlinedButton.icon(
                    onPressed: () => context.go('/citas/calendario'),
                    icon: const Icon(Icons.calendar_month, size: 18),
                    label: const Text('Vista Agenda'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // ── Filtros (solo secretaria/admin) ────────────────────────────
            if (!Permisos.puedeVerCitasAsignadas(rol))
              Row(
                children: [
                  _FiltroChip(
                    label: 'Hoy',
                    activo: filtro == 'hoy',
                    onTap: () =>
                        ref.read(filtroCitasProvider.notifier).state = 'hoy',
                  ),
                  const SizedBox(width: 8),
                  _FiltroChip(
                    label: 'Esta Semana',
                    activo: filtro == 'semana',
                    onTap: () =>
                        ref.read(filtroCitasProvider.notifier).state = 'semana',
                  ),
                  const SizedBox(width: 8),
                  _FiltroChip(
                    label: 'Todas',
                    activo: filtro == 'todas',
                    onTap: () =>
                        ref.read(filtroCitasProvider.notifier).state = 'todas',
                  ),
                ],
              ),
            const SizedBox(height: 16),
            // ── Tabla de citas ─────────────────────────────────────────────
            citasAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Error: $e',
                    style: const TextStyle(color: AppColors.danger)),
              ),
              data: (citas) {
                if (citas.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Text('📅',
                              style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            'No hay citas programadas',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontFamily: GoogleFonts.dmSans().fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return _buildTablaCitas(context, ref, citas, rol);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablaCitas(BuildContext context, WidgetRef ref,
      List<CitaMedica> citas, RolUsuario? rol) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Encabezado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.bgGeneral,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                _HeaderCell('Fecha/Hora', flex: 2),
                _HeaderCell('Paciente', flex: 3),
                _HeaderCell('Servicio', flex: 2),
                _HeaderCell('Clínica', flex: 2),
                _HeaderCell('Doctora', flex: 2),
                _HeaderCell('Estado', flex: 1),
                if (Permisos.puedeGestionarCitas(rol))
                  _HeaderCell('Acciones', flex: 2),
              ],
            ),
          ),
          // Filas
          ...citas.asMap().entries.map((entry) {
            final i = entry.key;
            final cita = entry.value;
            return _buildFilaCita(context, ref, cita, i, citas.length, rol);
          }),
        ],
      ),
    );
  }

  Widget _buildFilaCita(BuildContext context, WidgetRef ref, CitaMedica cita,
      int index, int total, RolUsuario? rol) {
    final fecha =
        '${cita.fecha.day.toString().padLeft(2, '0')}/${cita.fecha.month.toString().padLeft(2, '0')}/${cita.fecha.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.white : AppColors.bgGeneral.withValues(alpha: 0.4),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
        borderRadius: index == total - 1
            ? const BorderRadius.vertical(bottom: Radius.circular(10))
            : BorderRadius.zero,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fecha, style: const TextStyle(fontSize: 12)),
                Text(cita.hora,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cita.nombrePaciente,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500)),
                if (cita.motivo.isNotEmpty)
                  Text(cita.motivo,
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(cita.servicio, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text(cita.clinica, style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text(cita.doctora ?? '—',
                style: const TextStyle(fontSize: 12)),
          ),
          Expanded(
            flex: 1,
            child: _EstadoBadge(estado: cita.estado),
          ),
          if (Permisos.puedeGestionarCitas(rol))
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  if (cita.estado == 'pendiente') ...[
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline,
                          color: AppColors.success, size: 18),
                      tooltip: 'Confirmar',
                      onPressed: () => _confirmarCita(context, ref, cita),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined,
                          color: AppColors.danger, size: 18),
                      tooltip: 'Cancelar',
                      onPressed: () =>
                          _mostrarDialogCancelar(context, ref, cita),
                    ),
                  ],
                  if (cita.estado == 'confirmada')
                    IconButton(
                      icon: const Icon(Icons.check_circle,
                          color: AppColors.clinicalGreen, size: 18),
                      tooltip: 'Completar',
                      onPressed: () => _completarCita(context, ref, cita),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _confirmarCita(
      BuildContext context, WidgetRef ref, CitaMedica cita) async {
    try {
      await ref.read(citaServiceProvider).confirmarCitaMedica(cita.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cita confirmada'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _completarCita(
      BuildContext context, WidgetRef ref, CitaMedica cita) async {
    try {
      await ref.read(citaServiceProvider).completarCitaMedica(cita.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cita completada'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _mostrarDialogCancelar(
      BuildContext context, WidgetRef ref, CitaMedica cita) {
    final motivoController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cancelar Cita'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('¿Cancelar la cita de ${cita.nombrePaciente}?'),
              const SizedBox(height: 16),
              TextField(
                controller: motivoController,
                decoration: const InputDecoration(
                  labelText: 'Motivo de cancelación',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Volver'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(citaServiceProvider).cancelarCitaMedica(
                        cita.id,
                        motivoController.text.trim(),
                      );
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Cita cancelada'),
                          backgroundColor: AppColors.warning),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: AppColors.danger),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('Cancelar Cita'),
            ),
          ],
        );
      },
    );
  }

  int _getSidebarIndex(RolUsuario? rol) {
    switch (rol) {
      case RolUsuario.administradora:
        return 2;
      case RolUsuario.enfermera:
        return 1;
      case RolUsuario.secretaria_recepcion:
        return 1;
      case RolUsuario.doctora:
        return 1;
      default:
        return 0;
    }
  }
}

// ── Formulario Nueva Cita ───────────────────────────────────────────────────

void mostrarFormularioNuevaCita(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: _FormularioNuevaCita(
          onClose: () => Navigator.of(ctx).pop(),
        ),
      ),
    ),
  );
}

class _FormularioNuevaCita extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const _FormularioNuevaCita({required this.onClose});

  @override
  ConsumerState<_FormularioNuevaCita> createState() =>
      _FormularioNuevaCitaState();
}

class _FormularioNuevaCitaState extends ConsumerState<_FormularioNuevaCita> {
  final _formKey = GlobalKey<FormState>();
  bool _guardando = false;

  // Paciente seleccionado
  Paciente? _pacienteSeleccionado;
  final _buscadorCtrl = TextEditingController();
  List<Paciente> _resultadosBusqueda = [];

  // Campos del formulario
  DateTime _fecha = DateTime.now();
  TimeOfDay _hora = TimeOfDay.now();
  String? _servicioId;
  String? _servicioNombre;
  String? _clinicaId;
  String? _clinicaNombre;
  String? _doctoraId;
  String? _doctoraNombre;
  final _motivoCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  @override
  void dispose() {
    _buscadorCtrl.dispose();
    _motivoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _buscarPacientes(String query) async {
    if (query.length < 2) {
      setState(() => _resultadosBusqueda = []);
      return;
    }
    final resultados =
        await ref.read(pacienteServiceProvider).buscarPacientesActivos(query);
    setState(() => _resultadosBusqueda = resultados);
  }

  void _seleccionarPaciente(Paciente paciente) {
    setState(() {
      _pacienteSeleccionado = paciente;
      _buscadorCtrl.text = paciente.nombreCompleto;
      _resultadosBusqueda = [];
      // Pre-llenar servicio y clínica del paciente
      if (paciente.servicioId != null) {
        _servicioId = paciente.servicioId;
        _servicioNombre = paciente.servicio;
      }
      if (paciente.clinicaId != null) {
        _clinicaId = paciente.clinicaId;
        _clinicaNombre = paciente.clinica;
      }
    });
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _fecha = picked);
    }
  }

  Future<void> _seleccionarHora() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _hora,
    );
    if (picked != null) {
      setState(() => _hora = picked);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pacienteSeleccionado == null) {
      _showError('Selecciona un paciente');
      return;
    }
    if (_servicioId == null) {
      _showError('Selecciona un servicio');
      return;
    }
    if (_clinicaId == null) {
      _showError('Selecciona una clínica');
      return;
    }

    setState(() => _guardando = true);

    try {
      final usuario = ref.read(usuarioActivoProvider);
      final citaService = ref.read(citaServiceProvider);

      final fechaHora = DateTime(
        _fecha.year,
        _fecha.month,
        _fecha.day,
        _hora.hour,
        _hora.minute,
      );

      final cita = CitaMedica(
        id: '',
        pacienteId: _pacienteSeleccionado!.id,
        nombrePaciente: _pacienteSeleccionado!.nombreCompleto,
        servicio: _servicioNombre!,
        servicioId: _servicioId!,
        clinica: _clinicaNombre!,
        clinicaId: _clinicaId!,
        doctora: _doctoraNombre,
        doctoraId: _doctoraId,
        fecha: fechaHora,
        hora: '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}',
        motivo: _motivoCtrl.text.trim(),
        notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
        estado: 'pendiente',
        creadaPor: usuario?.id ?? '',
      );

      await citaService.crearCitaMedica(cita);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Cita creada exitosamente'),
              backgroundColor: AppColors.success),
        );
        widget.onClose();
      }
    } catch (e) {
      _showError('Error al crear la cita: $e');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final serviciosAsync = ref.watch(serviciosStreamProvider);
    final clinicasAsync = ref.watch(clinicasStreamProvider);
    final doctorasAsync = ref.watch(doctorasStreamProvider);

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nueva Cita',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: GoogleFonts.dmSans().fontFamily,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onClose,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Buscador de pacientes
            const Text('Paciente *',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextField(
              controller: _buscadorCtrl,
              decoration: const InputDecoration(
                hintText: 'Buscar paciente por nombre...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _buscarPacientes,
            ),
            if (_resultadosBusqueda.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _resultadosBusqueda.length,
                  itemBuilder: (ctx, i) {
                    final p = _resultadosBusqueda[i];
                    return ListTile(
                      dense: true,
                      title: Text(p.nombreCompleto),
                      subtitle: Text(p.telefono),
                      onTap: () => _seleccionarPaciente(p),
                    );
                  },
                ),
              ),
            if (_pacienteSeleccionado != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: 8),
                    Text('Paciente: ${_pacienteSeleccionado!.nombreCompleto}',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // Fecha y Hora
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Fecha *',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _seleccionarFecha,
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
                              Text(
                                '${_fecha.day.toString().padLeft(2, '0')}/${_fecha.month.toString().padLeft(2, '0')}/${_fecha.year}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Hora *',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _seleccionarHora,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                '${_hora.hour.toString().padLeft(2, '0')}:${_hora.minute.toString().padLeft(2, '0')}',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Servicio y Clínica
            Row(
              children: [
                Expanded(
                  child: serviciosAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                    data: (servicios) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Servicio *',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: servicios.any((s) => s.id == _servicioId)
                                ? _servicioId
                                : null,
                            decoration: const InputDecoration(
                              hintText: 'Seleccionar',
                            ),
                            items: servicios
                                .map((s) => DropdownMenuItem(
                                      value: s.id,
                                      child: Text(s.nombre),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              final s = servicios.firstWhere((x) => x.id == v);
                              setState(() {
                                _servicioId = v;
                                _servicioNombre = s.nombre;
                              });
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: clinicasAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
                    data: (clinicas) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Clínica *',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: clinicas.any((c) => c.id == _clinicaId)
                                ? _clinicaId
                                : null,
                            decoration: const InputDecoration(
                              hintText: 'Seleccionar',
                            ),
                            items: clinicas
                                .map((c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.nombre),
                                    ))
                                .toList(),
                            onChanged: (v) {
                              final c = clinicas.firstWhere((x) => x.id == v);
                              setState(() {
                                _clinicaId = v;
                                _clinicaNombre = c.nombre;
                              });
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Doctora
            doctorasAsync.when(
              loading: () => const SizedBox(),
              error: (e, _) => Text('Error: $e'),
              data: (doctoras) {
                if (doctoras.isEmpty) return const SizedBox();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Doctora Asignada',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: doctoras.any((d) => d.id == _doctoraId)
                          ? _doctoraId
                          : null,
                      decoration: const InputDecoration(
                        hintText: 'Seleccionar (opcional)',
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Sin asignar')),
                        ...doctoras.map((d) => DropdownMenuItem(
                              value: d.id,
                              child: Text(d.nombre),
                            )),
                      ],
                      onChanged: (v) {
                        if (v == null) {
                          setState(() {
                            _doctoraId = null;
                            _doctoraNombre = null;
                          });
                        } else {
                          final d = doctoras.firstWhere((x) => x.id == v);
                          setState(() {
                            _doctoraId = v;
                            _doctoraNombre = d.nombre;
                          });
                        }
                      },
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Motivo
            const Text('Motivo de la cita *',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _motivoCtrl,
              decoration: const InputDecoration(
                hintText: 'Describe el motivo de la cita...',
              ),
              maxLines: 2,
              validator: (v) =>
                  v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),

            // Notas
            const Text('Notas adicionales',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _notasCtrl,
              decoration: const InputDecoration(
                hintText: 'Notas opcionales...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Botones
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _guardando ? null : widget.onClose,
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Crear Cita'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ──────────────────────────────────────────────────────

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  const _HeaderCell(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFamily: GoogleFonts.dmSans().fontFamily,
        ),
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final String estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bgColor;
    String label;

    switch (estado) {
      case 'confirmada':
        color = AppColors.success;
        bgColor = AppColors.successBg;
        label = 'Confirmada';
        break;
      case 'cancelada':
        color = AppColors.danger;
        bgColor = AppColors.dangerBg;
        label = 'Cancelada';
        break;
      case 'completada':
        color = AppColors.clinicalGreen;
        bgColor = AppColors.clinicalGreenBg;
        label = 'Completada';
        break;
      case 'pendiente':
      default:
        color = AppColors.warning;
        bgColor = AppColors.warningBg;
        label = 'Pendiente';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
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

class _FiltroChip extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: activo
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.bgGeneral,
          border:
              Border.all(color: activo ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: activo ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
