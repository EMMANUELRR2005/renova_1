import 'package:cloud_firestore/cloud_firestore.dart';
import '../mock/mock_data.dart';

class UsuarioService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream de todos los usuarios (solo administradora)
  Stream<List<Usuario>> getUsuarios() {
    return _db.collection('usuarios')
        .orderBy('nombre')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Usuario.fromMap(d.data(), d.id))
            .toList());
  }

  /// Modificar datos de usuario
  Future<void> modificarUsuario(String id, Map<String, dynamic> datos) async {
    await _db.collection('usuarios').doc(id).update(datos);
  }
}
