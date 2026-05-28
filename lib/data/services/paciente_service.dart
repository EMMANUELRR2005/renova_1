import 'package:cloud_firestore/cloud_firestore.dart';
import '../mock/mock_data.dart';

class PacienteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Modelo antiguo (Patient) ─────────────────────────────────────────────

  Stream<List<Patient>> getPacientes() {
    return _db
        .collection('pacientes')
        .orderBy('nombre')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Patient.fromMap(d.data(), d.id)).toList());
  }

  Future<void> eliminarPaciente(String id) async {
    await _db.collection('pacientes').doc(id).delete();
  }

  Stream<Patient?> getPaciente(String id) {
    return _db.collection('pacientes').doc(id).snapshots().map(
        (doc) => doc.exists ? Patient.fromMap(doc.data()!, doc.id) : null);
  }

  // ─── Modelo nuevo (Paciente) ──────────────────────────────────────────────

  Stream<List<Paciente>> streamPacientes({String? filtroEstado}) {
    Query<Map<String, dynamic>> query =
        _db.collection('pacientes').orderBy('apellido');
    if (filtroEstado != null && filtroEstado != 'todos') {
      query = query.where('estado', isEqualTo: filtroEstado);
    }
    return query.snapshots().map((snap) =>
        snap.docs.map((d) => Paciente.fromMap(d.data(), d.id)).toList());
  }

  Future<String> crearPaciente(Paciente paciente) async {
    final ref = _db.collection('pacientes').doc();
    await ref.set(paciente.toMap());
    return ref.id;
  }

  Future<void> actualizarPaciente(
      String id, Paciente paciente, String actualizadoPorUid) async {
    await _db
        .collection('pacientes')
        .doc(id)
        .update(paciente.toUpdateMap(actualizadoPorUid));
  }

  Stream<Paciente?> streamPacienteById(String id) {
    return _db.collection('pacientes').doc(id).snapshots().map(
        (doc) => doc.exists ? Paciente.fromMap(doc.data()!, doc.id) : null);
  }

  Future<bool> existeNumeroIdentificacion(String numero,
      {String? excludeId}) async {
    final snap = await _db
        .collection('pacientes')
        .where('numeroIdentificacion', isEqualTo: numero)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return false;
    if (excludeId != null && snap.docs.first.id == excludeId) return false;
    return true;
  }

  // ─── Historial ────────────────────────────────────────────────────────────

  Stream<List<HistorialConsulta>> streamHistorial(String pacienteId) {
    return _db
        .collection('pacientes')
        .doc(pacienteId)
        .collection('historial')
        .orderBy('fecha', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => HistorialConsulta.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> agregarEntradaHistorial(
      String pacienteId, HistorialConsulta entrada) async {
    await _db
        .collection('pacientes')
        .doc(pacienteId)
        .collection('historial')
        .add(entrada.toMap());
  }

  // ─── Antiguo (mantener compatibilidad) ───────────────────────────────────

  Future<String> agregarPaciente(Patient paciente) async {
    final ref = _db.collection('pacientes').doc();
    await ref.set(paciente.toMap());
    return ref.id;
  }

  Future<void> modificarPaciente(
      String id, Map<String, dynamic> datos) async {
    await _db.collection('pacientes').doc(id).update(datos);
  }
}
