import '../../data/mock/mock_data.dart';

class Permisos {
  static bool puedeVerFinanzas(RolUsuario? rol) =>
      rol == RolUsuario.administradora;

  static bool puedeEliminar(RolUsuario? rol) =>
      rol == RolUsuario.administradora;

  static bool puedeVerExpedientes(RolUsuario? rol) =>
      rol == RolUsuario.administradora || rol == RolUsuario.enfermera;

  static bool puedeRegistrarNotas(RolUsuario? rol) => rol != null;

  static bool puedeAgendarCitas(RolUsuario? rol) =>
      rol == RolUsuario.administradora ||
      rol == RolUsuario.enfermera ||
      rol == RolUsuario.secretaria_recepcion;

  // Gestión de pacientes (crear/editar datos): solo secretaria_recepcion
  static bool puedeCrearPacientes(RolUsuario? rol) =>
      rol == RolUsuario.secretaria_recepcion;

  static bool puedeEditarPacientes(RolUsuario? rol) =>
      rol == RolUsuario.secretaria_recepcion;

  // Ver lista y detalle: todos excepto terapeuta
  static bool puedeVerListaPacientes(RolUsuario? rol) =>
      rol == RolUsuario.administradora ||
      rol == RolUsuario.enfermera ||
      rol == RolUsuario.secretaria_recepcion ||
      rol == RolUsuario.doctora;

  // Agregar comentarios/notas: solo secretaria_recepcion
  static bool puedeAgregarComentarios(RolUsuario? rol) =>
      rol == RolUsuario.secretaria_recepcion;

  // Crear consultas médicas: doctora y enfermera
  static bool puedeCrearConsultas(RolUsuario? rol) =>
      rol == RolUsuario.doctora || rol == RolUsuario.enfermera;

  static bool puedeVerReportes(RolUsuario? rol) =>
      rol == RolUsuario.administradora;

  static bool puedeGestionarUsuarios(RolUsuario? rol) =>
      rol == RolUsuario.administradora;

  static bool puedeAccederCaja(RolUsuario? rol) =>
      rol == RolUsuario.administradora;

  static bool puedeModificarPrecios(RolUsuario? rol) =>
      rol == RolUsuario.administradora;

  static bool puedeVerDashboard(RolUsuario? rol) =>
      rol == RolUsuario.administradora;

  static bool puedeVerAgendaTerapeuta(RolUsuario? rol) =>
      rol == RolUsuario.terapeuta;

  static bool puedeVerCitas(RolUsuario? rol) =>
      rol == RolUsuario.administradora ||
      rol == RolUsuario.enfermera ||
      rol == RolUsuario.secretaria_recepcion;

  // Cambiar estado del paciente: SOLO enfermera
  static bool puedeCambiarEstadoPaciente(RolUsuario? rol) =>
      rol == RolUsuario.enfermera;

  // Gestionar citas: secretaria y administradora
  static bool puedeGestionarCitas(RolUsuario? rol) =>
      rol == RolUsuario.secretaria_recepcion ||
      rol == RolUsuario.administradora;

  // Crear citas: solo secretaria
  static bool puedeCrearCitas(RolUsuario? rol) =>
      rol == RolUsuario.secretaria_recepcion;

  // Ver citas asignadas (doctora ve solo las suyas)
  static bool puedeVerCitasAsignadas(RolUsuario? rol) =>
      rol == RolUsuario.doctora;
}
