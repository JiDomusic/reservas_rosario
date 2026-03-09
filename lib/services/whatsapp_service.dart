import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';

class _WebUtils {
  static Future<bool> openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        final result = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        return result;
      } else {
        final result = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
        return result;
      }
    } catch (e) {
      return false;
    }
  }
}

class WhatsAppService {
  /// Enviar recordatorio de reserva por WhatsApp
  static Future<void> sendReservationReminder({
    required String phoneNumber,
    required String customerName,
    required String confirmationCode,
    required DateTime reservationDate,
    required String reservationTime,
    required int guests,
    String? specialNotes,
  }) async {
    final message = _buildReservationMessage(
      customerName: customerName,
      confirmationCode: confirmationCode,
      reservationDate: reservationDate,
      reservationTime: reservationTime,
      guests: guests,
      specialNotes: specialNotes,
    );

    final whatsappUrl = _generateWhatsAppUrl(phoneNumber, message);

    final success = await _WebUtils.openUrl(whatsappUrl);
    if (!success) {
      throw Exception('No se pudo abrir WhatsApp');
    }
  }

  /// Copiar mensaje al portapapeles para WhatsApp manual
  static Future<void> copyReservationMessageToClipboard({
    required String customerName,
    required String confirmationCode,
    required DateTime reservationDate,
    required String reservationTime,
    required int guests,
    String? specialNotes,
  }) async {
    final message = _buildReservationMessage(
      customerName: customerName,
      confirmationCode: confirmationCode,
      reservationDate: reservationDate,
      reservationTime: reservationTime,
      guests: guests,
      specialNotes: specialNotes,
    );

    await Clipboard.setData(ClipboardData(text: message));
  }

  /// Construir mensaje de confirmación de reserva
  static String _buildReservationMessage({
    required String customerName,
    required String confirmationCode,
    required DateTime reservationDate,
    required String reservationTime,
    required int guests,
    String? specialNotes,
  }) {
    final config = AppConfig.instance;
    final dayNames = ['Domingo', 'Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado'];
    final monthNames = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    final dayName = dayNames[reservationDate.weekday % 7];
    final monthName = monthNames[reservationDate.month];

    String message = '''*${config.restaurantName.toUpperCase()}*

Hola $customerName! Tu reserva esta confirmada

*DETALLES DE TU RESERVA:*
Fecha: $dayName ${reservationDate.day} de $monthName
Hora: $reservationTime
Personas: $guests
Codigo: *$confirmationCode*

*UBICACION:*
${config.restaurantName}
${config.city}${config.province.isNotEmpty ? ', ${config.province}' : ''}

*IMPORTANTE:*
- Llega 10 minutos antes de tu horario
- Presenta tu codigo de confirmacion
- Si llegas ${config.autoReleaseMinutes} min tarde, la mesa se libera automaticamente''';

    if (specialNotes?.isNotEmpty == true) {
      message += '\n\n*OBSERVACIONES:*\n$specialNotes';
    }

    message += '''

*CONTACTO:*
WhatsApp: ${config.whatsappNumber}
Email: ${config.contactEmail}

_Mensaje automatico de ${config.restaurantName}_''';

    return message;
  }

  /// Generar URL de WhatsApp Web
  static String _generateWhatsAppUrl(String phoneNumber, String message) {
    final config = AppConfig.instance;
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Si no tiene código de país, agregar el configurado
    if (!cleanPhone.startsWith(config.countryCode)) {
      if (cleanPhone.startsWith('0')) {
        cleanPhone = '${config.countryCode}${cleanPhone.substring(1)}';
      } else if (cleanPhone.startsWith('15')) {
        cleanPhone = '${config.countryCode}9${cleanPhone.substring(2)}';
      } else {
        cleanPhone = '${config.countryCode}9$cleanPhone';
      }
    }

    final encodedMessage = Uri.encodeComponent(message);

    return 'https://wa.me/$cleanPhone?text=$encodedMessage';
  }

  /// Generar mensaje de recordatorio (24h antes)
  static String buildReminderMessage({
    required String customerName,
    required String confirmationCode,
    required DateTime reservationDate,
    required String reservationTime,
    required int guests,
  }) {
    final config = AppConfig.instance;
    final dayNames = ['Domingo', 'Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado'];
    final dayName = dayNames[reservationDate.weekday % 7];

    return '''*RECORDATORIO DE RESERVA*

Hola $customerName!

Tu reserva en ${config.restaurantName} es *MANANA*:

$dayName ${reservationDate.day}
$reservationTime
$guests personas
Codigo: *$confirmationCode*

*RECUERDA:*
- Llegar 10 minutos antes
- Traer tu codigo de confirmacion
- Si necesitas cancelar, avisanos con tiempo

Nos vemos manana!

_${config.restaurantName}_''';
  }

  /// Generar mensaje de cancelación
  static String buildCancellationMessage({
    required String customerName,
    required String confirmationCode,
    required DateTime reservationDate,
    required String reservationTime,
  }) {
    final config = AppConfig.instance;
    return '''*RESERVA CANCELADA*

Hola $customerName,

Tu reserva ha sido cancelada:

Codigo: *$confirmationCode*
Era para: ${reservationDate.day}/${reservationDate.month} a las $reservationTime

Quieres hacer una nueva reserva?
${config.website.isNotEmpty ? 'Visita: ${config.website}' : ''}

Esperamos verte pronto!

_${config.restaurantName}_''';
  }

  /// Enviar recordatorio automático (sería llamado por un cron job)
  static void scheduleReminder({
    required String phoneNumber,
    required String customerName,
    required String confirmationCode,
    required DateTime reservationDate,
    required String reservationTime,
    required int guests,
  }) {
    final reminderMessage = buildReminderMessage(
      customerName: customerName,
      confirmationCode: confirmationCode,
      reservationDate: reservationDate,
      reservationTime: reservationTime,
      guests: guests,
    );

    // En producción, esto se enviaría automáticamente 24h antes
  }

  /// Generar mensaje pidiendo confirmación al cliente
  static String buildConfirmationRequestMessage({
    required String customerName,
    required String confirmationCode,
    required DateTime reservationDate,
    required String reservationTime,
    required int guests,
  }) {
    final config = AppConfig.instance;
    final dayNames = ['Domingo', 'Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado'];
    final dayName = dayNames[reservationDate.weekday % 7];

    return '''*${config.restaurantName.toUpperCase()}*

Hola $customerName! Recibimos tu solicitud de reserva

*DETALLES:*
Fecha: $dayName ${reservationDate.day}/${reservationDate.month}
Hora: $reservationTime
Personas: $guests

*CONFIRMA TU RESERVA:*
Ingresa a nuestra app y usa tu codigo:
*$confirmationCode*

Si no confirmas dentro de ${config.confirmationWindowHours} horas, la reserva se cancelara automaticamente.

_${config.restaurantName}_''';
  }

  /// Generar mensaje de "se liberó un lugar" para waitlist
  static String buildWaitlistNotificationMessage({
    required String customerName,
    required DateTime date,
    required String time,
    required int guests,
  }) {
    final config = AppConfig.instance;
    return '''*BUENAS NOTICIAS!*

Hola $customerName!

Se libero un lugar en ${config.restaurantName} para:

Fecha: ${date.day}/${date.month}/${date.year}
Hora: $time
Personas: $guests

Queres que te reservemos? Respondenos rapido para asegurar tu lugar!

_${config.restaurantName}_''';
  }

  /// Enviar mensaje genérico por WhatsApp
  static Future<void> sendMessage({
    required String phoneNumber,
    required String message,
  }) async {
    final whatsappUrl = _generateWhatsAppUrl(phoneNumber, message);
    final success = await _WebUtils.openUrl(whatsappUrl);
    if (!success) {
      throw Exception('No se pudo abrir WhatsApp');
    }
  }

  /// Validar formato de teléfono
  static bool isValidPhone(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanPhone.length >= 8 && cleanPhone.length <= 15) {
      return true;
    }

    return false;
  }

  /// Formatear teléfono para mostrar
  static String formatPhoneForDisplay(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    if (cleanPhone.length == 10) {
      return '${cleanPhone.substring(0, 3)}-${cleanPhone.substring(3, 6)}-${cleanPhone.substring(6)}';
    } else if (cleanPhone.length == 11) {
      return '${cleanPhone.substring(0, 2)}-${cleanPhone.substring(2, 6)}-${cleanPhone.substring(6)}';
    }

    return phone;
  }
}
