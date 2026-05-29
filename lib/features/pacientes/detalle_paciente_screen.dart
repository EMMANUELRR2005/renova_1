import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/permisos.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../data/mock/mock_data.dart';
import '../../data/mock/providers.dart';
import '../../data/services/catalogo_service.dart';
import '../../features/auth/providers/auth_provider.dart';

class DetallePacienteScreen extends ConsumerWidget {
  const DetallePacienteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pacienteId = ref.watch(selectedPacienteIdProvider);
    final usuario = ref.watch(usuarioActivoProvider);
    final rol = usuario?.rol;

    if (pacienteId == null) {
      return AppShell(
        selectedIndex: 0,
        onNavigate: (_) {},
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No se seleccionó ningún paciente'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/pacientes'),
                child: const Text('Volver a la lista'),
              ),
            ],
          ),
        ),
      );
    }

    final pacienteAsync = ref.watch(pacienteByIdProvider(pacienteId));
    final historialAsync = ref.watch(historialPacienteProvider(pacienteId));

    return AppShell(
      selectedIndex: 0,
      onNavigate: (_) {},
      child: pacienteAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Error: $e')),
        data: (paciente) {
          if (paciente == null) {
            return const Center(child: Text('Paciente no encontrado'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/pacientes'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        paciente.nombreCompleto,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: GoogleFonts.dmSans().fontFamily,
                        ),
                      ),
                    ),
                    _EstadoBadge(estado: paciente.estado),
                    const SizedBox(width: 12),
                    if (Permisos.puedeCambiarEstadoPaciente(rol))
                      OutlinedButton(
                        onPressed: () => _mostrarDialogCambioEstado(
                            context, ref, paciente, usuario!),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: paciente.estado == 'activo'
                              ? AppColors.danger
                              : AppColors.success,
                        ),
                        child: Text(paciente.estado == 'activo'
                            ? 'Inactivar'
                            : 'Reactivar'),
                      ),
                    const SizedBox(width: 12),
                    if (Permisos.puedeEditarPacientes(rol))
                      ElevatedButton(
                        onPressed: () => context.go('/pacientes/editar'),
                        child: const Text('Editar'),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                // ── Info en 2 columnas ───────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _InfoCard(
                            title: 'Información Personal',
                            rows: [
                              _InfoRow('Nombre', paciente.nombreCompleto),
                              _InfoRow('Género', paciente.genero),
                              _InfoRow('Fecha de Nacimiento',
                                  '${paciente.fechaNacimiento} (${paciente.edad} años)'),
                              _InfoRow('Teléfono', paciente.telefono),
                              _InfoRow('Email',
                                  paciente.email.isEmpty ? '—' : paciente.email),
                              _InfoRow('Dirección', paciente.direccion),
                              _InfoRow('Ciudad', paciente.ciudad),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _InfoCard(
                            title: 'Identificación',
                            rows: [
                              _InfoRow('Tipo', paciente.tipoIdentificacion),
                              _InfoRow('Número', paciente.numeroIdentificacion),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _InfoCard(
                            title: 'Datos Médicos',
                            rows: [
                              _InfoRow(
                                  'Alergias',
                                  paciente.alergias.isEmpty
                                      ? 'Ninguna'
                                      : paciente.alergias),
                              _InfoRow(
                                  'Condiciones Preexistentes',
                                  paciente.condicionesPreexistentes.isEmpty
                                      ? 'Ninguna'
                                      : paciente.condicionesPreexistentes),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _InfoCard(
                            title: 'Contacto de Emergencia',
                            rows: [
                              _InfoRow('Nombre',
                                  paciente.contactoEmergencia.nombre.isEmpty
                                      ? '—'
                                      : paciente.contactoEmergencia.nombre),
                              _InfoRow('Teléfono',
                                  paciente.contactoEmergencia.telefono.isEmpty
                                      ? '—'
                                      : paciente.contactoEmergencia.telefono),
                              _InfoRow('Relación',
                                  paciente.contactoEmergencia.relacion.isEmpty
                                      ? '—'
                                      : paciente.contactoEmergencia.relacion),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _InfoCard(
                            title: 'Servicio y Clínica',
                            rows: [
                              _InfoRow('Servicio',
                                  paciente.servicio ?? '—'),
                              _InfoRow('Clínica',
                                  paciente.clinica ?? '—'),
                            ],
                          ),
                          if (paciente.estado == 'inactivo' &&
                              paciente.servicioRealizado != null) ...[
                            const SizedBox(height: 12),
                            _InfoCard(
                              title: 'Información de Inactivación',
                              rows: [
                                _InfoRow('Servicio Realizado',
                                    paciente.servicioRealizado ?? '—'),
                                _InfoRow('Inactivado por',
                                    paciente.nombreInactivador ?? '—'),
                                _InfoRow(
                                    'Fecha',
                                    paciente.fechaInactivacion != null
                                        ? '${paciente.fechaInactivacion!.day}/${paciente.fechaInactivacion!.month}/${paciente.fechaInactivacion!.year}'
                                        : '—'),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // ── Botones de acción historial ──────────────────────────
                Row(
                  children: [
                    Text(
                      'Historial Médico',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFamily: GoogleFonts.dmSans().fontFamily,
                      ),
                    ),
                    const Spacer(),
                    if (Permisos.puedeAgregarComentarios(rol))
                      OutlinedButton(
                        onPressed: () => context.go('/pacientes/comentario'),
                        child: const Text('+ Agregar Nota'),
                      ),
                    if (Permisos.puedeCrearConsultas(rol)) ...[
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => context.go('/pacientes/consulta'),
                        child: const Text('+ Nueva Consulta'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // ── Historial ────────────────────────────────────────────
                historialAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (historial) {
                    if (historial.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            'No hay registros en el historial',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontFamily: GoogleFonts.dmSans().fontFamily,
                            ),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: historial
                          .map((h) => _HistorialCard(entrada: h))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> rows;
  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              fontFamily: GoogleFonts.dmSans().fontFamily,
            ),
          ),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final String estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final activo = estado == 'activo';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: activo ? AppColors.successBg : AppColors.dangerBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: activo ? AppColors.success : AppColors.danger,
        ),
      ),
    );
  }
}

class _HistorialCard extends StatefulWidget {
  final HistorialConsulta entrada;
  const _HistorialCard({required this.entrada});

  @override
  State<_HistorialCard> createState() => _HistorialCardState();
}

class _HistorialCardState extends State<_HistorialCard> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.entrada;
    final color = _tipoColor(h.tipo);
    final fecha = h.fecha != null
        ? '${h.fecha!.day.toString().padLeft(2, '0')}/${h.fecha!.month.toString().padLeft(2, '0')}/${h.fecha!.year}'
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expandido = !_expandido),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _tipoLabel(h.tipo),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    fecha,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _preview(h),
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _expandido ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_expandido)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  if (h.motivo.isNotEmpty) _DetailRow('Motivo', h.motivo),
                  if (h.diagnostico.isNotEmpty)
                    _DetailRow('Diagnóstico', h.diagnostico),
                  if (h.tratamiento.isNotEmpty)
                    _DetailRow('Tratamiento', h.tratamiento),
                  if (h.comentarios.isNotEmpty)
                    _DetailRow('Comentarios', h.comentarios),
                  if (h.doctora.isNotEmpty) _DetailRow('Doctora', h.doctora),
                  if (h.medicamentos.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Medicamentos:',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    ...h.medicamentos.map((m) => Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 2),
                          child: Text(
                            '• ${m.nombre} — ${m.dosis} — ${m.frecuencia} — ${m.duracion} días',
                            style: const TextStyle(fontSize: 12),
                          ),
                        )),
                  ],
                  if (h.proximaCita != null && h.proximaCita!.isNotEmpty)
                    _DetailRow('Próxima cita', h.proximaCita!),
                  _DetailRow('Registrado por',
                      '${h.rolCreador.replaceAll('_', ' ')} (${h.creadoPor})'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _tipoColor(String tipo) {
    switch (tipo) {
      case 'consulta':
        return AppColors.primary;
      case 'nota_medica':
        return AppColors.clinicalGreen;
      case 'procedimiento':
        return AppColors.warning;
      default:
        return AppColors.neutral;
    }
  }

  String _tipoLabel(String tipo) {
    switch (tipo) {
      case 'consulta':
        return 'Consulta';
      case 'nota_medica':
        return 'Nota Médica';
      case 'procedimiento':
        return 'Procedimiento';
      default:
        return 'Comentario';
    }
  }

  String _preview(HistorialConsulta h) {
    if (h.motivo.isNotEmpty) return h.motivo;
    if (h.comentarios.isNotEmpty) return h.comentarios;
    if (h.diagnostico.isNotEmpty) return h.diagnostico;
    return '—';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ── Dialog para cambio de estado (Enfermera) ────────────────────────────────

void _mostrarDialogCambioEstado(
  BuildContext context,
  WidgetRef ref,
  Paciente paciente,
  Usuario usuario,
) {
  if (paciente.estado == 'activo') {
    _mostrarDialogInactivar(context, ref, paciente, usuario);
  } else {
    _mostrarDialogReactivar(context, ref, paciente, usuario);
  }
}

void _mostrarDialogInactivar(
  BuildContext context,
  WidgetRef ref,
  Paciente paciente,
  Usuario usuario,
) {
  showDialog(
    context: context,
    builder: (ctx) {
      return _InactivarPacienteDialog(
        paciente: paciente,
        usuario: usuario,
        onConfirmar: (servicioId, servicioNombre) async {
          await ref.read(pacienteServiceProvider).inactivarPaciente(
                pacienteId: paciente.id,
                servicioRealizado: servicioNombre,
                servicioRealizadoId: servicioId,
                enfermeraUid: usuario.id,
                nombreEnfermera: usuario.nombre,
              );
        },
      );
    },
  );
}

class _InactivarPacienteDialog extends StatefulWidget {
  final Paciente paciente;
  final Usuario usuario;
  final Future<void> Function(String servicioId, String servicioNombre) onConfirmar;

  const _InactivarPacienteDialog({
    required this.paciente,
    required this.usuario,
    required this.onConfirmar,
  });

  @override
  State<_InactivarPacienteDialog> createState() => _InactivarPacienteDialogState();
}

class _InactivarPacienteDialogState extends State<_InactivarPacienteDialog> {
  String? _servicioId;
  String? _servicioNombre;
  List<ServicioClinica> _servicios = [];
  bool _cargando = true;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarServicios();
  }

  Future<void> _cargarServicios() async {
    try {
      final servicios = await CatalogoService().getServicios();
      if (mounted) {
        setState(() {
          _servicios = servicios;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _cargando = false;
        });
      }
    }
  }

  Future<void> _confirmar() async {
    if (_servicioId == null || _servicioNombre == null) return;

    setState(() => _guardando = true);
    try {
      await widget.onConfirmar(_servicioId!, _servicioNombre!);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paciente inactivado'),
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Inactivar Paciente'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Confirmar cambio a Inactivo para ${widget.paciente.nombreCompleto}?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Servicio realizado *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            if (_cargando)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Text('Error: $_error', style: const TextStyle(color: AppColors.danger))
            else if (_servicios.isEmpty)
              const Text(
                'No hay servicios disponibles',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              DropdownButtonFormField<String>(
                value: _servicioId,
                decoration: const InputDecoration(
                  hintText: 'Selecciona el servicio realizado',
                  border: OutlineInputBorder(),
                ),
                items: _servicios
                    .map((s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.nombre),
                        ))
                    .toList(),
                onChanged: (v) {
                  final servicio = _servicios.firstWhere((s) => s.id == v);
                  setState(() {
                    _servicioId = v;
                    _servicioNombre = servicio.nombre;
                  });
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: (_servicioId == null || _guardando) ? null : _confirmar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
          ),
          child: _guardando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Confirmar Inactivación'),
        ),
      ],
    );
  }
}

void _mostrarDialogReactivar(
  BuildContext context,
  WidgetRef ref,
  Paciente paciente,
  Usuario usuario,
) {
  showDialog(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Reactivar Paciente'),
        content: Text(
          '¿Confirmar reactivación de ${paciente.nombreCompleto}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(pacienteServiceProvider).reactivarPaciente(
                      pacienteId: paciente.id,
                      enfermeraUid: usuario.id,
                    );
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Paciente reactivado'),
                      backgroundColor: AppColors.success,
                    ),
                  );
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
            ),
            child: const Text('Confirmar Reactivación'),
          ),
        ],
      );
    },
  );
}
