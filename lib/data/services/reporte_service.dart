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

  // ══════════════════════════════════════════════════════════════════════════
  // SEPARACIÓN CLÍNICA / FARMACIA
  // ══════════════════════════════════════════════════════════════════════════

  bool _enRango(DateTime? f, DateTime desde, DateTime hasta) =>
      f != null &&
      f.isAfter(desde.subtract(const Duration(seconds: 1))) &&
      f.isBefore(hasta);

  /// Un ítem de venta es de farmacia si su descripción es 'Medicamento'
  /// (así se registran en caja) o si el nombre incluye el patrón '(xN)'.
  bool _esItemFarmacia(Map item) {
    final desc = (item['descripcion'] ?? '').toString().toLowerCase();
    if (desc == 'medicamento') return true;
    final serv = (item['servicio'] ?? '').toString();
    return RegExp(r'\(x\d+\)').hasMatch(serv);
  }

  int _unidadesItem(Map item) {
    final serv = (item['servicio'] ?? '').toString();
    final m = RegExp(r'\(x(\d+)\)').firstMatch(serv);
    if (m != null) return int.tryParse(m.group(1)!) ?? 1;
    final c = item['cantidad'];
    if (c is int) return c;
    if (c is num) return c.toInt();
    return 1;
  }

  /// Divide una venta en su monto de servicios y su monto de farmacia.
  ({double servicio, double farmacia, int unidadesFarmacia}) _dividirVenta(
      Map<String, dynamic> data) {
    final items = (data['items'] as List?) ?? [];
    double servicio = 0;
    double farmacia = 0;
    int unidades = 0;
    if (items.isNotEmpty) {
      for (final raw in items) {
        final item = raw as Map;
        final monto = (item['monto'] ?? 0).toDouble();
        if (_esItemFarmacia(item)) {
          farmacia += monto;
          unidades += _unidadesItem(item);
        } else {
          servicio += monto;
        }
      }
    } else {
      // Ventas antiguas sin items: usar tipoVenta.
      final monto = (data['monto'] ?? 0).toDouble();
      if ((data['tipoVenta'] ?? 'servicio') == 'farmacia') {
        farmacia += monto;
      } else {
        servicio += monto;
      }
    }
    return (servicio: servicio, farmacia: farmacia, unidadesFarmacia: unidades);
  }

  DateTime? _parseFecha(dynamic v) =>
      v is Timestamp ? v.toDate() : null;

  /// Reporte completo de CLÍNICA (servicios médicos, pacientes, citas).
  Future<Map<String, dynamic>> getReporteClinica({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final hoy = DateTime.now();
    final inicioMes = DateTime(hoy.year, hoy.month, 1);
    final inicioHoy = DateTime(hoy.year, hoy.month, hoy.day);
    final finHoy = inicioHoy.add(const Duration(days: 1));

    // ── Pacientes ──
    final pacSnap = await _db.collection('pacientes').get();
    int activos = 0, inactivos = 0, nuevosMes = 0;
    final porClinica = <String, int>{};
    final porServicio = <String, int>{};
    for (final d in pacSnap.docs) {
      final data = d.data();
      if ((data['estado'] ?? 'activo') == 'activo') {
        activos++;
      } else {
        inactivos++;
      }
      final fReg = _parseFecha(data['fechaRegistro'] ?? data['creadoEn']);
      if (fReg != null && fReg.isAfter(inicioMes)) nuevosMes++;
      final cl = (data['clinica'] ?? '').toString();
      if (cl.isNotEmpty) porClinica[cl] = (porClinica[cl] ?? 0) + 1;
      final sv = (data['servicio'] ?? '').toString();
      if (sv.isNotEmpty) porServicio[sv] = (porServicio[sv] ?? 0) + 1;
    }

    // ── Citas médicas ──
    final citasSnap = await _db.collection('citas_medicas').get();
    int citasTotal = 0,
        completadas = 0,
        canceladas = 0,
        pendientes = 0,
        confirmadas = 0,
        citasHoy = 0;
    final porDoctora = <String, int>{};
    for (final d in citasSnap.docs) {
      final data = d.data();
      final f = _parseFecha(data['fecha']);
      if (f != null && f.isAfter(inicioHoy.subtract(const Duration(seconds: 1))) &&
          f.isBefore(finHoy)) {
        citasHoy++;
      }
      if (!_enRango(f, desde, hasta)) continue;
      citasTotal++;
      switch (data['estado']) {
        case 'completada':
          completadas++;
          break;
        case 'cancelada':
          canceladas++;
          break;
        case 'confirmada':
          confirmadas++;
          break;
        default:
          pendientes++;
      }
      final doc = (data['doctora'] ?? '').toString();
      if (doc.isNotEmpty) porDoctora[doc] = (porDoctora[doc] ?? 0) + 1;
    }

    // ── Ventas de servicios ──
    final ventasSnap = await _db.collection('ventas').get();
    double ingresos = 0;
    int countVentas = 0;
    final porMetodo = <String, double>{'efectivo': 0, 'tarjeta': 0, 'visa_cuotas': 0};
    final serviciosPie = <String, int>{};
    final serie6 = List<double>.filled(6, 0);
    final meses6 = <Map<String, int>>[];
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(hoy.year, hoy.month - i, 1);
      meses6.add({'mes': m.month, 'anio': m.year});
    }
    final ultimas = <Map<String, dynamic>>[];

    for (final doc in ventasSnap.docs) {
      final data = doc.data();
      if (data['estado'] == 'anulado') continue;
      final f = _parseFecha(data['fechaVenta']);
      final split = _dividirVenta(data);
      if (split.servicio <= 0) continue;

      // Serie 6 meses
      if (f != null) {
        for (int i = 0; i < 6; i++) {
          if (f.year == meses6[i]['anio'] && f.month == meses6[i]['mes']) {
            serie6[i] += split.servicio;
          }
        }
      }

      if (!_enRango(f, desde, hasta)) continue;
      ingresos += split.servicio;
      countVentas++;
      final mp = (data['metodoPago'] ?? 'efectivo').toString();
      porMetodo[mp] = (porMetodo[mp] ?? 0) + split.servicio;
      // Pie de servicios (por nombre de items de servicio)
      final items = (data['items'] as List?) ?? [];
      for (final raw in items) {
        final item = raw as Map;
        if (_esItemFarmacia(item)) continue;
        final s = (item['servicio'] ?? '').toString();
        if (s.isNotEmpty) serviciosPie[s] = (serviciosPie[s] ?? 0) + 1;
      }
      ultimas.add({
        'fecha': f ?? DateTime.now(),
        'paciente': data['nombrePaciente'] ?? '',
        'servicio': items.isNotEmpty
            ? items
                .where((i) => !_esItemFarmacia(i as Map))
                .map((i) => (i as Map)['servicio'])
                .where((s) => (s ?? '').toString().isNotEmpty)
                .join(', ')
            : (data['servicio'] ?? ''),
        'monto': split.servicio,
        'metodoPago': data['metodoPago'] ?? '',
        'secretaria': data['nombreSecretaria'] ?? '',
      });
    }
    ultimas.sort((a, b) =>
        (b['fecha'] as DateTime).compareTo(a['fecha'] as DateTime));

    return {
      'totalPacientes': pacSnap.docs.length,
      'pacientesActivos': activos,
      'pacientesInactivos': inactivos,
      'nuevosMes': nuevosMes,
      'porClinica': porClinica,
      'porServicio': porServicio,
      'citasTotal': citasTotal,
      'citasHoy': citasHoy,
      'completadas': completadas,
      'canceladas': canceladas,
      'pendientes': pendientes,
      'confirmadas': confirmadas,
      'porDoctora': porDoctora,
      'ingresos': ingresos,
      'countVentas': countVentas,
      'ticketPromedio': countVentas > 0 ? ingresos / countVentas : 0.0,
      'porMetodo': porMetodo,
      'serviciosPie': serviciosPie,
      'serie6': serie6,
      'meses6': meses6,
      'ultimas': ultimas.take(15).toList(),
    };
  }

  /// Reporte completo de FARMACIA (inventario, ventas de medicamentos).
  Future<Map<String, dynamic>> getReporteFarmacia({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final hoy = DateTime.now();

    // ── Inventario ──
    final medSnap = await _db.collection('medicamentos').get();
    int totalMed = medSnap.docs.length;
    int stockBajo = 0, sinStock = 0, vencidos = 0, porVencer = 0;
    double valorInventario = 0;
    final porCategoria = <String, int>{};
    final stockCritico = <Map<String, dynamic>>[];
    for (final d in medSnap.docs) {
      final data = d.data();
      final cant = (data['cantidad'] ?? 0) is int
          ? (data['cantidad'] ?? 0) as int
          : (data['cantidad'] as num).toInt();
      final minimo = (data['cantidadMinima'] ?? 0) is int
          ? (data['cantidadMinima'] ?? 0) as int
          : (data['cantidadMinima'] as num).toInt();
      final precioCompra = (data['precioCompra'] ?? 0).toDouble();
      valorInventario += cant * precioCompra;
      final cat = (data['categoria'] ?? 'Otro').toString();
      porCategoria[cat] = (porCategoria[cat] ?? 0) + 1;
      if (cant <= 0) {
        sinStock++;
      } else if (cant <= minimo) {
        stockBajo++;
      }
      if (cant <= minimo) {
        stockCritico.add({
          'nombre': data['nombre'] ?? '',
          'cantidad': cant,
          'minimo': minimo,
          'estante': data['estante'] ?? '',
        });
      }
      final fvStr = (data['fechaVencimiento'] ?? '').toString();
      if (fvStr.isNotEmpty) {
        final fv = DateTime.tryParse(fvStr);
        if (fv != null) {
          final dias = DateTime(fv.year, fv.month, fv.day)
              .difference(DateTime(hoy.year, hoy.month, hoy.day))
              .inDays;
          if (dias < 0) {
            vencidos++;
          } else if (dias <= 30) {
            porVencer++;
          }
        }
      }
    }

    // ── Ventas de farmacia ──
    final ventasSnap = await _db.collection('ventas').get();
    double ingresos = 0;
    int countVentas = 0;
    final porMetodo = <String, double>{'efectivo': 0, 'tarjeta': 0, 'visa_cuotas': 0};
    final serie6 = List<double>.filled(6, 0);
    final meses6 = <Map<String, int>>[];
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(hoy.year, hoy.month - i, 1);
      meses6.add({'mes': m.month, 'anio': m.year});
    }
    final ultimas = <Map<String, dynamic>>[];

    for (final doc in ventasSnap.docs) {
      final data = doc.data();
      if (data['estado'] == 'anulado') continue;
      final f = _parseFecha(data['fechaVenta']);
      final split = _dividirVenta(data);
      if (split.farmacia <= 0) continue;

      if (f != null) {
        for (int i = 0; i < 6; i++) {
          if (f.year == meses6[i]['anio'] && f.month == meses6[i]['mes']) {
            serie6[i] += split.farmacia;
          }
        }
      }

      if (!_enRango(f, desde, hasta)) continue;
      ingresos += split.farmacia;
      countVentas++;
      final mp = (data['metodoPago'] ?? 'efectivo').toString();
      porMetodo[mp] = (porMetodo[mp] ?? 0) + split.farmacia;
      final items = (data['items'] as List?) ?? [];
      ultimas.add({
        'fecha': f ?? DateTime.now(),
        'cliente': data['nombrePaciente'] ?? '',
        'medicamento': items
            .where((i) => _esItemFarmacia(i as Map))
            .map((i) => (i as Map)['servicio'])
            .where((s) => (s ?? '').toString().isNotEmpty)
            .join(', '),
        'monto': split.farmacia,
        'metodoPago': data['metodoPago'] ?? '',
      });
    }
    ultimas.sort((a, b) =>
        (b['fecha'] as DateTime).compareTo(a['fecha'] as DateTime));

    // ── Movimientos de inventario (ventas y otros) ──
    final movSnap = await _db.collection('movimientos_farmacia').get();
    final vendidosPorMed = <String, Map<String, dynamic>>{};
    int unidadesVendidas = 0;
    final movimientos = <Map<String, dynamic>>[];
    for (final d in movSnap.docs) {
      final data = d.data();
      final f = _parseFecha(data['fecha']);
      final tipo = (data['tipo'] ?? '').toString();
      final cant = (data['cantidad'] ?? 0) is int
          ? (data['cantidad'] ?? 0) as int
          : (data['cantidad'] as num?)?.toInt() ?? 0;
      movimientos.add({
        'fecha': f ?? DateTime.now(),
        'medicamento': data['nombreMedicamento'] ?? '',
        'tipo': tipo,
        'cantidad': cant,
        'responsable': data['nombreResponsable'] ?? '',
      });
      if (tipo == 'venta' && _enRango(f, desde, hasta)) {
        unidadesVendidas += cant;
        final nombre = (data['nombreMedicamento'] ?? '').toString();
        final e = vendidosPorMed.putIfAbsent(
            nombre, () => {'nombre': nombre, 'unidades': 0});
        e['unidades'] = (e['unidades'] as int) + cant;
      }
    }
    movimientos.sort((a, b) =>
        (b['fecha'] as DateTime).compareTo(a['fecha'] as DateTime));
    final masVendidos = vendidosPorMed.values.toList()
      ..sort((a, b) => (b['unidades'] as int).compareTo(a['unidades'] as int));

    return {
      'totalMedicamentos': totalMed,
      'stockBajo': stockBajo,
      'sinStock': sinStock,
      'vencidos': vencidos,
      'porVencer': porVencer,
      'valorInventario': valorInventario,
      'porCategoria': porCategoria,
      'stockCritico': stockCritico,
      'ingresos': ingresos,
      'countVentas': countVentas,
      'ticketPromedio': countVentas > 0 ? ingresos / countVentas : 0.0,
      'unidadesVendidas': unidadesVendidas,
      'porMetodo': porMetodo,
      'serie6': serie6,
      'meses6': meses6,
      'ultimas': ultimas.take(15).toList(),
      'masVendidos': masVendidos.take(8).toList(),
      'movimientos': movimientos.take(20).toList(),
    };
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
