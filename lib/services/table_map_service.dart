import 'dart:ui';

import '../config/app_config.dart';
import '../models/table_definition.dart';
import 'local_reservation_service.dart';
import 'supabase_service.dart';

enum TableStatus { free, reserved, occupied, vip, blocked }

/// Info de asignación: qué reserva tiene cada mesa.
class TableAssignment {
  final TableStatus status;
  final Map<String, dynamic>? reservation; // null si está libre/bloqueada
  final int wastedSeats; // sillas que sobran (0 = perfecto)
  final List<String>? combinedWith; // nombres de las otras mesas juntadas, null si es mesa sola

  const TableAssignment({
    required this.status,
    this.reservation,
    this.wastedSeats = 0,
    this.combinedWith,
  });

  bool get isCombined => combinedWith != null && combinedWith!.isNotEmpty;
}

class TableMapService {
  /// Obtiene el estado de cada mesa expandida + asignación inteligente.
  ///
  /// Algoritmo "Smart Host":
  /// 1. Separa mesas bloqueadas/VIP bloqueadas
  /// 2. Ordena reservas de mayor a menor personas (las difíciles primero)
  /// 3. Para cada reserva busca la mesa disponible más chica que le entre (best-fit)
  /// 4. Si no entra en una sola mesa, intenta combinar mesas adyacentes del mismo tipo
  /// 5. Las mesas que sobran quedan libres
  static Future<Map<String, TableAssignment>> getSmartAssignments(
      DateTime fecha, String hora) async {
    final config = AppConfig.instance;
    final reservations = await LocalReservationService.getActiveReservationsForSlot(
      fecha: fecha,
      hora: hora,
    );
    final tableBlocks = await SupabaseService.instance.getTableBlocks();
    final expanded = await expandTablesForMap(config.tables);

    final assignments = <String, TableAssignment>{};
    final availableTables = <TableDefinition>[]; // mesas disponibles para asignar

    // Paso 1: marcar bloqueadas y VIP bloqueadas, separar disponibles
    for (final table in expanded) {
      if (!table.activo) continue;

      final originalId = table.id.replaceAll(RegExp(r'_\d+$'), '');

      if (tableBlocks[originalId] == true) {
        assignments[table.id] = const TableAssignment(status: TableStatus.blocked);
      } else if (table.esVip && table.bloqueable) {
        assignments[table.id] = const TableAssignment(status: TableStatus.vip);
      } else {
        availableTables.add(table);
      }
    }

    // Paso 2: separar reservas por área, ordenar por personas desc (las difíciles primero)
    final occupiedReservations = reservations
        .where((r) => r['estado'] == 'en_mesa')
        .toList()
      ..sort((a, b) => (b['personas'] as int? ?? 2).compareTo(a['personas'] as int? ?? 2));

    final pendingReservations = reservations
        .where((r) => r['estado'] == 'confirmada' || r['estado'] == 'pendiente_confirmacion')
        .toList()
      ..sort((a, b) => (b['personas'] as int? ?? 2).compareTo(a['personas'] as int? ?? 2));

    // Pool de mesas libres por área, ordenadas por capacidad asc (para best-fit)
    final areaPool = <String, List<TableDefinition>>{};
    for (final t in availableTables) {
      areaPool.putIfAbsent(t.area, () => []).add(t);
    }
    for (final list in areaPool.values) {
      list.sort((a, b) => a.maxCapacidad.compareTo(b.maxCapacidad));
    }

    // Paso 3: asignar — primero las "en_mesa" (ocupadas), después las reservadas
    //
    // Lógica inteligente:
    // - Si entran en 1 mesa → usa la más chica que alcance (best-fit)
    // - Si NO entran en ninguna mesa sola → combina mesas (junta 2 o más)
    //   Ej: 5 personas, mesas de 4 → junta 2 mesas de 4 (8 sillas, 3 libres)
    void assignReservation(Map<String, dynamic> res, TableStatus status) {
      final area = res['area'] as String? ?? '';
      final personas = res['personas'] as int? ?? 2;
      final pool = areaPool[area];
      if (pool == null || pool.isEmpty) return;

      // Intentar best-fit en una sola mesa
      TableDefinition? bestFit;
      for (final mesa in pool) {
        if (mesa.maxCapacidad >= personas) {
          bestFit = mesa;
          break; // ordenadas asc, la primera que entra es la mejor
        }
      }

      if (bestFit != null) {
        // Entra en 1 mesa sola
        pool.remove(bestFit);
        final wasted = bestFit.maxCapacidad - personas;
        assignments[bestFit.id] = TableAssignment(
          status: status,
          reservation: res,
          wastedSeats: wasted,
        );
        return;
      }

      // No entra en ninguna mesa sola → combinar mesas
      // Estrategia: ir sumando mesas de mayor a menor hasta cubrir las personas
      final poolDesc = List<TableDefinition>.from(pool)
        ..sort((a, b) => b.maxCapacidad.compareTo(a.maxCapacidad));

      int acumulado = 0;
      final mesasUsadas = <TableDefinition>[];

      for (final mesa in poolDesc) {
        mesasUsadas.add(mesa);
        acumulado += mesa.maxCapacidad;
        if (acumulado >= personas) break;
      }

      if (mesasUsadas.isEmpty) return;

      // Asignar todas las mesas combinadas a esta reserva
      final totalCapacidad = acumulado;
      final wasted = totalCapacidad - personas;
      for (final mesa in mesasUsadas) {
        pool.remove(mesa);
        assignments[mesa.id] = TableAssignment(
          status: status,
          reservation: res,
          wastedSeats: wasted, // el desperdicio total se muestra en cada mesa del grupo
          combinedWith: mesasUsadas.length > 1
              ? mesasUsadas.where((m) => m.id != mesa.id).map((m) => m.nombre).toList()
              : null,
        );
      }
    }

    for (final res in occupiedReservations) {
      assignReservation(res, TableStatus.occupied);
    }
    for (final res in pendingReservations) {
      assignReservation(res, TableStatus.reserved);
    }

    // Paso 4: las que quedan son libres
    for (final pool in areaPool.values) {
      for (final mesa in pool) {
        assignments[mesa.id] = TableAssignment(
          status: mesa.esVip ? TableStatus.vip : TableStatus.free,
        );
      }
    }

    return assignments;
  }

  /// Versión simplificada que devuelve solo el status (para compatibilidad)
  static Future<Map<String, TableStatus>> getTableStatuses(
      DateTime fecha, String hora) async {
    final assignments = await getSmartAssignments(fecha, hora);
    return assignments.map((id, a) => MapEntry(id, a.status));
  }

  /// Expande las TableDefinition según `cantidad` para el mapa.
  /// Cada mesa física obtiene un ID único y posición propia.
  /// Las posiciones guardadas se leen desde storage; las nuevas se disponen automáticamente.
  static Future<List<TableDefinition>> expandTablesForMap(List<TableDefinition> tables) async {
    final storage = SupabaseService.instance;
    final savedPositions = await storage.getMapPositions(); // Map<String, Map<String, double>>
    final expanded = <TableDefinition>[];

    for (final table in tables) {
      for (int i = 0; i < table.cantidad; i++) {
        final mapId = '${table.id}_$i';
        final saved = savedPositions[mapId];
        expanded.add(TableDefinition(
          id: mapId,
          nombre: table.cantidad > 1 ? '${table.nombre} #${i + 1}' : table.nombre,
          area: table.area,
          minCapacidad: table.minCapacidad,
          maxCapacidad: table.maxCapacidad,
          cantidad: 1,
          esVip: table.esVip,
          bloqueable: table.bloqueable,
          activo: table.activo,
          posX: saved?['posX'] ?? (20.0 + (i % 8) * 110),
          posY: saved?['posY'] ?? (20.0 + (i ~/ 8) * 110),
          width: table.width,
          height: table.height,
          shape: table.shape,
        ));
      }
    }
    return expanded;
  }

  /// Guarda las posiciones de las mesas expandidas del mapa.
  static Future<void> saveTablePositions(List<TableDefinition> tables) async {
    final storage = SupabaseService.instance;
    final positions = <String, Map<String, double>>{};
    for (final t in tables) {
      positions[t.id] = {'posX': t.posX, 'posY': t.posY};
    }
    await storage.saveMapPositions(positions);
  }

  /// Color para cada estado.
  static Color statusColor(TableStatus status) {
    switch (status) {
      case TableStatus.free:
        return const Color(0xFF4CAF50); // verde
      case TableStatus.reserved:
        return const Color(0xFFFFC107); // amarillo
      case TableStatus.occupied:
        return const Color(0xFFF44336); // rojo
      case TableStatus.vip:
        return const Color(0xFFFFD700); // dorado
      case TableStatus.blocked:
        return const Color(0xFF9E9E9E); // gris
    }
  }

  /// Label para cada estado.
  static String statusLabel(TableStatus status) {
    switch (status) {
      case TableStatus.free: return 'Libre';
      case TableStatus.reserved: return 'Reservada';
      case TableStatus.occupied: return 'Ocupada';
      case TableStatus.vip: return 'VIP';
      case TableStatus.blocked: return 'Bloqueada';
    }
  }
}
