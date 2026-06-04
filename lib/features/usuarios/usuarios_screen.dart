import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/widgets_comunes.dart';
import '../../data/mock/mock_data.dart';
import '../../data/mock/providers.dart' hide authServiceProvider;
import '../../features/auth/providers/auth_provider.dart';

class UsuariosScreen extends ConsumerWidget {
  const UsuariosScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuariosAsync = ref.watch(usuariosStreamProvider);

    return AppShell(
      selectedIndex: 6,
      onNavigate: (index) {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gestión de Usuarios',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontFamily: GoogleFonts.dmSans().fontFamily,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showNuevoUsuarioDialog(context, ref),
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Nuevo Usuario'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            usuariosAsync.when(
              loading: () => Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: kSombraSuave,
                ),
                padding: const EdgeInsets.all(16),
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: kSombraSuave,
                ),
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Error cargando usuarios: $error',
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ),
              data: (usuarios) {
                final usuarioActual = ref.watch(usuarioActivoProvider);
                final totalAdmins = usuarios
                    .where((u) => u.rol == RolUsuario.administradora)
                    .length;
                return Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: kSombraSuave,
                ),
                clipBehavior: Clip.antiAlias,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: usuarios.length,
                  itemBuilder: (context, index) {
                    final usuario = usuarios[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: index < usuarios.length - 1
                            ? Border(bottom: BorderSide(color: AppColors.border))
                            : null,
                      ),
                      child: Row(
                        children: [
                          // Avatar con iniciales
                          CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                _getRolColor(usuario.rol).withValues(alpha: 0.12),
                            child: Text(
                              usuario.avatarIniciales.isNotEmpty
                                  ? usuario.avatarIniciales
                                  : (usuario.nombre.isNotEmpty
                                      ? usuario.nombre[0].toUpperCase()
                                      : 'U'),
                              style: TextStyle(
                                color: _getRolColor(usuario.rol),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  usuario.nombre,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  usuario.email,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _getRolColor(usuario.rol)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _getRolLabel(usuario.rol),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _getRolColor(usuario.rol),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              buildBadgeEstado(
                                  usuario.activo ? 'activo' : 'inactivo'),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () => _toggleUsuario(
                                    context, ref, usuario.id, !usuario.activo),
                                icon: Icon(
                                  usuario.activo
                                      ? Icons.block
                                      : Icons.check_circle_outline,
                                  size: 16,
                                ),
                                label: Text(
                                  usuario.activo ? 'Desactivar' : 'Activar',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: usuario.activo
                                      ? AppColors.warning
                                      : AppColors.success,
                                  side: BorderSide(
                                      color: usuario.activo
                                          ? AppColors.warning
                                          : AppColors.success),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                          if (usuarioActual != null &&
                              usuario.id != usuarioActual.id) ...[
                            const SizedBox(width: 4),
                            IconButton(
                              onPressed: () => _confirmarEliminarUsuario(
                                context,
                                ref,
                                usuario,
                                esUltimoAdmin:
                                    usuario.rol == RolUsuario.administradora &&
                                        totalAdmins <= 1,
                              ),
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.danger, size: 20),
                              tooltip: 'Eliminar usuario',
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Eliminar usuario ────────────────────────────────────────────────────

  Future<void> _confirmarEliminarUsuario(
    BuildContext context,
    WidgetRef ref,
    Usuario usuario, {
    required bool esUltimoAdmin,
  }) async {
    if (esUltimoAdmin) {
      mostrarSnackbar(context,
          'No puedes eliminar al último administrador del sistema.',
          tipo: TipoMensaje.advertencia);
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.danger),
            SizedBox(width: 8),
            Expanded(child: Text('Eliminar usuario')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Eliminar a "${usuario.nombre}"?',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Email: ${usuario.email}\nRol: ${_getRolLabel(usuario.rol)}',
                style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Esta acción elimina el usuario de Firestore y bloquea su '
              'acceso. No se puede deshacer.',
              style: TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete, color: Colors.white, size: 16),
            label: const Text('Sí, eliminar',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      await ref.read(authServiceProvider).eliminarUsuario(usuario.id);
      if (context.mounted) {
        mostrarSnackbar(context, 'Usuario ${usuario.nombre} eliminado',
            tipo: TipoMensaje.exito);
      }
    } catch (e) {
      if (context.mounted) {
        mostrarSnackbar(context, 'Error: $e', tipo: TipoMensaje.error);
      }
    }
  }

  Future<void> _toggleUsuario(
      BuildContext context, WidgetRef ref, String uid, bool nuevoEstado) async {
    try {
      final service = ref.read(authServiceProvider);
      await service.toggleUsuarioActivo(uid, nuevoEstado);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                nuevoEstado ? 'Usuario activado' : 'Usuario desactivado'),
            backgroundColor:
                nuevoEstado ? AppColors.success : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showNuevoUsuarioDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _NuevoUsuarioDialog(ref: ref),
    );
  }

  // ── Helpers para lista ─────────────────────────────────────────────────────

  Color _getRolColor(RolUsuario rol) {
    switch (rol) {
      case RolUsuario.administradora:
        return AppColors.danger;
      case RolUsuario.doctora:
        return const Color(0xFF6A1B9A);
      case RolUsuario.enfermera:
        return AppColors.primary;
      case RolUsuario.secretaria_recepcion:
        return AppColors.clinicalGreen;
      case RolUsuario.terapeuta:
        return const Color(0xFF00838F);
      case RolUsuario.farmaceutica:
        return const Color(0xFF00796B);
      case RolUsuario.boutique:
        return const Color(0xFFC9A96E);
    }
  }

  String _getRolLabel(RolUsuario rol) {
    switch (rol) {
      case RolUsuario.administradora:
        return 'Administradora';
      case RolUsuario.doctora:
        return 'Doctora';
      case RolUsuario.enfermera:
        return 'Enfermera';
      case RolUsuario.secretaria_recepcion:
        return 'Secretaria';
      case RolUsuario.terapeuta:
        return 'Terapeuta';
      case RolUsuario.farmaceutica:
        return 'Farmacéutica';
      case RolUsuario.boutique:
        return 'Boutique';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DIALOG: Nuevo Usuario — StatefulWidget con lógica real
// ═══════════════════════════════════════════════════════════════════════════

class _NuevoUsuarioDialog extends StatefulWidget {
  final WidgetRef ref;
  const _NuevoUsuarioDialog({required this.ref});

  @override
  State<_NuevoUsuarioDialog> createState() => _NuevoUsuarioDialogState();
}

class _NuevoUsuarioDialogState extends State<_NuevoUsuarioDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // Roles disponibles para crear (excluyendo terapeuta — se gestiona aparte)
  static const _rolesCreables = [
    (RolUsuario.administradora, 'Administradora'),
    (RolUsuario.doctora, 'Doctora'),
    (RolUsuario.enfermera, 'Enfermera'),
    (RolUsuario.secretaria_recepcion, 'Secretaria de Recepción'),
    (RolUsuario.farmaceutica, 'Farmacéutica'),
    (RolUsuario.boutique, 'Boutique'),
  ];

  RolUsuario _rolSeleccionado = RolUsuario.enfermera;
  bool _guardando = false;
  bool _mostrarPassword = false;
  String? _errorMsg;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
      _errorMsg = null;
    });

    print('🔵 Iniciando creación de usuario: ${_emailCtrl.text.trim()}');

    try {
      final authService = widget.ref.read(authServiceProvider);

      print('🔵 Llamando crearUsuario en AuthService...');

      // Timeout de 40s para que el spinner nunca quede infinito
      final usuario = await authService
          .crearUsuario(
            nombre: _nombreCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            rol: _rolSeleccionado,
          )
          .timeout(const Duration(seconds: 40));

      if (usuario != null) {
        print('✅ Usuario creado — UID: ${usuario.id} / rol: ${usuario.rol.name}');
        if (mounted) {
          // ① Snackbar PRIMERO — contexto aún vivo dentro del dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Usuario "${usuario.nombre}" creado exitosamente'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 3),
            ),
          );
          // ② Cerrar modal DESPUÉS — el contexto del dialog ya no se necesita
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) setState(() => _errorMsg = 'No se pudo crear el usuario.');
      }

    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuth: ${e.code} — ${e.message}');
      if (mounted) setState(() => _errorMsg = _mapAuthError(e.code));

    } on FirebaseException catch (e) {
      print('❌ Firestore: ${e.code} — ${e.message}');
      if (mounted) {
        setState(() => _errorMsg = 'Error de base de datos: ${e.message ?? e.code}');
      }

    } on TimeoutException {
      print('❌ Timeout: la operación tardó más de 40 segundos');
      if (mounted) {
        setState(() => _errorMsg =
            'Tiempo de espera agotado. Verifica tu conexión a internet.');
      }

    } catch (e) {
      print('❌ Error desconocido: $e');
      if (mounted) setState(() => _errorMsg = 'Error inesperado: $e');

    } finally {
      // Garantizado: el spinner SIEMPRE se detiene
      if (mounted) setState(() => _guardando = false);
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Ese email ya está registrado.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'invalid-email':
        return 'El formato del email no es válido.';
      case 'operation-not-allowed':
        return 'Operación no permitida. Verifica la configuración de Firebase.';
      case 'network-request-failed':
        return 'Sin conexión a internet. Intenta de nuevo.';
      default:
        return 'Error de autenticación ($code).';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Nuevo Usuario',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: GoogleFonts.dmSans().fontFamily,
        ),
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error banner
              if (_errorMsg != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.danger),
                  ),
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(
                        color: AppColors.danger, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Nombre
              TextFormField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo *',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo requerido'
                    : null,
              ),
              const SizedBox(height: 12),
              // Email
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(labelText: 'Email *'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.\w+$')
                      .hasMatch(v.trim())) {
                    return 'Email inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              // Rol
              DropdownButtonFormField<RolUsuario>(
                value: _rolSeleccionado,
                decoration:
                    const InputDecoration(labelText: 'Rol *'),
                items: _rolesCreables
                    .map((entry) => DropdownMenuItem(
                          value: entry.$1,
                          child: Text(entry.$2),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _rolSeleccionado = v);
                },
              ),
              const SizedBox(height: 12),
              // Password
              TextFormField(
                controller: _passwordCtrl,
                obscureText: !_mostrarPassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña *',
                  suffixIcon: IconButton(
                    icon: Icon(_mostrarPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () => setState(
                        () => _mostrarPassword = !_mostrarPassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerida';
                  if (v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardando ? null : _crear,
          child: _guardando
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Crear Usuario'),
        ),
      ],
    );
  }
}
