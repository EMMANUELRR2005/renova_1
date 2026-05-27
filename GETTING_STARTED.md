# 🏥 Sanatorio Renova - Sistema de Control Clínico

## Inicio Rápido

### Requisitos
- Flutter 3.12.0+
- iPad o tablet Android (orientación horizontal)
- Xcode (para iOS) o Android Studio (para Android)

### Instalación

```bash
# Clonar o navegar al proyecto
cd /Users/emmanuelrodriguez/Renova/renova_1

# Instalar dependencias
flutter pub get

# Ejecutar en dispositivo/emulador
flutter run

# Build web (para testing rápido)
flutter build web
```

### Credenciales Demo

```
Usuario: admin
Contraseña: 1234
Clínica: Seleccionar cualquiera de las disponibles
```

---

## 📱 Pantallas Disponibles

### 1. **Login** (Entrada)
- 2 paneles: branding izquierdo, formulario derecho
- Selector de clínicas
- Delay simulado 1.5s en autenticación
- Credenciales: admin/1234

### 2. **Dashboard** (Inicio)
- 4 KPI cards: hospitalizados, citas hoy, camas, alertas
- Tabla últimos ingresos con 5 pacientes
- Panel de actividad reciente con timeline

### 3. **Pacientes** (Gestión)
- Búsqueda real-time
- Filtros: Todos, Hospitalizados, En consulta, Alta
- Split view: lista + detalle con TabBar
- Info: DPI, nacimiento, teléfono, dirección, alergias, médico

### 4. **Citas** (Calendario)
- Calendario `table_calendar` interactivo
- Lista de citas por día seleccionado
- Estado visual con colores (confirmada/pendiente)
- 4 citas demo para hoy

---

## 🎨 Personalización

### Cambiar Colores
```dart
// lib/core/theme/app_theme.dart
class AppColors {
  static const Color primary = Color(0xFF1565C0);  // Modificar aquí
}
```

### Cambiar Nombre Sanatorio
```dart
// lib/core/widgets/app_shell.dart
Text('Sanatorio Renova')  // Reemplazar texto
```

### Agregar Más Pacientes
```dart
// lib/data/mock/mock_data.dart
final List<Patient> mockPatients = [
  Patient(...),
  // Agregar aquí
];
```

---

## 📐 Estructura MVC

```
lib/
├── core/          → Tema, router, widgets base
├── features/      → Pantallas (auth, dashboard, pacientes, citas)
├── data/          → Mock data + providers Riverpod
└── main.dart      → Entry point
```

---

## 🔌 Próximas Integraciones

1. **Backend:** Reemplazar mock data con API calls
2. **Auth:** JWT real en lugar de demo
3. **Notificaciones:** Push notifications
4. **Expedientes:** Módulo de documentos digitales
5. **Reportes:** Dashboard analítico

---

## ❓ Troubleshooting

**Error: "Landscape only"**
→ Dispositivo no está en orientación horizontal. Girar pantalla.

**Error: "AssetNotFound"**
→ Ejecutar `flutter pub get` nuevamente

**Error de fuentes:**
→ Ejecutar `flutter clean && flutter pub get`

---

## 📞 Soporte

Para preguntas o reportar issues, contactar al equipo de desarrollo.

---

**Versión:** 1.0.0  
**Última actualización:** 2024-05-26  
**Estado:** ✅ Compilado y navegable
