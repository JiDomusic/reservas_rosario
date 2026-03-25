import 'dart:math';
import '../config/app_config.dart';
import 'supabase_service.dart';
import 'local_block_service.dart';

class LocalReservationService {
  static Map<String, List<Map<String, dynamic>>>? _queryCache;
  static DateTime? _lastQueryTime;

  static void clearReservationsCache() {
    _queryCache = null;
    _lastQueryTime = null;
  }

  /// Determina el área según el horario
  static String _determineAreaByTime(String hora) {
    final config = AppConfig.instance;
    final int hour = int.parse(hora.split(':')[0]);
    final int minute = int.parse(hora.split(':')[1]);
    final totalMinutes = hour * 60 + minute;

    for (final area in config.areas) {
      if (area.horaInicio != null && area.horaFin != null) {
        final startParts = area.horaInicio!.split(':');
        final endParts = area.horaFin!.split(':');
        final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
        final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
        if (totalMinutes >= startMin && totalMinutes <= endMin) {
          return area.nombre;
        }
      }
    }
    return config.areas.isNotEmpty ? config.areas.first.nombre : 'principal';
  }

  /// Crear una nueva reserva
  static Future<Map<String, dynamic>> createReservation({
    required DateTime fecha,
    required String hora,
    required int personas,
    required String nombre,
    required String telefono,
    required String codigoConfirmacion,
    String? email,
    String? comentarios,
  }) async {
    try {
      if (AppConfig.instance.isDayClosed(fecha.weekday)) {
        return {
          'success': false,
          'error': 'No se pueden hacer reservas este día. El restaurante permanece cerrado.',
        };
      }

      final isBlocked = await LocalBlockService.isSlotBlocked(fecha, hora);
      if (isBlocked) {
        return {
          'success': false,
          'error': 'El horario fue bloqueado por administración.',
        };
      }

      final fechaStr = fecha.toIso8601String().split('T')[0];
      final area = _determineAreaByTime(hora);
      final id = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999).toString().padLeft(5, '0')}';

      final reserva = {
        'id': id,
        'fecha': fechaStr,
        'hora': hora,
        'personas': personas,
        'nombre': nombre,
        'telefono': telefono,
        'codigo_confirmacion': codigoConfirmacion,
        'email': email,
        'comentarios': comentarios,
        'estado': 'pendiente_confirmacion',
        'area': area,
        'created_at': DateTime.now().toIso8601String(),
      };

      final storage = SupabaseService.instance;
      await storage.insertReservation(reserva);
      clearReservationsCache();

      return {
        'success': true,
        'data': reserva,
        'message': 'Reserva creada exitosamente',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Error al crear la reserva',
      };
    }
  }

  /// Obtener reservas para una fecha
  static Future<List<Map<String, dynamic>>> getReservationsForDate(DateTime fecha) async {
    final fechaStr = fecha.toIso8601String().split('T')[0];

    if (_queryCache != null &&
        _lastQueryTime != null &&
        DateTime.now().difference(_lastQueryTime!).inSeconds < 10 &&
        _queryCache!.containsKey(fechaStr)) {
      return _queryCache![fechaStr]!;
    }

    final all = await SupabaseService.instance.getReservations();
    final result = all.where((r) => r['fecha'] == fechaStr).toList();
    result.sort((a, b) => (a['hora'] as String).compareTo(b['hora'] as String));

    _queryCache = {fechaStr: result};
    _lastQueryTime = DateTime.now();

    return result;
  }

  /// Obtener reservas activas para fecha y hora
  static Future<List<Map<String, dynamic>>> getActiveReservationsForSlot({
    required DateTime fecha,
    required String hora,
  }) async {
    final fechaStr = fecha.toIso8601String().split('T')[0];
    final all = await SupabaseService.instance.getReservations();
    return all.where((r) =>
      r['fecha'] == fechaStr &&
      r['hora'] == hora &&
      (r['estado'] == 'confirmada' || r['estado'] == 'en_mesa' || r['estado'] == 'pendiente_confirmacion')
    ).toList();
  }

  /// Obtener personas reservadas para un slot
  static Future<int> getOccupancyForSlot({
    required DateTime fecha,
    required String hora,
  }) async {
    final reservas = await getActiveReservationsForSlot(fecha: fecha, hora: hora);
    int total = 0;
    for (final r in reservas) {
      total += (r['personas'] as int);
    }
    return total;
  }

  /// Obtener ocupación diaria
  static Future<int> getDailyOccupancy(DateTime fecha) async {
    final fechaStr = fecha.toIso8601String().split('T')[0];
    final all = await SupabaseService.instance.getReservations();
    int total = 0;
    for (final r in all) {
      if (r['fecha'] == fechaStr &&
          (r['estado'] == 'confirmada' || r['estado'] == 'en_mesa' || r['estado'] == 'pendiente_confirmacion')) {
        total += (r['personas'] as int);
      }
    }
    return total;
  }

  /// Actualizar estado de reserva
  static Future<bool> updateReservationStatus(String reservationId, String newStatus) async {
    try {
      final storage = SupabaseService.instance;
      final reservations = await storage.getReservations();
      final index = reservations.indexWhere((r) => r['id'] == reservationId);
      if (index == -1) return false;

      reservations[index]['estado'] = newStatus;
      await storage.saveReservations(reservations);
      clearReservationsCache();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> cancelReservation(String reservationId) async {
    return updateReservationStatus(reservationId, 'cancelada');
  }

  static Future<bool> markAsNoShow(String reservationId) async {
    return updateReservationStatus(reservationId, 'no_show');
  }

  static Future<bool> markCustomerArrived(String reservationId) async {
    return updateReservationStatus(reservationId, 'en_mesa');
  }

  static Future<bool> completeReservation(String reservationId) async {
    return updateReservationStatus(reservationId, 'completada');
  }

  /// Capacidad disponible para fecha/hora
  static Future<Map<String, int>> getAvailableCapacity({
    required DateTime fecha,
    required String hora,
  }) async {
    final config = AppConfig.instance;
    final personasReservadas = await getOccupancyForSlot(fecha: fecha, hora: hora);
    final areaName = _determineAreaByTime(hora);
    final area = config.getArea(areaName);
    final capacidadArea = area?.capacidadFrontend ?? 0;
    final disponible = capacidadArea - personasReservadas;

    return {
      'total_capacity': capacidadArea,
      'reserved': personasReservadas,
      'available': disponible > 0 ? disponible : 0,
    };
  }

  /// Buscar reserva por código
  static Future<Map<String, dynamic>?> findReservationByCode(String code) async {
    final all = await SupabaseService.instance.getReservations();
    try {
      return all.firstWhere((r) => r['codigo_confirmacion'] == code);
    } catch (_) {
      return null;
    }
  }

  /// Verificar si un código ya existe
  static Future<bool> isCodeUsed(String code) async {
    final all = await SupabaseService.instance.getReservations();
    return all.any((r) => r['codigo_confirmacion'] == code);
  }
}
