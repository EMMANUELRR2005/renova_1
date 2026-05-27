import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mock_data.dart';

// ============================================================================
// USUARIOS Y AUTENTICACIÓN
// ============================================================================

final usuariosProvider = Provider<List<Usuario>>((ref) {
  return mockUsuarios;
});

// ============================================================================
// PACIENTES
// ============================================================================

final patientsProvider = Provider<List<Patient>>((ref) {
  return mockPatients;
});

final activePatientProvider = StateProvider<Patient?>((ref) {
  return null;
});

final patientFilterProvider = StateProvider<String>((ref) {
  return 'todos';
});

final patientSearchProvider = StateProvider<String>((ref) {
  return '';
});

final filteredPatientsProvider = Provider<List<Patient>>((ref) {
  final patients = ref.watch(patientsProvider);
  final filter = ref.watch(patientFilterProvider);
  final search = ref.watch(patientSearchProvider);

  return patients.where((p) {
    bool matchesFilter = filter == 'todos'; // Se ampliará según necesidad
    bool matchesSearch = search.isEmpty ||
        p.nombre.toLowerCase().contains(search.toLowerCase()) ||
        p.dpi.toLowerCase().contains(search.toLowerCase());
    return matchesFilter && matchesSearch;
  }).toList();
});

// ============================================================================
// TERAPEUTAS
// ============================================================================

final terapeutasProvider = Provider<List<Terapeuta>>((ref) {
  return mockTerapeutas;
});

// ============================================================================
// SALAS
// ============================================================================

final salasProvider = Provider<List<Sala>>((ref) {
  return mockSalas;
});

// ============================================================================
// CITAS
// ============================================================================

final appointmentsProvider = Provider<List<Appointment>>((ref) {
  return mockAppointments;
});

final citasHoyProvider = Provider<List<Appointment>>((ref) {
  final appointments = ref.watch(appointmentsProvider);
  final hoy = DateTime.now();
  
  return appointments
      .where((a) => a.fecha.year == hoy.year &&
          a.fecha.month == hoy.month &&
          a.fecha.day == hoy.day)
      .toList();
});

final sesionesActivasProvider = Provider<List<SesionTerapia>>((ref) {
  return mockSesiones.where((s) => s.fechaHoraFin == null).toList();
});

// ============================================================================
// SESIONES DE TERAPIA
// ============================================================================

final sesionesProvider = Provider<List<SesionTerapia>>((ref) {
  return mockSesiones;
});

// ============================================================================
// PLANES DE TRATAMIENTO
// ============================================================================

final planesProvider = Provider<List<PlanTratamiento>>((ref) {
  return mockPlanes;
});

final planesActivosProvider = Provider<List<PlanTratamiento>>((ref) {
  final planes = ref.watch(planesProvider);
  return planes.where((p) => p.activo).toList();
});

// ============================================================================
// KPIs PARA DASHBOARD (Clínica Estética)
// ============================================================================

final kpiDataProvider = Provider<Map<String, dynamic>>((ref) {
  final citasHoy = ref.watch(citasHoyProvider);
  final sesionesActivas = ref.watch(sesionesActivasProvider);
  final planesActivos = ref.watch(planesActivosProvider);

  // Ingresos del día (sumar precioBase de citas completadas de hoy)
  double ingresosDelDia = citasHoy
      .where((c) => c.estado == EstadoCita.completada)
      .fold(0, (sum, c) => sum + c.precioBase);

  // Alertas clínicas (pacientes con alergias críticas)
  final patients = ref.watch(patientsProvider);
  int alertasClinicas = patients
      .where((p) => p.alergias.isNotEmpty || p.condicionesBase.isNotEmpty)
      .length;

  return {
    'citasHoy': citasHoy.length,
    'sesionesEnCurso': sesionesActivas.length,
    'ingresosDelDia': ingresosDelDia,
    'alertasClinicas': alertasClinicas,
    'planesActivos': planesActivos.length,
  };
});
