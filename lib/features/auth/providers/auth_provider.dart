import 'package:flutter_riverpod/flutter_riverpod.dart';

class User {
  final String username;
  final String clinic;

  User({required this.username, required this.clinic});
}

// Auth state provider - cambiar a StateNotifier para mejor control
class AuthNotifier extends StateNotifier<bool> {
  AuthNotifier() : super(false);

  Future<bool> login(String username, String password, String clinic) async {
    // Simulación de login con delay
    await Future.delayed(const Duration(milliseconds: 1500));

    // Credenciales demo
    if (username == 'admin' && password == '1234') {
      state = true;
      return true;
    }

    return false;
  }

  void logout() {
    state = false;
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, bool>((ref) {
  return AuthNotifier();
});

// Current user provider
final currentUserProvider = StateProvider<User?>((ref) {
  return null;
});

// Logout provider
final logoutProvider = FutureProvider.autoDispose<void>((ref) async {
  ref.read(authStateProvider.notifier).logout();
  ref.read(currentUserProvider.notifier).state = null;
});
