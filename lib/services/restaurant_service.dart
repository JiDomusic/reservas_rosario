import '../config/app_config.dart';
import 'local_reservation_service.dart';
import 'table_combination_service.dart';

class RestaurantService {
  static bool esDomingo(DateTime date) {
    return date.weekday == DateTime.sunday;
  }

  static List<String> getAvailableTimeSlotsForDate(DateTime date, int guests) {
    final config = AppConfig.instance;
    final now = DateTime.now();
    final isToday = date.day == now.day &&
                   date.month == now.month &&
                   date.year == now.year;

    if (config.isDayClosed(date.weekday)) {
      return [];
    }

    final hoursForDay = config.getHoursForDay(date.weekday);
    if (hoursForDay.isEmpty) return [];

    List<String> availableSlots = [];

    for (final opHours in hoursForDay) {
      final interval = opHours.intervaloMinutos;
      int currentMinutes = opHours.horaInicioInt * 60 + opHours.minutoInicioInt;
      final endMinutes = opHours.horaFinInt * 60 + opHours.minutoFinInt;

      while (currentMinutes <= endMinutes) {
        final hour = currentMinutes ~/ 60;
        final minute = currentMinutes % 60;
        final timeString = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        final timeSlot = DateTime(date.year, date.month, date.day, hour, minute);

        if (_isTimeSlotAvailable(timeSlot, guests, now, isToday, opHours.area)) {
          availableSlots.add(timeString);
        }

        currentMinutes += interval;
      }
    }

    return availableSlots;
  }

  static List<String> getAllTimeSlotsForDate(DateTime date, int guests) {
    final config = AppConfig.instance;

    if (config.isDayClosed(date.weekday)) {
      return [];
    }

    final hoursForDay = config.getHoursForDay(date.weekday);
    if (hoursForDay.isEmpty) return [];

    List<String> allSlots = [];

    for (final opHours in hoursForDay) {
      final interval = opHours.intervaloMinutos;
      int currentMinutes = opHours.horaInicioInt * 60 + opHours.minutoInicioInt;
      final endMinutes = opHours.horaFinInt * 60 + opHours.minutoFinInt;

      while (currentMinutes <= endMinutes) {
        final hour = currentMinutes ~/ 60;
        final minute = currentMinutes % 60;
        final timeString = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        allSlots.add(timeString);
        currentMinutes += interval;
      }
    }

    return allSlots;
  }

  static bool isOutsideAdvanceTime(DateTime date, String timeString, int guests) {
    final config = AppConfig.instance;
    final now = DateTime.now();
    final timeParts = timeString.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    final timeSlot = DateTime(date.year, date.month, date.day, hour, minute);
    final isLunchTime = hour >= 12 && hour <= 15;

    if (isLunchTime) {
      final minTime = now.add(Duration(hours: config.lunchAdvanceHours));
      return timeSlot.isBefore(minTime);
    } else {
      final minTime = now.add(Duration(hours: config.regularAdvanceHours));
      return timeSlot.isBefore(minTime);
    }
  }

  static bool _isTimeSlotAvailable(DateTime timeSlot, int guests, DateTime now, bool isToday, String areaName) {
    final config = AppConfig.instance;
    final area = config.getArea(areaName);

    if (isToday && timeSlot.isBefore(now)) {
      return false;
    }

    if (guests > config.maxGuests) {
      return false;
    }

    if (area != null && guests > area.capacidadFrontend) {
      return false;
    }

    final hour = timeSlot.hour;
    final isLunchTime = hour >= 12 && hour <= 15;

    if (isLunchTime) {
      final minTime = now.add(Duration(hours: config.lunchAdvanceHours));
      if (timeSlot.isBefore(minTime)) {
        return false;
      }
    } else if (timeSlot.isAfter(now)) {
      final minTime = now.add(Duration(hours: config.regularAdvanceHours));
      if (timeSlot.isBefore(minTime)) {
        return false;
      }
    }

    return true;
  }

  static String getRestrictionInfo() {
    final config = AppConfig.instance;
    final buffer = StringBuffer();

    final dayNames = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

    for (final area in config.areas) {
      final areaHours = config.operatingHours.where((oh) => oh.area == area.nombre).toList();
      if (areaHours.isEmpty) continue;

      final Map<String, List<int>> rangesByDay = {};
      for (final oh in areaHours) {
        final range = '${oh.horaInicio} a ${oh.horaFin}';
        rangesByDay.putIfAbsent(range, () => []);
        rangesByDay[range]!.add(oh.diaSemana);
      }

      for (final entry in rangesByDay.entries) {
        final days = entry.value..sort();
        final dayRangeStr = _formatDayRange(days, dayNames);
        buffer.writeln('${area.nombreDisplay} (${area.capacidadFrontend} pers): ${entry.key} - $dayRangeStr');
      }
    }

    buffer.writeln();
    buffer.writeln('ANTICIPACION REQUERIDA:');
    buffer.writeln('Almuerzo (12:00-15:00): ${config.lunchAdvanceHours} horas de anticipacion');
    buffer.writeln('Resto de horarios: ${config.regularAdvanceHours} horas de anticipacion');
    buffer.writeln();
    buffer.writeln('GRUPOS: ${config.minGuests}-${config.maxGuests} personas');
    buffer.writeln('Para mas de ${config.maxGuests} personas contactar por WhatsApp: ${config.whatsappNumber}');

    return buffer.toString();
  }

  static String _formatDayRange(List<int> days, List<String> dayNames) {
    if (days.length == 1) return dayNames[days.first];
    if (days.length == 7) return 'Todos los días';

    final sorted = List<int>.from(days)..sort();
    if (_isConsecutive(sorted)) {
      return '${dayNames[sorted.first]} a ${dayNames[sorted.last]}';
    }

    return sorted.map((d) => dayNames[d]).join(', ');
  }

  static bool _isConsecutive(List<int> sorted) {
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i] != sorted[i - 1] + 1) return false;
    }
    return true;
  }

  static Future<Map<String, dynamic>> validateReservation({
    required DateTime date,
    required String time,
    required int guests,
  }) async {
    final config = AppConfig.instance;
    final now = DateTime.now();
    final timeSlot = DateTime(
      date.year,
      date.month,
      date.day,
      int.parse(time.split(':')[0]),
      int.parse(time.split(':')[1])
    );

    final isToday = date.day == now.day &&
                   date.month == now.month &&
                   date.year == now.year;

    if (config.isDayClosed(date.weekday)) {
      return {
        'valid': false,
        'error': 'El restaurante no abre este día.',
      };
    }

    final hoursForDay = config.getHoursForDay(date.weekday);
    String? matchedArea;
    for (final oh in hoursForDay) {
      final slotMinutes = timeSlot.hour * 60 + timeSlot.minute;
      final startMin = oh.horaInicioInt * 60 + oh.minutoInicioInt;
      final endMin = oh.horaFinInt * 60 + oh.minutoFinInt;
      if (slotMinutes >= startMin && slotMinutes <= endMin) {
        matchedArea = oh.area;
        break;
      }
    }

    if (matchedArea == null) {
      return {
        'valid': false,
        'error': 'Horario fuera de operación.',
      };
    }

    final area = config.getArea(matchedArea);
    final areaDisplay = area?.nombreDisplay ?? matchedArea;
    final maxCapacity = area?.capacidadFrontend ?? 0;

    if (guests > config.maxGuests) {
      return {
        'valid': false,
        'error': 'Para grupos de mas de ${config.maxGuests} personas, contactar por WhatsApp:\n${config.whatsappNumber}',
      };
    }

    if (guests < config.minGuests) {
      return {
        'valid': false,
        'error': 'Las reservas son para grupos de ${config.minGuests} a ${config.maxGuests} personas.',
      };
    }

    if (config.useTableSystem) {
      final tableValidation = await TableCombinationService.validateReservationWithTables(
        fecha: date,
        hora: time,
        personas: guests,
      );

      if (!tableValidation['valid']) {
        return tableValidation;
      }
    }

    if (guests > maxCapacity) {
      return {
        'valid': false,
        'error': 'Excede la capacidad de $areaDisplay (maximo $maxCapacity personas).',
      };
    }

    final hour = timeSlot.hour;
    final isLunchTime = hour >= 12 && hour <= 15;

    if (isLunchTime && isToday) {
      final minTime = now.add(Duration(hours: config.lunchAdvanceHours));
      if (timeSlot.isBefore(minTime)) {
        return {
          'valid': false,
          'error': 'El almuerzo requiere reserva con ${config.lunchAdvanceHours} horas de anticipacion.',
        };
      }
    } else {
      final minTime = now.add(Duration(hours: config.regularAdvanceHours));
      if (timeSlot.isBefore(minTime)) {
        return {
          'valid': false,
          'error': 'Este horario requiere reserva con ${config.regularAdvanceHours} horas de anticipacion.',
        };
      }
    }

    final capacityInfo = await LocalReservationService.getAvailableCapacity(
      fecha: date,
      hora: time,
    );

    final availableCapacity = capacityInfo['available'] ?? 0;

    if (guests > availableCapacity) {
      return {
        'valid': false,
        'error': 'No hay mas lugar para $guests personas en ese horario.\nCapacidad disponible: $availableCapacity personas.',
      };
    }

    return {
      'valid': true,
      'area': areaDisplay,
      'capacity': maxCapacity,
      'available_capacity': availableCapacity,
    };
  }
}
