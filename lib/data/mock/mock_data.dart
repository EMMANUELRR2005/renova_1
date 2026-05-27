class Patient {
  final String id;
  final String name;
  final String expedient;
  final String clinica;
  final String status;
  final int age;
  final String bloodType;
  final String doctor;
  final String admission;

  Patient({
    required this.id,
    required this.name,
    required this.expedient,
    required this.clinica,
    required this.status,
    required this.age,
    required this.bloodType,
    required this.doctor,
    required this.admission,
  });
}

class Doctor {
  final String id;
  final String name;
  final String specialty;

  Doctor({
    required this.id,
    required this.name,
    required this.specialty,
  });
}

class Appointment {
  final String id;
  final String patientName;
  final String patientExpedient;
  final String doctor;
  final String clinica;
  final String time;
  final String status;
  final String date;
  final String reason;

  Appointment({
    required this.id,
    required this.patientName,
    required this.patientExpedient,
    required this.doctor,
    required this.clinica,
    required this.time,
    required this.status,
    required this.date,
    required this.reason,
  });
}

class Clinic {
  final String id;
  final String name;

  Clinic({required this.id, required this.name});
}

// Mock Data
final List<Patient> mockPatients = [
  Patient(
    id: 'PAC001',
    name: 'María José Pérez Xol',
    expedient: 'EXP-2024-001',
    clinica: 'Clínica General',
    status: 'hospitalized',
    age: 45,
    bloodType: 'O+',
    doctor: 'Dr. Roberto Anleu',
    admission: '2024-05-20 08:15',
  ),
  Patient(
    id: 'PAC002',
    name: 'Carlos Enrique Ajú Toj',
    expedient: 'EXP-2024-002',
    clinica: 'Cardiología',
    status: 'inConsultation',
    age: 62,
    bloodType: 'A+',
    doctor: 'Dr. José Samayoa',
    admission: '2024-05-19 14:30',
  ),
  Patient(
    id: 'PAC003',
    name: 'Luisa Fernanda Caal Pop',
    expedient: 'EXP-2024-003',
    clinica: 'Pediatría',
    status: 'waiting',
    age: 8,
    bloodType: 'AB+',
    doctor: 'Dra. Ana Lucía Batres',
    admission: '2024-05-21 09:00',
  ),
  Patient(
    id: 'PAC004',
    name: 'Jorge Luis González Morales',
    expedient: 'EXP-2024-004',
    clinica: 'Ortopedia',
    status: 'discharged',
    age: 35,
    bloodType: 'B-',
    doctor: 'Dr. Francisco Sánchez',
    admission: '2024-05-18 10:45',
  ),
  Patient(
    id: 'PAC005',
    name: 'Patricia Elena Rivas López',
    expedient: 'EXP-2024-005',
    clinica: 'Ginecología',
    status: 'hospitalized',
    age: 52,
    bloodType: 'O-',
    doctor: 'Dra. Gabriela Paz',
    admission: '2024-05-21 11:20',
  ),
];

final List<Doctor> mockDoctors = [
  Doctor(id: 'DOC001', name: 'Dr. Roberto Anleu', specialty: 'Medicina General'),
  Doctor(id: 'DOC002', name: 'Dra. Ana Lucía Batres', specialty: 'Pediatría'),
  Doctor(id: 'DOC003', name: 'Dr. José Samayoa', specialty: 'Cardiología'),
  Doctor(id: 'DOC004', name: 'Dr. Francisco Sánchez', specialty: 'Ortopedia'),
  Doctor(id: 'DOC005', name: 'Dra. Gabriela Paz', specialty: 'Ginecología'),
];

final List<Clinic> mockClinics = [
  Clinic(id: 'CLI001', name: 'Clínica General'),
  Clinic(id: 'CLI002', name: 'Pediatría'),
  Clinic(id: 'CLI003', name: 'Ginecología'),
  Clinic(id: 'CLI004', name: 'Cardiología'),
  Clinic(id: 'CLI005', name: 'Ortopedia'),
];

final List<Appointment> mockAppointments = [
  Appointment(
    id: 'CITA001',
    patientName: 'María José Pérez Xol',
    patientExpedient: 'EXP-2024-001',
    doctor: 'Dr. Roberto Anleu',
    clinica: 'Clínica General',
    time: '08:30',
    status: 'confirmed',
    date: '2024-05-26',
    reason: 'Revisión control',
  ),
  Appointment(
    id: 'CITA002',
    patientName: 'Carlos Enrique Ajú Toj',
    patientExpedient: 'EXP-2024-002',
    doctor: 'Dr. José Samayoa',
    clinica: 'Cardiología',
    time: '10:00',
    status: 'confirmed',
    date: '2024-05-26',
    reason: 'Ecocardiograma',
  ),
  Appointment(
    id: 'CITA003',
    patientName: 'Luisa Fernanda Caal Pop',
    patientExpedient: 'EXP-2024-003',
    doctor: 'Dra. Ana Lucía Batres',
    clinica: 'Pediatría',
    time: '14:30',
    status: 'pending',
    date: '2024-05-26',
    reason: 'Revisión rutinaria',
  ),
  Appointment(
    id: 'CITA004',
    patientName: 'Patricia Elena Rivas López',
    patientExpedient: 'EXP-2024-005',
    doctor: 'Dra. Gabriela Paz',
    clinica: 'Ginecología',
    time: '16:00',
    status: 'confirmed',
    date: '2024-05-26',
    reason: 'Control pre-natal',
  ),
];
