import 'package:cloud_firestore/cloud_firestore.dart';

/// Consulta realizada por la doctora que queda pendiente de cobro en caja.
/// Vive en la colección `consultas_pendientes_cobro` y se refleja además en el
/// historial del paciente (subcolección `historial`).
class ConsultaPendiente {
  final String id;
  final String pacienteId;
  final String nombrePaciente;
  final String telefonoPaciente;
  final String emailPaciente;
  final List<Map<String, dynamic>> procedimientos;
  final double totalEstimado;
  final String doctoraId;
  final String nombreDoctora;
  final String estado; // pendiente_cobro | cobrado
  final DateTime? fechaConsulta;
  final String motivo;
  final String diagnostico;
  final String tratamiento;
  final String notasPrivadas;
  final String notasParaCaja;
  final String clinicaId;
  final String clinica;

  ConsultaPendiente({
    required this.id,
    required this.pacienteId,
    required this.nombrePaciente,
    required this.telefonoPaciente,
    required this.emailPaciente,
    required this.procedimientos,
    required this.totalEstimado,
    required this.doctoraId,
    required this.nombreDoctora,
    required this.estado,
    this.fechaConsulta,
    this.motivo = '',
    this.diagnostico = '',
    this.tratamiento = '',
    this.notasPrivadas = '',
    this.notasParaCaja = '',
    this.clinicaId = '',
    this.clinica = '',
  });

  factory ConsultaPendiente.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parseFecha(dynamic v) => v is Timestamp ? v.toDate() : null;
    return ConsultaPendiente(
      id: docId,
      pacienteId: map['pacienteId'] ?? '',
      nombrePaciente: map['nombrePaciente'] ?? '',
      telefonoPaciente: map['telefonoPaciente'] ?? '',
      emailPaciente: map['emailPaciente'] ?? '',
      procedimientos: (map['procedimientos'] as List?)
              ?.map((p) => Map<String, dynamic>.from(p as Map))
              .toList() ??
          [],
      totalEstimado: (map['totalEstimado'] ?? 0).toDouble(),
      doctoraId: map['doctoraId'] ?? '',
      nombreDoctora: map['nombreDoctora'] ?? '',
      estado: map['estado'] ?? 'pendiente_cobro',
      fechaConsulta: parseFecha(map['fechaConsulta']),
      motivo: map['motivo'] ?? '',
      diagnostico: map['diagnostico'] ?? '',
      tratamiento: map['tratamiento'] ?? '',
      notasPrivadas: map['notasPrivadas'] ?? '',
      notasParaCaja: map['notasParaCaja'] ?? '',
      clinicaId: map['clinicaId'] ?? '',
      clinica: map['clinica'] ?? '',
    );
  }
}

class ConsultaCobroService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Crea la consulta de la doctora: la deja pendiente de cobro en caja y la
  /// registra en el historial del paciente (un solo batch atómico).
  /// Devuelve el id de la consulta.
  Future<String> crearConsulta({
    required String pacienteId,
    required String nombrePaciente,
    required String telefonoPaciente,
    required String emailPaciente,
    required List<Map<String, dynamic>> procedimientos,
    required double totalEstimado,
    required String doctoraId,
    required String nombreDoctora,
    String motivo = '',
    String diagnostico = '',
    String tratamiento = '',
    String comentarios = '',
    List<Map<String, dynamic>> medicamentos = const [],
    String notasPrivadas = '',
    String notasParaCaja = '',
    String? proximaCita,
    String clinicaId = '',
    String clinica = '',
    String rolCreador = 'doctora',
  }) async {
    final batch = _db.batch();

    final consultaRef = _db.collection('consultas_pendientes_cobro').doc();
    final consultaId = consultaRef.id;

    batch.set(consultaRef, {
      'id': consultaId,
      'pacienteId': pacienteId,
      'nombrePaciente': nombrePaciente,
      'telefonoPaciente': telefonoPaciente,
      'emailPaciente': emailPaciente,
      'procedimientos': procedimientos,
      'totalEstimado': totalEstimado,
      'doctoraId': doctoraId,
      'nombreDoctora': nombreDoctora,
      'estado': 'pendiente_cobro',
      'fechaConsulta': FieldValue.serverTimestamp(),
      'fechaCobro': null,
      'ventaId': null,
      'motivo': motivo,
      'diagnostico': diagnostico,
      'tratamiento': tratamiento,
      'notasPrivadas': notasPrivadas,
      'notasParaCaja': notasParaCaja,
      'clinicaId': clinicaId,
      'clinica': clinica,
    });

    // Entrada en el historial del paciente.
    final historialRef = _db
        .collection('pacientes')
        .doc(pacienteId)
        .collection('historial')
        .doc();

    batch.set(historialRef, {
      'tipo': 'consulta_medica',
      'consultaId': consultaId,
      'fecha': FieldValue.serverTimestamp(),
      'motivo': motivo,
      'diagnostico': diagnostico,
      'tratamiento': tratamiento,
      'comentarios': comentarios,
      'medicamentos': medicamentos,
      'procedimientos': procedimientos,
      'totalEstimado': totalEstimado,
      'notasPrivadas': notasPrivadas,
      'doctora': nombreDoctora,
      'doctora_uid': doctoraId,
      'creadoPor': doctoraId,
      'rol_creador': rolCreador,
      'proxima_cita': proximaCita,
      'estado': 'pendiente_cobro',
    });

    await batch.commit();
    return consultaId;
  }

  /// Stream de consultas pendientes de cobro (para la caja). Se ordena en Dart
  /// para no requerir índice compuesto en Firestore.
  Stream<List<ConsultaPendiente>> streamPendientes() {
    return _db
        .collection('consultas_pendientes_cobro')
        .where('estado', isEqualTo: 'pendiente_cobro')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => ConsultaPendiente.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) {
        final fa = a.fechaConsulta ?? DateTime(1970);
        final fb = b.fechaConsulta ?? DateTime(1970);
        return fb.compareTo(fa);
      });
      return list;
    });
  }

  /// Marca una consulta como cobrada: actualiza el documento pendiente y las
  /// entradas del historial del paciente asociadas a esa consulta.
  Future<void> marcarCobrada({
    required String consultaId,
    required String pacienteId,
    required String ventaId,
  }) async {
    await _db
        .collection('consultas_pendientes_cobro')
        .doc(consultaId)
        .update({
      'estado': 'cobrado',
      'fechaCobro': FieldValue.serverTimestamp(),
      'ventaId': ventaId,
    });

    if (pacienteId.isEmpty) return;

    final historial = await _db
        .collection('pacientes')
        .doc(pacienteId)
        .collection('historial')
        .where('consultaId', isEqualTo: consultaId)
        .get();

    for (final doc in historial.docs) {
      await doc.reference.update({
        'estado': 'cobrado',
        'fechaCobro': FieldValue.serverTimestamp(),
        'ventaId': ventaId,
      });
    }
  }
}
