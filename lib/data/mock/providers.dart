import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mock_data.dart';

// Patients Provider
final patientsProvider = Provider<List<Patient>>((ref) {
  return mockPatients;
});

// Doctors Provider
final doctorsProvider = Provider<List<Doctor>>((ref) {
  return mockDoctors;
});

// Clinics Provider
final clinicsProvider = Provider<List<Clinic>>((ref) {
  return mockClinics;
});

// Appointments Provider
final appointmentsProvider = Provider<List<Appointment>>((ref) {
  return mockAppointments;
});

// Selected Clinic Provider
final selectedClinicProvider = StateProvider<String>((ref) {
  return 'CLI001';
});

// Active Patient Provider
final activePatientProvider = StateProvider<Patient?>((ref) {
  return null;
});

// Filter status
final patientFilterProvider = StateProvider<String>((ref) {
  return 'all';
});

// Search query
final patientSearchProvider = StateProvider<String>((ref) {
  return '';
});

// Filtered patients
final filteredPatientsProvider = Provider<List<Patient>>((ref) {
  final patients = ref.watch(patientsProvider);
  final filter = ref.watch(patientFilterProvider);
  final search = ref.watch(patientSearchProvider);

  return patients.where((p) {
    bool matchesFilter = filter == 'all' || p.status == filter;
    bool matchesSearch = search.isEmpty ||
        p.name.toLowerCase().contains(search.toLowerCase()) ||
        p.expedient.toLowerCase().contains(search.toLowerCase());
    return matchesFilter && matchesSearch;
  }).toList();
});

// Today's appointments
final todayAppointmentsProvider = Provider<List<Appointment>>((ref) {
  final appointments = ref.watch(appointmentsProvider);
  final today = DateTime.now();
  final todayStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  return appointments.where((a) => a.date == todayStr).toList();
});

// KPI Data
final kpiDataProvider = Provider<Map<String, dynamic>>((ref) {
  final patients = ref.watch(patientsProvider);
  final appointments = ref.watch(todayAppointmentsProvider);

  final hospitalized =
      patients.where((p) => p.status == 'hospitalized').length;
  final available = 15 - hospitalized;
  final todayAppointments = appointments.length;
  final alerts = patients.where((p) => p.status == 'emergency').length;

  return {
    'hospitalized': hospitalized,
    'available': available,
    'todayAppointments': todayAppointments,
    'alerts': alerts,
  };
});
