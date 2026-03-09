/// Servicio de combinación de mesas estilo Woki App
/// Gestiona las capacidades reales basadas en mesas físicas.
///
/// REGLAS:
/// - Máximo 3 lugares vacíos por combinación de mesas
/// - Mesas VIP pueden bloquearse individualmente
/// - La capacidad compartida entre horarios es configurable

import '../config/app_config.dart';
import '../models/table_definition.dart';
import 'local_reservation_service.dart';
import 'local_block_service.dart';
import 'supabase_service.dart';

class TableType {
  final String id;
  final int minCapacity;
  final int maxCapacity;
  final int quantity;
  final bool isVip;
  final bool blockable;

  const TableType({
    required this.id,
    required this.minCapacity,
    required this.maxCapacity,
    required this.quantity,
    this.isVip = false,
    this.blockable = false,
  });

  factory TableType.fromDefinition(TableDefinition def) {
    return TableType(
      id: def.nombre,
      minCapacity: def.minCapacidad,
      maxCapacity: def.maxCapacidad,
      quantity: def.cantidad,
      isVip: def.esVip,
      blockable: def.bloqueable,
    );
  }

  @override
  String toString() => 'Mesa $id: $minCapacity-$maxCapacity ($quantity unidades)';
}

class TableCombination {
  final List<TableType> tables;
  final int totalTables;
  final int minCapacity;
  final int maxCapacity;
  final int wastedSeats;

  const TableCombination({
    required this.tables,
    required this.totalTables,
    required this.minCapacity,
    required this.maxCapacity,
    required this.wastedSeats,
  });

  bool canAccommodate(int guests) {
    return guests >= minCapacity &&
           guests <= maxCapacity &&
           wastedSeats <= 3;
  }

  @override
  String toString() {
    final tableNames = tables.map((t) => '${t.id}').join('+');
    return 'Combinacion: $tableNames ($totalTables mesas) | Capacidad: $minCapacity-$maxCapacity | Desperdicio: $wastedSeats lugares';
  }
}

class TableCombinationService {
  static List<TableType> _loadTablesFromConfig({String? area}) {
    final config = AppConfig.instance;
    var definitions = config.tables;
    if (area != null) {
      definitions = definitions.where((t) => t.area == area).toList();
    }
    return definitions.map((d) => TableType.fromDefinition(d)).toList();
  }

  static Future<List<TableType>> getAvailableTables({String? area}) async {
    final allTables = _loadTablesFromConfig(area: area);

    final List<TableType> available = [];
    for (final table in allTables) {
      if (table.blockable) {
        final isBlocked = await isTableBlocked(table.id);
        if (!isBlocked) {
          available.add(table);
        }
      } else {
        available.add(table);
      }
    }
    return available;
  }

  static Future<int> getRealCapacity({String? area}) async {
    final tables = await getAvailableTables(area: area);
    int total = 0;
    for (final t in tables) {
      total += t.maxCapacity * t.quantity;
    }
    return total;
  }

  static Future<bool> isTableBlocked(String tableId) async {
    final blocks = await SupabaseService.instance.getTableBlocks();
    return blocks['mesa_${tableId}_bloqueada'] == true;
  }

  static Future<bool> toggleTableBlocked(String tableId) async {
    try {
      final blocks = await SupabaseService.instance.getTableBlocks();
      final key = 'mesa_${tableId}_bloqueada';
      final currentState = blocks[key] ?? false;
      final newState = !currentState;
      blocks[key] = newState;
      await SupabaseService.instance.saveTableBlocks(blocks);
      return newState;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> validateReservationWithTables({
    required DateTime fecha,
    required String hora,
    required int personas,
  }) async {
    final config = AppConfig.instance;

    final blockStatus = await LocalBlockService.getStatus(fecha);
    final hourParts = hora.split(':');
    final hourKey = hourParts.length >= 2
        ? '${hourParts[0].padLeft(2, '0')}:${hourParts[1].padLeft(2, '0')}'
        : hora;

    if (blockStatus.isDayBlocked) {
      return {
        'valid': false,
        'blocked': true,
        'showCross': true,
        'error': blockStatus.reason ?? 'Dia bloqueado por administracion',
      };
    }

    if (blockStatus.blockedHours.contains(hourKey)) {
      return {
        'valid': false,
        'blocked': true,
        'showCross': true,
        'error': blockStatus.reason ?? 'Horario bloqueado por administracion',
      };
    }

    final area = _getAreaForTime(hora, fecha.weekday);

    if (!config.useTableSystem) {
      return await _validateSimpleCapacity(
        fecha: fecha,
        hora: hora,
        personas: personas,
        area: area,
      );
    }

    final areaConfig = config.getArea(area);
    final areaTables = config.getTablesForArea(area);

    if (areaTables.isEmpty) {
      return await _validateSimpleCapacity(
        fecha: fecha,
        hora: hora,
        personas: personas,
        area: area,
      );
    }

    final smallestMin = areaTables.fold<int>(999, (min, t) => t.minCapacidad < min ? t.minCapacidad : min);
    if (personas < smallestMin) {
      final sugerencia = await getSugerenciaInteligente(
        fecha: fecha,
        hora: hora,
        personas: personas,
      );
      return {
        'valid': false,
        'error': 'El minimo de personas para ${areaConfig?.nombreDisplay ?? area} es $smallestMin.',
        'blocked': true,
        'showCross': true,
        'sugerencia': sugerencia,
      };
    }

    if (personas > config.maxGuests) {
      return {
        'valid': false,
        'error': 'El maximo de personas es ${config.maxGuests}. Para grupos mas grandes, contactanos por WhatsApp al ${config.whatsappNumber}.',
        'blocked': true,
      };
    }

    final combination = await findBestCombination(
      guests: personas,
      area: area,
    );

    if (combination == null) {
      final sugerencia = await getSugerenciaInteligente(
        fecha: fecha,
        hora: hora,
        personas: personas,
      );
      return {
        'valid': false,
        'error': 'No hay disponibilidad para $personas personas en este horario.',
        'blocked': true,
        'sugerencia': sugerencia,
      };
    }

    final availability = await checkRealAvailability(
      fecha: fecha,
      hora: hora,
      personas: personas,
      area: area,
      combination: combination,
    );

    if (availability['valid'] == false) {
      final sugerencia = await getSugerenciaInteligente(
        fecha: fecha,
        hora: hora,
        personas: personas,
      );
      availability['sugerencia'] = sugerencia;
    }

    return availability;
  }

  static Future<Map<String, dynamic>> _validateSimpleCapacity({
    required DateTime fecha,
    required String hora,
    required int personas,
    required String area,
  }) async {
    try {
      final config = AppConfig.instance;
      final areaConfig = config.getArea(area);
      final frontendCapacity = areaConfig?.capacidadFrontend ?? 0;

      final personasOcupadas = await LocalReservationService.getOccupancyForSlot(
        fecha: fecha,
        hora: hora,
      );

      final capacidadDisponible = frontendCapacity - personasOcupadas;
      final hayCupo = capacidadDisponible >= personas;

      if (!hayCupo) {
        return {
          'valid': false,
          'error': 'No hay capacidad para $personas personas',
          'available': capacidadDisponible,
          'required': personas,
          'showCross': true,
          'area': area,
          'whatsappNumber': config.whatsappNumber,
          'whatsappMessage': 'Hola! Necesito reservar para $personas personas. Tienen disponibilidad?',
        };
      }

      return {
        'valid': true,
        'area': area,
        'remaining': capacidadDisponible - personas,
        'message': 'Disponible en ${areaConfig?.nombreDisplay ?? area}',
      };
    } catch (e) {
      return {
        'valid': false,
        'error': 'Error al verificar disponibilidad',
        'showCross': false,
      };
    }
  }

  static final Map<String, TableCombination?> _combinationCache = {};

  static Future<TableCombination?> findBestCombination({
    required int guests,
    required String area,
  }) async {
    final cacheKey = '${guests}_$area';
    if (_combinationCache.containsKey(cacheKey)) {
      return _combinationCache[cacheKey];
    }

    final availableTables = await getAvailableTables(area: area);

    if (availableTables.isEmpty) {
      _combinationCache[cacheKey] = null;
      return null;
    }

    TableCombination? fastResult = _tryFastPath(guests, availableTables);
    if (fastResult != null) {
      _combinationCache[cacheKey] = fastResult;
      return fastResult;
    }

    for (int numMesas = 1; numMesas <= 6; numMesas++) {
      final validCombinations = <TableCombination>[];

      _generateCombinations(
        availableTables,
        numMesas,
        guests,
        validCombinations,
      );

      final filtered = validCombinations.where((c) => c.wastedSeats <= 3).toList();
      if (filtered.isNotEmpty) {
        filtered.sort((a, b) => a.wastedSeats.compareTo(b.wastedSeats));
        _combinationCache[cacheKey] = filtered.first;
        return filtered.first;
      }
    }

    _combinationCache[cacheKey] = null;
    return null;
  }

  static TableCombination? _tryFastPath(int guests, List<TableType> tables) {
    for (final table in tables) {
      if (guests >= table.minCapacity && guests <= table.maxCapacity) {
        final waste = table.maxCapacity - guests;
        if (waste <= 3) {
          return TableCombination(
            tables: [table],
            totalTables: 1,
            minCapacity: table.minCapacity,
            maxCapacity: table.maxCapacity,
            wastedSeats: waste,
          );
        }
      }
    }

    final smallTables = tables.where((t) => t.maxCapacity <= 4).toList();
    if (smallTables.length >= 2 && guests >= 5 && guests <= 8) {
      final t1 = smallTables[0];
      final t2 = smallTables[1];
      final maxCap = t1.maxCapacity + t2.maxCapacity;
      final minCap = t1.minCapacity + t2.minCapacity;
      if (guests >= minCap && guests <= maxCap) {
        return TableCombination(
          tables: [t1, t2],
          totalTables: 2,
          minCapacity: minCap,
          maxCapacity: maxCap,
          wastedSeats: maxCap - guests,
        );
      }
    }

    return null;
  }

  static void _generateCombinations(
    List<TableType> availableTables,
    int numMesas,
    int guests,
    List<TableCombination> results,
  ) {
    if (numMesas == 1) {
      for (final table in availableTables) {
        if (guests >= table.minCapacity && guests <= table.maxCapacity) {
          results.add(TableCombination(
            tables: [table],
            totalTables: 1,
            minCapacity: table.minCapacity,
            maxCapacity: table.maxCapacity,
            wastedSeats: table.maxCapacity - guests,
          ));
        }
      }
    } else if (numMesas == 2) {
      for (int i = 0; i < availableTables.length; i++) {
        for (int j = i; j < availableTables.length; j++) {
          if (i == j && availableTables[i].quantity < 2) continue;

          final t1 = availableTables[i];
          final t2 = availableTables[j];
          final maxCap = t1.maxCapacity + t2.maxCapacity;
          final minCap = t1.minCapacity + t2.minCapacity;

          if (guests >= minCap && guests <= maxCap) {
            results.add(TableCombination(
              tables: [t1, t2],
              totalTables: 2,
              minCapacity: minCap,
              maxCapacity: maxCap,
              wastedSeats: maxCap - guests,
            ));
          }
        }
      }
    } else if (numMesas == 3) {
      for (int i = 0; i < availableTables.length; i++) {
        for (int j = i; j < availableTables.length; j++) {
          for (int k = j; k < availableTables.length; k++) {
            final sameAsI = [i, j, k].where((idx) => idx == i).length;
            final sameAsJ = [i, j, k].where((idx) => idx == j).length;
            final sameAsK = [i, j, k].where((idx) => idx == k).length;

            if (sameAsI > availableTables[i].quantity) continue;
            if (j != i && sameAsJ > availableTables[j].quantity) continue;
            if (k != i && k != j && sameAsK > availableTables[k].quantity) continue;

            final t1 = availableTables[i];
            final t2 = availableTables[j];
            final t3 = availableTables[k];
            final maxCap = t1.maxCapacity + t2.maxCapacity + t3.maxCapacity;
            final minCap = t1.minCapacity + t2.minCapacity + t3.minCapacity;

            if (guests >= minCap && guests <= maxCap) {
              results.add(TableCombination(
                tables: [t1, t2, t3],
                totalTables: 3,
                minCapacity: minCap,
                maxCapacity: maxCap,
                wastedSeats: maxCap - guests,
              ));
            }
          }
        }
      }
    } else if (numMesas >= 4) {
      final smallTables = availableTables.where((t) => t.maxCapacity <= 4).toList();
      final totalSmallTables = smallTables.fold<int>(0, (sum, t) => sum + t.quantity);

      if (smallTables.isEmpty || totalSmallTables < numMesas) return;

      final maxCap = numMesas * 4;
      final minCap = numMesas * 2;

      if (guests >= minCap && guests <= maxCap) {
        final tablesList = <TableType>[];
        var mesasUsadas = 0;

        for (final table in smallTables) {
          for (int i = 0; i < table.quantity && mesasUsadas < numMesas; i++) {
            tablesList.add(table);
            mesasUsadas++;
          }
          if (mesasUsadas >= numMesas) break;
        }

        results.add(TableCombination(
          tables: tablesList,
          totalTables: numMesas,
          minCapacity: minCap,
          maxCapacity: maxCap,
          wastedSeats: maxCap - guests,
        ));
      }
    }
  }

  static Future<Map<String, dynamic>> checkRealAvailability({
    required DateTime fecha,
    required String hora,
    required int personas,
    required String area,
    required TableCombination combination,
  }) async {
    try {
      final config = AppConfig.instance;
      List<Map<String, dynamic>> reservas;

      if (config.sharedCapacity) {
        // Get all hours for this area
        final allHours = <String>{};
        for (final oh in config.operatingHours.where((oh) => oh.area == area)) {
          int current = oh.horaInicioInt * 60 + oh.minutoInicioInt;
          final end = oh.horaFinInt * 60 + oh.minutoFinInt;
          while (current <= end) {
            final h = current ~/ 60;
            final m = current % 60;
            allHours.add('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
            current += oh.intervaloMinutos;
          }
        }

        final fechaStr = fecha.toIso8601String().split('T')[0];
        final all = await SupabaseService.instance.getReservations();
        reservas = all.where((r) =>
          r['fecha'] == fechaStr &&
          allHours.contains(r['hora']) &&
          (r['estado'] == 'confirmada' || r['estado'] == 'en_mesa')
        ).toList();
      } else {
        reservas = await LocalReservationService.getActiveReservationsForSlot(
          fecha: fecha,
          hora: hora,
        );
      }

      int capacidadBloqueada = 0;

      for (final reserva in reservas) {
        final personasReserva = reserva['personas'] as int;

        final combinacionReserva = await findBestCombination(
          guests: personasReserva,
          area: area,
        );

        if (combinacionReserva != null) {
          capacidadBloqueada += combinacionReserva.maxCapacity;
        } else {
          capacidadBloqueada += personasReserva;
        }
      }

      final maxCapacity = await getRealCapacity(area: area);
      final capacidadDisponible = maxCapacity - capacidadBloqueada;

      final requiredCapacity = combination.maxCapacity;

      if (capacidadDisponible < requiredCapacity) {
        return {
          'valid': false,
          'error': 'Este horario tiene alta demanda para $personas personas',
          'showCross': true,
          'remaining': capacidadDisponible,
          'area': area,
        };
      }

      final porcentajeOcupacion = (capacidadBloqueada / maxCapacity) * 100;

      if (config.strictTableOptimization &&
          combination.wastedSeats == 1 && porcentajeOcupacion < 95.0) {
        return {
          'valid': false,
          'error': 'Este horario tiene alta demanda para $personas personas',
          'blocked': true,
          'showCross': true,
          'remaining': capacidadDisponible,
          'area': area,
        };
      }

      return {
        'valid': true,
        'combination': combination.toString(),
        'tables': combination.tables.map((t) => t.id).toList(),
        'totalTables': combination.totalTables,
        'remaining': capacidadDisponible - requiredCapacity,
        'area': area,
      };

    } catch (e) {
      return {
        'valid': false,
        'error': 'Error al verificar disponibilidad: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getRemainingCapacity({
    required DateTime fecha,
    required String hora,
  }) async {
    try {
      final config = AppConfig.instance;
      final area = _getAreaForTime(hora, fecha.weekday);
      final areaConfig = config.getArea(area);

      final reservas = await LocalReservationService.getActiveReservationsForSlot(
        fecha: fecha,
        hora: hora,
      );

      int capacidadBloqueada = 0;
      int personasReales = 0;

      for (final reserva in reservas) {
        final personasReserva = reserva['personas'] as int;
        personasReales += personasReserva;

        if (config.useTableSystem) {
          final combinacion = await findBestCombination(
            guests: personasReserva,
            area: area,
          );

          if (combinacion != null) {
            capacidadBloqueada += combinacion.maxCapacity;
          } else {
            capacidadBloqueada += personasReserva;
          }
        } else {
          capacidadBloqueada += personasReserva;
        }
      }

      final maxCapacityReal = config.useTableSystem
          ? await getRealCapacity(area: area)
          : (areaConfig?.capacidadReal ?? 0);

      final maxCapacityFrontend = areaConfig?.capacidadFrontend ?? 0;

      final remaining = maxCapacityReal - capacidadBloqueada;

      return {
        'area': area,
        'maxCapacity': maxCapacityFrontend,
        'maxCapacityReal': maxCapacityReal,
        'currentOccupancy': personasReales,
        'blockedCapacity': capacidadBloqueada,
        'remaining': remaining > 0 ? remaining : 0,
        'isFull': remaining <= 0,
        'showCross': remaining <= 0,
      };

    } catch (e) {
      return {
        'error': 'Error al calcular capacidad: $e',
      };
    }
  }

  static Future<List<Map<String, dynamic>>> getAvailableTimeSlots({
    required DateTime fecha,
  }) async {
    final config = AppConfig.instance;
    final List<Map<String, dynamic>> slots = [];
    final hoursForDay = config.getHoursForDay(fecha.weekday);

    for (final opHours in hoursForDay) {
      int currentMinutes = opHours.horaInicioInt * 60 + opHours.minutoInicioInt;
      final endMinutes = opHours.horaFinInt * 60 + opHours.minutoFinInt;

      while (currentMinutes <= endMinutes) {
        final h = currentMinutes ~/ 60;
        final m = currentMinutes % 60;
        final hora = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

        final capacity = await getRemainingCapacity(fecha: fecha, hora: hora);

        slots.add({
          'hora': hora,
          'area': opHours.area,
          'available': !(capacity['isFull'] ?? true),
          'remaining': capacity['remaining'] ?? 0,
          'showCross': capacity['showCross'] ?? false,
        });

        currentMinutes += opHours.intervaloMinutos;
      }
    }

    return slots;
  }

  static String _getAreaForTime(String hora, int weekday) {
    final config = AppConfig.instance;
    final hour = int.parse(hora.split(':')[0]);
    final minute = int.parse(hora.split(':')[1]);
    final totalMinutes = hour * 60 + minute;

    final hoursForDay = config.getHoursForDay(weekday);
    for (final oh in hoursForDay) {
      final startMin = oh.horaInicioInt * 60 + oh.minutoInicioInt;
      final endMin = oh.horaFinInt * 60 + oh.minutoFinInt;
      if (totalMinutes >= startMin && totalMinutes <= endMin) {
        return oh.area;
      }
    }

    return config.areas.isNotEmpty ? config.areas.first.nombre : 'principal';
  }

  static bool esDomingo(DateTime fecha) {
    return fecha.weekday == DateTime.sunday;
  }

  static int getHoraApertura(DateTime fecha) {
    final hoursForDay = AppConfig.instance.getHoursForDay(fecha.weekday);
    if (hoursForDay.isEmpty) return 9;
    return hoursForDay.map((h) => h.horaInicioInt).reduce((a, b) => a < b ? a : b);
  }

  static Future<Map<String, dynamic>> getCapacidadCompartida({
    required DateTime fecha,
    String? area,
  }) async {
    try {
      final config = AppConfig.instance;
      final targetArea = area ?? (config.areas.length > 1 ? config.areas.last.nombre : config.areas.first.nombre);

      final capacidadBase = await getRealCapacity(area: targetArea);

      final areaHours = config.operatingHours.where((oh) => oh.area == targetArea).toList();
      final allSlots = <String>[];
      for (final oh in areaHours) {
        int current = oh.horaInicioInt * 60 + oh.minutoInicioInt;
        final end = oh.horaFinInt * 60 + oh.minutoFinInt;
        while (current <= end) {
          final h = current ~/ 60;
          final m = current % 60;
          allSlots.add('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
          current += oh.intervaloMinutos;
        }
      }

      final fechaStr = fecha.toIso8601String().split('T')[0];
      final allReservations = await SupabaseService.instance.getReservations();
      final reservas = allReservations.where((r) =>
        r['fecha'] == fechaStr &&
        allSlots.contains(r['hora']) &&
        (r['estado'] == 'confirmada' || r['estado'] == 'en_mesa')
      ).toList();

      final Map<String, int> ocupacionPorHora = {};
      int ocupacionTotal = 0;

      for (final r in reservas) {
        final personas = r['personas'] as int;
        final hora = (r['hora'] as String).substring(0, 5);
        ocupacionPorHora[hora] = (ocupacionPorHora[hora] ?? 0) + personas;
        ocupacionTotal += personas;
      }

      final disponibleTotal = capacidadBase - ocupacionTotal;
      final disponibleReal = disponibleTotal > 0 ? disponibleTotal : 0;

      final result = <String, dynamic>{
        'capacidad_base': capacidadBase,
        'ocupacion_total': ocupacionTotal,
        'disponible_total': disponibleReal,
      };

      for (final slot in allSlots) {
        result['disponible_$slot'] = disponibleReal;
        result['ocupacion_$slot'] = ocupacionPorHora[slot] ?? 0;
      }

      return result;
    } catch (e) {
      return {
        'error': e.toString(),
        'capacidad_base': 0,
        'disponible_total': 0,
      };
    }
  }

  static Future<Map<String, dynamic>> getSugerenciaInteligente({
    required DateTime fecha,
    required String hora,
    required int personas,
  }) async {
    final config = AppConfig.instance;
    final area = _getAreaForTime(hora, fecha.weekday);

    if (!config.useTableSystem) {
      return {'mostrar': false};
    }

    final capacidad = await getCapacidadCompartida(fecha: fecha, area: area);
    final disponibleTotal = capacidad['disponible_total'] as int? ?? 0;

    if (disponibleTotal >= personas) {
      if (disponibleTotal > 0 && disponibleTotal < 8) {
        return {
          'mostrar': true,
          'tipo': 'urgencia',
          'titulo': 'Ultimas mesas disponibles',
          'mensaje': 'Este horario tiene alta demanda. Te recomendamos confirmar tu reserva ahora.',
          'accionPrimaria': null,
          'bloqueado': false,
          'color': 'dorado',
        };
      }
      return {'mostrar': false};
    }

    return {
      'mostrar': true,
      'tipo': 'contacto',
      'titulo': 'Contactanos para opciones especiales',
      'mensaje': 'Para $personas personas en esta fecha, escribinos por WhatsApp y te ayudamos a encontrar la mejor opcion.',
      'accionPrimaria': 'Abrir WhatsApp',
      'whatsapp': config.whatsappNumber,
      'accionSecundaria': 'Probar otra fecha',
      'bloqueado': true,
      'color': 'azul',
    };
  }

  static Future<Map<String, dynamic>> getMensajeSugerente({
    required DateTime fecha,
    required String hora,
    required int personas,
  }) async {
    return getSugerenciaInteligente(fecha: fecha, hora: hora, personas: personas);
  }

  static Future<Map<String, dynamic>> verificarDisponibilidadArea({
    required DateTime fecha,
    required String hora,
    required int personas,
    String? area,
  }) async {
    final config = AppConfig.instance;
    final targetArea = area ?? _getAreaForTime(hora, fecha.weekday);

    if (personas < config.minGuests) {
      return {
        'disponible': false,
        'razon': 'minimo',
        'mensaje': await getMensajeSugerente(fecha: fecha, hora: hora, personas: personas),
      };
    }

    final capacidad = await getCapacidadCompartida(fecha: fecha, area: targetArea);
    final disponible = capacidad['disponible_total'] as int? ?? 0;

    if (disponible < personas) {
      return {
        'disponible': false,
        'razon': 'sin_capacidad',
        'mensaje': await getMensajeSugerente(fecha: fecha, hora: hora, personas: personas),
      };
    }

    if (config.useTableSystem) {
      final combinacion = await findBestCombination(guests: personas, area: targetArea);
      if (combinacion == null) {
        return {
          'disponible': false,
          'razon': 'sin_combinacion',
          'mensaje': {
            'mostrar': true,
            'tipo': 'contacto',
            'titulo': 'Grupo especial',
            'mensaje': 'Para $personas personas contactanos por WhatsApp',
            'accion': 'Abrir WhatsApp',
            'whatsapp': config.whatsappNumber,
          },
        };
      }
    }

    return {
      'disponible': true,
      'mensaje': await getMensajeSugerente(fecha: fecha, hora: hora, personas: personas),
    };
  }
}
