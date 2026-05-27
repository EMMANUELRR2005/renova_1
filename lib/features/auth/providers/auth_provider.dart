import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/mock/mock_data.dart';

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

// Provider de login - busca usuario en mockUsuarios por email + password
final loginProvider = FutureProvider.autoDispose.family<bool, (String, String)>((ref, args) async {
  final (email, password) = args;
  await Future.delayed(const Duration(milliseconds: 1500));

  try {
    final usuario = mockUsuarios.firstWhere(
      (u) => u.email == email && u.password == password && u.activo,
    );
    ref.read(usuarioActivoProvider.notifier).state = usuario;
    return true;
  } catch (e) {
    return false;
  }
});

// Provider de logout
final logoutProvider = Provider<void>((ref) {
  ref.read(usuarioActivoProvider.notifier).state = null;
});
