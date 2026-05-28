import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mock_data.dart';
import '../services/auth_service.dart';
import '../services/paciente_service.dart';
import '../services/cita_service.dart';
import '../services/sesion_service.dart';
import '../services/usuario_service.dart';

// ============================================================================
// SERVICIOS FIREBASE
// ============================================================================

final authServiceProvider = Provider((ref) => AuthService());
final pacienteServiceProvider = Provider((ref) => PacienteService());
final citaServiceProvider = Provider((ref) => CitaService());
final sesionServiceProvider = Provider((ref) => SesionService());
final usuarioServiceProvider = Provider((ref) => UsuarioService());

// ============================================================================
// STREAMS EN TIEMPO REAL
// ============================================================================

/// Stream de pacientes en tiempo real
final pacientesStreamProvider = StreamProvider<List<Patient>>((ref) {
  return ref.watch(pacienteServiceProvider).getPacientes();
});

/// Stream de citas de hoy
final citasHoyStreamProvider = StreamProvider<List<Appointment>>((ref) {
  return ref.watch(citaServiceProvider).getCitasHoy();
});

/// Stream de citas del terapeuta activo
final citasTerapeutaProvider = StreamProvider<List<Appointment>>((ref) {
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();
  return ref.watch(citaServiceProvider).getCitasTerapeutaHoy(usuario.id);
});

/// Stream de usuarios (para pantalla de usuarios)
final usuariosStreamProvider = StreamProvider<List<Usuario>>((ref) {
  return ref.watch(usuarioServiceProvider).getUsuarios();
});

/// Stream de sesiones activas
final sesionesActivasStreamProvider = StreamProvider<List<SesionTerapia>>((ref) {
  return ref.watch(sesionServiceProvider).getSesionesActivas();
});

// ============================================================================
// KPIs CALCULADOS DESDE CITAS DE HOY
// ============================================================================

final kpiProvider = Provider<Map<String, dynamic>>((ref) {
  final citasHoyAsync = ref.watch(citasHoyStreamProvider);
  final sesionesActivasAsync = ref.watch(sesionesActivasStreamProvider);
  final planesAsync = ref.watch(planesActivosStreamProvider);
  final pacientesAsync = ref.watch(pacientesStreamProvider);

  if (citasHoyAsync.isLoading || sesionesActivasAsync.isLoading) {
    return {
      'citasHoy': 0,
      'sesionesEnCurso': 0,
      'ingresosDelDia': 0.0,
      'alertasClinicas': 0,
      'planesActivos': 0,
    };
  }

  final citasHoy = citasHoyAsync.asData?.value ?? [];
  final sesionesActivas = sesionesActivasAsync.asData?.value ?? [];
  final planes = planesAsync.asData?.value ?? [];
  final pacientes = pacientesAsync.asData?.value ?? [];

  final ingresosDelDia = citasHoy
      .where((c) => c.estado == EstadoCita.completada)
      .fold(0.0, (sum, c) => sum + c.precioBase);

  final alertasClinicas = pacientes
      .where((p) => p.alergias.isNotEmpty || p.condicionesBase.isNotEmpty)
      .length;

  return {
    'citasHoy': citasHoy.length,
    'sesionesEnCurso': sesionesActivas.length,
    'ingresosDelDia': ingresosDelDia,
    'alertasClinicas': alertasClinicas,
    'planesActivos': planes.length,
  };
});

// ============================================================================
// FILTROS Y SELECCIONES
// ============================================================================

/// Filtro de pacientes seleccionado
final filtroPacientesProvider = StateProvider<String>((ref) => 'todos');

/// Paciente seleccionado para ver detalle
final pacienteSeleccionadoProvider = StateProvider<Patient?>((ref) => null);

/// Usuario activo - importado del auth_provider
final usuarioActivoProvider = StateProvider<Usuario?>((ref) => null);

// ============================================================================
// PROVIDERS PARA COMPATIBILIDAD (sin usar, pero se mantienen para referencia)
// ============================================================================

final patientsProvider = Provider<List<Patient>>((ref) {
  return [];
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

final appointmentsProvider = Provider<List<Appointment>>((ref) {
  return [];
});

final sesionesProvider = Provider<List<SesionTerapia>>((ref) {
  return [];
});

final planesProvider = Provider<List<PlanTratamiento>>((ref) {
  return [];
});

/// Stream de planes activos
final planesActivosStreamProvider = StreamProvider<List<PlanTratamiento>>((ref) {
  return FirebaseFirestore.instance
      .collection('planes')
      .where('activo', isEqualTo: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => PlanTratamiento.fromMap(d.data(), d.id))
          .toList());
});

