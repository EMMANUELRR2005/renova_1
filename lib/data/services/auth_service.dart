import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../mock/mock_data.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Usuario?> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    // Retry automático si Firestore está temporalmente no disponible
    final doc = await _withRetry(() => _db.collection('usuarios').doc(uid).get());
    if (!doc.exists) return null;
    return Usuario.fromMap(doc.data()!, uid);
  }

  /// Reintenta UNA vez ante `unavailable` (cold-start de Firebase).
  /// No más — si falla 2 veces, el problema es real y hay que reportarlo.
  Future<T> _withRetry<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on FirebaseException catch (e) {
      // `unavailable`: cold-start de Firestore.
      // `permission-denied`: carrera de arranque en la que el token de auth aún
      //   no llegó a Firestore. En ambos casos un reintento corto lo resuelve.
      if (e.code != 'unavailable' && e.code != 'permission-denied') rethrow;
      print('⚠️ [Auth] Firestore ${e.code} — reintentando en 1.5s...');
      await Future.delayed(const Duration(milliseconds: 1500));
      return await op(); // segundo intento, sin más
    }
  }

  Future<void> logout() async => await _auth.signOut();

  /// Crear nuevo usuario sin cerrar sesión del admin.
  /// Usa secondary app para aislar el Auth del nuevo usuario.
  Future<Usuario?> crearUsuario({
    required String nombre,
    required String email,
    required String password,
    required RolUsuario rol,
  }) async {
    FirebaseApp? secondaryApp;

    try {
      // ── Paso 1: inicializar app secundaria ─────────────────────────────
      print('🔵 [Auth] Inicializando app secundaria...');
      secondaryApp = await Firebase.initializeApp(
        name: 'secondaryApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      print('✅ [Auth] App secundaria lista');

      // ── Paso 2: crear usuario en Firebase Auth ─────────────────────────
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      print('🔵 [Auth] Creando usuario en Firebase Auth: $email');
      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = credential.user!.uid;
      print('✅ [Auth] Usuario creado en Auth — UID: $uid');

      // ── Paso 3: cerrar sesión del nuevo usuario en la app secundaria ────
      // CRÍTICO: liberar la sesión ANTES de delete() para evitar cuelgue.
      print('🔵 [Auth] Cerrando sesión de app secundaria...');
      await secondaryAuth.signOut();
      print('✅ [Auth] Sesión secundaria cerrada');

      // ── Paso 4: guardar en Firestore (usando sesión admin activa) ───────
      final iniciales = nombre.trim().split(' ')
          .take(2)
          .map((p) => p[0].toUpperCase())
          .join();

      final usuario = Usuario(
        id: uid,
        nombre: nombre,
        email: email,
        password: '',
        rol: rol,
        activo: true,
        avatarIniciales: iniciales,
      );

      print('🔵 [Auth] Guardando en Firestore...');
      await _db
          .collection('usuarios')
          .doc(uid)
          .set(usuario.toMap())
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
          'Firestore no respondió en 15s. '
          'Ve a Firebase Console → Firestore Rules y verifica que permita escrituras.',
        ),
      );
      print('✅ [Auth] Guardado en Firestore — rol: ${rol.name}');

      return usuario;

    } finally {
      // ── Limpieza: eliminar app secundaria con timeout ──────────────────
      // No usamos await sin timeout: si delete() se cuelga no bloqueamos.
      if (secondaryApp != null) {
        try {
          await secondaryApp.delete().timeout(const Duration(seconds: 5));
          print('✅ [Auth] App secundaria eliminada');
        } catch (_) {
          // Ignorar errores de limpieza — no afectan el resultado.
          print('⚠️ [Auth] No se pudo eliminar app secundaria (ignorado)');
        }
      }
    }
  }

  Future<void> toggleUsuarioActivo(String uid, bool activo) async {
    await _db.collection('usuarios').doc(uid).update({'activo': activo});
  }

  Future<Usuario?> getUsuarioActual() async {
    // En el arranque en frío `currentUser` puede ser null momentáneamente
    // mientras Firebase Auth restaura la sesión persistida. Esperamos al primer
    // evento de authStateChanges para conocer el estado real.
    User? user = _auth.currentUser ?? await _auth.authStateChanges().first;
    if (user == null) {
      print('🔵 [Auth] Sin sesión persistida al arrancar');
      return null;
    }

    // CLAVE: forzar que el ID token esté disponible y propagado ANTES de leer
    // Firestore. Sin esto, una lectura inmediata en el arranque puede fallar con
    // permission-denied porque Firestore aún no recibió el token de auth.
    try {
      await user.getIdToken();
    } catch (e) {
      print('⚠️ [Auth] No se pudo obtener idToken: $e');
    }

    final uid = user.uid;
    print('🔵 [Auth] Sesión restaurada: $uid (${user.email})');

    final doc = await _withRetry(
        () => _db.collection('usuarios').doc(uid).get());
    if (!doc.exists) {
      print('❌ [Auth] El documento usuarios/$uid no existe');
      return null;
    }
    return Usuario.fromMap(doc.data()!, uid);
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
