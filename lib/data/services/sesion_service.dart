import 'package:cloud_firestore/cloud_firestore.dart';
import '../mock/mock_data.dart';

class SesionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Registrar nueva sesión
  Future<void> registrarSesion(SesionTerapia sesion) async {
    final ref = _db.collection('sesiones').doc();
    await ref.set(sesion.toMap());
    
    // Actualizar sesionesCompletadas del plan si existe
    final planes = await _db.collection('planes')
        .where('pacienteId', isEqualTo: sesion.pacienteId)
        .where('activo', isEqualTo: true)
        .get();
    
    if (planes.docs.isNotEmpty) {
      final plan = planes.docs.first;
      final completadas = (plan.data()['sesionesCompletadas'] ?? 0) + 1;
      await plan.reference.update({'sesionesCompletadas': completadas});
    }
  }

  /// Stream de sesiones de un paciente
  Stream<List<SesionTerapia>> getSesionesPaciente(String pacienteId) {
    return _db.collection('sesiones')
        .where('pacienteId', isEqualTo: pacienteId)
        .orderBy('fechaHoraInicio', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SesionTerapia.fromMap(d.data(), d.id))
            .toList());
  }

  /// Stream de sesiones activas (sin fecha fin)
  Stream<List<SesionTerapia>> getSesionesActivas() {
    return _db.collection('sesiones')
        .where('fechaHoraFin', isNull: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SesionTerapia.fromMap(d.data(), d.id))
            .toList());
  }
}
