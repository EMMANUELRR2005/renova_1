import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mock_data.dart';
import '../services/auth_service.dart';
import '../services/paciente_service.dart';
import '../services/cita_service.dart';
import '../services/sesion_service.dart';
import '../services/usuario_service.dart';
import '../services/catalogo_service.dart';
import '../services/venta_service.dart';
import '../services/expediente_service.dart';
import '../services/reporte_service.dart';
import '../../features/auth/providers/auth_provider.dart';

// ============================================================================
// SERVICIOS FIREBASE
// ============================================================================

final authServiceProvider = Provider((ref) => AuthService());
final pacienteServiceProvider = Provider((ref) => PacienteService());
final citaServiceProvider = Provider((ref) => CitaService());
final sesionServiceProvider = Provider((ref) => SesionService());
final usuarioServiceProvider = Provider((ref) => UsuarioService());
final catalogoServiceProvider = Provider((ref) => CatalogoService());

// ============================================================================
// STREAMS EN TIEMPO REAL
// ============================================================================

/// Stream de pacientes en tiempo real
/// Se invalida automáticamente cuando el usuario cambia (logout/login)
final pacientesStreamProvider = StreamProvider<List<Patient>>((ref) {
  // Depender del usuario activo para que el stream se reinicie al cambiar sesión
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();
  return ref.watch(pacienteServiceProvider).getPacientes();
});

/// Stream de citas de hoy
/// Se invalida automáticamente cuando el usuario cambia (logout/login)
final citasHoyStreamProvider = StreamProvider<List<Appointment>>((ref) {
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();
  return ref.watch(citaServiceProvider).getCitasHoy();
});

/// Stream de citas del terapeuta activo
final citasTerapeutaProvider = StreamProvider<List<Appointment>>((ref) {
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();
  return ref.watch(citaServiceProvider).getCitasTerapeutaHoy(usuario.id);
});

/// Stream de usuarios (para pantalla de usuarios)
/// Se invalida automáticamente cuando el usuario cambia (logout/login)
final usuariosStreamProvider = StreamProvider<List<Usuario>>((ref) {
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();
  return ref.watch(usuarioServiceProvider).getUsuarios();
});

/// Stream de sesiones activas
/// Se invalida automáticamente cuando el usuario cambia (logout/login)
final sesionesActivasStreamProvider = StreamProvider<List<SesionTerapia>>((ref) {
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();
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
// STREAMS MODELO NUEVO (Paciente)
// ============================================================================

/// Filtro de estado para la lista de pacientes nueva
final filtroPacientesEstadoProvider = StateProvider<String>((ref) => 'todos');

/// ID del paciente seleccionado (para navegar entre pantallas)
final selectedPacienteIdProvider = StateProvider<String?>((ref) => null);

/// Stream de pacientes con modelo nuevo
/// Se invalida automáticamente cuando el usuario cambia (logout/login)
final pacientesV2StreamProvider = StreamProvider<List<Paciente>>((ref) {
  // Depender del usuario activo para que el stream se reinicie al cambiar sesión
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();

  final filtro = ref.watch(filtroPacientesEstadoProvider);
  return ref.watch(pacienteServiceProvider).streamPacientes(
      filtroEstado: filtro == 'todos' ? null : filtro);
});

/// Stream de historial de un paciente específico
/// Se invalida automáticamente cuando el usuario cambia (logout/login)
final historialPacienteProvider =
    StreamProvider.family<List<HistorialConsulta>, String>((ref, pacienteId) {
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();
  return ref.watch(pacienteServiceProvider).streamHistorial(pacienteId);
});

/// Stream de un paciente por ID
/// Se invalida automáticamente cuando el usuario cambia (logout/login)
final pacienteByIdProvider =
    StreamProvider.family<Paciente?, String>((ref, id) {
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();
  return ref.watch(pacienteServiceProvider).streamPacienteById(id);
});

// ============================================================================
// FILTROS Y SELECCIONES
// ============================================================================

/// Filtro de pacientes seleccionado
final filtroPacientesProvider = StateProvider<String>((ref) => 'todos');

/// Paciente seleccionado para ver detalle
final pacienteSeleccionadoProvider = StateProvider<Patient?>((ref) => null);

// usuarioActivoProvider se define en features/auth/providers/auth_provider.dart

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
/// Se invalida automáticamente cuando el usuario cambia (logout/login)
final planesActivosStreamProvider = StreamProvider<List<PlanTratamiento>>((ref) {
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('planes')
      .where('activo', isEqualTo: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => PlanTratamiento.fromMap(d.data(), d.id))
          .toList());
});

// ============================================================================
// CATÁLOGOS: SERVICIOS Y CLÍNICAS
// ============================================================================

final serviciosStreamProvider = StreamProvider<List<ServicioClinica>>((ref) {
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();
  return ref.watch(catalogoServiceProvider).streamServicios();
});

final clinicasStreamProvider = StreamProvider<List<Clinica>>((ref) {
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();
  return ref.watch(catalogoServiceProvider).streamClinicas();
});

final doctorasStreamProvider = StreamProvider<List<Usuario>>((ref) {
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();
  return ref.watch(catalogoServiceProvider).streamDoctoras();
});

final pacientesActivosStreamProvider = StreamProvider<List<Paciente>>((ref) {
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();
  return ref.watch(pacienteServiceProvider).streamPacientesActivos();
});

// ============================================================================
// CITAS MÉDICAS (SECRETARIA)
// ============================================================================

final filtroCitasProvider = StateProvider<String>((ref) => 'hoy');

final citasMedicasStreamProvider = StreamProvider<List<CitaMedica>>((ref) {
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();

  final filtro = ref.watch(filtroCitasProvider);
  final citaService = ref.watch(citaServiceProvider);

  switch (filtro) {
    case 'hoy':
      return citaService.streamCitasMedicasHoy();
    case 'semana':
      return citaService.streamCitasMedicasSemana();
    case 'todas':
    default:
      return citaService.streamCitasMedicas();
  }
});

final citasDoctoraStreamProvider = StreamProvider<List<CitaMedica>>((ref) {
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();
  return ref.watch(citaServiceProvider).streamCitasDoctora(usuario.id);
});

// ============================================================================
// VENTAS / CAJA (SECRETARIA)
// ============================================================================

final ventaServiceProvider = Provider((ref) => VentaService());

final filtroVentasProvider = StateProvider<String>((ref) => 'hoy');

final ventasStreamProvider = StreamProvider<List<Venta>>((ref) {
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();

  final filtro = ref.watch(filtroVentasProvider);
  final ventaService = ref.watch(ventaServiceProvider);

  switch (filtro) {
    case 'hoy':
      return ventaService.streamVentasHoy();
    case 'semana':
      return ventaService.streamVentasSemana();
    case 'todas':
    default:
      return ventaService.streamTodasLasVentas();
  }
});

// ============================================================================
// EXPEDIENTES
// ============================================================================

final expedienteServiceProvider = Provider((ref) => ExpedienteService());

final filtroExpedientesProvider = StateProvider<String>((ref) => 'todos');

final expedientesStreamProvider = StreamProvider<List<Expediente>>((ref) {
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();

  final filtro = ref.watch(filtroExpedientesProvider);
  return ref.watch(expedienteServiceProvider).streamExpedientes(
      filtroEstado: filtro == 'todos' ? null : filtro);
});

final selectedExpedienteIdProvider = StateProvider<String?>((ref) => null);

final expedienteByIdProvider =
    StreamProvider.family<Expediente?, String>((ref, id) {
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();
  return ref.watch(expedienteServiceProvider).streamExpedienteById(id);
});

final entradasExpedienteProvider =
    StreamProvider.family<List<EntradaExpediente>, String>((ref, expedienteId) {
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();
  return ref.watch(expedienteServiceProvider).streamEntradas(expedienteId);
});

// ============================================================================
// REPORTES (ADMINISTRADORA)
// ============================================================================

final reporteServiceProvider = Provider((ref) => ReporteService());

