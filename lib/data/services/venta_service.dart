import 'package:cloud_firestore/cloud_firestore.dart';
import '../mock/mock_data.dart';

class Venta {
  final String id;
  final String pacienteId;
  final String nombrePaciente;
  final String telefonoPaciente;
  final String servicio;
  final String servicioId;
  final String clinica;
  final String clinicaId;
  final String descripcion;
  final double monto;
  final String metodoPago; // efectivo, tarjeta, visa_cuotas
  final int cuotas;
  final String referencia;
  final String estado; // pagado, pendiente, anulado
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
    required this.servicio,
    required this.servicioId,
    required this.clinica,
    required this.clinicaId,
    required this.descripcion,
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
    return Venta(
      id: docId,
      pacienteId: map['pacienteId'] ?? '',
      nombrePaciente: map['nombrePaciente'] ?? '',
      telefonoPaciente: map['telefonoPaciente'] ?? '',
      servicio: map['servicio'] ?? '',
      servicioId: map['servicioId'] ?? '',
      clinica: map['clinica'] ?? '',
      clinicaId: map['clinicaId'] ?? '',
      descripcion: map['descripcion'] ?? '',
      monto: (map['monto'] ?? 0).toDouble(),
      metodoPago: map['metodoPago'] ?? 'efectivo',
      cuotas: map['cuotas'] ?? 0,
      referencia: map['referencia'] ?? '',
      estado: map['estado'] ?? 'pagado',
      cobradoPor: map['cobradoPor'] ?? '',
      nombreSecretaria: map['nombreSecretaria'] ?? '',
      fechaVenta: (map['fechaVenta'] as Timestamp?)?.toDate() ?? DateTime.now(),
      numeroCorrelativo: map['numeroCorrelativo'] ?? '',
      motivoAnulacion: map['motivoAnulacion'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pacienteId': pacienteId,
      'nombrePaciente': nombrePaciente,
      'telefonoPaciente': telefonoPaciente,
      'servicio': servicio,
      'servicioId': servicioId,
      'clinica': clinica,
      'clinicaId': clinicaId,
      'descripcion': descripcion,
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
        .where('fechaVenta', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
        .where('fechaVenta', isLessThan: Timestamp.fromDate(fin))
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => Venta.fromMap(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.fechaVenta.compareTo(a.fechaVenta));
          return list;
        });
  }

  Stream<List<Venta>> streamVentasSemana() {
    final hoy = DateTime.now();
    final inicioSemana = hoy.subtract(Duration(days: hoy.weekday - 1));
    final inicio = DateTime(inicioSemana.year, inicioSemana.month, inicioSemana.day);

    return _db.collection('ventas').snapshots().map((snap) {
      final list = snap.docs
          .map((d) => Venta.fromMap(d.data(), d.id))
          .where((v) => v.fechaVenta.isAfter(inicio.subtract(const Duration(seconds: 1))))
          .toList();
      list.sort((a, b) => b.fechaVenta.compareTo(a.fechaVenta));
      return list;
    });
  }

  Stream<List<Venta>> streamTodasLasVentas() {
    return _db.collection('ventas').snapshots().map((snap) {
      final list = snap.docs
          .map((d) => Venta.fromMap(d.data(), d.id))
          .toList();
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
        .where('fechaVenta', isGreaterThanOrEqualTo: Timestamp.fromDate(inicio))
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
          venta.fechaVenta.isAfter(inicioMes.subtract(const Duration(seconds: 1)))) {
        transacciones++;
        total += venta.monto;
        porMetodo[venta.metodoPago] = (porMetodo[venta.metodoPago] ?? 0) + venta.monto;
      }
    }

    return {
      'total': total,
      'transacciones': transacciones,
      'porMetodo': porMetodo,
    };
  }
}
