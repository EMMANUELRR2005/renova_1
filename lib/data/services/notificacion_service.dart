import 'package:cloud_firestore/cloud_firestore.dart';

class NotificacionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> crearNotificacionCita({
    required String doctoraId,
    required String nombrePaciente,
    required String fecha,
    required String hora,
    String citaId = '',
    String pacienteId = '',
  }) async {
    if (doctoraId.isEmpty) return;
    final ref = _db.collection('notificaciones').doc();
    await ref.set({
      'id': ref.id,
      'destinatarioId': doctoraId,
      'tipo': 'nueva_cita_asignada',
      'titulo': 'Nueva cita asignada',
      'mensaje':
          'Tienes una nueva cita con $nombrePaciente el $fecha a las $hora',
      'datos': {
        'nombrePaciente': nombrePaciente,
        'fecha': fecha,
        'hora': hora,
        if (citaId.isNotEmpty) 'citaId': citaId,
        if (pacienteId.isNotEmpty) 'pacienteId': pacienteId,
      },
      'leida': false,
      'fecha': FieldValue.serverTimestamp(),
    });
  }

  /// Stream del número de notificaciones no leídas para un usuario.
  Stream<int> streamCantidadNoLeidas(String usuarioId) {
    if (usuarioId.isEmpty) return Stream.value(0);
    return _db
        .collection('notificaciones')
        .where('destinatarioId', isEqualTo: usuarioId)
        .where('leida', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Stream de todas las notificaciones del usuario, ordenadas por fecha.
  Stream<QuerySnapshot<Map<String, dynamic>>> streamNotificaciones(
      String usuarioId) {
    return _db
        .collection('notificaciones')
        .where('destinatarioId', isEqualTo: usuarioId)
        .snapshots();
  }

  Future<void> marcarLeida(String notifId) async {
    await _db
        .collection('notificaciones')
        .doc(notifId)
        .update({'leida': true});
  }

  Future<void> marcarTodasLeidas(String usuarioId) async {
    final snap = await _db
        .collection('notificaciones')
        .where('destinatarioId', isEqualTo: usuarioId)
        .where('leida', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.update({'leida': true});
    }
  }
}
