import 'supabase_service.dart';

class ReportService {
  /// Genera un reporte con estadísticas para un rango de fechas.
  static Future<Map<String, dynamic>> generateReport(DateTime startDate, DateTime endDate) async {
    final storage = SupabaseService.instance;
    final allReservations = await storage.getReservations();

    final startStr = startDate.toIso8601String().split('T')[0];
    final endStr = endDate.toIso8601String().split('T')[0];

    final filtered = allReservations.where((r) {
      final fecha = r['fecha'] as String? ?? '';
      return fecha.compareTo(startStr) >= 0 && fecha.compareTo(endStr) <= 0;
    }).toList();

    if (filtered.isEmpty) {
      return {
        'total_reservas': 0,
        'tasa_no_show': 0.0,
        'tasa_cancelacion': 0.0,
        'promedio_personas': 0.0,
        'dia_mas_ocupado': null,
        'horario_mas_ocupado': null,
        'ocupacion_por_area': <String, int>{},
        'reservas_por_estado': <String, int>{},
        'reservas_por_dia': <String, int>{},
        'reservas_por_hora': <String, int>{},
      };
    }

    final total = filtered.length;
    int noShows = 0;
    int canceladas = 0;
    int totalPersonas = 0;
    final porDia = <String, int>{};
    final porHora = <String, int>{};
    final porArea = <String, int>{};
    final porEstado = <String, int>{};

    final dayNames = ['', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

    for (final r in filtered) {
      final estado = r['estado'] as String? ?? 'desconocido';
      porEstado[estado] = (porEstado[estado] ?? 0) + 1;

      if (estado == 'no_show') noShows++;
      if (estado == 'cancelada') canceladas++;

      final personas = r['personas'];
      if (personas is int) {
        totalPersonas += personas;
      }

      final fecha = r['fecha'] as String?;
      if (fecha != null) {
        try {
          final dt = DateTime.parse(fecha);
          final dayName = dayNames[dt.weekday];
          porDia[dayName] = (porDia[dayName] ?? 0) + 1;
        } catch (_) {}
      }

      final hora = r['hora'] as String?;
      if (hora != null) {
        final horaShort = hora.substring(0, 5);
        porHora[horaShort] = (porHora[horaShort] ?? 0) + 1;
      }

      final area = r['area'] as String?;
      if (area != null) {
        porArea[area] = (porArea[area] ?? 0) + 1;
      }
    }

    // Día más ocupado
    String? diaMasOcupado;
    int maxDia = 0;
    for (final entry in porDia.entries) {
      if (entry.value > maxDia) {
        maxDia = entry.value;
        diaMasOcupado = entry.key;
      }
    }

    // Horario más ocupado
    String? horarioMasOcupado;
    int maxHora = 0;
    for (final entry in porHora.entries) {
      if (entry.value > maxHora) {
        maxHora = entry.value;
        horarioMasOcupado = entry.key;
      }
    }

    return {
      'total_reservas': total,
      'tasa_no_show': total > 0 ? (noShows / total * 100) : 0.0,
      'tasa_cancelacion': total > 0 ? (canceladas / total * 100) : 0.0,
      'promedio_personas': total > 0 ? (totalPersonas / total) : 0.0,
      'dia_mas_ocupado': diaMasOcupado,
      'horario_mas_ocupado': horarioMasOcupado,
      'ocupacion_por_area': porArea,
      'reservas_por_estado': porEstado,
      'reservas_por_dia': porDia,
      'reservas_por_hora': porHora,
    };
  }
}
