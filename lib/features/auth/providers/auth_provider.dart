import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/mock/mock_data.dart';
import '../../../data/services/auth_service.dart';

// Provider del usuario activo (contiene el usuario completo con rol)
final usuarioActivoProvider = StateProvider<Usuario?>((ref) => null);

// Provider del estado de autenticación (basado en si hay usuario activo)
final authStateProvider = Provider<bool>((ref) {
  return ref.watch(usuarioActivoProvider) != null;
});

// Provider del rol del usuario autenticado
final authRolProvider = Provider<RolUsuario?>((ref) {
  return ref.watch(usuarioActivoProvider)?.rol;
});

// Provider de login con Firebase Auth.
// NO captura excepciones: las deja propagar para que el UI muestre
// el error correcto (FirebaseAuthException.code, red, etc.)
final loginProvider = FutureProvider.autoDispose
    .family<bool, (String, String)>((ref, args) async {
  final (email, password) = args;
  final authService = ref.read(authServiceProvider);
  final usuario = await authService.login(email, password);
  // null → doc no existe en Firestore; activo=false → desactivado
  if (usuario == null || !usuario.activo) return false;
  ref.read(usuarioActivoProvider.notifier).state = usuario;
  return true;
});

// Provider de logout con Firebase Auth
// IMPORTANTE: Invalida todos los providers para evitar listeners zombie
final logoutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    final authService = AuthService();

    // 1. Limpiar el usuario activo ANTES de signOut
    //    Esto hace que los StreamProviders que dependen de usuarioActivoProvider
    //    dejen de escuchar Firestore inmediatamente.
    ref.read(usuarioActivoProvider.notifier).state = null;

    // 2. Invalidar providers que tienen streams activos de Firestore
    //    Esto fuerza la cancelación de las suscripciones.
    ref.invalidate(usuarioActivoProvider);

    // 3. Cerrar sesión en Firebase Auth
    await authService.logout();
  };
});

// Verificar sesión activa al abrir la app
final inicializarSesionProvider = FutureProvider<void>((ref) async {
  final authService = AuthService();
  final usuario = await authService.getUsuarioActual();
  if (usuario != null && usuario.activo) {
    ref.read(usuarioActivoProvider.notifier).state = usuario;
  }
});

// Provider del servicio de auth para inyección de dependencias
final authServiceProvider = Provider((ref) => AuthService());
