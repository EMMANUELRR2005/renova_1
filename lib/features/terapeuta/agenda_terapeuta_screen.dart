import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/widgets_comunes.dart';
import '../../data/mock/providers.dart';

class AgendaTerapeutaScreen extends ConsumerWidget {
  const AgendaTerapeutaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citasAsync = ref.watch(citasTerapeutaProvider);

    return AppShell(
      selectedIndex: 0,
      onNavigate: (index) {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mi Agenda - Hoy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontFamily: GoogleFonts.dmSans().fontFamily,
              ),
            ),
            const SizedBox(height: 20),
            citasAsync.when(
              loading: () => Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: kSombraSuave,
                ),
                padding: const EdgeInsets.all(16),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stackTrace) => Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: kSombraSuave,
                ),
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'Error cargando citas: $error',
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ),
              data: (citasHoy) => Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: kSombraSuave,
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (citasHoy.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No tienes citas programadas hoy'),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: citasHoy.length,
                        itemBuilder: (context, index) {
                          final cita = citasHoy[index];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(8),
                              color: cita.estado.toString() == 'EstadoCita.en_curso'
                                  ? AppColors.primaryLight
                                  : Colors.white,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cita.hora,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Servicio: ${cita.tipoServicio.toString().split('.').last}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            fontFamily:
                                                GoogleFonts.dmSans().fontFamily,
                                          ),
                                        ),
                                        Text(
                                          'Sala: ${cita.salaId}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            fontFamily:
                                                GoogleFonts.dmSans().fontFamily,
                                          ),
                                        ),
                                        Text(
                                          'Duración: ${cita.duracionMinutos} minutos',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                            fontFamily:
                                                GoogleFonts.dmSans().fontFamily,
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
                                            color: cita.estado.toString() ==
                                                    'EstadoCita.confirmada'
                                                ? AppColors.successBg
                                                : AppColors.warningBg,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            cita.estado
                                                .toString()
                                                .split('.')
                                                .last,
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (cita.estado.toString() !=
                                            'EstadoCita.completada')
                                          ElevatedButton(
                                            onPressed: () {
                                              _showSessionForm(context);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.primary,
                                            ),
                                            child: const Text(
                                              'Registrar Sesión',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (cita.notas != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgGeneral,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Notas: ${cita.notas}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSessionForm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Sesión'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Observaciones',
                hintText: 'Describe la sesión...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            const Text('Evolución (1-5 estrellas)'),
            const SizedBox(height: 4),
            Row(
              children: List.generate(
                5,
                (index) => const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text('⭐'),
                ),
              ),
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
                const SnackBar(content: Text('Sesión registrada')),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
