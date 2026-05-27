import '../../data/mock/mock_data.dart';

class Permisos {
  /// Administradora puede ver finanzas, cobros y reportes
  static bool puedeVerFinanzas(RolUsuario? rol) {
    return rol == RolUsuario.administradora;
  }

  /// Solo administradora puede eliminar pacientes, usuarios o citas
  static bool puedeEliminar(RolUsuario? rol) {
    return rol == RolUsuario.administradora;
  }

  /// Administradora y enfermera pueden ver expedientes de pacientes
  static bool puedeVerExpedientes(RolUsuario? rol) {
    return rol == RolUsuario.administradora || rol == RolUsuario.enfermera;
  }

  /// Todos menos administradora pueden registrar notas de sesión
  /// Administradora también puede registrar notas
  static bool puedeRegistrarNotas(RolUsuario? rol) {
    return rol != null;
  }

  /// Administradora y enfermera pueden agendar citas
  static bool puedeAgendarCitas(RolUsuario? rol) {
    return rol == RolUsuario.administradora || rol == RolUsuario.enfermera;
  }

  /// Administradora y enfermera pueden crear pacientes
  static bool puedeCrearPacientes(RolUsuario? rol) {
    return rol == RolUsuario.administradora || rol == RolUsuario.enfermera;
  }

  /// Solo administradora puede ver reportes y estadísticas
  static bool puedeVerReportes(RolUsuario? rol) {
    return rol == RolUsuario.administradora;
  }

  /// Solo administradora puede gestionar usuarios
  static bool puedeGestionarUsuarios(RolUsuario? rol) {
    return rol == RolUsuario.administradora;
  }

  /// Solo administradora puede acceder a la caja (cobros)
  static bool puedeAccederCaja(RolUsuario? rol) {
    return rol == RolUsuario.administradora;
  }

  /// Solo administradora puede ver y modificar precios
  static bool puedeModificarPrecios(RolUsuario? rol) {
    return rol == RolUsuario.administradora;
  }

  /// Todos los roles autenticados pueden ver dashboard según su rol
  static bool puedeVerDashboard(RolUsuario? rol) {
    return rol == RolUsuario.administradora;
  }

  /// Solo terapeuta puede ver su propia agenda
  static bool puedeVerAgendaTerapeuta(RolUsuario? rol) {
    return rol == RolUsuario.terapeuta;
  }

  /// Administradora y enfermera pueden ver lista de pacientes
  static bool puedeVerListaPacientes(RolUsuario? rol) {
    return rol == RolUsuario.administradora || rol == RolUsuario.enfermera;
  }

  /// Administradora y enfermera pueden ver citas
  static bool puedeVerCitas(RolUsuario? rol) {
    return rol == RolUsuario.administradora || rol == RolUsuario.enfermera;
  }
}
