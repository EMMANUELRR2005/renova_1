import 'package:cloud_firestore/cloud_firestore.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODELOS
// ════════════════════════════════════════════════════════════════════════════

class Medicamento {
  final String id;
  // Identificación
  final String nombre;
  final String nombreGenerico;
  final String marca;
  final String codigoBarras;
  final String codigoInterno;
  // Ubicación
  final String estante;
  final String descripcionEstante;
  // Inventario
  final int cantidad;
  final int cantidadMinima;
  final String unidad;
  // Información del producto
  final String categoria;
  final String descripcion;
  final String presentacion;
  final double precioCompra;
  final double precioVenta;
  final bool requiereReceta;
  // Fechas
  final String fechaVencimiento;
  final DateTime? fechaIngreso;
  // Auditoría
  final String creadoPor;
  final String nombreCreador;
  final DateTime? ultimaActualizacion;
  final String actualizadoPor;

  Medicamento({
    required this.id,
    required this.nombre,
    this.nombreGenerico = '',
    this.marca = '',
    this.codigoBarras = '',
    this.codigoInterno = '',
    this.estante = '',
    this.descripcionEstante = '',
    this.cantidad = 0,
    this.cantidadMinima = 0,
    this.unidad = 'tabletas',
    this.categoria = 'Otro',
    this.descripcion = '',
    this.presentacion = '',
    this.precioCompra = 0,
    this.precioVenta = 0,
    this.requiereReceta = false,
    this.fechaVencimiento = '',
    this.fechaIngreso,
    this.creadoPor = '',
    this.nombreCreador = '',
    this.ultimaActualizacion,
    this.actualizadoPor = '',
  });

  /// True si la cantidad está en o por debajo del mínimo configurado.
  bool get stockBajo => cantidad <= cantidadMinima;

  /// True si no hay existencias.
  bool get sinStock => cantidad <= 0;

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'nombreGenerico': nombreGenerico,
        'marca': marca,
        'codigoBarras': codigoBarras,
        'codigoInterno': codigoInterno,
        'estante': estante,
        'descripcionEstante': descripcionEstante,
        'cantidad': cantidad,
        'cantidadMinima': cantidadMinima,
        'unidad': unidad,
        'categoria': categoria,
        'descripcion': descripcion,
        'presentacion': presentacion,
        'precioCompra': precioCompra,
        'precioVenta': precioVenta,
        'requiereReceta': requiereReceta,
        'fechaVencimiento': fechaVencimiento,
      };

  factory Medicamento.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parseFecha(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return null;
    }

    return Medicamento(
      id: docId,
      nombre: map['nombre'] ?? '',
      nombreGenerico: map['nombreGenerico'] ?? '',
      marca: map['marca'] ?? '',
      codigoBarras: map['codigoBarras'] ?? '',
      codigoInterno: map['codigoInterno'] ?? '',
      estante: map['estante'] ?? '',
      descripcionEstante: map['descripcionEstante'] ?? '',
      cantidad: (map['cantidad'] ?? 0) is int
          ? map['cantidad'] ?? 0
          : (map['cantidad'] as num).toInt(),
      cantidadMinima: (map['cantidadMinima'] ?? 0) is int
          ? map['cantidadMinima'] ?? 0
          : (map['cantidadMinima'] as num).toInt(),
      unidad: map['unidad'] ?? 'tabletas',
      categoria: map['categoria'] ?? 'Otro',
      descripcion: map['descripcion'] ?? '',
      presentacion: map['presentacion'] ?? '',
      precioCompra: (map['precioCompra'] ?? 0).toDouble(),
      precioVenta: (map['precioVenta'] ?? 0).toDouble(),
      requiereReceta: map['requiereReceta'] ?? false,
      fechaVencimiento: map['fechaVencimiento'] ?? '',
      fechaIngreso: parseFecha(map['fechaIngreso']),
      creadoPor: map['creadoPor'] ?? '',
      nombreCreador: map['nombreCreador'] ?? '',
      ultimaActualizacion: parseFecha(map['ultimaActualizacion']),
      actualizadoPor: map['actualizadoPor'] ?? '',
    );
  }
}

class MovimientoFarmacia {
  final String id;
  final String tipo; // entrada | salida | venta | ajuste
  final String medicamentoId;
  final String nombreMedicamento;
  final int cantidad;
  final int cantidadAnterior;
  final int cantidadNueva;
  final String motivo;
  final String ventaId;
  final String realizadoPor;
  final String nombreResponsable;
  final DateTime? fecha;

  MovimientoFarmacia({
    required this.id,
    required this.tipo,
    required this.medicamentoId,
    required this.nombreMedicamento,
    required this.cantidad,
    required this.cantidadAnterior,
    required this.cantidadNueva,
    this.motivo = '',
    this.ventaId = '',
    this.realizadoPor = '',
    this.nombreResponsable = '',
    this.fecha,
  });

  factory MovimientoFarmacia.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parseFecha(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return null;
    }

    int parseInt(dynamic v) =>
        v is int ? v : (v is num ? v.toInt() : 0);

    return MovimientoFarmacia(
      id: docId,
      tipo: map['tipo'] ?? 'ajuste',
      medicamentoId: map['medicamentoId'] ?? '',
      nombreMedicamento: map['nombreMedicamento'] ?? '',
      cantidad: parseInt(map['cantidad']),
      cantidadAnterior: parseInt(map['cantidadAnterior']),
      cantidadNueva: parseInt(map['cantidadNueva']),
      motivo: map['motivo'] ?? '',
      ventaId: map['ventaId'] ?? '',
      realizadoPor: map['realizadoPor'] ?? '',
      nombreResponsable: map['nombreResponsable'] ?? '',
      fecha: parseFecha(map['fecha']),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SERVICIO
// ════════════════════════════════════════════════════════════════════════════

class FarmaciaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Medicamentos ──────────────────────────────────────────────────────────

  /// Stream en tiempo real del inventario, ordenado por nombre (en Dart para
  /// evitar índices compuestos).
  Stream<List<Medicamento>> streamMedicamentos() {
    return _db.collection('medicamentos').snapshots().map((snap) {
      final list =
          snap.docs.map((d) => Medicamento.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) =>
          a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      return list;
    });
  }

  /// Obtiene el inventario una sola vez (para buscadores en caja).
  Future<List<Medicamento>> getMedicamentos() async {
    final snap = await _db.collection('medicamentos').get();
    final list =
        snap.docs.map((d) => Medicamento.fromMap(d.data(), d.id)).toList();
    list.sort((a, b) =>
        a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return list;
  }

  /// Genera el siguiente código interno con formato MED-0001.
  Future<String> generarCodigoInterno() async {
    final snap = await _db.collection('medicamentos').get();
    final numero = snap.docs.length + 1;
    return 'MED-${numero.toString().padLeft(4, '0')}';
  }

  /// Busca un medicamento por su código de barras exacto. Retorna null si no
  /// existe.
  Future<Medicamento?> buscarPorCodigoBarras(String codigo) async {
    final snap = await _db
        .collection('medicamentos')
        .where('codigoBarras', isEqualTo: codigo)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return Medicamento.fromMap(doc.data(), doc.id);
  }

  Future<String> crearMedicamento(
    Medicamento med, {
    required String uid,
    required String nombreCreador,
  }) async {
    final ref = _db.collection('medicamentos').doc();
    await ref.set({
      ...med.toMap(),
      'id': ref.id,
      'creadoPor': uid,
      'nombreCreador': nombreCreador,
      'fechaIngreso': FieldValue.serverTimestamp(),
      'ultimaActualizacion': FieldValue.serverTimestamp(),
      'actualizadoPor': uid,
    });
    return ref.id;
  }

  Future<void> actualizarMedicamento(
    String id,
    Medicamento med, {
    required String uid,
  }) async {
    await _db.collection('medicamentos').doc(id).update({
      ...med.toMap(),
      'ultimaActualizacion': FieldValue.serverTimestamp(),
      'actualizadoPor': uid,
    });
  }

  Future<void> eliminarMedicamento(String id) async {
    await _db.collection('medicamentos').doc(id).delete();
  }

  /// Registra un movimiento de inventario (auditoría) sin tocar el stock.
  /// Útil al editar un medicamento cuando la cantidad cambió.
  Future<void> registrarMovimiento({
    required String tipo, // entrada | salida | ajuste
    required String medicamentoId,
    required String nombreMedicamento,
    required int cantidadAnterior,
    required int cantidadNueva,
    required String motivo,
    required String uid,
    required String nombreResponsable,
  }) async {
    final movRef = _db.collection('movimientos_farmacia').doc();
    await movRef.set({
      'id': movRef.id,
      'tipo': tipo,
      'medicamentoId': medicamentoId,
      'nombreMedicamento': nombreMedicamento,
      'cantidad': (cantidadNueva - cantidadAnterior).abs(),
      'cantidadAnterior': cantidadAnterior,
      'cantidadNueva': cantidadNueva,
      'motivo': motivo,
      'ventaId': '',
      'realizadoPor': uid,
      'nombreResponsable': nombreResponsable,
      'fecha': FieldValue.serverTimestamp(),
    });
  }

  // ── Movimientos ───────────────────────────────────────────────────────────

  Stream<List<MovimientoFarmacia>> streamMovimientos({int limite = 200}) {
    return _db
        .collection('movimientos_farmacia')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => MovimientoFarmacia.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) {
        final fa = a.fecha ?? DateTime(1970);
        final fb = b.fecha ?? DateTime(1970);
        return fb.compareTo(fa);
      });
      if (list.length > limite) return list.sublist(0, limite);
      return list;
    });
  }

  /// Ajuste/entrada manual de stock con registro de movimiento. Usa transacción
  /// para evitar condiciones de carrera.
  Future<void> ajustarStock({
    required String medicamentoId,
    required String nombreMedicamento,
    required int nuevaCantidad,
    required String tipo, // entrada | salida | ajuste
    required String motivo,
    required String uid,
    required String nombreResponsable,
  }) async {
    final medRef = _db.collection('medicamentos').doc(medicamentoId);
    final movRef = _db.collection('movimientos_farmacia').doc();

    await _db.runTransaction((transaction) async {
      final medSnap = await transaction.get(medRef);
      if (!medSnap.exists) {
        throw Exception('Medicamento no encontrado');
      }
      final cantidadAnterior = (medSnap.data()!['cantidad'] ?? 0) as int;

      transaction.update(medRef, {
        'cantidad': nuevaCantidad,
        'ultimaActualizacion': FieldValue.serverTimestamp(),
        'actualizadoPor': uid,
      });

      transaction.set(movRef, {
        'id': movRef.id,
        'tipo': tipo,
        'medicamentoId': medicamentoId,
        'nombreMedicamento': nombreMedicamento,
        'cantidad': (nuevaCantidad - cantidadAnterior).abs(),
        'cantidadAnterior': cantidadAnterior,
        'cantidadNueva': nuevaCantidad,
        'motivo': motivo,
        'ventaId': '',
        'realizadoPor': uid,
        'nombreResponsable': nombreResponsable,
        'fecha': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Descuenta una cantidad de stock por una venta en caja. Atómico: valida que
  /// haya stock suficiente y registra el movimiento de tipo 'venta'. Lanza una
  /// excepción si no hay suficiente stock.
  Future<void> descontarPorVenta({
    required String medicamentoId,
    required String nombreMedicamento,
    required int cantidad,
    required String ventaId,
    required String uid,
    required String nombreResponsable,
  }) async {
    final medRef = _db.collection('medicamentos').doc(medicamentoId);
    final movRef = _db.collection('movimientos_farmacia').doc();

    await _db.runTransaction((transaction) async {
      final medSnap = await transaction.get(medRef);
      if (!medSnap.exists) {
        throw Exception('Medicamento no encontrado: $nombreMedicamento');
      }
      final cantidadActual = (medSnap.data()!['cantidad'] ?? 0) as int;
      final cantidadNueva = cantidadActual - cantidad;

      if (cantidadNueva < 0) {
        throw Exception(
            'Stock insuficiente de $nombreMedicamento. Disponible: $cantidadActual');
      }

      transaction.update(medRef, {
        'cantidad': cantidadNueva,
        'ultimaActualizacion': FieldValue.serverTimestamp(),
        'actualizadoPor': uid,
      });

      transaction.set(movRef, {
        'id': movRef.id,
        'tipo': 'venta',
        'medicamentoId': medicamentoId,
        'nombreMedicamento': nombreMedicamento,
        'cantidad': cantidad,
        'cantidadAnterior': cantidadActual,
        'cantidadNueva': cantidadNueva,
        'motivo': 'Venta en caja',
        'ventaId': ventaId,
        'realizadoPor': uid,
        'nombreResponsable': nombreResponsable,
        'fecha': FieldValue.serverTimestamp(),
      });
    });
  }
}
