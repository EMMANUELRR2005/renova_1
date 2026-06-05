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
  // Ordenamos en Dart para evitar índices compuestos

  Stream<List<Paciente>> streamPacientes({String? filtroEstado}) {
    Query<Map<String, dynamic>> query = _db.collection('pacientes');
    if (filtroEstado != null && filtroEstado != 'todos') {
      query = query.where('estado', isEqualTo: filtroEstado);
    }
    return query.snapshots().map((snap) {
      final list = snap.docs
          .map((d) => Paciente.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) => a.apellido.compareTo(b.apellido));
      return list;
    });
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

  Future<void> actualizarFotoPaciente(String pacienteId, String fotoUrl) async {
    await _db.collection('pacientes').doc(pacienteId).update({
      'fotoUrl': fotoUrl,
    });
  }

  Stream<Paciente?> streamPacienteById(String id) {
    return _db.collection('pacientes').doc(id).snapshots().map(
        (doc) => doc.exists ? Paciente.fromMap(doc.data()!, doc.id) : null);
  }

  Future<Paciente?> getPacienteById(String id) async {
    final doc = await _db.collection('pacientes').doc(id).get();
    return doc.exists ? Paciente.fromMap(doc.data()!, doc.id) : null;
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

  // ─── Cambio de estado (Enfermera) ─────────────────────────────────────────

  Future<void> inactivarPaciente({
    required String pacienteId,
    required String servicioRealizado,
    required String servicioRealizadoId,
    required String enfermeraUid,
    required String nombreEnfermera,
  }) async {
    await _db.collection('pacientes').doc(pacienteId).update({
      'estado': 'inactivo',
      'servicioRealizado': servicioRealizado,
      'servicioRealizadoId': servicioRealizadoId,
      'fechaInactivacion': FieldValue.serverTimestamp(),
      'inactivadoPor': enfermeraUid,
      'nombreInactivador': nombreEnfermera,
    });

    // Guardar en historial del paciente
    await _db
        .collection('pacientes')
        .doc(pacienteId)
        .collection('historial')
        .add({
      'tipo': 'servicio_realizado',
      'fecha': FieldValue.serverTimestamp(),
      'servicio': servicioRealizado,
      'servicioId': servicioRealizadoId,
      'registradoPor': enfermeraUid,
      'nombreEnfermera': nombreEnfermera,
      'nota': 'Paciente marcado como inactivo',
      'creadoPor': enfermeraUid,
      'rol_creador': 'enfermera',
    });
  }

  Future<void> reactivarPaciente({
    required String pacienteId,
    required String enfermeraUid,
  }) async {
    await _db.collection('pacientes').doc(pacienteId).update({
      'estado': 'activo',
      'fechaReactivacion': FieldValue.serverTimestamp(),
      'reactivadoPor': enfermeraUid,
      'servicioRealizado': FieldValue.delete(),
      'servicioRealizadoId': FieldValue.delete(),
    });
  }

  // ─── Pacientes activos (para citas) ───────────────────────────────────────
  // Ordenamos en Dart para evitar índices compuestos

  Stream<List<Paciente>> streamPacientesActivos() {
    return _db
        .collection('pacientes')
        .where('estado', isEqualTo: 'activo')
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => Paciente.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => a.apellido.compareTo(b.apellido));
          return list;
        });
  }

  Future<List<Paciente>> buscarPacientesActivos(String query) async {
    final snap = await _db
        .collection('pacientes')
        .where('estado', isEqualTo: 'activo')
        .get();
    final queryLower = query.toLowerCase();
    return snap.docs
        .map((d) => Paciente.fromMap(d.data(), d.id))
        .where((p) =>
            p.nombreCompleto.toLowerCase().contains(queryLower) ||
            p.numeroIdentificacion.contains(query))
        .toList();
  }

  Future<int> contarPacientesActivos() async {
    final snap = await _db
        .collection('pacientes')
        .where('estado', isEqualTo: 'activo')
        .get();
    return snap.docs.length;
  }

  Future<int> contarPacientesNuevosMes() async {
    final inicioMes = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final snap = await _db.collection('pacientes').get();

    int count = 0;
    for (final doc in snap.docs) {
      final data = doc.data();
      final fechaCreacion = data['fechaCreacion'];
      if (fechaCreacion != null && fechaCreacion is Timestamp) {
        if (fechaCreacion.toDate().isAfter(inicioMes.subtract(const Duration(seconds: 1)))) {
          count++;
        }
      }
    }
    return count;
  }
}
