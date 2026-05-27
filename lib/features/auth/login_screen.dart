import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/clinica_chip.dart';
import '../../data/mock/mock_data.dart';
import 'providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  String _selectedClinic = 'CLI001';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    setState(() => _isLoading = true);

    final authNotifier = ref.read(authStateProvider.notifier);
    final result = await authNotifier.login(
      _usernameController.text,
      _passwordController.text,
      _selectedClinic,
    );

    if (result && mounted) {
      // Actualizar clínica seleccionada
      ref.read(selectedClinicStateProvider.notifier).state = _selectedClinic;
      // Actualizar usuario actual
      ref.read(currentUserProvider.notifier).state = 
          User(username: _usernameController.text, clinic: _selectedClinic);
      // Invalidar router para que reacte al cambio de authState
      ref.invalidate(goRouterProvider);
      // Navegar a dashboard con pequeño delay
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        context.go('/dashboard');
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenciales inválidas. Usa admin/1234'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
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
                        '⊕',
                        style: TextStyle(
                          fontSize: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Nombre sanatorio
                  Text(
                    'Sanatorio\nRenova',
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
                    'Sistema de Control Clínico',
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
                    ('✓', 'Gestión integral de pacientes'),
                    ('✓', 'Control de citas y agenda'),
                    ('✓', 'Expedientes digitales seguros'),
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
                      // Selector de clínica
                      Text(
                        'Clínica',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: GoogleFonts.dmSans().fontFamily,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: mockClinics
                            .map(
                              (clinic) => ClinicaChip(
                                label: clinic.name,
                                isSelected: _selectedClinic == clinic.id,
                                onTap: () {
                                  setState(() => _selectedClinic = clinic.id);
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 32),
                      // Usuario
                      AppTextField(
                        label: 'Usuario',
                        hintText: 'admin',
                        controller: _usernameController,
                        icon: '👤',
                        keyboardType: TextInputType.text,
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
                          'Demo: admin / 1234',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                            fontFamily: GoogleFonts.dmSans().fontFamily,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'v1.0.0',
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
}

// Provider para clínica seleccionada durante login
final selectedClinicStateProvider = StateProvider<String>((ref) {
  return 'CLI001';
});
