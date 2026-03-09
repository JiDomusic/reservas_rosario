import '../config/app_config.dart';
import 'supabase_service.dart';
import 'local_reservation_service.dart';

class AutoReleaseService {
  /// Escanea reservas "confirmada" cuya hora + autoReleaseMinutes ya pasó
  /// y las marca como "no_show".
  static Future<int> processAutoRelease() async {
    final config = AppConfig.instance;
    final now = DateTime.now();
    final storage = SupabaseService.instance;
    final reservations = await storage.getReservations();
    int released = 0;

    for (int i = 0; i < reservations.length; i++) {
      final r = reservations[i];
      if (r['estado'] != 'confirmada' && r['estado'] != 'pendiente_confirmacion') continue;

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

        final releaseTime = reservationTime.add(
          Duration(minutes: config.autoReleaseMinutes),
        );

        if (now.isAfter(releaseTime)) {
          reservations[i]['estado'] = 'no_show';
          released++;
        }
      } catch (_) {
        continue;
      }
    }

    if (released > 0) {
      await storage.saveReservations(reservations);
      LocalReservationService.clearReservationsCache();
    }

    return released;
  }

  /// Devuelve reservas confirmadas que están retrasadas (hora ya pasó pero
  /// aún no se cumple el autoReleaseMinutes).
  static List<Map<String, dynamic>> getLateReservations(
      List<Map<String, dynamic>> reservations) {
    final config = AppConfig.instance;
    final now = DateTime.now();
    final late = <Map<String, dynamic>>[];

    for (final r in reservations) {
      if (r['estado'] != 'confirmada') continue;

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

        final releaseTime = reservationTime.add(
          Duration(minutes: config.autoReleaseMinutes),
        );

        if (now.isAfter(reservationTime) && now.isBefore(releaseTime)) {
          final lateMinutes = now.difference(reservationTime).inMinutes;
          late.add({...r, '_late_minutes': lateMinutes});
        }
      } catch (_) {
        continue;
      }
    }

    return late;
  }

  /// Calcula minutos de retraso para una reserva específica.
  /// Retorna null si no está retrasada.
  static int? getLateMinutes(Map<String, dynamic> reservation) {
    if (reservation['estado'] != 'confirmada') return null;

    final now = DateTime.now();
    final fechaStr = reservation['fecha'] as String?;
    final horaStr = reservation['hora'] as String?;
    if (fechaStr == null || horaStr == null) return null;

    try {
      final fecha = DateTime.parse(fechaStr);
      final horaParts = horaStr.split(':');
      final reservationTime = DateTime(
        fecha.year, fecha.month, fecha.day,
        int.parse(horaParts[0]), int.parse(horaParts[1]),
      );

      if (now.isAfter(reservationTime)) {
        return now.difference(reservationTime).inMinutes;
      }
    } catch (_) {
      // ignore
    }

    return null;
  }
}
