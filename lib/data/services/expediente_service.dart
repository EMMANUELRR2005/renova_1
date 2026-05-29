import 'package:cloud_firestore/cloud_firestore.dart';

class Expediente {
  final String id;
  final String pacienteId;
  final String nombrePaciente;
  final String numeroExpediente;
  final String servicio;
  final String clinica;
  final String doctora;
  final String doctoraId;
  final DateTime fechaApertura;
  final String estado; // abierto, cerrado
  final String creadoPor;
  final DateTime? ultimaActualizacion;

  Expediente({
    required this.id,
    required this.pacienteId,
    required this.nombrePaciente,
    required this.numeroExpediente,
    required this.servicio,
    required this.clinica,
    required this.doctora,
    required this.doctoraId,
    required this.fechaApertura,
    required this.estado,
    required this.creadoPor,
    this.ultimaActualizacion,
  });

  factory Expediente.fromMap(Map<String, dynamic> map, String docId) {
    return Expediente(
      id: docId,
      pacienteId: map['pacienteId'] ?? '',
      nombrePaciente: map['nombrePaciente'] ?? '',
      numeroExpediente: map['numeroExpediente'] ?? '',
      servicio: map['servicio'] ?? '',
      clinica: map['clinica'] ?? '',
      doctora: map['doctora'] ?? '',
      doctoraId: map['doctoraId'] ?? '',
      fechaApertura: (map['fechaApertura'] as Timestamp?)?.toDate() ?? DateTime.now(),
      estado: map['estado'] ?? 'abierto',
      creadoPor: map['creadoPor'] ?? '',
      ultimaActualizacion: (map['ultimaActualizacion'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pacienteId': pacienteId,
      'nombrePaciente': nombrePaciente,
      'numeroExpediente': numeroExpediente,
      'servicio': servicio,
      'clinica': clinica,
      'doctora': doctora,
      'doctoraId': doctoraId,
      'fechaApertura': FieldValue.serverTimestamp(),
      'estado': estado,
      'creadoPor': creadoPor,
      'ultimaActualizacion': FieldValue.serverTimestamp(),
    };
  }
}

class EntradaExpediente {
  final String id;
  final String tipo; // consulta, nota, procedimiento, medicamento, resultado
  final DateTime fecha;
  final String titulo;
  final String descripcion;
  final List<String> archivos;
  final String creadoPor;
  final String nombreCreador;
  final String rolCreador;

  EntradaExpediente({
    required this.id,
    required this.tipo,
    required this.fecha,
    required this.titulo,
    required this.descripcion,
    required this.archivos,
    required this.creadoPor,
    required this.nombreCreador,
    required this.rolCreador,
  });

  factory EntradaExpediente.fromMap(Map<String, dynamic> map, String docId) {
    return EntradaExpediente(
      id: docId,
      tipo: map['tipo'] ?? 'nota',
      fecha: (map['fecha'] as Timestamp?)?.toDate() ?? DateTime.now(),
      titulo: map['titulo'] ?? '',
      descripcion: map['descripcion'] ?? '',
      archivos: List<String>.from(map['archivos'] ?? []),
      creadoPor: map['creadoPor'] ?? '',
      nombreCreador: map['nombreCreador'] ?? '',
      rolCreador: map['rolCreador'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'fecha': FieldValue.serverTimestamp(),
      'titulo': titulo,
      'descripcion': descripcion,
      'archivos': archivos,
      'creadoPor': creadoPor,
      'nombreCreador': nombreCreador,
      'rolCreador': rolCreador,
    };
  }

  String get tipoDisplay {
    switch (tipo) {
      case 'consulta':
        return 'Consulta';
      case 'nota':
        return 'Nota';
      case 'procedimiento':
        return 'Procedimiento';
      case 'medicamento':
        return 'Medicamento';
      case 'resultado':
        return 'Resultado';
      default:
        return tipo;
    }
  }
}

class ExpedienteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> generarNumeroExpediente() async {
    final snap = await _db.collection('expedientes').get();
    final numero = snap.docs.length + 1;
    return 'EXP-${numero.toString().padLeft(4, '0')}';
  }

  Future<String> crearExpediente(Expediente expediente) async {
    final ref = _db.collection('expedientes').doc();
    await ref.set(expediente.toMap());
    return ref.id;
  }

  Stream<List<Expediente>> streamExpedientes({String? filtroEstado}) {
    return _db.collection('expedientes').snapshots().map((snap) {
      var list = snap.docs
          .map((d) => Expediente.fromMap(d.data(), d.id))
          .toList();

      if (filtroEstado != null && filtroEstado != 'todos') {
        list = list.where((e) => e.estado == filtroEstado).toList();
      }

      list.sort((a, b) => b.fechaApertura.compareTo(a.fechaApertura));
      return list;
    });
  }

  Stream<Expediente?> streamExpedienteById(String id) {
    return _db.collection('expedientes').doc(id).snapshots().map(
        (doc) => doc.exists ? Expediente.fromMap(doc.data()!, doc.id) : null);
  }

  Stream<Expediente?> streamExpedientePorPaciente(String pacienteId) {
    return _db
        .collection('expedientes')
        .where('pacienteId', isEqualTo: pacienteId)
        .limit(1)
        .snapshots()
        .map((snap) =>
            snap.docs.isEmpty ? null : Expediente.fromMap(snap.docs.first.data(), snap.docs.first.id));
  }

  Future<void> cerrarExpediente(String expedienteId) async {
    await _db.collection('expedientes').doc(expedienteId).update({
      'estado': 'cerrado',
      'ultimaActualizacion': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reabrirExpediente(String expedienteId) async {
    await _db.collection('expedientes').doc(expedienteId).update({
      'estado': 'abierto',
      'ultimaActualizacion': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<EntradaExpediente>> streamEntradas(String expedienteId) {
    return _db
        .collection('expedientes')
        .doc(expedienteId)
        .collection('entradas')
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => EntradaExpediente.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.fecha.compareTo(a.fecha));
          return list;
        });
  }

  Future<String> agregarEntrada(String expedienteId, EntradaExpediente entrada) async {
    final ref = _db
        .collection('expedientes')
        .doc(expedienteId)
        .collection('entradas')
        .doc();
    await ref.set(entrada.toMap());

    await _db.collection('expedientes').doc(expedienteId).update({
      'ultimaActualizacion': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  Future<int> contarExpedientesAbiertos() async {
    final snap = await _db
        .collection('expedientes')
        .where('estado', isEqualTo: 'abierto')
        .get();
    return snap.docs.length;
  }

  Future<int> contarExpedientesCerrados() async {
    final snap = await _db
        .collection('expedientes')
        .where('estado', isEqualTo: 'cerrado')
        .get();
    return snap.docs.length;
  }
}
