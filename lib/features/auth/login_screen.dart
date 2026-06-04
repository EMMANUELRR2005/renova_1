import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/app_exit.dart';
import '../../data/mock/mock_data.dart';
import 'providers/auth_provider.dart';

const _azul = Color(0xFF1E3A5F);
const _dorado = Color(0xFFC9A96E);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _emailError = false;
  bool _passwordError = false;
  bool _ocultarPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Lógica de autenticación ───────────────────────────────────────────────

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
      final result = await ref.read(loginProvider(
              (_emailController.text.trim(), _passwordController.text))
          .future);

      if (result) {
        if (mounted) {
          final usuario = ref.read(usuarioActivoProvider);
          if (usuario != null) {
            await Future.delayed(const Duration(milliseconds: 200));
            if (mounted) context.go(_getRutaInicial(usuario.rol));
          } else {
            setState(() => _isLoading = false);
            _showError('Cuenta no configurada. Contacta al administrador.');
          }
        }
      } else {
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
      case RolUsuario.boutique:
        return '/boutique';
    }
  }

  // ── Salir de la app ───────────────────────────────────────────────────────

  Future<void> _confirmarSalir() async {
    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app, color: _azul),
            SizedBox(width: 8),
            Expanded(child: Text('¿Salir de la aplicación?')),
          ],
        ),
        content: const Text(
          'Se cerrará la aplicación. Tu sesión quedará como esté '
          '(si ya iniciaste sesión, al volver entrarás directo).',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.exit_to_app, color: Colors.white, size: 16),
            label: const Text('Salir', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: _azul),
          ),
        ],
      ),
    );
    if (confirmar == true) salirDeApp();
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mostrarCarrusel = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      body: Stack(
        children: [
          Row(
            children: [
              if (mostrarCarrusel) const Expanded(child: _CarruselLogin()),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: _buildFormulario(mostrarCarrusel),
                ),
              ),
            ],
          ),
          // Botón Salir discreto, abajo a la derecha.
          Positioned(
            bottom: 12,
            right: 16,
            child: TextButton.icon(
              onPressed: _confirmarSalir,
              icon: const Icon(Icons.exit_to_app, size: 14, color: Colors.grey),
              label: const Text('Salir',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulario(bool hayCarrusel) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En móvil (sin carrusel) mostramos el logo arriba.
              if (!hayCarrusel) ...[
                Center(
                  child: Image.asset('assets/images/logo_renova.png',
                      height: 80, fit: BoxFit.contain),
                ),
                const SizedBox(height: 24),
              ],
              Text('Bienvenido',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _azul,
                    fontFamily: GoogleFonts.dmSans().fontFamily,
                  )),
              const SizedBox(height: 8),
              const Text('Inicia sesión en tu cuenta',
                  style: TextStyle(color: Colors.grey, fontSize: 15)),
              const SizedBox(height: 40),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                onChanged: (_) {
                  if (_emailError) setState(() => _emailError = false);
                },
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  hintText: 'ejemplo@renova.gt',
                  prefixIcon: Icon(Icons.email_outlined,
                      color: _emailError ? AppColors.danger : _azul),
                  errorText: _emailError ? 'Correo no registrado' : null,
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: _emailError ? AppColors.danger : AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: _emailError ? AppColors.danger : _azul, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Contraseña
              TextFormField(
                controller: _passwordController,
                obscureText: _ocultarPassword,
                onFieldSubmitted: (_) => _isLoading ? null : _handleLogin(),
                onChanged: (_) {
                  if (_passwordError) setState(() => _passwordError = false);
                },
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: Icon(Icons.lock_outline,
                      color: _passwordError ? AppColors.danger : _azul),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _ocultarPassword = !_ocultarPassword),
                  ),
                  errorText: _passwordError ? 'Contraseña incorrecta' : null,
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color:
                            _passwordError ? AppColors.danger : AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: _passwordError ? AppColors.danger : _azul,
                        width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Botón
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _azul,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Iniciar sesión',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 32),

              const Center(
                child: Text('Prueba con:',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ),
              const SizedBox(height: 12),
              _buildCredentialDemo('Admin', 'admin@renova.gt', 'renova2024'),
              _buildCredentialDemo('Secretaria', 'marcos@renova.gt', 'renova2024'),
              _buildCredentialDemo('Enfermera', 'carmen@renova.gt', 'renova2024'),
              _buildCredentialDemo('Doctora', 'maria@renova.gt', 'renova2024'),
              const SizedBox(height: 16),
              const Center(
                child: Text('v1.0.0 · Renova Clínica',
                    style: TextStyle(color: Colors.grey, fontSize: 11)),
              ),
            ],
          ),
        ),
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
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(role,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(width: 8),
            Expanded(
              child: Text('$email / $password',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis),
            ),
            TextButton(
              onPressed: () {
                _emailController.text = email;
                _passwordController.text = password;
              },
              style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 0)),
              child: const Text('Usar', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CARRUSEL DE IMÁGENES (lado izquierdo)
// ════════════════════════════════════════════════════════════════════════════

class _CarruselLogin extends StatefulWidget {
  const _CarruselLogin();

  @override
  State<_CarruselLogin> createState() => _CarruselLoginState();
}

class _CarruselLoginState extends State<_CarruselLogin> {
  final PageController _pageController = PageController();
  int _paginaActual = 0;
  Timer? _timer;

  static const List<Map<String, String>> _slides = [
    {
      'imagen': 'assets/images/login/medicina-estetica.jpg',
      'titulo': 'Medicina Estética',
      'subtitulo': 'Tratamientos de vanguardia\npara tu bienestar',
    },
    {
      'imagen': 'assets/images/login/tecnologia-medica.jpg',
      'titulo': 'Tecnología Médica',
      'subtitulo': 'Los mejores procedimientos\ncon tecnología de punta',
    },
    {
      'imagen': 'assets/images/login/medicina_estetica_2.jpg',
      'titulo': 'Procedimientos Estéticos',
      'subtitulo': 'Expertos en tratamientos\nfaciales y corporales',
    },
    {
      'imagen': 'assets/images/login/medicina_estetica_3.jpg',
      'titulo': 'Innovación Médica',
      'subtitulo': 'Técnicas modernas para\ntu transformación',
    },
  ];

  @override
  void initState() {
    super.initState();
    _iniciarTimer();
  }

  void _iniciarTimer() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_pageController.hasClients && _slides.length > 1) {
        final siguiente = (_paginaActual + 1) % _slides.length;
        _pageController.animateToPage(
          siguiente,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _paginaActual = i),
            itemCount: _slides.length,
            itemBuilder: (_, i) => Image.asset(
              _slides[i]['imagen']!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: _azul),
            ),
          ),
          // Overlay gradiente para legibilidad del texto.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _azul.withValues(alpha: 0.45),
                  Colors.black.withValues(alpha: 0.70),
                ],
              ),
            ),
          ),
          // Logo arriba.
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset('assets/images/logo_renova.png',
                      height: 80, fit: BoxFit.contain),
                ),
                const SizedBox(height: 10),
                Text('Clínica Renova',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: GoogleFonts.dmSans().fontFamily,
                    )),
                const SizedBox(height: 4),
                const Text('Tecnología médica para\nuna vida renovada',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          // Título del slide (con fade).
          Positioned(
            bottom: 80,
            left: 32,
            right: 32,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Column(
                key: ValueKey(_paginaActual),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_slides[_paginaActual]['titulo']!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(_slides[_paginaActual]['subtitulo']!,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
          ),
          // Indicadores (puntos).
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _paginaActual == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _paginaActual == i ? _dorado : Colors.white54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
