import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../data/mock/providers.dart';

class UsuariosScreen extends ConsumerWidget {
  const UsuariosScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usuarios = ref.watch(usuariosProvider);

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
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: GoogleFonts.dmSans().fontFamily,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _showNuevoUsuarioDialog(context);
                  },
                  child: const Text('+ Nuevo Usuario'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: usuarios.length,
                itemBuilder: (context, index) {
                  final usuario = usuarios[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: index < usuarios.length - 1
                          ? Border(
                              bottom: BorderSide(color: AppColors.border),
                            )
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              usuario.nombre,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              usuario.email,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontFamily: GoogleFonts.dmSans().fontFamily,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getRolColor(usuario.rol),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getRolLabel(usuario.rol),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: usuario.activo
                                    ? AppColors.successBg
                                    : AppColors.dangerBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                usuario.activo ? 'Activo' : 'Inactivo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: usuario.activo
                                      ? AppColors.success
                                      : AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: usuario.activo
                                    ? AppColors.warning
                                    : AppColors.success,
                              ),
                              child: Text(
                                usuario.activo ? 'Desactivar' : 'Activar',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRolColor(dynamic rol) {
    switch (rol.toString()) {
      case 'RolUsuario.administradora':
        return AppColors.danger;
      case 'RolUsuario.enfermera':
        return AppColors.primary;
      case 'RolUsuario.terapeuta':
        return AppColors.clinicalGreen;
      default:
        return AppColors.neutral;
    }
  }

  String _getRolLabel(dynamic rol) {
    switch (rol.toString()) {
      case 'RolUsuario.administradora':
        return 'Administradora';
      case 'RolUsuario.enfermera':
        return 'Enfermera';
      case 'RolUsuario.terapeuta':
        return 'Terapeuta';
      default:
        return 'Sin rol';
    }
  }

  void _showNuevoUsuarioDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Nombre completo',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Rol',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'administradora',
                  child: Text('Administradora'),
                ),
                DropdownMenuItem(
                  value: 'enfermera',
                  child: Text('Enfermera'),
                ),
                DropdownMenuItem(
                  value: 'terapeuta',
                  child: Text('Terapeuta'),
                ),
              ],
              onChanged: (value) {},
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Contraseña',
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Usuario creado')),
              );
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }
}
