import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/auth/permisos.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../data/mock/mock_data.dart';
import '../../data/mock/providers.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'appointments_screen.dart' show mostrarFormularioNuevaCita;

const _colorDorado = Color(0xFFC9A96E);

/// Agenda visual de citas: calendario mensual con vistas Mes / Semana / Día.
class CalendarioCitasScreen extends ConsumerStatefulWidget {
  const CalendarioCitasScreen({super.key});

  @override
  ConsumerState<CalendarioCitasScreen> createState() =>
      _CalendarioCitasScreenState();
}

enum _Vista { mes, semana, dia }

class _CalendarioCitasScreenState extends ConsumerState<CalendarioCitasScreen> {
  _Vista _vista = _Vista.mes;
  DateTime _diaSeleccionado = DateTime.now();
  DateTime _diaFocused = DateTime.now();

  DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Agrupa todas las citas por día (clave normalizada a medianoche).
  Map<DateTime, List<CitaMedica>> _agrupar(List<CitaMedica> citas) {
    final mapa = <DateTime, List<CitaMedica>>{};
    for (final c in citas) {
      final key = _soloFecha(c.fecha);
      mapa.putIfAbsent(key, () => []).add(c);
    }
    for (final lista in mapa.values) {
      lista.sort((a, b) => a.hora.compareTo(b.hora));
    }
    return mapa;
  }

  List<CitaMedica> _citasDe(
      Map<DateTime, List<CitaMedica>> mapa, DateTime dia) {
    return mapa[_soloFecha(dia)] ?? [];
  }

  int _sidebarIndex(RolUsuario? rol) {
    switch (rol) {
      case RolUsuario.administradora:
        return 4;
      case RolUsuario.enfermera:
        return 2;
      case RolUsuario.secretaria_recepcion:
        return 3;
      case RolUsuario.doctora:
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(usuarioActivoProvider);
    final rol = usuario?.rol;
    final citasAsync = ref.watch(todasCitasMedicasStreamProvider);

    return AppShell(
      selectedIndex: _sidebarIndex(rol),
      onNavigate: (_) {},
      floatingActionButton: Permisos.puedeCrearCitas(rol)
          ? FloatingActionButton.extended(
              onPressed: () => mostrarFormularioNuevaCita(context, ref),
              backgroundColor: AppColors.primaryDark,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nueva Cita',
                  style: TextStyle(color: Colors.white)),
            )
          : null,
      child: citasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.danger)),
        ),
        data: (citas) {
          final mapa = _agrupar(citas);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, rol),
                const SizedBox(height: 16),
                _buildSelectorVista(),
                const SizedBox(height: 16),
                if (_vista == _Vista.mes) _buildVistaMes(mapa),
                if (_vista == _Vista.semana) _buildVistaSemana(mapa),
                if (_vista == _Vista.dia) _buildVistaDia(mapa),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, RolUsuario? rol) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          Permisos.puedeVerCitasAsignadas(rol)
              ? 'Mi Agenda'
              : 'Agenda de Citas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: GoogleFonts.dmSans().fontFamily,
          ),
        ),
        if (Permisos.puedeVerCitas(rol) || Permisos.puedeVerCitasAsignadas(rol))
          OutlinedButton.icon(
            onPressed: () => context.go('/citas'),
            icon: const Icon(Icons.view_list, size: 18),
            label: const Text('Vista Lista'),
          ),
      ],
    );
  }

  Widget _buildSelectorVista() {
    Widget chip(String label, _Vista v, IconData icon) {
      final activo = _vista == v;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _vista = v),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: activo ? AppColors.primaryDark : AppColors.card,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: activo ? AppColors.primaryDark : AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 16,
                    color: activo ? Colors.white : AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: activo ? Colors.white : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Row(
        children: [
          chip('Mes', _Vista.mes, Icons.calendar_view_month),
          chip('Semana', _Vista.semana, Icons.calendar_view_week),
          chip('Día', _Vista.dia, Icons.calendar_view_day),
        ],
      ),
    );
  }

  // ── Vista Mes ───────────────────────────────────────────────────────────

  Widget _buildVistaMes(Map<DateTime, List<CitaMedica>> mapa) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(8),
          child: TableCalendar<CitaMedica>(
            locale: 'es',
            firstDay: DateTime(2024, 1, 1),
            lastDay: DateTime(2030, 12, 31),
            focusedDay: _diaFocused,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Mes'},
            startingDayOfWeek: StartingDayOfWeek.monday,
            selectedDayPredicate: (d) => isSameDay(d, _diaSeleccionado),
            eventLoader: (dia) => _citasDe(mapa, dia),
            onDaySelected: (selected, focused) {
              setState(() {
                _diaSeleccionado = selected;
                _diaFocused = focused;
              });
            },
            onPageChanged: (focused) => _diaFocused = focused,
            calendarStyle: CalendarStyle(
              markersMaxCount: 3,
              markerDecoration: const BoxDecoration(
                color: _colorDorado,
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: AppColors.primaryDark,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildListaDelDia(mapa, _diaSeleccionado),
      ],
    );
  }

  Widget _buildListaDelDia(
      Map<DateTime, List<CitaMedica>> mapa, DateTime dia) {
    final citas = _citasDe(mapa, dia);
    final titulo = toBeginningOfSentenceCase(
        DateFormat("EEEE d 'de' MMMM", 'es').format(dia));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                titulo,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${citas.length} cita${citas.length == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (citas.isEmpty)
          _vacio('No hay citas para este día')
        else
          ...citas.map(_buildTarjetaCita),
      ],
    );
  }

  Widget _buildTarjetaCita(CitaMedica cita) {
    final estilo = _estiloEstado(cita.estado);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () => _mostrarDetalleCita(cita),
        leading: SizedBox(
          width: 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.schedule, size: 16, color: AppColors.primary),
              const SizedBox(height: 2),
              Text(
                cita.hora.isEmpty ? '--:--' : cita.hora,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        title: Text(cita.nombrePaciente,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cita.servicio, style: const TextStyle(fontSize: 12)),
            if ((cita.doctora ?? '').isNotEmpty)
              Text(cita.doctora!,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(estilo.icono, color: estilo.color, size: 20),
            const SizedBox(height: 2),
            Text(estilo.label,
                style: TextStyle(color: estilo.color, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  // ── Vista Semana ────────────────────────────────────────────────────────

  Widget _buildVistaSemana(Map<DateTime, List<CitaMedica>> mapa) {
    final inicioSemana = _diaSeleccionado
        .subtract(Duration(days: _diaSeleccionado.weekday - 1));
    final dias =
        List.generate(7, (i) => _soloFecha(inicioSemana.add(Duration(days: i))));

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _diaSeleccionado =
                  _diaSeleccionado.subtract(const Duration(days: 7))),
            ),
            Text(
              '${DateFormat('d MMM', 'es').format(dias.first)} - '
              '${DateFormat('d MMM yyyy', 'es').format(dias.last)}',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() => _diaSeleccionado =
                  _diaSeleccionado.add(const Duration(days: 7))),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: dias.map((d) => _buildColumnaDia(mapa, d)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildColumnaDia(Map<DateTime, List<CitaMedica>> mapa, DateTime dia) {
    final citas = _citasDe(mapa, dia);
    final esHoy = isSameDay(dia, DateTime.now());
    return Container(
      width: 170,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(
            color: esHoy ? AppColors.primary : AppColors.border,
            width: esHoy ? 2 : 1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: esHoy
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : AppColors.bgGeneral,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Column(
              children: [
                Text(
                  toBeginningOfSentenceCase(
                      DateFormat('EEEE', 'es').format(dia)),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  DateFormat('d MMM', 'es').format(dia),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: citas.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('—',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textDisabled)),
                  )
                : Column(
                    children: citas.map(_buildMiniCita).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCita(CitaMedica cita) {
    final estilo = _estiloEstado(cita.estado);
    return GestureDetector(
      onTap: () => _mostrarDetalleCita(cita),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: estilo.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border(left: BorderSide(color: estilo.color, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cita.hora,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: estilo.color)),
            Text(cita.nombrePaciente,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(cita.servicio,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  // ── Vista Día (timeline) ─────────────────────────────────────────────────

  Widget _buildVistaDia(Map<DateTime, List<CitaMedica>> mapa) {
    final citas = _citasDe(mapa, _diaSeleccionado);
    // Mapa hora-entera -> citas que comienzan en esa hora.
    final porHora = <int, List<CitaMedica>>{};
    for (final c in citas) {
      final h = int.tryParse(c.hora.split(':').first) ?? 0;
      porHora.putIfAbsent(h, () => []).add(c);
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => setState(() => _diaSeleccionado =
                  _diaSeleccionado.subtract(const Duration(days: 1))),
            ),
            Text(
              toBeginningOfSentenceCase(
                  DateFormat("EEEE d 'de' MMMM yyyy", 'es')
                      .format(_diaSeleccionado)),
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => setState(() => _diaSeleccionado =
                  _diaSeleccionado.add(const Duration(days: 1))),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: List.generate(13, (i) {
              final hora = 7 + i; // 07:00 .. 19:00
              final citasHora = porHora[hora] ?? [];
              return Container(
                decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: AppColors.border)),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 52,
                      child: Text(
                        '${hora.toString().padLeft(2, '0')}:00',
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    Expanded(
                      child: citasHora.isEmpty
                          ? const SizedBox(height: 20)
                          : Column(
                              children:
                                  citasHora.map(_buildBloqueCita).toList(),
                            ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildBloqueCita(CitaMedica cita) {
    final estilo = _estiloEstado(cita.estado);
    return GestureDetector(
      onTap: () => _mostrarDetalleCita(cita),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: estilo.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border(left: BorderSide(color: estilo.color, width: 3)),
        ),
        child: Row(
          children: [
            Text(cita.hora,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: estilo.color)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${cita.nombrePaciente} · ${cita.servicio}',
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(estilo.icono, size: 16, color: estilo.color),
          ],
        ),
      ),
    );
  }

  // ── Detalle de cita ──────────────────────────────────────────────────────

  void _mostrarDetalleCita(CitaMedica cita) {
    final estilo = _estiloEstado(cita.estado);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(estilo.icono, color: estilo.color),
            const SizedBox(width: 8),
            const Expanded(child: Text('Detalle de la cita')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detalleRow('Paciente', cita.nombrePaciente),
            _detalleRow(
                'Fecha',
                toBeginningOfSentenceCase(
                    DateFormat("EEEE d 'de' MMMM yyyy", 'es')
                        .format(cita.fecha))),
            _detalleRow('Hora', cita.hora),
            _detalleRow('Servicio', cita.servicio),
            _detalleRow('Clínica', cita.clinica),
            if ((cita.doctora ?? '').isNotEmpty)
              _detalleRow('Doctora', cita.doctora!),
            if (cita.motivo.isNotEmpty) _detalleRow('Motivo', cita.motivo),
            _detalleRow('Estado', estilo.label),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _detalleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _vacio(String msg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            const Text('📅', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text(msg,
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );

  _EstiloEstado _estiloEstado(String estado) {
    switch (estado) {
      case 'confirmada':
        return const _EstiloEstado(
            AppColors.success, Icons.check_circle, 'Confirmada');
      case 'cancelada':
        return const _EstiloEstado(
            AppColors.danger, Icons.cancel, 'Cancelada');
      case 'completada':
        return const _EstiloEstado(
            AppColors.clinicalGreen, Icons.task_alt, 'Completada');
      case 'pendiente':
      default:
        return const _EstiloEstado(
            AppColors.warning, Icons.schedule, 'Pendiente');
    }
  }
}

class _EstiloEstado {
  final Color color;
  final IconData icono;
  final String label;
  const _EstiloEstado(this.color, this.icono, this.label);
}
