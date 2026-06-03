import 'package:cloud_firestore/cloud_firestore.dart';

import 'venta_service.dart';

/// Modelo de un cierre de caja diario.
class CierreCaja {
  final String id;
  final DateTime fecha;
  final String fechaString; // 'AAAA-MM-DD'
  final double totalEfectivo;
  final double totalTarjeta;
  final double totalVisaCuotas;
  final double totalGeneral;
  final double totalAnulados;
  final int cantidadTransacciones;
  final String realizadoPor;
  final String nombreSecretaria;
  // Detalle ligero de transacciones (correlativo, paciente, monto, método).
  final List<Map<String, dynamic>> transacciones;

  CierreCaja({
    required this.id,
    required this.fecha,
    required this.fechaString,
    required this.totalEfectivo,
    required this.totalTarjeta,
    required this.totalVisaCuotas,
    required this.totalGeneral,
    required this.totalAnulados,
    required this.cantidadTransacciones,
    required this.realizadoPor,
    required this.nombreSecretaria,
    this.transacciones = const [],
  });

  Map<String, dynamic> toMap() => {
        'fecha': FieldValue.serverTimestamp(),
        'fechaString': fechaString,
        'totalEfectivo': totalEfectivo,
        'totalTarjeta': totalTarjeta,
        'totalVisaCuotas': totalVisaCuotas,
        'totalGeneral': totalGeneral,
        'totalAnulados': totalAnulados,
        'cantidadTransacciones': cantidadTransacciones,
        'realizadoPor': realizadoPor,
        'nombreSecretaria': nombreSecretaria,
        'transacciones': transacciones,
        'estado': 'cerrado',
      };

  factory CierreCaja.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseFecha(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return DateTime.now();
    }

    return CierreCaja(
      id: docId,
      fecha: parseFecha(map['fecha']),
      fechaString: map['fechaString'] ?? '',
      totalEfectivo: (map['totalEfectivo'] ?? 0).toDouble(),
      totalTarjeta: (map['totalTarjeta'] ?? 0).toDouble(),
      totalVisaCuotas: (map['totalVisaCuotas'] ?? 0).toDouble(),
      totalGeneral: (map['totalGeneral'] ?? 0).toDouble(),
      totalAnulados: (map['totalAnulados'] ?? 0).toDouble(),
      cantidadTransacciones: (map['cantidadTransacciones'] ?? 0) is int
          ? map['cantidadTransacciones'] ?? 0
          : (map['cantidadTransacciones'] as num).toInt(),
      realizadoPor: map['realizadoPor'] ?? '',
      nombreSecretaria: map['nombreSecretaria'] ?? '',
      transacciones: (map['transacciones'] as List?)
              ?.map((t) => Map<String, dynamic>.from(t as Map))
              .toList() ??
          [],
    );
  }
}

class CierreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _fechaString(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// True si ya existe un cierre para la fecha indicada (hoy por defecto).
  Future<bool> yaSeCerro({DateTime? fecha}) async {
    final f = fecha ?? DateTime.now();
    final snap = await _db
        .collection('cierres_caja')
        .where('fechaString', isEqualTo: _fechaString(f))
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Retorna el cierre del día si existe, null si no.
  Future<CierreCaja?> getCierreDelDia({DateTime? fecha}) async {
    final f = fecha ?? DateTime.now();
    final snap = await _db
        .collection('cierres_caja')
        .where('fechaString', isEqualTo: _fechaString(f))
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return CierreCaja.fromMap(doc.data(), doc.id);
  }

  /// Calcula el resumen del cierre del día a partir de las ventas.
  Future<CierreCaja> calcularCierre({
    required String realizadoPor,
    required String nombreSecretaria,
  }) async {
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
    double totalAnulados = 0;
    int cantidad = 0;
    final transacciones = <Map<String, dynamic>>[];

    for (final doc in snap.docs) {
      final venta = Venta.fromMap(doc.data(), doc.id);
      if (venta.estado == 'anulado') {
        totalAnulados += venta.monto;
        continue;
      }
      cantidad++;
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
      transacciones.add({
        'correlativo': venta.numeroCorrelativo,
        'paciente': venta.nombrePaciente,
        'monto': venta.monto,
        'metodoPago': venta.metodoPago,
        'hora':
            '${venta.fechaVenta.hour.toString().padLeft(2, '0')}:${venta.fechaVenta.minute.toString().padLeft(2, '0')}',
      });
    }

    transacciones.sort(
        (a, b) => (a['correlativo'] as String).compareTo(b['correlativo'] as String));

    return CierreCaja(
      id: '',
      fecha: hoy,
      fechaString: _fechaString(hoy),
      totalEfectivo: totalEfectivo,
      totalTarjeta: totalTarjeta,
      totalVisaCuotas: totalVisaCuotas,
      totalGeneral: totalEfectivo + totalTarjeta + totalVisaCuotas,
      totalAnulados: totalAnulados,
      cantidadTransacciones: cantidad,
      realizadoPor: realizadoPor,
      nombreSecretaria: nombreSecretaria,
      transacciones: transacciones,
    );
  }

  /// Persiste el cierre. Lanza una excepción si ya existe uno para hoy.
  Future<String> guardarCierre(CierreCaja cierre) async {
    if (await yaSeCerro()) {
      throw Exception('El cierre de caja de hoy ya fue realizado.');
    }
    final ref = _db.collection('cierres_caja').doc();
    await ref.set(cierre.toMap());
    return ref.id;
  }

  /// Histórico de cierres ordenado por fecha descendente (en Dart para evitar
  /// índices compuestos).
  Stream<List<CierreCaja>> streamCierres() {
    return _db.collection('cierres_caja').snapshots().map((snap) {
      final list =
          snap.docs.map((d) => CierreCaja.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) => b.fechaString.compareTo(a.fechaString));
      return list;
    });
  }
}
