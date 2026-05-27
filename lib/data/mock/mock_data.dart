// ============================================================================
// ENUMS
// ============================================================================

enum RolUsuario {
  administradora,
  enfermera,
  terapeuta,
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
}

// ============================================================================
// MODELOS
// ============================================================================

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
}

// ============================================================================
// MOCK DATA
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
