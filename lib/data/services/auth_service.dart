import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../mock/mock_data.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Login con email y password
  Future<Usuario?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final doc = await _db.collection('usuarios').doc(uid).get();
      if (!doc.exists) return null;
      return Usuario.fromMap(doc.data()!, uid);
    } catch (e) {
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async => await _auth.signOut();

  /// Crear nuevo usuario (solo administradora)
  /// Usa una segunda instancia de FirebaseApp para no cerrar la sesión actual
  Future<Usuario?> crearUsuario({
    required String nombre,
    required String email,
    required String password,
    required RolUsuario rol,
  }) async {
    final secondaryApp = await Firebase.initializeApp(
      name: 'secondaryApp_${DateTime.now().millisecondsSinceEpoch}',
      options: Firebase.app().options,
    );
    try {
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      final iniciales = nombre.trim().split(' ')
          .take(2).map((p) => p[0].toUpperCase()).join();
      final usuario = Usuario(
        id: uid,
        nombre: nombre,
        email: email,
        password: '',
        rol: rol,
        activo: true,
        avatarIniciales: iniciales,
      );
      await _db.collection('usuarios').doc(uid).set(usuario.toMap());
      return usuario;
    } finally {
      await secondaryApp.delete();
    }
  }

  /// Desactivar/activar usuario
  Future<void> toggleUsuarioActivo(String uid, bool activo) async {
    await _db.collection('usuarios').doc(uid).update({'activo': activo});
  }

  /// Obtener usuario actual de Firestore
  Future<Usuario?> getUsuarioActual() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _db.collection('usuarios').doc(user.uid).get();
    if (!doc.exists) return null;
    return Usuario.fromMap(doc.data()!, user.uid);
  }

  /// Stream de cambios de estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
