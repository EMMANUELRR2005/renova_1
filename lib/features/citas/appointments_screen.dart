import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../data/mock/providers.dart';

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(appointmentsProvider);

    return AppShell(
      selectedIndex: 2,
      onNavigate: (index) {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Citas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: GoogleFonts.dmSans().fontFamily,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Encabezado
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgGeneral,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 15,
                          child: Text(
                            'Hora',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFamily: GoogleFonts.dmSans().fontFamily,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 20,
                          child: Text(
                            'Servicio',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFamily: GoogleFonts.dmSans().fontFamily,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 20,
                          child: Text(
                            'Sala',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFamily: GoogleFonts.dmSans().fontFamily,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 15,
                          child: Text(
                            'Duración',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFamily: GoogleFonts.dmSans().fontFamily,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 12,
                          child: Text(
                            'Precio',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFamily: GoogleFonts.dmSans().fontFamily,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 15,
                          child: Text(
                            'Estado',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontFamily: GoogleFonts.dmSans().fontFamily,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filas de citas
                  ...appointments.map((cita) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 15,
                            child: Text(
                              cita.hora,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 20,
                            child: Text(
                              cita.tipoServicio.toString().split('.').last,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 20,
                            child: Text(
                              'Sala ${cita.salaId}',
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 15,
                            child: Text(
                              '${cita.duracionMinutos} min',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 12,
                            child: Text(
                              'Q${cita.precioBase.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 15,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: cita.estado.toString() == 'EstadoCita.confirmada'
                                    ? AppColors.successBg
                                    : AppColors.warningBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                cita.estado.toString().split('.').last,
                                style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
