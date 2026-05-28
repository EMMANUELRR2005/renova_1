import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/kpi_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/mock/mock_data.dart';
import '../../data/mock/providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpiData = ref.watch(kpiProvider);
    final citasHoyAsync = ref.watch(citasHoyStreamProvider);

    return AppShell(
      selectedIndex: 0,
      onNavigate: (index) {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFamily: GoogleFonts.dmSans().fontFamily,
              ),
            ),
            const SizedBox(height: 20),
            // KPI Cards Row
            Row(
              children: [
                Expanded(
                  child: KpiCard(
                    icon: '📅',
                    number: '${kpiData['citasHoy']}',
                    label: 'Citas hoy',
                    trend: '→ Programadas',
                    iconBgColor: AppColors.successBg,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KpiCard(
                    icon: '⏱️',
                    number: '${kpiData['sesionesEnCurso']}',
                    label: 'En sesión ahora',
                    trend: '→ En progreso',
                    iconBgColor: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KpiCard(
                    icon: '💰',
                    number: 'Q ${kpiData['ingresosDelDia'].toStringAsFixed(0)}',
                    label: 'Ingresos del día',
                    trend: '↑ Del mes',
                    iconBgColor: AppColors.clinicalGreenBg,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KpiCard(
                    icon: '⚠️',
                    number: '${kpiData['alertasClinicas']}',
                    label: 'Alertas clínicas',
                    trend: 'Revisar pacientes',
                    iconBgColor: AppColors.dangerBg,
                    trendColor: AppColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Fila con dos paneles
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Panel izquierdo - Próximas citas
                Expanded(
                  flex: 60,
                  child: citasHoyAsync.when(
                    loading: () => Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: Text(
                          'Error: $error',
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ),
                    data: (citas) {
                      final citasList = citas.take(5).toList();
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            // Header tabla
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.bgGeneral,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'PRÓXIMAS CITAS',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                      fontFamily: GoogleFonts.dmSans().fontFamily,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Tabla de citas
                            if (citasList.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'No hay citas para hoy',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontFamily: GoogleFonts.dmSans().fontFamily,
                                  ),
                                ),
                              )
                            else
                              ...citasList.asMap().entries.map((entry) {
                                final index = entry.key;
                                final cita = entry.value;
                                final isEven = index % 2 == 0;

                                return Container(
                                  color: isEven
                                      ? Colors.white
                                      : const Color(0xFFFAFBFC),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 15,
                                        child: Text(
                                          cita.hora,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.primary,
                                            fontFamily:
                                                GoogleFonts.dmSans().fontFamily,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 25,
                                        child: Text(
                                          'Cita ${cita.id}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.textPrimary,
                                            fontFamily:
                                                GoogleFonts.dmSans().fontFamily,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 20,
                                        child: Text(
                                          cita.tipoServicio.toString().split('.').last,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.textSecondary,
                                            fontFamily:
                                                GoogleFonts.dmSans().fontFamily,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 20,
                                        child: Text(
                                          'Terapeuta',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.textSecondary,
                                            fontFamily:
                                                GoogleFonts.dmSans().fontFamily,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 12,
                                        child: StatusBadge(
                                          status: _estadoToCita(cita.estado),
                                          fontSize: 11,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 12,
                                        child: Text(
                                          'Q${cita.precioBase.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.textSecondary,
                                            fontFamily:
                                                GoogleFonts.dmSans().fontFamily,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 20),
                // Panel derecho - Actividad reciente
                Expanded(
                  flex: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTIVIDAD RECIENTE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontFamily: GoogleFonts.dmSans().fontFamily,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._buildActivityTimeline(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActivityTimeline() {
    final activities = [
      ('08:15', 'María J. Pérez ingresada a Clínica General'),
      ('09:30', 'Nueva cita confirmada - Carlos E. Ajú'),
      ('10:45', 'Luisa F. Caal en consulta pediátrica'),
      ('12:00', 'Alta médica procesada - Jorge L. González'),
      ('14:20', 'Alerta: Patricia E. Rivas - signos vitales'),
    ];

    return activities.map((activity) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                Container(
                  width: 2,
                  height: 30,
                  color: AppColors.border,
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.$1,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      fontFamily: GoogleFonts.dmSans().fontFamily,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.$2,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      fontFamily: GoogleFonts.dmSans().fontFamily,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

StatusType _estadoToCita(EstadoCita estado) {
  switch (estado) {
    case EstadoCita.confirmada:
      return StatusType.inConsultation;
    case EstadoCita.agendada:
      return StatusType.waiting;
    case EstadoCita.en_curso:
      return StatusType.inConsultation;
    case EstadoCita.completada:
      return StatusType.discharged;
    case EstadoCita.cancelada:
      return StatusType.emergency;
  }
}
