import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio de recetas médicas: numeración correlativa y persistencia tanto en
/// la colección global `recetas` como en el historial del paciente.
class RecetaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Genera el siguiente número de receta con formato REC-0001.
  Future<String> generarNumeroReceta() async {
    final snap = await _db.collection('recetas').get();
    final numero = snap.docs.length + 1;
    return 'REC-${numero.toString().padLeft(4, '0')}';
  }

  /// Guarda la receta en la colección global y en el historial del paciente.
  /// [medicamentos] es una lista de mapas con: nombre, dosis, frecuencia,
  /// duracion, instrucciones.
  Future<void> guardarReceta({
    required String pacienteId,
    required String nombrePaciente,
    required String numeroReceta,
    required String diagnostico,
    required List<Map<String, dynamic>> medicamentos,
    required String indicaciones,
    String? proximaCita,
    required String doctoraUid,
    required String nombreDoctora,
  }) async {
    // 1. Colección global (sirve para el correlativo y consultas futuras).
    final recetaRef = _db.collection('recetas').doc();
    await recetaRef.set({
      'id': recetaRef.id,
      'numeroReceta': numeroReceta,
      'pacienteId': pacienteId,
      'nombrePaciente': nombrePaciente,
      'diagnostico': diagnostico,
      'medicamentos': medicamentos,
      'indicaciones': indicaciones,
      'proximaCita': proximaCita ?? '',
      'doctoraUid': doctoraUid,
      'nombreDoctora': nombreDoctora,
      'fecha': FieldValue.serverTimestamp(),
    });

    // 2. Historial del paciente (tipo 'receta_medica').
    final histRef = _db
        .collection('pacientes')
        .doc(pacienteId)
        .collection('historial')
        .doc();
    await histRef.set({
      'id': histRef.id,
      'tipo': 'receta_medica',
      'fecha': FieldValue.serverTimestamp(),
      'numeroReceta': numeroReceta,
      'diagnostico': diagnostico,
      'medicamentos': medicamentos,
      // 'comentarios' permite que el render por defecto del historial muestre
      // las indicaciones generales.
      'comentarios': indicaciones,
      'proxima_cita': proximaCita ?? '',
      'doctora': nombreDoctora,
      'doctora_uid': doctoraUid,
      'creadoPor': doctoraUid,
      'rol_creador': 'doctora',
    });
  }
}
