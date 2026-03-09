import '../config/app_config.dart';
import 'local_reservation_service.dart';

class ReservationCapacityService {
  static int get dailyCapacity => AppConfig.instance.totalCapacity;

  static int getCapacityForArea(String areaName) {
    return AppConfig.instance.getArea(areaName)?.capacidadFrontend ?? 100;
  }

  static String getAreaForTime(String time) {
    final hour = int.parse(time.split(':')[0]);
    for (final area in AppConfig.instance.areas) {
      if (area.horaInicio != null && area.horaFin != null) {
        final startH = int.parse(area.horaInicio!.split(':')[0]);
        final endH = int.parse(area.horaFin!.split(':')[0]);
        if (hour >= startH && hour <= endH) {
          return area.nombre;
        }
      }
    }
    return AppConfig.instance.areas.isNotEmpty
        ? AppConfig.instance.areas.first.nombre
        : 'planta_baja';
  }

  static int getCapacityForTime(String time) {
    final area = getAreaForTime(time);
    return getCapacityForArea(area);
  }

  static bool isLunchTime(String time) {
    final hour = int.parse(time.split(':')[0]);
    return hour >= 12 && hour <= 15;
  }

  static bool canReserveWithAnticipation(String time, DateTime reservationDate) {
    if (AppConfig.instance.isDayClosed(reservationDate.weekday)) {
      return false;
    }

    DateTime now = DateTime.now();
    DateTime reservationDateTime = DateTime(
      reservationDate.year,
      reservationDate.month,
      reservationDate.day,
      int.parse(time.split(':')[0]),
      int.parse(time.split(':')[1]),
    );

    Duration difference = reservationDateTime.difference(now);

    if (isLunchTime(time)) {
      return difference.inHours >= AppConfig.instance.lunchAdvanceHours;
    } else {
      return difference.inHours >= AppConfig.instance.regularAdvanceHours;
    }
  }

  static Future<int> getCurrentOccupancyForTime({
    required DateTime fecha,
    required String hora,
  }) async {
    return LocalReservationService.getOccupancyForSlot(fecha: fecha, hora: hora);
  }

  static Future<int> getDailyOccupancy({
    required DateTime fecha,
  }) async {
    return LocalReservationService.getDailyOccupancy(fecha);
  }

  static Future<bool> checkAvailabilityWithFloorCapacity({
    required DateTime fecha,
    required String hora,
    required int personas,
  }) async {
    try {
      if (!canReserveWithAnticipation(hora, fecha)) {
        return false;
      }

      int dailyTotal = await getDailyOccupancy(fecha: fecha);
      if ((dailyTotal + personas) > dailyCapacity) {
        return false;
      }

      int currentOccupancy = await getCurrentOccupancyForTime(
        fecha: fecha,
        hora: hora,
      );

      int maxCapacity = getCapacityForTime(hora);

      return (currentOccupancy + personas) <= maxCapacity;

    } catch (e) {
      return false;
    }
  }
}
