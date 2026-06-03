// Fachada multiplataforma para cerrar la aplicación.
//
// En móvil/desktop usa `dart:io` (exit), que cierra el proceso de forma
// fiable incluso cuando hay un PopScope(canPop:false) en la raíz (que bloquea
// SystemNavigator.pop). En web cae al stub seguro.
export 'app_exit_web.dart' if (dart.library.io) 'app_exit_io.dart';
