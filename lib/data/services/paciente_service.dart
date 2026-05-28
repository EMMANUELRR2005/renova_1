import 'package:cloud_firestore/cloud_firestore.dart';
import '../mock/mock_data.dart';

class PacienteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream en tiempo real de todos los pacientes
  Stream<List<Patient>> getPacientes() {
    return _db.collection('pacientes')
        .orderBy('nombre')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Patient.fromMap(d.data(), d.id))
            .toList());
  }

  /// Agregar nuevo paciente (secretaria y enfermera pueden)
  Future<String> agregarPaciente(Patient paciente) async {
    final ref = _db.collection('pacientes').doc();
    await ref.set(paciente.toMap());
    return ref.id;
  }

  /// Modificar paciente (enfermera y doctor pueden)
  Future<void> modificarPaciente(String id, Map<String, dynamic> datos) async {
    await _db.collection('pacientes').doc(id).update(datos);
  }

  /// Eliminar paciente (solo administradora)
  Future<void> eliminarPaciente(String id) async {
    await _db.collection('pacientes').doc(id).delete();
  }

  /// Stream de un paciente específico
  Stream<Patient?> getPaciente(String id) {
    return _db.collection('pacientes').doc(id)
        .snapshots()
        .map((doc) => doc.exists
            ? Patient.fromMap(doc.data()!, doc.id)
            : null);
  }
}
