import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Generador de recetas médicas en PDF con la identidad visual de Renova.
class RecetaPDF {
  static Future<void> generarYMostrar({
    required String nombrePaciente,
    required int edadPaciente,
    required String identificacionPaciente,
    required String nombreDoctora,
    required String diagnostico,
    required List<Map<String, dynamic>> medicamentos,
    required String indicaciones,
    String? proximaCita,
    required String numeroReceta,
  }) async {
    final pdf = await _documento(
      nombrePaciente: nombrePaciente,
      edadPaciente: edadPaciente,
      identificacionPaciente: identificacionPaciente,
      nombreDoctora: nombreDoctora,
      diagnostico: diagnostico,
      medicamentos: medicamentos,
      indicaciones: indicaciones,
      proximaCita: proximaCita,
      numeroReceta: numeroReceta,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Receta_$numeroReceta.pdf',
    );
  }

  static Future<pw.Document> _documento({
    required String nombrePaciente,
    required int edadPaciente,
    required String identificacionPaciente,
    required String nombreDoctora,
    required String diagnostico,
    required List<Map<String, dynamic>> medicamentos,
    required String indicaciones,
    String? proximaCita,
    required String numeroReceta,
  }) async {
    final pdf = pw.Document();

    pw.MemoryImage? logo;
    try {
      final data = await rootBundle.load('assets/images/logo_renova.png');
      logo = pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      // Continuar sin logo.
    }

    final colorPrimario = PdfColor.fromHex('#1E3A5F');
    final colorDorado = PdfColor.fromHex('#C9A96E');
    final fecha = DateFormat('dd/MM/yyyy').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
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
                          pw.Text('Belleza y Bienestar',
                              style: pw.TextStyle(
                                  color: colorDorado, fontSize: 11)),
                          pw.Text('Tel: +502 2345-6789',
                              style: const pw.TextStyle(
                                  color: PdfColors.white, fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('RECETA MEDICA',
                          style: pw.TextStyle(
                              color: colorDorado,
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold)),
                      pw.Text(numeroReceta,
                          style: const pw.TextStyle(
                              color: PdfColors.white, fontSize: 12)),
                      pw.Text('Fecha: $fecha',
                          style: const pw.TextStyle(
                              color: PdfColors.white, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // DATOS DEL PACIENTE
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Paciente: $nombrePaciente',
                          style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold, fontSize: 12)),
                      pw.Text('Edad: $edadPaciente anios',
                          style: const pw.TextStyle(fontSize: 11)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Doctora: $nombreDoctora',
                          style: const pw.TextStyle(fontSize: 11)),
                      pw.Text('No. Identificacion: $identificacionPaciente',
                          style: const pw.TextStyle(fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // DIAGNÓSTICO
            if (diagnostico.trim().isNotEmpty) ...[
              pw.Text('Diagnostico:',
                  style: pw.TextStyle(
                      color: colorPrimario,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12)),
              pw.Divider(color: colorDorado),
              pw.Text(diagnostico,
                  style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 16),
            ],

            // MEDICAMENTOS
            pw.Text('Rx',
                style: pw.TextStyle(
                    color: colorPrimario,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 18)),
            pw.Divider(color: colorDorado),
            ...medicamentos.asMap().entries.map((entry) {
              final i = entry.key + 1;
              final med = entry.value;
              final instr = (med['instrucciones'] ?? '').toString();
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('$i. ${med['nombre'] ?? ''}',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    if ((med['dosis'] ?? '').toString().isNotEmpty)
                      pw.Text('   Dosis: ${med['dosis']}',
                          style: const pw.TextStyle(fontSize: 11)),
                    if ((med['frecuencia'] ?? '').toString().isNotEmpty)
                      pw.Text('   Frecuencia: ${med['frecuencia']}',
                          style: const pw.TextStyle(fontSize: 11)),
                    if ((med['duracion'] ?? '').toString().isNotEmpty)
                      pw.Text('   Duracion: ${med['duracion']}',
                          style: const pw.TextStyle(fontSize: 11)),
                    if (instr.isNotEmpty)
                      pw.Text('   $instr',
                          style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                              fontStyle: pw.FontStyle.italic)),
                  ],
                ),
              );
            }),

            pw.SizedBox(height: 8),

            // INDICACIONES
            if (indicaciones.trim().isNotEmpty) ...[
              pw.Text('Indicaciones generales:',
                  style: pw.TextStyle(
                      color: colorPrimario,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12)),
              pw.Divider(color: colorDorado),
              pw.Text(indicaciones,
                  style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 12),
            ],

            // PRÓXIMA CITA
            if (proximaCita != null && proximaCita.trim().isNotEmpty) ...[
              pw.Text('Proxima cita: $proximaCita',
                  style: pw.TextStyle(
                      color: colorPrimario,
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11)),
            ],

            pw.SizedBox(height: 40),

            // FIRMA
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(width: 200, child: pw.Divider(color: colorPrimario)),
                  pw.Text(nombreDoctora,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text('Medico',
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfColors.grey600)),
                ],
              ),
            ),

            pw.Spacer(),
            pw.Center(
              child: pw.Text(
                '"Tu belleza y bienestar son nuestra mision"',
                style: pw.TextStyle(
                    color: colorPrimario,
                    fontSize: 9,
                    fontStyle: pw.FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );

    return pdf;
  }
}
