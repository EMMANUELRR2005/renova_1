import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/services/cierre_service.dart';

/// Generador del PDF de cierre de caja diario.
class CierreCajaPDF {
  static Future<void> generarYMostrar(CierreCaja cierre) async {
    final pdf = await _documento(cierre);
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Cierre_Caja_${cierre.fechaString}.pdf',
    );
  }

  static Future<pw.Document> _documento(CierreCaja c) async {
    final pdf = pw.Document();

    pw.MemoryImage? logo;
    try {
      final data = await rootBundle.load('assets/images/logo_renova.png');
      logo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {}

    final colorPrimario = PdfColor.fromHex('#1E3A5F');
    final colorDorado = PdfColor.fromHex('#C9A96E');

    final fechaLarga = toBeginningOfSentenceCase(
        DateFormat("EEEE d 'de' MMMM yyyy", 'es').format(c.fecha));
    final horaCierre = DateFormat('HH:mm').format(c.fecha);

    pw.Widget filaResumen(String label, String valor, {bool bold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                    fontSize: bold ? 13 : 11,
                    fontWeight:
                        bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                    color: bold ? colorPrimario : PdfColors.black)),
            pw.Text(valor,
                style: pw.TextStyle(
                    fontSize: bold ? 13 : 11,
                    fontWeight:
                        bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                    color: bold ? colorPrimario : PdfColors.black)),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // HEADER
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: colorPrimario,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    if (logo != null) ...[
                      pw.ClipRRect(
                        horizontalRadius: 6,
                        verticalRadius: 6,
                        child: pw.Image(logo, height: 46, width: 46),
                      ),
                      pw.SizedBox(width: 12),
                    ],
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('CLINICA RENOVA',
                            style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold)),
                        pw.Text('Cierre de Caja Diario',
                            style: pw.TextStyle(
                                color: colorDorado, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                pw.Text('Q ${c.totalGeneral.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // DATOS DEL CIERRE
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Fecha: $fechaLarga',
                    style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Hora de cierre: $horaCierre',
                    style: const pw.TextStyle(fontSize: 11)),
                pw.Text('Responsable: ${c.nombreSecretaria}',
                    style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // RESUMEN DE VENTAS
          pw.Text('RESUMEN DE VENTAS',
              style: pw.TextStyle(
                  color: colorPrimario,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12)),
          pw.Divider(color: colorDorado),
          filaResumen('Efectivo', 'Q ${c.totalEfectivo.toStringAsFixed(2)}'),
          filaResumen('Tarjeta', 'Q ${c.totalTarjeta.toStringAsFixed(2)}'),
          filaResumen(
              'Visa Cuotas', 'Q ${c.totalVisaCuotas.toStringAsFixed(2)}'),
          pw.Divider(color: colorPrimario),
          filaResumen(
              'TOTAL COBRADO', 'Q ${c.totalGeneral.toStringAsFixed(2)}',
              bold: true),
          pw.SizedBox(height: 8),
          filaResumen(
              'Ventas anuladas', 'Q ${c.totalAnulados.toStringAsFixed(2)}'),
          filaResumen(
              'Total transacciones', '${c.cantidadTransacciones}'),

          pw.SizedBox(height: 16),

          // DETALLE DE TRANSACCIONES
          pw.Text('DETALLE DE TRANSACCIONES',
              style: pw.TextStyle(
                  color: colorPrimario,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12)),
          pw.Divider(color: colorDorado),
          if (c.transacciones.isEmpty)
            pw.Text('Sin transacciones registradas.',
                style: const pw.TextStyle(fontSize: 10))
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(4),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(3),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: colorPrimario),
                  children: [
                    _th('No.'),
                    _th('Paciente'),
                    _th('Monto'),
                    _th('Método'),
                    _th('Hora'),
                  ],
                ),
                ...c.transacciones.map((t) => pw.TableRow(children: [
                      _td('${t['correlativo'] ?? ''}'),
                      _td('${t['paciente'] ?? ''}'),
                      _td('Q ${(t['monto'] as num).toStringAsFixed(2)}'),
                      _td(_metodo('${t['metodoPago']}')),
                      _td('${t['hora'] ?? ''}'),
                    ])),
              ],
            ),

          pw.SizedBox(height: 40),

          // FIRMAS
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _firma(c.nombreSecretaria, 'Secretaria de Recepción',
                  colorPrimario),
              _firma('', 'Vo.Bo. Administración', colorPrimario),
            ],
          ),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _th(String t) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: pw.Text(t,
            style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold)),
      );

  static pw.Widget _td(String t) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: pw.Text(t, style: const pw.TextStyle(fontSize: 9)),
      );

  static pw.Widget _firma(String nombre, String cargo, PdfColor color) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(width: 180, child: pw.Divider(color: color)),
        if (nombre.isNotEmpty)
          pw.Text(nombre,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, fontSize: 11)),
        pw.Text(cargo,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      ],
    );
  }

  static String _metodo(String m) {
    switch (m) {
      case 'efectivo':
        return 'Efectivo';
      case 'tarjeta':
        return 'Tarjeta';
      case 'visa_cuotas':
        return 'Visa Cuotas';
      default:
        return m;
    }
  }
}
