import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/services/venta_service.dart';

class FacturaPDF {
  static Future<void> generarYMostrar({
    required Venta venta,
    Map<String, dynamic>? configuracion,
  }) async {
    final pdf = await _generarDocumento(venta, configuracion);

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Factura_${venta.numeroCorrelativo.replaceAll('VTA', 'FAC')}.pdf',
    );
  }

  static Future<List<int>> generarBytes({
    required Venta venta,
    Map<String, dynamic>? configuracion,
  }) async {
    final pdf = await _generarDocumento(venta, configuracion);
    return pdf.save();
  }

  static Future<pw.Document> _generarDocumento(
    Venta venta,
    Map<String, dynamic>? configuracion,
  ) async {
    final config = configuracion ?? {
      'nit': '1234567-8',
      'direccion': 'Ciudad de Guatemala, Guatemala',
      'telefono': '+502 2345-6789',
      'regimen': 'General',
    };

    final pdf = pw.Document();

    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/logo_renova.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      // Si no se puede cargar el logo, continuar sin él
    }

    final colorPrimario = PdfColor.fromHex('#1E3A5F');
    final colorDorado = PdfColor.fromHex('#C9A96E');
    final colorGris = PdfColor.fromHex('#F5F5F5');
    final colorTexto = PdfColor.fromHex('#333333');

    final total = venta.monto;
    final subtotal = venta.subtotalSinIva > 0 ? venta.subtotalSinIva : total / 1.12;
    final iva = venta.iva > 0 ? venta.iva : total - subtotal;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // HEADER
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: colorPrimario,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        if (logoImage != null)
                          pw.ClipRRect(
                            horizontalRadius: 6,
                            verticalRadius: 6,
                            child: pw.Image(logoImage, height: 50, width: 50),
                          ),
                        if (logoImage != null) pw.SizedBox(width: 12),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'CLINICA RENOVA',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(
                              'Belleza y Bienestar',
                              style: pw.TextStyle(
                                color: colorDorado,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'FACTURA',
                          style: pw.TextStyle(
                            color: colorDorado,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          venta.numeroCorrelativo.replaceAll('VTA', 'FAC'),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 14,
                          ),
                        ),
                        pw.Text(
                          'Serie A',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // DATOS EMISOR
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: colorGris,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'NIT Emisor: ${config['nit']}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'Direccion: ${config['direccion']}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'Tel: ${config['telefono']}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Fecha: ${_formatearFecha(venta.fechaVenta)}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'Hora: ${_formatearHora(venta.fechaVenta)}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'Regimen: ${config['regimen']}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // DATOS CLIENTE
              pw.Text(
                'DATOS DEL CLIENTE',
                style: pw.TextStyle(
                  color: colorPrimario,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              pw.Divider(color: colorDorado, thickness: 1),
              pw.SizedBox(height: 8),
              pw.Row(
                children: [
                  pw.Text(
                    'Nombre: ',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  pw.Text(
                    venta.nombrePaciente.isNotEmpty
                        ? venta.nombrePaciente
                        : 'Consumidor Final',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),
              pw.Row(
                children: [
                  pw.Text(
                    'NIT: ',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  pw.Text(
                    venta.nitCliente.isNotEmpty ? venta.nitCliente : 'CF',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ],
              ),

              pw.SizedBox(height: 16),

              // DETALLE DEL SERVICIO
              pw.Text(
                'DETALLE',
                style: pw.TextStyle(
                  color: colorPrimario,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              pw.Divider(color: colorDorado, thickness: 1),
              pw.SizedBox(height: 8),

              // Encabezado tabla
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                color: colorPrimario,
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Text(
                        'DESCRIPCION',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        'CANT',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'PRECIO',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'TOTAL',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),

              // Filas de servicios (múltiples items)
              ...(_buildFilasServicios(venta, colorGris)),

              pw.SizedBox(height: 16),

              // TOTALES
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.SizedBox(
                  width: 220,
                  child: pw.Column(
                    children: [
                      _filaTotales(
                        'Subtotal (sin IVA):',
                        'Q${subtotal.toStringAsFixed(2)}',
                        colorTexto,
                      ),
                      _filaTotales(
                        'IVA (12%):',
                        'Q${iva.toStringAsFixed(2)}',
                        colorTexto,
                      ),
                      pw.Divider(
                        color: colorPrimario,
                        thickness: 1,
                      ),
                      _filaTotales(
                        'TOTAL:',
                        'Q${total.toStringAsFixed(2)}',
                        colorPrimario,
                        esBold: true,
                        fontSize: 13,
                      ),
                    ],
                  ),
                ),
              ),

              pw.SizedBox(height: 16),

              // MÉTODO DE PAGO
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: colorDorado,
                    width: 1,
                  ),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Metodo de pago: ${_formatearMetodoPago(venta.metodoPago)}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'Atendido por: ${venta.nombreSecretaria}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),
              pw.Divider(color: colorGris, thickness: 1),

              // PIE DE FACTURA
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Documento Tributario Electronico',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'Sujeto a validacion de SAT Guatemala',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      'No. Autorizacion: Pendiente de certificacion SAT',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'Gracias por confiar en Clinica Renova',
                      style: pw.TextStyle(
                        color: colorDorado,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '"Tu belleza y bienestar son nuestra mision"',
                      style: pw.TextStyle(
                        color: colorPrimario,
                        fontSize: 9,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static List<pw.Widget> _buildFilasServicios(Venta venta, PdfColor colorGris) {
    final items = venta.items.isNotEmpty
        ? venta.items
        : [
            ItemVenta(
              servicioId: venta.servicioId,
              servicio: venta.servicio,
              clinicaId: venta.clinicaId,
              clinica: venta.clinica,
              descripcion: venta.descripcion,
              monto: venta.monto,
            )
          ];

    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      final precioUnitario = item.monto / 1.12;

      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        color: index % 2 == 0 ? colorGris : PdfColors.white,
        child: pw.Row(
          children: [
            pw.Expanded(
              flex: 5,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    item.servicio.isNotEmpty ? item.servicio : 'Servicio medico',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (item.descripcion.isNotEmpty)
                    pw.Text(
                      item.descripcion,
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                '1',
                style: const pw.TextStyle(fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                'Q${precioUnitario.toStringAsFixed(2)}',
                style: const pw.TextStyle(fontSize: 10),
                textAlign: pw.TextAlign.right,
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                'Q${precioUnitario.toStringAsFixed(2)}',
                style: const pw.TextStyle(fontSize: 10),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  static pw.Widget _filaTotales(
    String label,
    String valor,
    PdfColor color, {
    bool esBold = false,
    double fontSize = 10,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: esBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
        pw.Text(
          valor,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: esBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  static String _formatearFecha(DateTime fecha) {
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  static String _formatearHora(DateTime fecha) {
    return '${fecha.hour.toString().padLeft(2, '0')}:'
        '${fecha.minute.toString().padLeft(2, '0')}';
  }

  static String _formatearMetodoPago(String metodo) {
    switch (metodo) {
      case 'efectivo':
        return 'Efectivo';
      case 'tarjeta':
        return 'Tarjeta de credito/debito';
      case 'visa_cuotas':
        return 'Visa Cuotas';
      default:
        return metodo;
    }
  }
}
