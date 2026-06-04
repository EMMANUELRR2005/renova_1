import 'package:cloud_firestore/cloud_firestore.dart';

// ════════════════════════════════════════════════════════════════════════════
// MODELOS
// ════════════════════════════════════════════════════════════════════════════

class ProductoBoutique {
  final String id;
  // Identificación
  final String nombre;
  final String descripcion;
  final String marca;
  final String codigoBarras;
  final String codigoInterno;
  final String categoria;
  // Imagen
  final String fotoUrl;
  // Variantes
  final String talla;
  final String color;
  // Ubicación
  final String estante;
  final String descripcionEstante;
  // Inventario
  final int cantidad;
  final int cantidadMinima;
  final String unidad;
  // Precios
  final double precioCompra;
  final double precioVenta;
  // Auditoría
  final DateTime? fechaIngreso;
  final String creadoPor;
  final String nombreCreador;
  final DateTime? ultimaActualizacion;
  final String actualizadoPor;

  ProductoBoutique({
    required this.id,
    required this.nombre,
    this.descripcion = '',
    this.marca = '',
    this.codigoBarras = '',
    this.codigoInterno = '',
    this.categoria = 'Otro',
    this.fotoUrl = '',
    this.talla = 'N/A',
    this.color = 'N/A',
    this.estante = '',
    this.descripcionEstante = '',
    this.cantidad = 0,
    this.cantidadMinima = 0,
    this.unidad = 'unidades',
    this.precioCompra = 0,
    this.precioVenta = 0,
    this.fechaIngreso,
    this.creadoPor = '',
    this.nombreCreador = '',
    this.ultimaActualizacion,
    this.actualizadoPor = '',
  });

  bool get stockBajo => cantidad <= cantidadMinima;
  bool get sinStock => cantidad <= 0;

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'marca': marca,
        'codigoBarras': codigoBarras,
        'codigoInterno': codigoInterno,
        'categoria': categoria,
        'fotoUrl': fotoUrl,
        'talla': talla,
        'color': color,
        'estante': estante,
        'descripcionEstante': descripcionEstante,
        'cantidad': cantidad,
        'cantidadMinima': cantidadMinima,
        'unidad': unidad,
        'precioCompra': precioCompra,
        'precioVenta': precioVenta,
      };

  factory ProductoBoutique.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parseFecha(dynamic v) => v is Timestamp ? v.toDate() : null;
    int parseInt(dynamic v) =>
        v is int ? v : (v is num ? v.toInt() : 0);

    return ProductoBoutique(
      id: docId,
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      marca: map['marca'] ?? '',
      codigoBarras: map['codigoBarras'] ?? '',
      codigoInterno: map['codigoInterno'] ?? '',
      categoria: map['categoria'] ?? 'Otro',
      fotoUrl: map['fotoUrl'] ?? '',
      talla: map['talla'] ?? 'N/A',
      color: map['color'] ?? 'N/A',
      estante: map['estante'] ?? '',
      descripcionEstante: map['descripcionEstante'] ?? '',
      cantidad: parseInt(map['cantidad']),
      cantidadMinima: parseInt(map['cantidadMinima']),
      unidad: map['unidad'] ?? 'unidades',
      precioCompra: (map['precioCompra'] ?? 0).toDouble(),
      precioVenta: (map['precioVenta'] ?? 0).toDouble(),
      fechaIngreso: parseFecha(map['fechaIngreso']),
      creadoPor: map['creadoPor'] ?? '',
      nombreCreador: map['nombreCreador'] ?? '',
      ultimaActualizacion: parseFecha(map['ultimaActualizacion']),
      actualizadoPor: map['actualizadoPor'] ?? '',
    );
  }
}

class MovimientoBoutique {
  final String id;
  final String tipo; // entrada | salida | venta | ajuste | eliminacion
  final String productoId;
  final String nombreProducto;
  final int cantidad;
  final int cantidadAnterior;
  final int cantidadNueva;
  final String motivo;
  final String ventaId;
  final String realizadoPor;
  final String nombreResponsable;
  final DateTime? fecha;

  MovimientoBoutique({
    required this.id,
    required this.tipo,
    required this.productoId,
    required this.nombreProducto,
    required this.cantidad,
    required this.cantidadAnterior,
    required this.cantidadNueva,
    this.motivo = '',
    this.ventaId = '',
    this.realizadoPor = '',
    this.nombreResponsable = '',
    this.fecha,
  });

  factory MovimientoBoutique.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parseFecha(dynamic v) => v is Timestamp ? v.toDate() : null;
    int parseInt(dynamic v) => v is int ? v : (v is num ? v.toInt() : 0);
    return MovimientoBoutique(
      id: docId,
      tipo: map['tipo'] ?? 'ajuste',
      productoId: map['productoId'] ?? '',
      nombreProducto: map['nombreProducto'] ?? '',
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

class BoutiqueService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ProductoBoutique>> streamProductos() {
    return _db.collection('boutique').snapshots().map((snap) {
      final list = snap.docs
          .map((d) => ProductoBoutique.fromMap(d.data(), d.id))
          .toList();
      list.sort((a, b) =>
          a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      return list;
    });
  }

  Future<List<ProductoBoutique>> getProductos() async {
    final snap = await _db.collection('boutique').get();
    final list = snap.docs
        .map((d) => ProductoBoutique.fromMap(d.data(), d.id))
        .toList();
    list.sort(
        (a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return list;
  }

  Future<String> generarCodigoInterno() async {
    final snap = await _db.collection('boutique').get();
    final numero = snap.docs.length + 1;
    return 'BUT-${numero.toString().padLeft(4, '0')}';
  }

  Future<String> crearProducto(
    ProductoBoutique p, {
    required String uid,
    required String nombreCreador,
  }) async {
    final ref = _db.collection('boutique').doc();
    await ref.set({
      ...p.toMap(),
      'id': ref.id,
      'creadoPor': uid,
      'nombreCreador': nombreCreador,
      'fechaIngreso': FieldValue.serverTimestamp(),
      'ultimaActualizacion': FieldValue.serverTimestamp(),
      'actualizadoPor': uid,
    });
    return ref.id;
  }

  Future<void> actualizarProducto(
    String id,
    ProductoBoutique p, {
    required String uid,
  }) async {
    await _db.collection('boutique').doc(id).update({
      ...p.toMap(),
      'ultimaActualizacion': FieldValue.serverTimestamp(),
      'actualizadoPor': uid,
    });
  }

  Future<void> actualizarFoto(String id, String url) async {
    await _db.collection('boutique').doc(id).update({'fotoUrl': url});
  }

  Future<void> eliminarProducto(String id) async {
    await _db.collection('boutique').doc(id).delete();
  }

  Future<void> registrarMovimiento({
    required String tipo,
    required String productoId,
    required String nombreProducto,
    required int cantidadAnterior,
    required int cantidadNueva,
    required String motivo,
    required String uid,
    required String nombreResponsable,
  }) async {
    final movRef = _db.collection('movimientos_boutique').doc();
    await movRef.set({
      'id': movRef.id,
      'tipo': tipo,
      'productoId': productoId,
      'nombreProducto': nombreProducto,
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

  Stream<List<MovimientoBoutique>> streamMovimientos({int limite = 200}) {
    return _db.collection('movimientos_boutique').snapshots().map((snap) {
      final list = snap.docs
          .map((d) => MovimientoBoutique.fromMap(d.data(), d.id))
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

  /// Descuenta stock por una venta en caja (atómico). Lanza excepción si no hay
  /// stock suficiente.
  Future<void> descontarPorVenta({
    required String productoId,
    required String nombreProducto,
    required int cantidad,
    required String ventaId,
    required String uid,
    required String nombreResponsable,
  }) async {
    final prodRef = _db.collection('boutique').doc(productoId);
    final movRef = _db.collection('movimientos_boutique').doc();

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(prodRef);
      if (!snap.exists) {
        throw Exception('Producto no encontrado: $nombreProducto');
      }
      final cantidadActual = (snap.data()!['cantidad'] ?? 0) as int;
      final cantidadNueva = cantidadActual - cantidad;
      if (cantidadNueva < 0) {
        throw Exception(
            'Stock insuficiente de $nombreProducto. Disponible: $cantidadActual');
      }

      transaction.update(prodRef, {
        'cantidad': cantidadNueva,
        'ultimaActualizacion': FieldValue.serverTimestamp(),
        'actualizadoPor': uid,
      });

      transaction.set(movRef, {
        'id': movRef.id,
        'tipo': 'venta',
        'productoId': productoId,
        'nombreProducto': nombreProducto,
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
