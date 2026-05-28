import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/mock/mock_data.dart';
import 'providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ref.read(loginProvider((_emailController.text, _passwordController.text)).future);
      
      if (result) {
        // Invalidar router para que reacte al cambio
        ref.invalidate(goRouterProvider);
        
        if (mounted) {
          final usuario = ref.read(usuarioActivoProvider);
          if (usuario != null) {
            await Future.delayed(const Duration(milliseconds: 300));
            if (mounted) {
              context.go(_getRutaInicial(usuario.rol));
            }
          }
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Credenciales inválidas o usuario desactivado'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String mensajeError = 'Error al iniciar sesión';
        
        if (e.toString().contains('user-not-found')) {
          mensajeError = 'Usuario no encontrado';
        } else if (e.toString().contains('wrong-password')) {
          mensajeError = 'Contraseña incorrecta';
        } else if (e.toString().contains('user-disabled')) {
          mensajeError = 'Usuario desactivado';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeError),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  String _getRutaInicial(RolUsuario rol) {
    switch (rol) {
      case RolUsuario.administradora:
        return '/dashboard';
      case RolUsuario.enfermera:
        return '/pacientes';
      case RolUsuario.terapeuta:
        return '/agenda-terapeuta';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      body: Row(
        children: [
          // LEFT PANEL - #0D2B4E
          Expanded(
            flex: 45,
            child: Container(
              color: AppColors.primaryDark,
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        '✨',
                        style: TextStyle(
                          fontSize: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Nombre clínica
                  Text(
                    'Clínica\nRenova',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: GoogleFonts.dmSans().fontFamily,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Slogan
                  Text(
                    'Belleza y Bienestar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textTertiary,
                      fontFamily: GoogleFonts.dmSans().fontFamily,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Características
                  ...[
                    ('✓', 'Gestión de pacientes'),
                    ('✓', 'Control de citas'),
                    ('✓', 'Expedientes digitales'),
                  ]
                      .map(
                        (feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              Text(
                                feature.$1,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: AppColors.clinicalGreen,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  feature.$2,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                    fontFamily: GoogleFonts.dmSans().fontFamily,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ),
          // RIGHT PANEL - #FFFFFF
          Expanded(
            flex: 55,
            child: Container(
              color: AppColors.topbar,
              padding: const EdgeInsets.all(60),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bienvenido
                      Text(
                        'Bienvenido',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: GoogleFonts.dmSans().fontFamily,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Inicia sesión en tu cuenta',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                          fontFamily: GoogleFonts.dmSans().fontFamily,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Email
                      AppTextField(
                        label: 'Email',
                        hintText: 'admin@renova.gt',
                        controller: _emailController,
                        icon: '✉️',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      // Contraseña
                      AppTextField(
                        label: 'Contraseña',
                        hintText: '••••••••',
                        controller: _passwordController,
                        icon: '🔒',
                        obscureText: true,
                      ),
                      const SizedBox(height: 32),
                      // Botón login
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Iniciar sesión',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily:
                                        GoogleFonts.dmSans().fontFamily,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Credenciales demo
                      Center(
                        child: Text(
                          'Prueba con:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontFamily: GoogleFonts.dmSans().fontFamily,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCredentialDemo('Admin', 'admin@renova.gt', 'renova2024'),
                      _buildCredentialDemo('Enfermera', 'carmen@renova.gt', 'renova2024'),
                      _buildCredentialDemo('Terapeuta', 'luis@renova.gt', 'renova2024'),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'v1.0.0 - Renova Clínica',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textDisabled,
                            fontFamily: GoogleFonts.dmSans().fontFamily,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialDemo(String role, String email, String password) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.bgGeneral,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(
              role,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: GoogleFonts.dmSans().fontFamily,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$email / $password',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  fontFamily: GoogleFonts.dmSans().fontFamily,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () {
                _emailController.text = email;
                _passwordController.text = password;
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              ),
              child: const Text('Usar', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}
