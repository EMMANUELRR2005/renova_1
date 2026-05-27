import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/clinica_chip.dart';
import '../../core/widgets/patient_avatar.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/mock/mock_data.dart';
import '../../data/mock/providers.dart';

class PatientsScreen extends ConsumerStatefulWidget {
  const PatientsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends ConsumerState<PatientsScreen> {
  late TextEditingController _searchController;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patients = ref.watch(filteredPatientsProvider);
    final activePatient = ref.watch(activePatientProvider);

    return AppShell(
      selectedIndex: 1,
      onNavigate: (index) {},
      child: Row(
        children: [
          // LISTA - 38%
          Expanded(
            flex: 38,
            child: Container(
              color: AppColors.bgGeneral,
              child: Column(
                children: [
                  // Header lista
                  Container(
                    color: AppColors.bgGeneral,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pacientes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontFamily: GoogleFonts.dmSans().fontFamily,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Buscador
                        TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            ref
                                .read(patientSearchProvider.notifier)
                                .state = value;
                          },
                          style: TextStyle(
                            fontSize: 13,
                            fontFamily: GoogleFonts.dmSans().fontFamily,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 12, right: 8),
                              child: Text('🔍', style: TextStyle(fontSize: 16)),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 0,
                              minHeight: 0,
                            ),
                            hintText: 'Buscar paciente...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Chips de filtro
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ClinicaChip(
                                label: 'Todos',
                                isSelected: _selectedFilter == 'all',
                                onTap: () {
                                  setState(() => _selectedFilter = 'all');
                                  ref
                                      .read(patientFilterProvider.notifier)
                                      .state = 'all';
                                },
                              ),
                              const SizedBox(width: 8),
                              ClinicaChip(
                                label: 'Hospitalizados',
                                isSelected:
                                    _selectedFilter == 'hospitalized',
                                onTap: () {
                                  setState(
                                    () => _selectedFilter = 'hospitalized',
                                  );
                                  ref
                                      .read(patientFilterProvider.notifier)
                                      .state = 'hospitalized';
                                },
                              ),
                              const SizedBox(width: 8),
                              ClinicaChip(
                                label: 'En consulta',
                                isSelected:
                                    _selectedFilter == 'inConsultation',
                                onTap: () {
                                  setState(
                                    () => _selectedFilter = 'inConsultation',
                                  );
                                  ref
                                      .read(patientFilterProvider.notifier)
                                      .state = 'inConsultation';
                                },
                              ),
                              const SizedBox(width: 8),
                              ClinicaChip(
                                label: 'Alta',
                                isSelected: _selectedFilter == 'discharged',
                                onTap: () {
                                  setState(() => _selectedFilter = 'discharged');
                                  ref
                                      .read(patientFilterProvider.notifier)
                                      .state = 'discharged';
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Lista de pacientes
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: patients.length,
                      itemBuilder: (context, index) {
                        final patient = patients[index];
                        final isSelected = activePatient?.id == patient.id;

                        return GestureDetector(
                          onTap: () {
                            ref
                                .read(activePatientProvider.notifier)
                                .state = patient;
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 0,
                            ),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryLight
                                  : const Color(0xFFF0F4FF),
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border(
                                      left: BorderSide(
                                        color: AppColors.primary,
                                        width: 3,
                                      ),
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                PatientAvatar(
                                  initials: _getInitials(patient.name),
                                  size: 40,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        patient.name,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                          fontFamily:
                                              GoogleFonts.dmSans().fontFamily,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        patient.expedient,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.textSecondary,
                                          fontFamily:
                                              GoogleFonts.dmSans().fontFamily,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatusBadge(
                                  status: StatusType.values.firstWhere(
                                    (e) =>
                                        e.name == patient.status ||
                                        e.toString().split('.').last ==
                                            patient.status,
                                    orElse: () => StatusType.waiting,
                                  ),
                                  fontSize: 10,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // DETALLE - 62%
          Expanded(
            flex: 62,
            child: activePatient != null
                ? _buildPatientDetail(activePatient)
                : Container(
                    color: AppColors.card,
                    child: Center(
                      child: Text(
                        'Selecciona un paciente',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                          fontFamily: GoogleFonts.dmSans().fontFamily,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientDetail(Patient patient) {
    final statusType = StatusType.values.firstWhere(
      (e) =>
          e.name == patient.status ||
          e.toString().split('.').last == patient.status,
      orElse: () => StatusType.waiting,
    );

    return Container(
      color: AppColors.card,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  PatientAvatar(
                    initials: _getInitials(patient.name),
                    size: 64,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontFamily: GoogleFonts.dmSans().fontFamily,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${patient.expedient} • ${patient.age} años • ${patient.bloodType}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                                fontFamily: GoogleFonts.dmSans().fontFamily,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        StatusBadge(status: statusType),
                      ],
                    ),
                  ),
                  // Botones de acción
                  SizedBox(
                    width: 120,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppColors.border,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('...'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // TabBar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border),
                ),
              ),
              child: Row(
                children: [
                  'Información',
                  'Historial',
                  'Signos Vitales',
                  'Medicamentos',
                ]
                    .map(
                      (tab) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Text(
                          tab,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: tab == 'Información'
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontFamily: GoogleFonts.dmSans().fontFamily,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grid info
                  GridView.count(
                    crossAxisCount: 2,
                    childAspectRatio: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      _buildInfoField('DPI', '1234567-123'),
                      _buildInfoField('Nacimiento', '15/03/1979'),
                      _buildInfoField('Teléfono', '+502 7845-1234'),
                      _buildInfoField('Dirección', 'Zona 10, Ciudad'),
                      _buildInfoField('Alergias', 'Penicilina, Ibuprofeno'),
                      _buildInfoField('Médico tratante', patient.doctor),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgGeneral,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontFamily: GoogleFonts.dmSans().fontFamily,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              fontFamily: GoogleFonts.dmSans().fontFamily,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    return name
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0] : '')
        .take(2)
        .join('')
        .toUpperCase();
  }
}
