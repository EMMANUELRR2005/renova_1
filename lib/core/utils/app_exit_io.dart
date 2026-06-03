import 'dart:io';

/// Cierra la aplicación por completo (mantiene la sesión de Firebase activa).
///
/// Se usa `exit(0)` en Android e iOS porque cierra el proceso de forma fiable
/// aun con un `PopScope(canPop: false)` en la raíz, que hace que
/// `SystemNavigator.pop()` sea ignorado. En Android la app se cierra; en iOS
/// el sistema la termina (Apple lo desaconseja pero es la única vía).
void salirDeApp() {
  exit(0);
}
