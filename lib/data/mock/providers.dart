import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// 'Medicamento' (inventario de farmacia) vive en farmacia_service.dart; aquí
// ocultamos el 'Medicamento' de receta de mock_data para evitar el choque.
import 'mock_data.dart' hide Medicamento;
import '../services/auth_service.dart';
import '../services/paciente_service.dart';
import '../services/cita_service.dart';
import '../services/sesion_service.dart';
import '../services/usuario_service.dart';
import '../services/catalogo_service.dart';
import '../services/venta_service.dart';
import '../services/expediente_service.dart';
import '../services/reporte_service.dart';
import '../services/farmacia_service.dart';
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

/// Stream con TODAS las citas médicas (sin filtro de fecha) para la agenda
/// visual / calendario. Si el usuario es doctora, solo trae sus citas.
final todasCitasMedicasStreamProvider = StreamProvider<List<CitaMedica>>((ref) {
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();
  final citaService = ref.watch(citaServiceProvider);
  if (usuario.rol == RolUsuario.doctora) {
    return citaService.streamCitasDoctora(usuario.id);
  }
  return citaService.streamCitasMedicas();
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

// ============================================================================
// FARMACIA (FARMACÉUTICA / ADMINISTRADORA)
// ============================================================================

final farmaciaServiceProvider = Provider((ref) => FarmaciaService());

/// Stream del inventario de medicamentos en tiempo real.
final medicamentosStreamProvider = StreamProvider<List<Medicamento>>((ref) {
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();
  return ref.watch(farmaciaServiceProvider).streamMedicamentos();
});

/// Stream de movimientos de farmacia (historial).
final movimientosFarmaciaStreamProvider =
    StreamProvider<List<MovimientoFarmacia>>((ref) {
  final usuario = ref.watch(usuarioActivoProvider);
  if (usuario == null) return const Stream.empty();
  return ref.watch(farmaciaServiceProvider).streamMovimientos();
});

/// Resultado de la verificación de alertas de inventario.
class AlertasFarmacia {
  /// Medicamentos próximos a vencer (entre 0 y 30 días).
  final List<Medicamento> porVencer;
  /// Medicamentos cuya fecha de vencimiento ya pasó (días < 0).
  final List<Medicamento> vencidos;
  final List<Medicamento> stockBajo;
  final List<Medicamento> sinStock;

  const AlertasFarmacia({
    this.porVencer = const [],
    this.vencidos = const [],
    this.stockBajo = const [],
    this.sinStock = const [],
  });

  int get total =>
      porVencer.length + vencidos.length + stockBajo.length + sinStock.length;
  bool get hayAlertas => total > 0;
}

/// Días restantes (puede ser negativo si ya venció) a partir de la
/// fechaVencimiento almacenada como texto 'AAAA-MM-DD'.
int? diasParaVencer(Medicamento m) {
  if (m.fechaVencimiento.trim().isEmpty) return null;
  final fecha = DateTime.tryParse(m.fechaVencimiento.trim());
  if (fecha == null) return null;
  final hoy = DateTime.now();
  return DateTime(fecha.year, fecha.month, fecha.day)
      .difference(DateTime(hoy.year, hoy.month, hoy.day))
      .inDays;
}

/// Provider derivado del inventario en tiempo real que clasifica las alertas.
/// Realtime: se recalcula automáticamente cuando cambia el stock.
final alertasFarmaciaProvider = Provider<AlertasFarmacia>((ref) {
  final medsAsync = ref.watch(medicamentosStreamProvider);
  final meds = medsAsync.asData?.value;
  if (meds == null) return const AlertasFarmacia();

  final porVencer = <Medicamento>[];
  final vencidos = <Medicamento>[];
  final stockBajo = <Medicamento>[];
  final sinStock = <Medicamento>[];

  for (final m in meds) {
    if (m.cantidad <= 0) {
      sinStock.add(m);
    } else if (m.cantidad <= m.cantidadMinima) {
      stockBajo.add(m);
    }
    final dias = diasParaVencer(m);
    if (dias != null) {
      if (dias < 0) {
        vencidos.add(m);
      } else if (dias <= 30) {
        porVencer.add(m);
      }
    }
  }

  porVencer.sort((a, b) => (diasParaVencer(a) ?? 9999)
      .compareTo(diasParaVencer(b) ?? 9999));
  // Vencidos: el más vencido (más negativo) primero.
  vencidos.sort((a, b) =>
      (diasParaVencer(a) ?? 0).compareTo(diasParaVencer(b) ?? 0));

  return AlertasFarmacia(
    porVencer: porVencer,
    vencidos: vencidos,
    stockBajo: stockBajo,
    sinStock: sinStock,
  );
});

