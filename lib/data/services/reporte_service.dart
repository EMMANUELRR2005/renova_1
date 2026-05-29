import 'package:cloud_firestore/cloud_firestore.dart';

class ReporteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getResumenGeneral({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    desde ??= DateTime.now().subtract(const Duration(days: 30));
    hasta ??= DateTime.now().add(const Duration(days: 1));

    final pacientesSnap = await _db.collection('pacientes').get();
    final pacientesActivos = pacientesSnap.docs
        .where((d) => d.data()['estado'] == 'activo')
        .length;

    final hoy = DateTime.now();
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final finHoy = inicioHoy.add(const Duration(days: 1));

    final citasHoySnap = await _db
        .collection('citas')
        .where('fecha', isGreaterThanOrEqualTo: Timestamp.fromDate(inicioHoy))
        .where('fecha', isLessThan: Timestamp.fromDate(finHoy))
        .get();

    final ventasSnap = await _db.collection('ventas').get();
    double totalVentas = 0;
    double ingresosMes = 0;
    int serviciosRealizados = 0;

    final inicioMes = DateTime(hoy.year, hoy.month, 1);

    for (final doc in ventasSnap.docs) {
      final data = doc.data();
      if (data['estado'] != 'anulado') {
        final monto = (data['monto'] ?? 0).toDouble();
        totalVentas += monto;

        final fecha = (data['fechaVenta'] as Timestamp?)?.toDate();
        if (fecha != null && fecha.isAfter(inicioMes.subtract(const Duration(seconds: 1)))) {
          ingresosMes += monto;
          serviciosRealizados++;
        }
      }
    }

    return {
      'totalPacientes': pacientesSnap.docs.length,
      'pacientesActivos': pacientesActivos,
      'citasHoy': citasHoySnap.docs.length,
      'totalVentas': totalVentas,
      'ingresosMes': ingresosMes,
      'serviciosRealizados': serviciosRealizados,
    };
  }

  Future<Map<String, dynamic>> getVentasPorMetodo({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    desde ??= DateTime.now().subtract(const Duration(days: 30));
    hasta ??= DateTime.now().add(const Duration(days: 1));

    final ventasSnap = await _db.collection('ventas').get();

    double efectivo = 0;
    double tarjeta = 0;
    double visaCuotas = 0;
    int countEfectivo = 0;
    int countTarjeta = 0;
    int countVisaCuotas = 0;

    for (final doc in ventasSnap.docs) {
      final data = doc.data();
      if (data['estado'] != 'anulado') {
        final fecha = (data['fechaVenta'] as Timestamp?)?.toDate();
        if (fecha != null && fecha.isAfter(desde!) && fecha.isBefore(hasta!)) {
          final monto = (data['monto'] ?? 0).toDouble();
          switch (data['metodoPago']) {
            case 'efectivo':
              efectivo += monto;
              countEfectivo++;
              break;
            case 'tarjeta':
              tarjeta += monto;
              countTarjeta++;
              break;
            case 'visa_cuotas':
              visaCuotas += monto;
              countVisaCuotas++;
              break;
          }
        }
      }
    }

    return {
      'efectivo': {'monto': efectivo, 'count': countEfectivo},
      'tarjeta': {'monto': tarjeta, 'count': countTarjeta},
      'visa_cuotas': {'monto': visaCuotas, 'count': countVisaCuotas},
      'total': efectivo + tarjeta + visaCuotas,
    };
  }

  Future<List<Map<String, dynamic>>> getServiciosMasVendidos({
    DateTime? desde,
    DateTime? hasta,
    int limite = 10,
  }) async {
    desde ??= DateTime.now().subtract(const Duration(days: 30));
    hasta ??= DateTime.now().add(const Duration(days: 1));

    final ventasSnap = await _db.collection('ventas').get();
    final serviciosCount = <String, int>{};

    for (final doc in ventasSnap.docs) {
      final data = doc.data();
      if (data['estado'] != 'anulado') {
        final fecha = (data['fechaVenta'] as Timestamp?)?.toDate();
        if (fecha != null && fecha.isAfter(desde!) && fecha.isBefore(hasta!)) {
          final servicio = data['servicio'] as String? ?? 'Sin servicio';
          serviciosCount[servicio] = (serviciosCount[servicio] ?? 0) + 1;
        }
      }
    }

    final sorted = serviciosCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(limite)
        .map((e) => {'servicio': e.key, 'cantidad': e.value})
        .toList();
  }

  Future<List<Map<String, dynamic>>> getPacientesPorClinica() async {
    final pacientesSnap = await _db.collection('pacientes').get();
    final clinicasCount = <String, int>{};

    for (final doc in pacientesSnap.docs) {
      final data = doc.data();
      final clinica = data['clinica'] as String? ?? 'Sin asignar';
      clinicasCount[clinica] = (clinicasCount[clinica] ?? 0) + 1;
    }

    final sorted = clinicasCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.map((e) => {'clinica': e.key, 'cantidad': e.value}).toList();
  }

  Future<List<Map<String, dynamic>>> getUltimasVentas({int limite = 10}) async {
    final ventasSnap = await _db.collection('ventas').get();

    final ventas = ventasSnap.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'fecha': (data['fechaVenta'] as Timestamp?)?.toDate() ?? DateTime.now(),
        'paciente': data['nombrePaciente'] ?? '',
        'servicio': data['servicio'] ?? '',
        'monto': (data['monto'] ?? 0).toDouble(),
        'metodoPago': data['metodoPago'] ?? '',
        'estado': data['estado'] ?? '',
      };
    }).toList();

    ventas.sort((a, b) => (b['fecha'] as DateTime).compareTo(a['fecha'] as DateTime));

    return ventas.take(limite).toList();
  }

  Future<Map<String, dynamic>> getEstadisticasCitas({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    desde ??= DateTime.now().subtract(const Duration(days: 30));
    hasta ??= DateTime.now().add(const Duration(days: 1));

    final citasSnap = await _db.collection('citas').get();

    int total = 0;
    int confirmadas = 0;
    int completadas = 0;
    int canceladas = 0;

    for (final doc in citasSnap.docs) {
      final data = doc.data();
      final fecha = (data['fecha'] as Timestamp?)?.toDate();
      if (fecha != null && fecha.isAfter(desde!) && fecha.isBefore(hasta!)) {
        total++;
        switch (data['estado']) {
          case 'confirmada':
            confirmadas++;
            break;
          case 'completada':
            completadas++;
            break;
          case 'cancelada':
            canceladas++;
            break;
        }
      }
    }

    return {
      'total': total,
      'confirmadas': confirmadas,
      'completadas': completadas,
      'canceladas': canceladas,
    };
  }
}
