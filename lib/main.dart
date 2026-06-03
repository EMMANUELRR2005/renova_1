import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/auth_service.dart';
import 'data/services/seed_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Pantalla completa: ocultar barra de estado y navegación (tablets iOS/Android)
  if (!kIsWeb) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF1E3A5F),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  // Inicializar datos de localización para fechas en español
  await initializeDateFormatting('es', null);

  // Limpiar caché local corrupto de Firestore (solo en mobile, no en web)
  if (!kIsWeb) {
    try {
      await FirebaseFirestore.instance.clearPersistence();
      print('✅ [Main] Caché Firestore limpiada');
    } catch (e) {
      print('⚠️ [Main] clearPersistence: $e');
    }
  }

  // Seed en background — no bloquea el arranque aunque Firestore tarde
  SeedService().seedTodo().catchError((e) {
    print('⚠️ [Main] Seed falló pero la app continúa: $e');
  });

  // Bloquear orientación a landscape (solo en mobile, no en web)
  if (!kIsWeb) {
    try {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } catch (_) {}
  }

  // Restaurar sesión activa: si el usuario solo "salió" de la app (sin cerrar
  // sesión), FirebaseAuth conserva su sesión y entramos directo al sistema.
  final usuarioInicial = await AuthService()
      .getUsuarioActual()
      .timeout(const Duration(seconds: 5))
      .then((u) => (u != null && u.activo) ? u : null)
      .catchError((_) => null);

  runApp(ProviderScope(
    overrides: [
      if (usuarioInicial != null)
        usuarioActivoProvider.overrideWith((ref) => usuarioInicial),
    ],
    child: const MainApp(),
  ));
}


class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reafirmar pantalla completa (immersiveSticky se reactiva tras gestos).
    if (!kIsWeb) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }

    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Renova',
      theme: AppTheme.lightTheme,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
