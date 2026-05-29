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

  // Garantizar que existan servicios y clínicas (independiente del seed principal)
  _seedServiciosYClinicas().catchError((e) {
    print('⚠️ [Main] Seed servicios/clínicas falló: $e');
  });

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

/// Crea servicios y clínicas si no existen.
/// Se ejecuta independientemente del seed principal.
Future<void> _seedServiciosYClinicas() async {
  final db = FirebaseFirestore.instance;

  // ─── Servicios ────────────────────────────────────────────────────────────
  final serviciosSnap = await db.collection('servicios').limit(1).get();
  if (serviciosSnap.docs.isEmpty) {
    print('🌱 [Main] Creando servicios...');
    final servicios = [
      {'nombre': 'Clínica General', 'descripcion': 'Consultas médicas generales'},
      {'nombre': 'Pediatría', 'descripcion': 'Atención especializada para niños'},
      {'nombre': 'Ginecología', 'descripcion': 'Salud femenina y obstetricia'},
      {'nombre': 'Odontología', 'descripcion': 'Salud dental y bucal'},
      {'nombre': 'Nutrición', 'descripcion': 'Planes alimenticios y control de peso'},
      {'nombre': 'Dermatología', 'descripcion': 'Cuidado de la piel'},
      {'nombre': 'Estética', 'descripcion': 'Tratamientos estéticos y belleza'},
    ];
    for (final s in servicios) {
      await db.collection('servicios').add({
        'nombre': s['nombre'],
        'descripcion': s['descripcion'],
        'activo': true,
      });
    }
    print('✅ [Main] ${servicios.length} servicios creados');
  } else {
    print('✅ [Main] Servicios ya existen (${serviciosSnap.docs.length}+)');
  }

  // ─── Clínicas ─────────────────────────────────────────────────────────────
  final clinicasSnap = await db.collection('clinicas').limit(1).get();
  if (clinicasSnap.docs.isEmpty) {
    print('🌱 [Main] Creando clínicas...');
    final clinicas = [
      {'nombre': 'Clínica Renova Central', 'direccion': 'Av. Principal 123, Zona 1'},
      {'nombre': 'Clínica Renova Norte', 'direccion': 'Blvd. del Norte 456, Zona 17'},
      {'nombre': 'Clínica Renova Sur', 'direccion': 'Calzada Sur 789, Zona 12'},
    ];
    for (final c in clinicas) {
      await db.collection('clinicas').add({
        'nombre': c['nombre'],
        'direccion': c['direccion'],
        'activo': true,
      });
    }
    print('✅ [Main] ${clinicas.length} clínicas creadas');
  } else {
    print('✅ [Main] Clínicas ya existen (${clinicasSnap.docs.length}+)');
  }
}
