# 🚀 Comandos para Ejecutar - Sanatorio Renova

## Desarrollo Local

### 1. Setup Inicial
```bash
cd /Users/emmanuelrodriguez/Renova/renova_1
flutter pub get
flutter pub upgrade
```

### 2. Ejecutar en Emulador/Dispositivo

#### iOS
```bash
flutter run -d iOS
```

#### Android
```bash
flutter run -d Android
```

#### Web (Testing rápido)
```bash
flutter run -d chrome --web-renderer html
```

### 3. Build para Distribución

#### iOS
```bash
flutter build ios --release
# Luego abrir en Xcode: build/ios
```

#### Android
```bash
flutter build apk --release
flutter build appbundle --release
```

#### Web
```bash
flutter build web --release
# Abrir: build/web/index.html
```

---

## Desarrollo con Hot Reload

```bash
# Mantener hot reload activo
flutter run

# En la terminal:
# - Presiona 'r' para hot reload
# - Presiona 'R' para restart
# - Presiona 'q' para salir
```

---

## Testing

### Analyze
```bash
flutter analyze
```

### Lint
```bash
flutter clean
flutter pub get
flutter analyze --no-fatal-infos
```

### Run Tests (cuando existan)
```bash
flutter test
```

---

## Debugging

### Modo Debug
```bash
flutter run -d <device> --debug
```

### Modo Release
```bash
flutter run -d <device> --release
```

### DevTools
```bash
flutter pub global activate devtools
flutter pub global run devtools

# O desde la terminal durante flutter run:
# Presiona 'w' para abrir DevTools
```

---

## Limpiar Proyecto

```bash
flutter clean
flutter pub get
flutter pub cache clean
flutter doctor
```

---

## Configuración de Orientación

La app está configurada para **landscape únicamente**. Verificar en:

```dart
// lib/main.dart
SystemChrome.setPreferredOrientations([
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
])
```

---

## Credenciales Demo para Probar

```
Usuario:      admin
Contraseña:   1234
Clínica:      Cualquiera de las disponibles
```

---

## Troubleshooting

### Error: "Could not find a version that matches flutter"
```bash
flutter upgrade
flutter pub get
```

### Error: "Build failed"
```bash
flutter clean
flutter pub get
flutter pub upgrade
```

### Error: "Gradle build failed"
```bash
flutter clean
cd android
./gradlew clean
cd ..
flutter run
```

### Error: "Pods failed"
```bash
flutter clean
cd ios
rm Podfile.lock
cd ..
flutter pub get
flutter run
```

---

## IDE Setup

### Android Studio
1. Abrir proyecto
2. File → Open → Seleccionar `/Users/emmanuelrodriguez/Renova/renova_1`
3. Esperar indexación
4. Run → Flutter Run

### VS Code
1. Instalar extensión "Flutter"
2. Abrir carpeta del proyecto
3. Run → Run Without Debugging (F5)

### Xcode (iOS)
1. `open ios/Runner.xcworkspace`
2. Seleccionar scheme "Runner"
3. Seleccionar simulator/device
4. Product → Run

---

## Performance Testing

```bash
# Timeline profiling
flutter run --profile

# Memory profiling
flutter run --profile
# En DevTools: Memory tab
```

---

## Build Metrics

```bash
flutter build apk --analyze-size
flutter build web --analyze-size
```

---

**Última actualización:** 2024-05-26
