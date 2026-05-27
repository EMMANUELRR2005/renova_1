import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import 'sidebar_item.dart';

class AppShell extends ConsumerWidget {
  final Widget child;
  final int selectedIndex;
  final Function(int) onNavigate;

  const AppShell({
    Key? key,
    required this.child,
    required this.selectedIndex,
    required this.onNavigate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedClinic = ref.watch(selectedClinicProvider);

    return Scaffold(
      body: Row(
        children: [
          // SIDEBAR
          Container(
            width: 220,
            color: AppColors.primaryDark,
            child: Column(
              children: [
                // Logo area
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            '⊕',
                            style: TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sanatorio\nRenova',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontFamily: GoogleFonts.dmSans().fontFamily,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Color(0xFF1A3F5C)),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      SidebarItem(
                        icon: '📊',
                        label: 'Dashboard',
                        isActive: selectedIndex == 0,
                        onTap: () {
                          onNavigate(0);
                          context.go('/dashboard');
                        },
                      ),
                      SidebarItem(
                        icon: '👥',
                        label: 'Pacientes',
                        isActive: selectedIndex == 1,
                        onTap: () {
                          onNavigate(1);
                          context.go('/pacientes');
                        },
                      ),
                      SidebarItem(
                        icon: '📅',
                        label: 'Citas',
                        isActive: selectedIndex == 2,
                        onTap: () {
                          onNavigate(2);
                          context.go('/citas');
                        },
                      ),
                      SidebarItem(
                        icon: '📋',
                        label: 'Expedientes',
                        isActive: selectedIndex == 3,
                        onTap: () => onNavigate(3),
                      ),
                      SidebarItem(
                        icon: '⚕️',
                        label: 'Enfermería',
                        isActive: selectedIndex == 4,
                        onTap: () => onNavigate(4),
                      ),
                      SidebarItem(
                        icon: '💊',
                        label: 'Farmacia',
                        isActive: selectedIndex == 5,
                        onTap: () => onNavigate(5),
                      ),
                      SidebarItem(
                        icon: '📈',
                        label: 'Reportes',
                        isActive: selectedIndex == 6,
                        onTap: () => onNavigate(6),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: Color(0xFF1A3F5C)),
                      ),
                      SidebarItem(
                        icon: '⚙️',
                        label: 'Configuración',
                        isActive: selectedIndex == 7,
                        onTap: () => onNavigate(7),
                      ),
                      SidebarItem(
                        icon: '🚪',
                        label: 'Cerrar sesión',
                        isActive: false,
                        onTap: () => context.go('/login'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // MAIN CONTENT
          Expanded(
            child: Column(
              children: [
                // TOPBAR
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.topbar,
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Text(
                                '⊕',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Sanatorio Renova',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFamily: GoogleFonts.dmSans().fontFamily,
                            ),
                          ),
                        ],
                      ),
                      // Center - Clínica activa
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Clínica General',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                            fontFamily: GoogleFonts.dmSans().fontFamily,
                          ),
                        ),
                      ),
                      // Right
                      Row(
                        children: [
                          const Text(
                            '🔔',
                            style: TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Center(
                              child: Text(
                                'RA',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Roberto Anleu',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                              fontFamily: GoogleFonts.dmSans().fontFamily,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // CONTENT AREA
                Expanded(
                  child: Container(
                    color: AppColors.bgGeneral,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Provider para el índice seleccionado del sidebar
final selectedSidebarIndexProvider = StateProvider<int>((ref) {
  return 0;
});

// Provider para clínica seleccionada (reutilizado de mock/providers)
final selectedClinicProvider = StateProvider<String>((ref) {
  return 'CLI001';
});
