import 'package:flutter/services.dart';

/// En web no se puede "cerrar" la app; se intenta el comportamiento estándar.
void salirDeApp() {
  SystemNavigator.pop();
}
