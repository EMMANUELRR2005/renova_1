import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/status_badge.dart';
import '../../data/mock/mock_data.dart';
import '../../data/mock/providers.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    final appointments = ref.watch(appointmentsProvider);
    final todayStr =
        '${_selectedDay?.year}-${_selectedDay!.month.toString().padLeft(2, '0')}-${_selectedDay!.day.toString().padLeft(2, '0')}';
    final dayAppointments =
        appointments.where((a) => a.date == todayStr).toList();

    return AppShell(
      selectedIndex: 2,
      onNavigate: (index) {},
      child: Row(
        children: [
          // CALENDARIO - 45%
          Expanded(
            flex: 45,
            child: Container(
              color: AppColors.bgGeneral,
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TableCalendar(
                  focusedDay: _focusedDay,
                  firstDay: DateTime(2024, 1, 1),
                  lastDay: DateTime(2025, 12, 31),
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    titleTextStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: GoogleFonts.dmSans().fontFamily,
                    ),
                    leftChevronIcon: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                    ),
                    rightChevronIcon: const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                    ),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      fontFamily: GoogleFonts.dmSans().fontFamily,
                    ),
                    weekendStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.danger,
                      fontFamily: GoogleFonts.dmSans().fontFamily,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    cellMargin: const EdgeInsets.all(4),
                    cellPadding: const EdgeInsets.all(0),
                    defaultDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    defaultTextStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                      fontFamily: GoogleFonts.dmSans().fontFamily,
                    ),
                    weekendDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    weekendTextStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textPrimary,
                      fontFamily: GoogleFonts.dmSans().fontFamily,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: GoogleFonts.dmSans().fontFamily,
                    ),
                    outsideTextStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textDisabled,
                      fontFamily: GoogleFonts.dmSans().fontFamily,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // LISTA DE CITAS - 55%
          Expanded(
            flex: 55,
            child: Container(
              color: AppColors.bgGeneral,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      border: Border(
                        bottom: BorderSide(color: AppColors.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Citas — ${_selectedDay?.day}/${_selectedDay?.month}/${_selectedDay?.year}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            fontFamily: GoogleFonts.dmSans().fontFamily,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${dayAppointments.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              fontFamily: GoogleFonts.dmSans().fontFamily,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Lista de citas
                  Expanded(
                    child: dayAppointments.isEmpty
                        ? Center(
                            child: Text(
                              'No hay citas programadas',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: AppColors.textSecondary,
                                fontFamily: GoogleFonts.dmSans().fontFamily,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(top: 8),
                            itemCount: dayAppointments.length,
                            itemBuilder: (context, index) {
                              final appointment = dayAppointments[index];
                              return _buildAppointmentCard(appointment);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final statusColor = appointment.status == 'confirmed'
        ? AppColors.success
        : AppColors.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
          right: BorderSide(color: AppColors.border),
          top: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Hora y datos principales
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.time,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontFamily: GoogleFonts.dmSans().fontFamily,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      appointment.patientName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        fontFamily: GoogleFonts.dmSans().fontFamily,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${appointment.doctor} • ${appointment.clinica}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        fontFamily: GoogleFonts.dmSans().fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
              // Badges
              Row(
                children: [
                  StatusBadge(
                    status: appointment.status == 'confirmed'
                        ? StatusType.inConsultation
                        : StatusType.waiting,
                    fontSize: 10,
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton(
                    child: const Text('⋮',
                        style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Editar'),
                      ),
                      const PopupMenuItem(
                        value: 'reschedule',
                        child: Text('Reprogramar'),
                      ),
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Text('Cancelar'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Motivo: ${appointment.reason}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              fontFamily: GoogleFonts.dmSans().fontFamily,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
