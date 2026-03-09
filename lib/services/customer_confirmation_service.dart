import '../config/app_config.dart';
import 'supabase_service.dart';
import 'local_reservation_service.dart';

class CustomerConfirmationService {
  /// Confirma una reserva por código del cliente.
  /// Cambia estado de "pendiente_confirmacion" a "confirmada".
  static Future<Map<String, dynamic>> confirmByCode(String code) async {
    final storage = SupabaseService.instance;
    final reservations = await storage.getReservations();
    final index = reservations.indexWhere(
        (r) => r['codigo_confirmacion'] == code.toUpperCase());

    if (index == -1) {
      return {'success': false, 'error': 'Código no encontrado'};
    }

    final reservation = reservations[index];

    if (reservation['estado'] == 'confirmada') {
      return {'success': true, 'message': 'Esta reserva ya estaba confirmada', 'data': reservation};
    }

    if (reservation['estado'] != 'pendiente_confirmacion') {
      return {
        'success': false,
        'error': 'Esta reserva no se puede confirmar (estado: ${reservation['estado']})',
      };
    }

    reservations[index]['estado'] = 'confirmada';
    reservations[index]['confirmado_cliente'] = true;
    reservations[index]['confirmado_at'] = DateTime.now().toIso8601String();

    await storage.saveReservations(reservations);
    LocalReservationService.clearReservationsCache();

    return {
      'success': true,
      'message': 'Reserva confirmada exitosamente',
      'data': reservations[index],
    };
  }

  /// Cancela reservas pendientes de confirmación que excedieron la ventana.
  static Future<int> processExpiredConfirmations() async {
    final config = AppConfig.instance;
    final now = DateTime.now();
    final storage = SupabaseService.instance;
    final reservations = await storage.getReservations();
    int expired = 0;

    for (int i = 0; i < reservations.length; i++) {
      final r = reservations[i];
      if (r['estado'] != 'pendiente_confirmacion') continue;

      final createdAt = r['created_at'] as String?;
      if (createdAt == null) continue;

      try {
        final createdTime = DateTime.parse(createdAt);
        final deadline = createdTime.add(
          Duration(hours: config.confirmationWindowHours),
        );

        if (now.isAfter(deadline)) {
          reservations[i]['estado'] = 'cancelada';
          expired++;
        }
      } catch (_) {
        continue;
      }
    }

    if (expired > 0) {
      await storage.saveReservations(reservations);
      LocalReservationService.clearReservationsCache();
    }

    return expired;
  }

  /// Confirmación manual por el admin.
  static Future<bool> adminConfirm(String reservationId) async {
    final storage = SupabaseService.instance;
    final reservations = await storage.getReservations();
    final index = reservations.indexWhere((r) => r['id'] == reservationId);
    if (index == -1) return false;

    if (reservations[index]['estado'] != 'pendiente_confirmacion') return false;

    reservations[index]['estado'] = 'confirmada';
    reservations[index]['confirmado_cliente'] = false;
    reservations[index]['confirmado_at'] = DateTime.now().toIso8601String();

    await storage.saveReservations(reservations);
    LocalReservationService.clearReservationsCache();
    return true;
  }
}
