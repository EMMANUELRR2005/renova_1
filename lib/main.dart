import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io' show Platform;

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/seed_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Limpiar caché local corrupto de Firestore (problema conocido con SPM + Firebase iOS SDK 11.x)
  try {
    await FirebaseFirestore.instance.clearPersistence();
    print('✅ [Main] Caché Firestore limpiada');
  } catch (e) {
    print('⚠️ [Main] clearPersistence: $e');
  }

  // Seed en background — no bloquea el arranque aunque Firestore tarde
  SeedService().seedTodo().catchError((e) {
    // ignore: avoid_print
    print('⚠️ [Main] Seed falló pero la app continúa: $e');
  });

  // Bloquear orientación a landscape (solo en mobile/desktop real)
  try {
    if (Platform.isAndroid || Platform.isIOS) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  } catch (_) {
    // Si falla (ej: en web), continuar sin error
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
