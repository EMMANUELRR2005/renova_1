import 'package:firebase_auth/firebase_auth.dart';
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
  bool _emailError = false;
  bool _passwordError = false;

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

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Por favor completa todos los campos');
      return;
    }

    setState(() {
      _isLoading = true;
      _emailError = false;
      _passwordError = false;
    });

    try {
      final result = await ref
          .read(loginProvider((_emailController.text.trim(), _passwordController.text)).future);

      if (result) {
        if (mounted) {
          final usuario = ref.read(usuarioActivoProvider);
          if (usuario != null) {
            // Pequeño delay para que el router detecte el cambio de auth state
            await Future.delayed(const Duration(milliseconds: 200));
            if (mounted) context.go(_getRutaInicial(usuario.rol));
          } else {
            // Usuario autenticado en Firebase pero sin doc en Firestore
            setState(() => _isLoading = false);
            _showError('Cuenta no configurada. Contacta al administrador.');
          }
        }
      } else {
        // login() devolvió null (doc no existe) o activo=false
        if (mounted) {
          setState(() => _isLoading = false);
          _showError('Cuenta desactivada o no configurada.');
        }
      }

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _mostrarErrorAuth(e.code);
      }
    } on FirebaseException catch (e) {
      // Firestore errors: unavailable, permission-denied, etc.
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(_mapFirestoreError(e.code));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error inesperado: ${e.toString()}');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  String _mapFirestoreError(String code) {
    switch (code) {
      case 'unavailable':
        return 'Servicio temporalmente no disponible. Verifica tu conexión e intenta de nuevo.';
      case 'permission-denied':
        return 'Sin permisos para acceder. Contacta al administrador.';
      case 'not-found':
        return 'Cuenta no configurada correctamente.';
      default:
        return 'Error de base de datos ($code). Intenta de nuevo.';
    }
  }

  /// Muestra un mensaje específico según el código de error y resalta el campo
  /// que corresponda (email o contraseña).
  void _mostrarErrorAuth(String code) {
    String mensaje;
    Color color;
    IconData icono;
    bool emailErr = false;
    bool passErr = false;

    switch (code) {
      case 'user-not-found':
      case 'invalid-email':
        mensaje = '❌ El correo electrónico no está registrado en el sistema. '
            'Verifica que sea correcto.';
        color = AppColors.danger;
        icono = Icons.email_outlined;
        emailErr = true;
        break;
      case 'wrong-password':
      case 'invalid-credential':
        mensaje = '❌ La contraseña es incorrecta. '
            'Verifica que estés escribiendo bien tu contraseña.';
        color = AppColors.danger;
        icono = Icons.lock_outline;
        passErr = true;
        break;
      case 'user-disabled':
        mensaje = '⛔ Esta cuenta está deshabilitada. '
            'Contacta al administrador para rehabilitarla.';
        color = AppColors.warning;
        icono = Icons.block;
        break;
      case 'too-many-requests':
        mensaje = '⚠️ Demasiados intentos fallidos. Tu cuenta está bloqueada '
            'temporalmente. Intenta de nuevo en unos minutos.';
        color = AppColors.warning;
        icono = Icons.timer_outlined;
        break;
      case 'network-request-failed':
        mensaje = '📶 Sin conexión a internet. '
            'Verifica tu red e intenta de nuevo.';
        color = AppColors.primary;
        icono = Icons.wifi_off;
        break;
      default:
        mensaje = '❌ Error al iniciar sesión. '
            'Verifica tu correo y contraseña.';
        color = AppColors.danger;
        icono = Icons.error_outline;
        emailErr = true;
        passErr = true;
    }

    setState(() {
      _emailError = emailErr;
      _passwordError = passErr;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icono, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getRutaInicial(RolUsuario rol) {
    switch (rol) {
      case RolUsuario.administradora:
        return '/dashboard';
      case RolUsuario.enfermera:
      case RolUsuario.secretaria_recepcion:
      case RolUsuario.doctora:
        return '/pacientes';
      case RolUsuario.terapeuta:
        return '/agenda-terapeuta';
      case RolUsuario.farmaceutica:
        return '/farmacia';
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/logo_renova.png',
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Nombre clínica
                  Text(
                    'Clínica Renova',
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
                        hasError: _emailError,
                        errorText:
                            _emailError ? 'Correo no registrado' : null,
                        onChanged: (_) {
                          if (_emailError) {
                            setState(() => _emailError = false);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      // Contraseña
                      AppTextField(
                        label: 'Contraseña',
                        hintText: '••••••••',
                        controller: _passwordController,
                        icon: '🔒',
                        obscureText: true,
                        hasError: _passwordError,
                        errorText:
                            _passwordError ? 'Contraseña incorrecta' : null,
                        onChanged: (_) {
                          if (_passwordError) {
                            setState(() => _passwordError = false);
                          }
                        },
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
                      _buildCredentialDemo('Secretaria', 'marcos@renova.gt', 'renova2024'),
                      _buildCredentialDemo('Enfermera', 'carmen@renova.gt', 'renova2024'),
                      _buildCredentialDemo('Doctora', 'maria@renova.gt', 'renova2024'),
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
