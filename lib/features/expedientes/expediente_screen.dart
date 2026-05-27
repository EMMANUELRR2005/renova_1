import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../data/mock/providers.dart';

class ExpedienteScreen extends ConsumerWidget {
  const ExpedienteScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patients = ref.watch(patientsProvider);
    final planesActivos = ref.watch(planesActivosProvider);

    return AppShell(
      selectedIndex: 3,
      onNavigate: (index) {},
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Expedientes',
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
                  const Text('Expedientes de Pacientes'),
                  const SizedBox(height: 12),
                  // Resumen de pacientes y planes
                  Text('Total pacientes: ${patients.length}'),
                  Text('Planes activos: ${planesActivos.length}'),
                  const SizedBox(height: 16),
                  // Tabla simplificada
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('DPI')),
                          DataColumn(label: Text('Nombre')),
                          DataColumn(label: Text('Expediente')),
                        ],
                        rows: patients
                            .map((p) => DataRow(cells: [
                                  DataCell(Text(p.dpi)),
                                  DataCell(Text(p.nombre)),
                                  DataCell(Text(p.expediente)),
                                ]))
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
