// Re-export from local implementation for backwards compatibility
export 'local_block_service.dart' show BlockStatus;
import 'local_block_service.dart';

class BlockService {
  static Future<BlockStatus> getStatus(DateTime date) {
    return LocalBlockService.getStatus(date);
  }

  static Future<bool> blockDay(DateTime date, {String? reason, String? createdBy}) {
    return LocalBlockService.blockDay(date, reason: reason, createdBy: createdBy);
  }

  static Future<bool> unblockDay(DateTime date) {
    return LocalBlockService.unblockDay(date);
  }

  static Future<bool> blockHour(DateTime date, String hour, {String? reason, String? createdBy}) {
    return LocalBlockService.blockHour(date, hour, reason: reason, createdBy: createdBy);
  }

  static Future<bool> unblockHour(DateTime date, String hour) {
    return LocalBlockService.unblockHour(date, hour);
  }

  static Future<bool> isSlotBlocked(DateTime date, String hour) {
    return LocalBlockService.isSlotBlocked(date, hour);
  }

  static Future<Set<DateTime>> getBlockedDaysInRange(DateTime start, DateTime end) {
    return LocalBlockService.getBlockedDaysInRange(start, end);
  }
}
