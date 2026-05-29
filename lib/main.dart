import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/seed_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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

  runApp(const ProviderScope(child: MainApp()));
}


class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Renova',
      theme: AppTheme.lightTheme,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
