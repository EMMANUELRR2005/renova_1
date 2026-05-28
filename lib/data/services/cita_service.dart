import 'package:cloud_firestore/cloud_firestore.dart';
import '../mock/mock_data.dart';

class CitaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream de citas de hoy
  Stream<List<Appointment>> getCitasHoy() {
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    final fin = inicio.add(const Duration(days: 1));
    return _db.collection('citas')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fecha', isLessThan: Timestamp.fromDate(fin))
        .orderBy('fecha')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Appointment.fromMap(d.data(), d.id))
            .toList());
  }

  /// Stream de citas de un terapeuta específico hoy
  Stream<List<Appointment>> getCitasTerapeutaHoy(String terapeutaId) {
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    final fin = inicio.add(const Duration(days: 1));
    return _db.collection('citas')
        .where('terapeutaId', isEqualTo: terapeutaId)
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fecha', isLessThan: Timestamp.fromDate(fin))
        .orderBy('fecha')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Appointment.fromMap(d.data(), d.id))
            .toList());
  }

  /// Crear cita
  Future<String> crearCita(Appointment cita) async {
    final ref = _db.collection('citas').doc();
    await ref.set(cita.toMap());
    return ref.id;
  }

  /// Cambiar estado de cita
  Future<void> cambiarEstado(String id, EstadoCita estado) async {
    await _db.collection('citas').doc(id).update({'estado': estado.name});
  }

  /// Stream de citas de un paciente
  Stream<List<Appointment>> getCitasPaciente(String pacienteId) {
    return _db.collection('citas')
        .where('pacienteId', isEqualTo: pacienteId)
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Appointment.fromMap(d.data(), d.id))
            .toList());
  }
}
