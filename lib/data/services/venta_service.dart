import 'package:cloud_firestore/cloud_firestore.dart';

class ItemVenta {
  String servicioId;
  String servicio;
  String clinicaId;
  String clinica;
  String descripcion;
  double monto;

  ItemVenta({
    required this.servicioId,
    required this.servicio,
    required this.clinicaId,
    required this.clinica,
    this.descripcion = '',
    required this.monto,
  });

  factory ItemVenta.fromMap(Map<String, dynamic> map) {
    return ItemVenta(
      servicioId: map['servicioId'] ?? '',
      servicio: map['servicio'] ?? '',
      clinicaId: map['clinicaId'] ?? '',
      clinica: map['clinica'] ?? '',
      descripcion: map['descripcion'] ?? '',
      monto: (map['monto'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'servicioId': servicioId,
        'servicio': servicio,
        'clinicaId': clinicaId,
        'clinica': clinica,
        'descripcion': descripcion,
        'monto': monto,
        'subtotal': monto,
      };
}

class Venta {
  final String id;
  final String pacienteId;
  final String nombrePaciente;
  final String telefonoPaciente;
  final String nitCliente;
  final List<ItemVenta> items;
  final String servicio;
  final String servicioId;
  final String clinica;
  final String clinicaId;
  final String descripcion;
  final double subtotalSinIva;
  final double iva;
  final double monto;
  final String metodoPago;
  final int cuotas;
  final String referencia;
  final String estado;
  final String cobradoPor;
  final String nombreSecretaria;
  final DateTime fechaVenta;
  final String numeroCorrelativo;
  final String? motivoAnulacion;

  Venta({
    required this.id,
    required this.pacienteId,
    required this.nombrePaciente,
    required this.telefonoPaciente,
    this.nitCliente = 'CF',
    required this.items,
    required this.servicio,
    required this.servicioId,
    required this.clinica,
    required this.clinicaId,
    required this.descripcion,
    required this.subtotalSinIva,
    required this.iva,
    required this.monto,
    required this.metodoPago,
    required this.cuotas,
    required this.referencia,
    required this.estado,
    required this.cobradoPor,
    required this.nombreSecretaria,
    required this.fechaVenta,
    required this.numeroCorrelativo,
    this.motivoAnulacion,
  });

  factory Venta.fromMap(Map<String, dynamic> map, String docId) {
    final itemsList = (map['items'] as List<dynamic>?)
            ?.map((i) => ItemVenta.fromMap(i as Map<String, dynamic>))
            .toList() ??
        [];

    return Venta(
      id: docId,
      pacienteId: map['pacienteId'] ?? '',
      nombrePaciente: map['nombrePaciente'] ?? '',
      telefonoPaciente: map['telefonoPaciente'] ?? '',
      nitCliente: map['nitCliente'] ?? 'CF',
      items: itemsList,
      servicio: map['servicio'] ?? '',
      servicioId: map['servicioId'] ?? '',
      clinica: map['clinica'] ?? '',
      clinicaId: map['clinicaId'] ?? '',
      descripcion: map['descripcion'] ?? '',
      subtotalSinIva: (map['subtotalSinIva'] ?? map['monto'] ?? 0).toDouble() /
          (map['subtotalSinIva'] != null ? 1 : 1.12),
      iva: (map['iva'] ?? 0).toDouble(),
      monto: (map['monto'] ?? 0).toDouble(),
      metodoPago: map['metodoPago'] ?? 'efectivo',
      cuotas: map['cuotas'] ?? 0,
      referencia: map['referencia'] ?? '',
      estado: map['estado'] ?? 'pagado',
      cobradoPor: map['cobradoPor'] ?? '',
      nombreSecretaria: map['nombreSecretaria'] ?? '',
      fechaVenta:
          (map['fechaVenta'] as Timestamp?)?.toDate() ?? DateTime.now(),
      numeroCorrelativo: map['numeroCorrelativo'] ?? '',
      motivoAnulacion: map['motivoAnulacion'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pacienteId': pacienteId,
      'nombrePaciente': nombrePaciente,
      'telefonoPaciente': telefonoPaciente,
      'nitCliente': nitCliente,
      'items': items.map((i) => i.toMap()).toList(),
      'servicio': servicio,
      'servicioId': servicioId,
      'clinica': clinica,
      'clinicaId': clinicaId,
      'descripcion': descripcion,
      'subtotalSinIva': subtotalSinIva,
      'iva': iva,
      'monto': monto,
      'metodoPago': metodoPago,
      'cuotas': cuotas,
      'referencia': referencia,
      'estado': estado,
      'cobradoPor': cobradoPor,
      'nombreSecretaria': nombreSecretaria,
      'fechaVenta': FieldValue.serverTimestamp(),
      'numeroCorrelativo': numeroCorrelativo,
      if (motivoAnulacion != null) 'motivoAnulacion': motivoAnulacion,
    };
  }

  String get metodoPagoDisplay {
    switch (metodoPago) {
      case 'efectivo':
        return 'Efectivo';
      case 'tarjeta':
        return 'Tarjeta';
      case 'visa_cuotas':
        return 'Visa Cuotas ($cuotas)';
      default:
        return metodoPago;
    }
  }

  String get serviciosResumen {
    if (items.isEmpty) return servicio;
    if (items.length == 1) return items.first.servicio;
    return '${items.first.servicio} (+${items.length - 1})';
  }
}

class VentaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> generarCorrelativo() async {
    final snap = await _db.collection('ventas').get();
    final numero = snap.docs.length + 1;
    return 'VTA-${numero.toString().padLeft(4, '0')}';
  }

  Future<String> crearVenta(Venta venta) async {
    final ref = _db.collection('ventas').doc();
    await ref.set(venta.toMap());
    return ref.id;
  }

  Stream<List<Venta>> streamVentasHoy() {
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    final fin = inicio.add(const Duration(days: 1));

    return _db
        .collection('ventas')
        .where('fechaVenta',
            isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fechaVenta', isLessThan: Timestamp.fromDate(fin))
        .snapshots()
        .map((snap) {
      final list =
          snap.docs.map((d) => Venta.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.fechaVenta.compareTo(a.fechaVenta));
      return list;
    });
  }

  Stream<List<Venta>> streamVentasSemana() {
    final hoy = DateTime.now();
    final inicioSemana = hoy.subtract(Duration(days: hoy.weekday - 1));
    final inicio =
        DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day);

    return _db.collection('ventas').snapshots().map((snap) {
      final list = snap.docs
          .map((d) => Venta.fromMap(d.data(), d.id))
          .where((v) =>
              v.fechaVenta.isAfter(inicio.subtract(const Duration(seconds: 1))))
          .toList();
      list.sort((a, b) => b.fechaVenta.compareTo(a.fechaVenta));
      return list;
    });
  }

  Stream<List<Venta>> streamTodasLasVentas() {
    return _db.collection('ventas').snapshots().map((snap) {
      final list =
          snap.docs.map((d) => Venta.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.fechaVenta.compareTo(a.fechaVenta));
      return list;
    });
  }

  Future<void> anularVenta(String ventaId, String motivo) async {
    await _db.collection('ventas').doc(ventaId).update({
      'estado': 'anulado',
      'motivoAnulacion': motivo,
    });
  }

  Future<Map<String, dynamic>> getResumenHoy() async {
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    final fin = inicio.add(const Duration(days: 1));

    final snap = await _db
        .collection('ventas')
        .where('fechaVenta',
            isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fechaVenta', isLessThan: Timestamp.fromDate(fin))
        .get();

    double totalEfectivo = 0;
    double totalTarjeta = 0;
    double totalVisaCuotas = 0;
    int transacciones = 0;

    for (final doc in snap.docs) {
      final venta = Venta.fromMap(doc.data(), doc.id);
      if (venta.estado != 'anulado') {
        transacciones++;
        switch (venta.metodoPago) {
          case 'efectivo':
            totalEfectivo += venta.monto;
            break;
          case 'tarjeta':
            totalTarjeta += venta.monto;
            break;
          case 'visa_cuotas':
            totalVisaCuotas += venta.monto;
            break;
        }
      }
    }

    return {
      'totalCobrado': totalEfectivo + totalTarjeta + totalVisaCuotas,
      'totalEfectivo': totalEfectivo,
      'totalTarjeta': totalTarjeta,
      'totalVisaCuotas': totalVisaCuotas,
      'transacciones': transacciones,
    };
  }

  Future<Map<String, dynamic>> getResumenMes() async {
    final hoy = DateTime.now();
    final inicioMes = DateTime(hoy.year, hoy.month, 1);

    final snap = await _db.collection('ventas').get();

    double total = 0;
    int transacciones = 0;
    Map<String, double> porMetodo = {
      'efectivo': 0,
      'tarjeta': 0,
      'visa_cuotas': 0,
    };

    for (final doc in snap.docs) {
      final venta = Venta.fromMap(doc.data(), doc.id);
      if (venta.estado != 'anulado' &&
          venta.fechaVenta
              .isAfter(inicioMes.subtract(const Duration(seconds: 1)))) {
        transacciones++;
        total += venta.monto;
        porMetodo[venta.metodoPago] =
            (porMetodo[venta.metodoPago] ?? 0) + venta.monto;
      }
    }

    return {
      'total': total,
      'transacciones': transacciones,
      'porMetodo': porMetodo,
    };
  }

  Future<List<Map<String, dynamic>>> getIngresosUltimos6Meses() async {
    final ahora = DateTime.now();
    final resultados = <Map<String, dynamic>>[];

    // Obtener todas las ventas una sola vez para evitar índices compuestos
    final snap = await _db.collection('ventas').get();
    final ventas = snap.docs.map((d) => Venta.fromMap(d.data(), d.id)).toList();

    for (int i = 5; i >= 0; i--) {
      final mes = DateTime(ahora.year, ahora.month - i, 1);
      final siguiente = DateTime(ahora.year, ahora.month - i + 1, 1);

      double total = 0;
      for (var venta in ventas) {
        if (venta.estado != 'anulado' &&
            venta.fechaVenta.isAfter(mes.subtract(const Duration(seconds: 1))) &&
            venta.fechaVenta.isBefore(siguiente)) {
          total += venta.monto;
        }
      }

      resultados.add({
        'mes': mes.month,
        'anio': mes.year,
        'total': total,
      });
    }

    return resultados;
  }

  Future<Map<String, int>> getServiciosPorMes() async {
    final inicio = DateTime(DateTime.now().year, DateTime.now().month, 1);

    // Evitar índices compuestos: traer todo y filtrar en cliente
    final snap = await _db.collection('ventas').get();

    final Map<String, int> conteo = {};
    for (var doc in snap.docs) {
      final venta = Venta.fromMap(doc.data(), doc.id);

      // Filtrar: solo ventas del mes actual y no anuladas
      if (venta.estado == 'anulado' ||
          venta.fechaVenta.isBefore(inicio)) {
        continue;
      }

      if (venta.items.isNotEmpty) {
        for (var item in venta.items) {
          final servicio = item.servicio.isNotEmpty ? item.servicio : 'Otro';
          conteo[servicio] = (conteo[servicio] ?? 0) + 1;
        }
      } else if (venta.servicio.isNotEmpty) {
        conteo[venta.servicio] = (conteo[venta.servicio] ?? 0) + 1;
      }
    }

    return conteo;
  }

  Future<Map<String, double>> getMetodosPagoMes() async {
    final inicio = DateTime(DateTime.now().year, DateTime.now().month, 1);

    // Evitar índices compuestos: traer todo y filtrar en cliente
    final snap = await _db.collection('ventas').get();

    final Map<String, double> totales = {
      'efectivo': 0,
      'tarjeta': 0,
      'visa_cuotas': 0,
    };

    for (var doc in snap.docs) {
      final venta = Venta.fromMap(doc.data(), doc.id);

      // Filtrar: solo ventas del mes actual y no anuladas
      if (venta.estado == 'anulado' ||
          venta.fechaVenta.isBefore(inicio)) {
        continue;
      }

      totales[venta.metodoPago] = (totales[venta.metodoPago] ?? 0) + venta.monto;
    }

    return totales;
  }
}
