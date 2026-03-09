import 'supabase_service.dart';

class BlockStatus {
  final bool isDayBlocked;
  final Set<String> blockedHours;
  final String? reason;

  const BlockStatus({
    required this.isDayBlocked,
    required this.blockedHours,
    this.reason,
  });
}

class LocalBlockService {
  static const Duration _cacheDuration = Duration(seconds: 20);
  static final Map<String, BlockStatus> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};

  static String _toDateStr(DateTime date) => date.toIso8601String().split('T')[0];

  static void _invalidateCache(String dateKey) {
    _cache.remove(dateKey);
    _cacheTime.remove(dateKey);
  }

  /// Obtiene bloqueos para una fecha
  static Future<BlockStatus> getStatus(DateTime date) async {
    final dateKey = _toDateStr(date);
    final now = DateTime.now();

    final cached = _cache[dateKey];
    final cachedAt = _cacheTime[dateKey];
    if (cached != null && cachedAt != null && now.difference(cachedAt) < _cacheDuration) {
      return cached;
    }

    final blocks = await SupabaseService.instance.getBlocks();
    bool dayBlocked = false;
    final Set<String> hours = {};
    String? reason;

    for (final row in blocks) {
      if (row['fecha'] != dateKey) continue;

      final isDayBlock = row['bloquea_dia'] == true;
      final hora = row['hora'];
      final motivo = row['motivo'] as String?;

      if (isDayBlock) {
        dayBlocked = true;
        reason ??= motivo;
      } else if (hora != null) {
        hours.add(hora.toString().substring(0, 5));
        reason ??= motivo;
      }
    }

    final status = BlockStatus(
      isDayBlocked: dayBlocked,
      blockedHours: hours,
      reason: reason,
    );

    _cache[dateKey] = status;
    _cacheTime[dateKey] = now;
    return status;
  }

  static String _normalizeHour(String hour) {
    if (hour.contains(':')) {
      final parts = hour.split(':');
      final h = parts.first.padLeft(2, '0');
      final m = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
      return '$h:$m';
    }
    if (hour.length <= 2) {
      return '${hour.padLeft(2, '0')}:00';
    }
    return hour;
  }

  /// Bloquea un día completo
  static Future<bool> blockDay(DateTime date, {String? reason, String? createdBy}) async {
    final dateKey = _toDateStr(date);
    try {
      final storage = SupabaseService.instance;
      final blocks = await storage.getBlocks();
      blocks.removeWhere((b) => b['fecha'] == dateKey);
      blocks.add({
        'fecha': dateKey,
        'bloquea_dia': true,
        'hora': null,
        'motivo': reason,
        'created_by': createdBy,
      });
      await storage.saveBlocks(blocks);
      _invalidateCache(dateKey);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> unblockDay(DateTime date) async {
    final dateKey = _toDateStr(date);
    try {
      final storage = SupabaseService.instance;
      final blocks = await storage.getBlocks();
      blocks.removeWhere((b) => b['fecha'] == dateKey && b['bloquea_dia'] == true);
      await storage.saveBlocks(blocks);
      _invalidateCache(dateKey);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> blockHour(DateTime date, String hour, {String? reason, String? createdBy}) async {
    final dateKey = _toDateStr(date);
    final normalizedHour = _normalizeHour(hour);
    try {
      final storage = SupabaseService.instance;
      final blocks = await storage.getBlocks();
      // Remove day block and existing hour block
      blocks.removeWhere((b) => b['fecha'] == dateKey && b['bloquea_dia'] == true);
      blocks.removeWhere((b) => b['fecha'] == dateKey && b['hora'] == normalizedHour);
      blocks.add({
        'fecha': dateKey,
        'hora': normalizedHour,
        'bloquea_dia': false,
        'motivo': reason,
        'created_by': createdBy,
      });
      await storage.saveBlocks(blocks);
      _invalidateCache(dateKey);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> unblockHour(DateTime date, String hour) async {
    final dateKey = _toDateStr(date);
    final normalizedHour = _normalizeHour(hour);
    try {
      final storage = SupabaseService.instance;
      final blocks = await storage.getBlocks();
      blocks.removeWhere((b) => b['fecha'] == dateKey && b['hora'] == normalizedHour);
      await storage.saveBlocks(blocks);
      _invalidateCache(dateKey);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isSlotBlocked(DateTime date, String hour) async {
    final status = await getStatus(date);
    if (status.isDayBlocked) return true;
    return status.blockedHours.contains(_normalizeHour(hour));
  }

  static Future<Set<DateTime>> getBlockedDaysInRange(DateTime start, DateTime end) async {
    final blocks = await SupabaseService.instance.getBlocks();
    final startStr = _toDateStr(start);
    final endStr = _toDateStr(end);
    final Set<DateTime> result = {};

    for (final row in blocks) {
      if (row['bloquea_dia'] != true) continue;
      final fechaStr = row['fecha']?.toString();
      if (fechaStr != null && fechaStr.compareTo(startStr) >= 0 && fechaStr.compareTo(endStr) <= 0) {
        result.add(DateTime.parse(fechaStr));
      }
    }
    return result;
  }
}
