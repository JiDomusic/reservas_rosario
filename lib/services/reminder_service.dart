import '../config/app_config.dart';
import 'supabase_service.dart';
import 'local_reservation_service.dart';

class ReminderService {
  /// Devuelve reservas confirmadas dentro de la ventana de recordatorio
  /// que aún no tienen recordatorio enviado.
  static Future<List<Map<String, dynamic>>> getPendingReminders() async {
    final config = AppConfig.instance;
    final now = DateTime.now();
    final storage = SupabaseService.instance;
    final reservations = await storage.getReservations();
    final pending = <Map<String, dynamic>>[];

    for (final r in reservations) {
      if (r['estado'] != 'confirmada') continue;
      if (r['recordatorio_enviado'] == true) continue;

      final fechaStr = r['fecha'] as String?;
      final horaStr = r['hora'] as String?;
      if (fechaStr == null || horaStr == null) continue;

      try {
        final fecha = DateTime.parse(fechaStr);
        final horaParts = horaStr.split(':');
        final reservationTime = DateTime(
          fecha.year, fecha.month, fecha.day,
          int.parse(horaParts[0]), int.parse(horaParts[1]),
        );

        final reminderWindow = reservationTime.subtract(
          Duration(hours: config.reminderHoursBefore),
        );

        // Dentro de la ventana y aún en el futuro
        if (now.isAfter(reminderWindow) && now.isBefore(reservationTime)) {
          pending.add(r);
        }
      } catch (_) {
        continue;
      }
    }

    // Ordenar por fecha/hora más próxima
    pending.sort((a, b) {
      final aKey = '${a['fecha']} ${a['hora']}';
      final bKey = '${b['fecha']} ${b['hora']}';
      return aKey.compareTo(bKey);
    });

    return pending;
  }

  /// Marca un recordatorio como enviado.
  static Future<bool> markReminderSent(String reservationId) async {
    final storage = SupabaseService.instance;
    final reservations = await storage.getReservations();
    final index = reservations.indexWhere((r) => r['id'] == reservationId);
    if (index == -1) return false;

    reservations[index]['recordatorio_enviado'] = true;
    reservations[index]['recordatorio_enviado_at'] = DateTime.now().toIso8601String();

    await storage.saveReservations(reservations);
    LocalReservationService.clearReservationsCache();
    return true;
  }
}
