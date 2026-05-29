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

  // ─── Citas Médicas (Secretaria) ───────────────────────────────────────────

  /// Stream de todas las citas médicas
  /// Ordenamos en Dart para evitar índices compuestos
  Stream<List<CitaMedica>> streamCitasMedicas() {
    return _db
        .collection('citas_medicas')
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => CitaMedica.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.fecha.compareTo(a.fecha));
          return list;
        });
  }

  /// Stream de citas médicas de hoy
  Stream<List<CitaMedica>> streamCitasMedicasHoy() {
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    final fin = inicio.add(const Duration(days: 1));
    return _db
        .collection('citas_medicas')
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => CitaMedica.fromMap(d.data(), d.id))
              .where((c) => c.fecha.isAfter(inicio.subtract(const Duration(seconds: 1)))
                         && c.fecha.isBefore(fin))
              .toList();
          list.sort((a, b) => a.fecha.compareTo(b.fecha));
          return list;
        });
  }

  /// Stream de citas médicas de la semana
  Stream<List<CitaMedica>> streamCitasMedicasSemana() {
    final hoy = DateTime.now();
    final inicioSemana = hoy.subtract(Duration(days: hoy.weekday - 1));
    final inicio = DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day);
    final fin = inicio.add(const Duration(days: 7));
    return _db
        .collection('citas_medicas')
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => CitaMedica.fromMap(d.data(), d.id))
              .where((c) => c.fecha.isAfter(inicio.subtract(const Duration(seconds: 1)))
                         && c.fecha.isBefore(fin))
              .toList();
          list.sort((a, b) => a.fecha.compareTo(b.fecha));
          return list;
        });
  }

  /// Stream de citas de una doctora específica
  Stream<List<CitaMedica>> streamCitasDoctora(String doctoraId) {
    return _db
        .collection('citas_medicas')
        .where('doctoraId', isEqualTo: doctoraId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => CitaMedica.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.fecha.compareTo(a.fecha));
          return list;
        });
  }

  /// Crear cita médica
  Future<String> crearCitaMedica(CitaMedica cita) async {
    final ref = _db.collection('citas_medicas').doc();
    await ref.set(cita.toMap());
    return ref.id;
  }

  /// Confirmar cita
  Future<void> confirmarCitaMedica(String citaId) async {
    await _db.collection('citas_medicas').doc(citaId).update({
      'estado': 'confirmada',
    });
  }

  /// Cancelar cita
  Future<void> cancelarCitaMedica(String citaId, String motivo) async {
    await _db.collection('citas_medicas').doc(citaId).update({
      'estado': 'cancelada',
      'motivoCancelacion': motivo,
    });
  }

  /// Completar cita
  Future<void> completarCitaMedica(String citaId) async {
    await _db.collection('citas_medicas').doc(citaId).update({
      'estado': 'completada',
    });
  }

  /// Actualizar cita médica
  Future<void> actualizarCitaMedica(String citaId, Map<String, dynamic> datos) async {
    await _db.collection('citas_medicas').doc(citaId).update(datos);
  }
}
