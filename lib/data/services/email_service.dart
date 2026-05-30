import 'dart:async';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

class EmailService {
  static const String _emailClinica = 'adminrenovagt@gmail.com';
  static const String _passwordApp = 'iodx fbcz yjir zvts';

  static Future<bool> enviarFactura({
    required String emailDestino,
    required String nombrePaciente,
    required String numeroFactura,
    required List<int> pdfBytes,
  }) async {
    if (emailDestino.isEmpty) {
      return false;
    }

    try {
      final smtpServer = gmail(_emailClinica, _passwordApp);

      final message = Message()
        ..from = Address(_emailClinica, 'Clínica Renova')
        ..recipients.add(emailDestino)
        ..subject = 'Factura $numeroFactura - Clínica Renova'
        ..html = '''
          <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">

            <div style="background-color: #1E3A5F; padding: 20px; text-align: center; border-radius: 8px 8px 0 0;">
              <h1 style="color: white; margin: 0;">Clínica Renova</h1>
              <p style="color: #C9A96E; margin: 5px 0;">Belleza y Bienestar</p>
            </div>

            <div style="padding: 30px; background-color: #f9f9f9;">
              <p style="font-size: 16px;">
                Estimado/a <strong>$nombrePaciente</strong>,
              </p>
              <p>
                Adjunto encontrará su factura <strong>$numeroFactura</strong>
                correspondiente a los servicios recibidos en Clínica Renova.
              </p>
              <p>
                Si tiene alguna pregunta sobre su factura, no dude en contactarnos.
              </p>

              <div style="background-color: #1E3A5F; padding: 15px; border-radius: 8px; margin: 20px 0; text-align: center;">
                <p style="color: white; margin: 0;">+502 2345-6789</p>
                <p style="color: #C9A96E; margin: 5px 0;">adminrenovagt@gmail.com</p>
              </div>

              <p style="color: #666; font-size: 13px;">
                Gracias por confiar en Clínica Renova.
                <br>
                <em>"Tu belleza y bienestar son nuestra misión"</em>
              </p>
            </div>

            <div style="background-color: #eee; padding: 10px; text-align: center; border-radius: 0 0 8px 8px;">
              <p style="margin: 0; font-size: 11px; color: #666;">
                Este correo fue generado automáticamente. Por favor no responda a este mensaje.
              </p>
            </div>
          </div>
        '''
        ..attachments = [
          StreamAttachment(
            Stream.fromIterable([pdfBytes]),
            'application/pdf',
            fileName: 'Factura_$numeroFactura.pdf',
          ),
        ];

      await send(message, smtpServer);
      return true;
    } catch (e) {
      return false;
    }
  }
}
