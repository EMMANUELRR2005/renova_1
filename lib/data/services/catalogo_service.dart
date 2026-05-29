import 'package:cloud_firestore/cloud_firestore.dart';
import '../mock/mock_data.dart';

class CatalogoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Servicios ────────────────────────────────────────────────────────────
  // Evitamos orderBy en Firestore para no requerir índice compuesto.
  // Ordenamos en Dart después de obtener los datos.

  Stream<List<ServicioClinica>> streamServicios() {
    return _db
        .collection('servicios')
        .where('activo', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => ServicioClinica.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => a.nombre.compareTo(b.nombre));
          return list;
        });
  }

  Future<List<ServicioClinica>> getServicios() async {
    final snap = await _db
        .collection('servicios')
        .where('activo', isEqualTo: true)
        .get();
    final list = snap.docs
        .map((d) => ServicioClinica.fromMap(d.data(), d.id))
        .toList();
    list.sort((a, b) => a.nombre.compareTo(b.nombre));
    return list;
  }

  Future<String> crearServicio(ServicioClinica servicio) async {
    final ref = _db.collection('servicios').doc();
    await ref.set(servicio.toMap());
    return ref.id;
  }

  // ─── Clínicas ─────────────────────────────────────────────────────────────

  Stream<List<Clinica>> streamClinicas() {
    return _db
        .collection('clinicas')
        .where('activo', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => Clinica.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => a.nombre.compareTo(b.nombre));
          return list;
        });
  }

  Future<List<Clinica>> getClinicas() async {
    final snap = await _db
        .collection('clinicas')
        .where('activo', isEqualTo: true)
        .get();
    final list = snap.docs
        .map((d) => Clinica.fromMap(d.data(), d.id))
        .toList();
    list.sort((a, b) => a.nombre.compareTo(b.nombre));
    return list;
  }

  Future<String> crearClinica(Clinica clinica) async {
    final ref = _db.collection('clinicas').doc();
    await ref.set(clinica.toMap());
    return ref.id;
  }

  // ─── Doctoras (para citas) ────────────────────────────────────────────────
  // Solo un where con rol, sin orderBy para evitar índice compuesto

  Stream<List<Usuario>> streamDoctoras() {
    return _db
        .collection('usuarios')
        .where('rol', isEqualTo: 'doctora')
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => Usuario.fromMap(d.data(), d.id))
              .where((u) => u.activo)
              .toList();
          list.sort((a, b) => a.nombre.compareTo(b.nombre));
          return list;
        });
  }

  Future<List<Usuario>> getDoctoras() async {
    final snap = await _db
        .collection('usuarios')
        .where('rol', isEqualTo: 'doctora')
        .get();
    final list = snap.docs
        .map((d) => Usuario.fromMap(d.data(), d.id))
        .where((u) => u.activo)
        .toList();
    list.sort((a, b) => a.nombre.compareTo(b.nombre));
    return list;
  }
}
