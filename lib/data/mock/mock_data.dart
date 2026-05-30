import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================================
// ENUMS
// ============================================================================

enum RolUsuario {
  administradora,
  enfermera,
  terapeuta,
  secretaria_recepcion,
  doctora,
}

enum EspecialidadTerapeuta {
  masajista,
  sueroterapista,
  terapia_avanzada,
  esteticista,
}

enum TipoServicio {
  sueroterapia,
  masaje,
  jacuzzi,
  terapia_avanzada,
  estetica,
  patologia,
}

enum TipoSala {
  sala_masajes,
  jacuzzi,
  sala_terapia,
  sala_estetica,
  sala_suero,
}

enum EstadoCita {
  agendada,
  confirmada,
  en_curso,
  completada,
  cancelada,
  pendiente,
}

// ============================================================================
// MODELOS - SERVICIOS Y CLÍNICAS
// ============================================================================

class ServicioClinica {
  final String id;
  final String nombre;
  final String? descripcion;
  final bool activo;

  ServicioClinica({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.activo = true,
  });

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'descripcion': descripcion ?? '',
    'activo': activo,
  };

  factory ServicioClinica.fromMap(Map<String, dynamic> map, String docId) =>
    ServicioClinica(
      id: docId,
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'],
      activo: map['activo'] ?? true,
    );
}

class Clinica {
  final String id;
  final String nombre;
  final String? direccion;
  final bool activo;

  Clinica({
    required this.id,
    required this.nombre,
    this.direccion,
    this.activo = true,
  });

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'direccion': direccion ?? '',
    'activo': activo,
  };

  factory Clinica.fromMap(Map<String, dynamic> map, String docId) =>
    Clinica(
      id: docId,
      nombre: map['nombre'] ?? '',
      direccion: map['direccion'],
      activo: map['activo'] ?? true,
    );
}

// ============================================================================
// MODELOS

class Usuario {
  final String id;
  final String nombre;
  final String email;
  final String password;
  final RolUsuario rol;
  final bool activo;
  final String avatarIniciales;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.password,
    required this.rol,
    required this.activo,
    required this.avatarIniciales,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'nombre': nombre,
    'email': email,
    'rol': rol.name,
    'activo': activo,
    'avatarIniciales': avatarIniciales,
  };

  factory Usuario.fromMap(Map<String, dynamic> map, String docId) =>
    Usuario(
      id: docId,
      nombre: map['nombre'] ?? '',
      email: map['email'] ?? '',
      password: '',
      rol: RolUsuario.values.firstWhere(
        (r) => r.name == map['rol'],
        orElse: () => RolUsuario.enfermera,
      ),
      activo: map['activo'] ?? true,
      avatarIniciales: map['avatarIniciales'] ?? '',
    );
}

class Terapeuta {
  final String id;
  final String nombre;
  final EspecialidadTerapeuta especialidad;
  final bool disponible;
  final String usuarioId;

  Terapeuta({
    required this.id,
    required this.nombre,
    required this.especialidad,
    required this.disponible,
    required this.usuarioId,
  });

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'especialidad': especialidad.name,
    'disponible': disponible,
    'usuarioId': usuarioId,
  };

  factory Terapeuta.fromMap(Map<String, dynamic> map, String docId) =>
    Terapeuta(
      id: docId,
      nombre: map['nombre'] ?? '',
      especialidad: EspecialidadTerapeuta.values.firstWhere(
        (e) => e.name == map['especialidad'],
        orElse: () => EspecialidadTerapeuta.masajista,
      ),
      disponible: map['disponible'] ?? true,
      usuarioId: map['usuarioId'] ?? '',
    );
}

class Patient {
  final String id;
  final String nombre;
  final String expediente;
  final String dpi;
  final String telefono;
  final String fechaNacimiento;
  final int edad;
  final String tipoSangre;
  final List<String> alergias;
  final List<String> condicionesBase;
  final List<String> medicamentosActuales;
  final String? fotoUrl;
  final String registradoPor;

  Patient({
    required this.id,
    required this.nombre,
    required this.expediente,
    required this.dpi,
    required this.telefono,
    required this.fechaNacimiento,
    required this.edad,
    required this.tipoSangre,
    required this.alergias,
    required this.condicionesBase,
    required this.medicamentosActuales,
    required this.registradoPor,
    this.fotoUrl,
  });

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'expediente': expediente,
    'dpi': dpi,
    'telefono': telefono,
    'fechaNacimiento': fechaNacimiento,
    'edad': edad,
    'tipoSangre': tipoSangre,
    'alergias': alergias,
    'condicionesBase': condicionesBase,
    'medicamentosActuales': medicamentosActuales,
    'fotoUrl': fotoUrl ?? '',
    'registradoPor': registradoPor,
    'creadoEn': FieldValue.serverTimestamp(),
  };

  factory Patient.fromMap(Map<String, dynamic> map, String docId) =>
    Patient(
      id: docId,
      nombre: map['nombre'] ?? '',
      expediente: map['expediente'] ?? '',
      dpi: map['dpi'] ?? '',
      telefono: map['telefono'] ?? '',
      fechaNacimiento: map['fechaNacimiento'] ?? '',
      edad: map['edad'] ?? 0,
      tipoSangre: map['tipoSangre'] ?? '',
      alergias: List<String>.from(map['alergias'] ?? []),
      condicionesBase: List<String>.from(map['condicionesBase'] ?? []),
      medicamentosActuales: List<String>.from(map['medicamentosActuales'] ?? []),
      fotoUrl: map['fotoUrl'],
      registradoPor: map['registradoPor'] ?? '',
    );
}

class Sala {
  final String id;
  final String nombre;
  final TipoSala tipo;
  final bool disponible;

  Sala({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.disponible,
  });

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'tipo': tipo.name,
    'disponible': disponible,
  };

  factory Sala.fromMap(Map<String, dynamic> map, String docId) =>
    Sala(
      id: docId,
      nombre: map['nombre'] ?? '',
      tipo: TipoSala.values.firstWhere(
        (t) => t.name == map['tipo'],
        orElse: () => TipoSala.sala_masajes,
      ),
      disponible: map['disponible'] ?? true,
    );
}

class Appointment {
  final String id;
  final String pacienteId;
  final String terapeutaId;
  final String salaId;
  final TipoServicio tipoServicio;
  final DateTime fecha;
  final String hora;
  final int duracionMinutos;
  final double precioBase;
  final EstadoCita estado;
  final String? notas;

  Appointment({
    required this.id,
    required this.pacienteId,
    required this.terapeutaId,
    required this.salaId,
    required this.tipoServicio,
    required this.fecha,
    required this.hora,
    required this.duracionMinutos,
    required this.precioBase,
    required this.estado,
    this.notas,
  });

  Map<String, dynamic> toMap() => {
    'pacienteId': pacienteId,
    'terapeutaId': terapeutaId,
    'salaId': salaId,
    'tipoServicio': tipoServicio.name,
    'fecha': Timestamp.fromDate(fecha),
    'hora': hora,
    'duracionMinutos': duracionMinutos,
    'precioBase': precioBase,
    'estado': estado.name,
    'notas': notas ?? '',
    'creadoEn': FieldValue.serverTimestamp(),
  };

  factory Appointment.fromMap(Map<String, dynamic> map, String docId) =>
    Appointment(
      id: docId,
      pacienteId: map['pacienteId'] ?? '',
      terapeutaId: map['terapeutaId'] ?? '',
      salaId: map['salaId'] ?? '',
      tipoServicio: TipoServicio.values.firstWhere(
        (t) => t.name == map['tipoServicio'],
        orElse: () => TipoServicio.masaje,
      ),
      fecha: (map['fecha'] as Timestamp).toDate(),
      hora: map['hora'] ?? '',
      duracionMinutos: map['duracionMinutos'] ?? 60,
      precioBase: (map['precioBase'] ?? 0).toDouble(),
      estado: EstadoCita.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => EstadoCita.agendada,
      ),
      notas: map['notas'],
    );
}

// ── Cita Médica (para secretaria) ───────────────────────────────────────────

class CitaMedica {
  final String id;
  final String pacienteId;
  final String nombrePaciente;
  final String servicio;
  final String servicioId;
  final String clinica;
  final String clinicaId;
  final String? doctora;
  final String? doctoraId;
  final DateTime fecha;
  final String hora;
  final String motivo;
  final String? notas;
  final String estado; // pendiente, confirmada, cancelada, completada
  final String creadaPor;
  final DateTime? fechaCreacion;
  final String? motivoCancelacion;

  CitaMedica({
    required this.id,
    required this.pacienteId,
    required this.nombrePaciente,
    required this.servicio,
    required this.servicioId,
    required this.clinica,
    required this.clinicaId,
    required this.fecha,
    required this.hora,
    required this.motivo,
    required this.estado,
    required this.creadaPor,
    this.doctora,
    this.doctoraId,
    this.notas,
    this.fechaCreacion,
    this.motivoCancelacion,
  });

  Map<String, dynamic> toMap() => {
    'pacienteId': pacienteId,
    'nombrePaciente': nombrePaciente,
    'servicio': servicio,
    'servicioId': servicioId,
    'clinica': clinica,
    'clinicaId': clinicaId,
    'doctora': doctora ?? '',
    'doctoraId': doctoraId ?? '',
    'fecha': Timestamp.fromDate(fecha),
    'hora': hora,
    'motivo': motivo,
    'notas': notas ?? '',
    'estado': estado,
    'creadaPor': creadaPor,
    'fechaCreacion': FieldValue.serverTimestamp(),
  };

  factory CitaMedica.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parseFecha(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      return null;
    }
    return CitaMedica(
      id: docId,
      pacienteId: map['pacienteId'] ?? '',
      nombrePaciente: map['nombrePaciente'] ?? '',
      servicio: map['servicio'] ?? '',
      servicioId: map['servicioId'] ?? '',
      clinica: map['clinica'] ?? '',
      clinicaId: map['clinicaId'] ?? '',
      doctora: map['doctora'],
      doctoraId: map['doctoraId'],
      fecha: parseFecha(map['fecha']) ?? DateTime.now(),
      hora: map['hora'] ?? '',
      motivo: map['motivo'] ?? '',
      notas: map['notas'],
      estado: map['estado'] ?? 'pendiente',
      creadaPor: map['creadaPor'] ?? '',
      fechaCreacion: parseFecha(map['fechaCreacion']),
      motivoCancelacion: map['motivoCancelacion'],
    );
  }
}

class SesionTerapia {
  final String id;
  final String citaId;
  final String pacienteId;
  final String terapeutaId;
  final DateTime fechaHoraInicio;
  final DateTime? fechaHoraFin;
  final String observaciones;
  final List<String> tecnicasUsadas;
  final int evolucion;
  final String proximaSesionRecomendada;
  final String registradaPor;

  SesionTerapia({
    required this.id,
    required this.citaId,
    required this.pacienteId,
    required this.terapeutaId,
    required this.fechaHoraInicio,
    required this.observaciones,
    required this.tecnicasUsadas,
    required this.evolucion,
    required this.proximaSesionRecomendada,
    required this.registradaPor,
    this.fechaHoraFin,
  });

  Map<String, dynamic> toMap() => {
    'citaId': citaId,
    'pacienteId': pacienteId,
    'terapeutaId': terapeutaId,
    'fechaHoraInicio': Timestamp.fromDate(fechaHoraInicio),
    'fechaHoraFin': fechaHoraFin != null ? Timestamp.fromDate(fechaHoraFin!) : null,
    'observaciones': observaciones,
    'tecnicasUsadas': tecnicasUsadas,
    'evolucion': evolucion,
    'proximaSesionRecomendada': proximaSesionRecomendada,
    'registradaPor': registradaPor,
    'creadoEn': FieldValue.serverTimestamp(),
  };

  factory SesionTerapia.fromMap(Map<String, dynamic> map, String docId) =>
    SesionTerapia(
      id: docId,
      citaId: map['citaId'] ?? '',
      pacienteId: map['pacienteId'] ?? '',
      terapeutaId: map['terapeutaId'] ?? '',
      fechaHoraInicio: (map['fechaHoraInicio'] as Timestamp).toDate(),
      fechaHoraFin: map['fechaHoraFin'] != null ? (map['fechaHoraFin'] as Timestamp).toDate() : null,
      observaciones: map['observaciones'] ?? '',
      tecnicasUsadas: List<String>.from(map['tecnicasUsadas'] ?? []),
      evolucion: map['evolucion'] ?? 0,
      proximaSesionRecomendada: map['proximaSesionRecomendada'] ?? '',
      registradaPor: map['registradaPor'] ?? '',
    );
}

class PlanTratamiento {
  final String id;
  final String pacienteId;
  final String diagnostico;
  final int totalSesiones;
  final int sesionesCompletadas;
  final String objetivo;
  final String fechaInicio;
  final bool activo;

  PlanTratamiento({
    required this.id,
    required this.pacienteId,
    required this.diagnostico,
    required this.totalSesiones,
    required this.sesionesCompletadas,
    required this.objetivo,
    required this.fechaInicio,
    required this.activo,
  });

  Map<String, dynamic> toMap() => {
    'pacienteId': pacienteId,
    'diagnostico': diagnostico,
    'totalSesiones': totalSesiones,
    'sesionesCompletadas': sesionesCompletadas,
    'objetivo': objetivo,
    'fechaInicio': fechaInicio,
    'activo': activo,
    'creadoEn': FieldValue.serverTimestamp(),
  };

  factory PlanTratamiento.fromMap(Map<String, dynamic> map, String docId) =>
    PlanTratamiento(
      id: docId,
      pacienteId: map['pacienteId'] ?? '',
      diagnostico: map['diagnostico'] ?? '',
      totalSesiones: map['totalSesiones'] ?? 0,
      sesionesCompletadas: map['sesionesCompletadas'] ?? 0,
      objetivo: map['objetivo'] ?? '',
      fechaInicio: map['fechaInicio'] ?? '',
      activo: map['activo'] ?? true,
    );
}

// ============================================================================
// MODELO PACIENTE (nuevo — para módulo de gestión de pacientes)
// ============================================================================

class ContactoEmergencia {
  final String nombre;
  final String telefono;
  final String relacion;

  ContactoEmergencia({
    required this.nombre,
    required this.telefono,
    required this.relacion,
  });

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'telefono': telefono,
    'relacion': relacion,
  };

  factory ContactoEmergencia.fromMap(Map<String, dynamic>? map) =>
    ContactoEmergencia(
      nombre: map?['nombre'] ?? '',
      telefono: map?['telefono'] ?? '',
      relacion: map?['relacion'] ?? '',
    );
}

class Medicamento {
  final String nombre;
  final String dosis;
  final String frecuencia;
  final String duracion;

  Medicamento({
    required this.nombre,
    required this.dosis,
    required this.frecuencia,
    required this.duracion,
  });

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'dosis': dosis,
    'frecuencia': frecuencia,
    'duracion': duracion,
  };

  factory Medicamento.fromMap(Map<String, dynamic> map) =>
    Medicamento(
      nombre: map['nombre'] ?? '',
      dosis: map['dosis'] ?? '',
      frecuencia: map['frecuencia'] ?? '',
      duracion: map['duracion'] ?? '',
    );
}

class Paciente {
  final String id;
  final String nombre;
  final String apellido;
  final String email;
  final String telefono;
  final String fechaNacimiento;
  final int edad;
  final String genero;
  final String direccion;
  final String ciudad;
  final String numeroIdentificacion;
  final String tipoIdentificacion;
  final String alergias;
  final String condicionesPreexistentes;
  final ContactoEmergencia contactoEmergencia;
  final String estado;
  final DateTime? fechaRegistro;
  final String registradoPor;
  final DateTime? ultimaActualizacion;
  final String? actualizadoPor;
  // Nuevos campos: Servicio y Clínica
  final String? servicio;
  final String? servicioId;
  final String? clinica;
  final String? clinicaId;
  // Campos de inactivación (enfermera)
  final String? servicioRealizado;
  final String? servicioRealizadoId;
  final DateTime? fechaInactivacion;
  final String? inactivadoPor;
  final String? nombreInactivador;
  final DateTime? fechaReactivacion;
  final String? reactivadoPor;

  Paciente({
    required this.id,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.telefono,
    required this.fechaNacimiento,
    required this.edad,
    required this.genero,
    required this.direccion,
    required this.ciudad,
    required this.numeroIdentificacion,
    required this.tipoIdentificacion,
    required this.alergias,
    required this.condicionesPreexistentes,
    required this.contactoEmergencia,
    required this.estado,
    required this.registradoPor,
    this.fechaRegistro,
    this.ultimaActualizacion,
    this.actualizadoPor,
    this.servicio,
    this.servicioId,
    this.clinica,
    this.clinicaId,
    this.servicioRealizado,
    this.servicioRealizadoId,
    this.fechaInactivacion,
    this.inactivadoPor,
    this.nombreInactivador,
    this.fechaReactivacion,
    this.reactivadoPor,
  });

  String get nombreCompleto => '$nombre $apellido'.trim();

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'apellido': apellido,
    'email': email,
    'telefono': telefono,
    'fechaNacimiento': fechaNacimiento,
    'edad': edad,
    'genero': genero,
    'direccion': direccion,
    'ciudad': ciudad,
    'numeroIdentificacion': numeroIdentificacion,
    'tipoIdentificacion': tipoIdentificacion,
    'alergias': alergias,
    'condicionesPreexistentes': condicionesPreexistentes,
    'contactoEmergencia': contactoEmergencia.toMap(),
    'estado': estado,
    'registradoPor': registradoPor,
    'fechaRegistro': FieldValue.serverTimestamp(),
    'servicio': servicio ?? '',
    'servicioId': servicioId ?? '',
    'clinica': clinica ?? '',
    'clinicaId': clinicaId ?? '',
  };

  Map<String, dynamic> toUpdateMap(String actualizadoPorUid) => {
    'nombre': nombre,
    'apellido': apellido,
    'email': email,
    'telefono': telefono,
    'fechaNacimiento': fechaNacimiento,
    'edad': edad,
    'genero': genero,
    'direccion': direccion,
    'ciudad': ciudad,
    'tipoIdentificacion': tipoIdentificacion,
    'alergias': alergias,
    'condicionesPreexistentes': condicionesPreexistentes,
    'contactoEmergencia': contactoEmergencia.toMap(),
    'estado': estado,
    'ultimaActualizacion': FieldValue.serverTimestamp(),
    'actualizadoPor': actualizadoPorUid,
    'servicio': servicio ?? '',
    'servicioId': servicioId ?? '',
    'clinica': clinica ?? '',
    'clinicaId': clinicaId ?? '',
  };

  factory Paciente.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parseFecha(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      return null;
    }
    return Paciente(
      id: docId,
      nombre: map['nombre'] ?? '',
      apellido: map['apellido'] ?? '',
      email: map['email'] ?? '',
      telefono: map['telefono'] ?? '',
      fechaNacimiento: map['fechaNacimiento'] ?? '',
      edad: map['edad'] ?? 0,
      genero: map['genero'] ?? '',
      direccion: map['direccion'] ?? '',
      ciudad: map['ciudad'] ?? '',
      numeroIdentificacion: map['numeroIdentificacion'] ?? map['dpi'] ?? '',
      tipoIdentificacion: map['tipoIdentificacion'] ?? 'cédula',
      alergias: map['alergias'] is String
          ? map['alergias']
          : (map['alergias'] as List?)?.join(', ') ?? '',
      condicionesPreexistentes: map['condicionesPreexistentes'] is String
          ? map['condicionesPreexistentes']
          : (map['condicionesBase'] as List?)?.join(', ') ?? '',
      contactoEmergencia: ContactoEmergencia.fromMap(
          map['contactoEmergencia'] as Map<String, dynamic>?),
      estado: map['estado'] ?? 'activo',
      fechaRegistro: parseFecha(map['fechaRegistro'] ?? map['creadoEn']),
      registradoPor: map['registradoPor'] ?? '',
      ultimaActualizacion: parseFecha(map['ultimaActualizacion']),
      actualizadoPor: map['actualizadoPor'],
      servicio: map['servicio'],
      servicioId: map['servicioId'],
      clinica: map['clinica'],
      clinicaId: map['clinicaId'],
      servicioRealizado: map['servicioRealizado'],
      servicioRealizadoId: map['servicioRealizadoId'],
      fechaInactivacion: parseFecha(map['fechaInactivacion']),
      inactivadoPor: map['inactivadoPor'],
      nombreInactivador: map['nombreInactivador'],
      fechaReactivacion: parseFecha(map['fechaReactivacion']),
      reactivadoPor: map['reactivadoPor'],
    );
  }
}

class HistorialConsulta {
  final String id;
  final String tipo;
  final DateTime? fecha;
  final String motivo;
  final String diagnostico;
  final String tratamiento;
  final List<Medicamento> medicamentos;
  final String comentarios;
  final String doctora;
  final String doctoraUid;
  final String enfermera;
  final String enfermeraUid;
  final String creadoPor;
  final String rolCreador;
  final String? proximaCita;
  // Campos para servicios cobrados
  final List<Map<String, dynamic>> itemsCobrados;
  final double montoTotal;
  final String metodoPago;
  final String numeroVenta;
  final String ventaId;
  final String nombreSecretaria;
  final String clinica;
  // Campos para servicio realizado (enfermera)
  final String servicioRealizado;
  final String nombreEnfermera;
  final String nota;

  HistorialConsulta({
    required this.id,
    required this.tipo,
    required this.creadoPor,
    required this.rolCreador,
    this.fecha,
    this.motivo = '',
    this.diagnostico = '',
    this.tratamiento = '',
    this.medicamentos = const [],
    this.comentarios = '',
    this.doctora = '',
    this.doctoraUid = '',
    this.enfermera = '',
    this.enfermeraUid = '',
    this.proximaCita,
    this.itemsCobrados = const [],
    this.montoTotal = 0,
    this.metodoPago = '',
    this.numeroVenta = '',
    this.ventaId = '',
    this.nombreSecretaria = '',
    this.clinica = '',
    this.servicioRealizado = '',
    this.nombreEnfermera = '',
    this.nota = '',
  });

  Map<String, dynamic> toMap() => {
    'tipo': tipo,
    'fecha': FieldValue.serverTimestamp(),
    'motivo': motivo,
    'diagnostico': diagnostico,
    'tratamiento': tratamiento,
    'medicamentos': medicamentos.map((m) => m.toMap()).toList(),
    'comentarios': comentarios,
    'doctora': doctora,
    'doctora_uid': doctoraUid,
    'enfermera': enfermera,
    'enfermera_uid': enfermeraUid,
    'creadoPor': creadoPor,
    'rol_creador': rolCreador,
    'proxima_cita': proximaCita,
  };

  factory HistorialConsulta.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parseFecha(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      return null;
    }
    return HistorialConsulta(
      id: docId,
      tipo: map['tipo'] ?? 'comentario',
      fecha: parseFecha(map['fecha']),
      motivo: map['motivo'] ?? '',
      diagnostico: map['diagnostico'] ?? '',
      tratamiento: map['tratamiento'] ?? '',
      medicamentos: (map['medicamentos'] as List?)
              ?.map((m) => Medicamento.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      comentarios: map['comentarios'] ?? '',
      doctora: map['doctora'] ?? '',
      doctoraUid: map['doctora_uid'] ?? '',
      enfermera: map['enfermera'] ?? '',
      enfermeraUid: map['enfermera_uid'] ?? '',
      creadoPor: map['creadoPor'] ?? '',
      rolCreador: map['rol_creador'] ?? '',
      proximaCita: map['proxima_cita'],
      // Campos para servicios cobrados
      itemsCobrados: (map['items'] as List?)
              ?.map((i) => Map<String, dynamic>.from(i as Map))
              .toList() ??
          [],
      montoTotal: (map['montoTotal'] ?? 0).toDouble(),
      metodoPago: map['metodoPago'] ?? '',
      numeroVenta: map['numeroVenta'] ?? '',
      ventaId: map['ventaId'] ?? '',
      nombreSecretaria: map['nombreSecretaria'] ?? '',
      clinica: map['clinica'] ?? '',
      // Campos para servicio realizado (enfermera)
      servicioRealizado: map['servicio'] ?? '',
      nombreEnfermera: map['nombreEnfermera'] ?? '',
      nota: map['nota'] ?? '',
    );
  }
}

// ============================================================================
// MOCK DATA (kept for reference/fallback)
// ============================================================================

final List<Usuario> mockUsuarios = [
  Usuario(
    id: 'USU001',
    nombre: 'Dra. Vania López',
    email: 'admin@renova.gt',
    password: '1234',
    rol: RolUsuario.administradora,
    activo: true,
    avatarIniciales: 'VL',
  ),
  Usuario(
    id: 'USU002',
    nombre: 'Enf. Carmen Soto',
    email: 'carmen@renova.gt',
    password: '1234',
    rol: RolUsuario.enfermera,
    activo: true,
    avatarIniciales: 'CS',
  ),
  Usuario(
    id: 'USU003',
    nombre: 'Enf. Rosa Ajú',
    email: 'rosa@renova.gt',
    password: '1234',
    rol: RolUsuario.enfermera,
    activo: true,
    avatarIniciales: 'RA',
  ),
  Usuario(
    id: 'USU004',
    nombre: 'Terapeuta Luis Choc',
    email: 'luis@renova.gt',
    password: '1234',
    rol: RolUsuario.terapeuta,
    activo: true,
    avatarIniciales: 'LC',
  ),
  Usuario(
    id: 'USU005',
    nombre: 'Terapeuta Ana Pac',
    email: 'ana@renova.gt',
    password: '1234',
    rol: RolUsuario.terapeuta,
    activo: true,
    avatarIniciales: 'AP',
  ),
];

final List<Terapeuta> mockTerapeutas = [
  Terapeuta(
    id: 'TER001',
    nombre: 'Terapeuta Luis Choc',
    especialidad: EspecialidadTerapeuta.masajista,
    disponible: true,
    usuarioId: 'USU004',
  ),
  Terapeuta(
    id: 'TER002',
    nombre: 'Terapeuta Ana Pac',
    especialidad: EspecialidadTerapeuta.sueroterapista,
    disponible: true,
    usuarioId: 'USU005',
  ),
];

final List<Patient> mockPatients = [
  Patient(
    id: 'PAC001',
    nombre: 'María José Pérez Xol',
    expediente: 'EXP-2024-001',
    dpi: '1234567890123',
    telefono: '+502 7123-4567',
    fechaNacimiento: '1979-03-15',
    edad: 45,
    tipoSangre: 'O+',
    alergias: ['Penicilina', 'Asparténo'],
    condicionesBase: ['Hipertensión', 'Diabetes tipo 2'],
    medicamentosActuales: ['Losartán 50mg', 'Metformina 850mg'],
    registradoPor: 'USU002',
  ),
  Patient(
    id: 'PAC002',
    nombre: 'Carlos Enrique Ajú Toj',
    expediente: 'EXP-2024-002',
    dpi: '9876543210987',
    telefono: '+502 7234-5678',
    fechaNacimiento: '1962-07-22',
    edad: 62,
    tipoSangre: 'A+',
    alergias: [],
    condicionesBase: ['Hiperlipidemia'],
    medicamentosActuales: ['Atorvastatina 40mg'],
    registradoPor: 'USU003',
  ),
  Patient(
    id: 'PAC003',
    nombre: 'Luisa Fernanda Caal Pop',
    expediente: 'EXP-2024-003',
    dpi: '5555555555555',
    telefono: '+502 7345-6789',
    fechaNacimiento: '1995-11-10',
    edad: 30,
    tipoSangre: 'AB+',
    alergias: ['Látex'],
    condicionesBase: [],
    medicamentosActuales: [],
    registradoPor: 'USU002',
  ),
  Patient(
    id: 'PAC004',
    nombre: 'Jorge Luis González Morales',
    expediente: 'EXP-2024-004',
    dpi: '4444444444444',
    telefono: '+502 7456-7890',
    fechaNacimiento: '1989-05-18',
    edad: 36,
    tipoSangre: 'B-',
    alergias: [],
    condicionesBase: ['Acné severo'],
    medicamentosActuales: ['Isotretinoína'],
    registradoPor: 'USU003',
  ),
  Patient(
    id: 'PAC005',
    nombre: 'Patricia Elena Rivas López',
    expediente: 'EXP-2024-005',
    dpi: '3333333333333',
    telefono: '+502 7567-8901',
    fechaNacimiento: '1972-09-08',
    edad: 52,
    tipoSangre: 'O-',
    alergias: ['Sulfas'],
    condicionesBase: ['Fotoenvejecimiento'],
    medicamentosActuales: ['Protector solar SPF 50'],
    registradoPor: 'USU002',
  ),
  Patient(
    id: 'PAC006',
    nombre: 'Diana Margarita Cotzal Sic',
    expediente: 'EXP-2024-006',
    dpi: '2222222222222',
    telefono: '+502 7678-9012',
    fechaNacimiento: '1998-02-14',
    edad: 26,
    tipoSangre: 'AB-',
    alergias: ['Árnica'],
    condicionesBase: ['Celulitis'],
    medicamentosActuales: [],
    registradoPor: 'USU003',
  ),
];

final List<Sala> mockSalas = [
  Sala(
    id: 'SAL001',
    nombre: 'Sala de Masajes 1',
    tipo: TipoSala.sala_masajes,
    disponible: true,
  ),
  Sala(
    id: 'SAL002',
    nombre: 'Sala de Masajes 2',
    tipo: TipoSala.sala_masajes,
    disponible: true,
  ),
  Sala(
    id: 'SAL003',
    nombre: 'Jacuzzi Premium',
    tipo: TipoSala.jacuzzi,
    disponible: true,
  ),
  Sala(
    id: 'SAL004',
    nombre: 'Sala de Terapia Avanzada',
    tipo: TipoSala.sala_terapia,
    disponible: true,
  ),
  Sala(
    id: 'SAL005',
    nombre: 'Sala Estética',
    tipo: TipoSala.sala_estetica,
    disponible: true,
  ),
  Sala(
    id: 'SAL006',
    nombre: 'Sala de Sueroterapia',
    tipo: TipoSala.sala_suero,
    disponible: true,
  ),
];

final List<Appointment> mockAppointments = [
  Appointment(
    id: 'CITA001',
    pacienteId: 'PAC001',
    terapeutaId: 'TER001',
    salaId: 'SAL001',
    tipoServicio: TipoServicio.masaje,
    fecha: DateTime(2026, 5, 27),
    hora: '08:30',
    duracionMinutos: 60,
    precioBase: 350.00,
    estado: EstadoCita.confirmada,
    notas: 'Masaje relajante enfocado en cervical',
  ),
  Appointment(
    id: 'CITA002',
    pacienteId: 'PAC002',
    terapeutaId: 'TER002',
    salaId: 'SAL006',
    tipoServicio: TipoServicio.sueroterapia,
    fecha: DateTime(2026, 5, 27),
    hora: '10:00',
    duracionMinutos: 45,
    precioBase: 450.00,
    estado: EstadoCita.confirmada,
    notas: 'Sueroterapia con ácido hialurónico',
  ),
  Appointment(
    id: 'CITA003',
    pacienteId: 'PAC003',
    terapeutaId: 'TER001',
    salaId: 'SAL003',
    tipoServicio: TipoServicio.jacuzzi,
    fecha: DateTime(2026, 5, 27),
    hora: '14:30',
    duracionMinutos: 45,
    precioBase: 250.00,
    estado: EstadoCita.agendada,
    notas: null,
  ),
  Appointment(
    id: 'CITA004',
    pacienteId: 'PAC004',
    terapeutaId: 'TER002',
    salaId: 'SAL005',
    tipoServicio: TipoServicio.estetica,
    fecha: DateTime(2026, 5, 27),
    hora: '16:00',
    duracionMinutos: 60,
    precioBase: 550.00,
    estado: EstadoCita.confirmada,
    notas: 'Limpieza profunda + peeling químico',
  ),
  Appointment(
    id: 'CITA005',
    pacienteId: 'PAC005',
    terapeutaId: 'TER001',
    salaId: 'SAL004',
    tipoServicio: TipoServicio.terapia_avanzada,
    fecha: DateTime(2026, 5, 27),
    hora: '17:30',
    duracionMinutos: 90,
    precioBase: 650.00,
    estado: EstadoCita.agendada,
    notas: null,
  ),
];

final List<SesionTerapia> mockSesiones = [
  SesionTerapia(
    id: 'SESION001',
    citaId: 'CITA001',
    pacienteId: 'PAC001',
    terapeutaId: 'TER001',
    fechaHoraInicio: DateTime(2026, 5, 26, 8, 30),
    fechaHoraFin: DateTime(2026, 5, 26, 9, 30),
    observaciones: 'Paciente con tensión cervical. Responde bien al masaje.',
    tecnicasUsadas: ['Masaje sueco', 'Liberación miofascial', 'Drenaje linfático'],
    evolucion: 4,
    proximaSesionRecomendada: 'Dentro de 5 días para continuar tratamiento',
    registradaPor: 'USU004',
  ),
];

final List<PlanTratamiento> mockPlanes = [
  PlanTratamiento(
    id: 'PLAN001',
    pacienteId: 'PAC001',
    diagnostico: 'Contractura cervical crónica',
    totalSesiones: 10,
    sesionesCompletadas: 3,
    objetivo: 'Reducir tensión y mejorar movilidad cervical',
    fechaInicio: '2026-05-10',
    activo: true,
  ),
  PlanTratamiento(
    id: 'PLAN002',
    pacienteId: 'PAC002',
    diagnostico: 'Rejuvenecimiento facial integral',
    totalSesiones: 6,
    sesionesCompletadas: 1,
    objetivo: 'Mejorar apariencia y elasticidad facial',
    fechaInicio: '2026-05-20',
    activo: true,
  ),
  PlanTratamiento(
    id: 'PLAN003',
    pacienteId: 'PAC004',
    diagnostico: 'Tratamiento de acné severo',
    totalSesiones: 8,
    sesionesCompletadas: 2,
    objetivo: 'Controlar brote y mejorar textura de piel',
    fechaInicio: '2026-05-08',
    activo: true,
  ),
];
