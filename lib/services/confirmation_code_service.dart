import 'dart:math';
import 'local_reservation_service.dart';

class ConfirmationCodeService {
  static const String _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const int _codeLength = 6;
  static final Random _random = Random();
  static final Set<String> _recentCodes = {};

  static Future<String> generateUniqueCode() async {
    String code;
    bool isUnique = false;
    int attempts = 0;
    const maxAttempts = 50;

    do {
      code = _generateCode();
      attempts++;

      if (attempts > maxAttempts) {
        throw Exception('No se pudo generar un codigo unico despues de $maxAttempts intentos');
      }

      if (_recentCodes.contains(code)) {
        continue;
      }

      isUnique = !(await LocalReservationService.isCodeUsed(code));

    } while (!isUnique);

    _recentCodes.add(code);
    if (_recentCodes.length > 1000) {
      _recentCodes.clear();
    }

    return code;
  }

  static String _generateCode() {
    return String.fromCharCodes(
      Iterable.generate(
        _codeLength,
        (_) => _chars.codeUnitAt(_random.nextInt(_chars.length))
      )
    );
  }

  static bool isValidCodeFormat(String code) {
    if (code.length != _codeLength) return false;

    for (int i = 0; i < code.length; i++) {
      if (!_chars.contains(code[i])) return false;
    }

    return true;
  }

  static Future<Map<String, dynamic>?> findReservationByCode(String code) async {
    if (!isValidCodeFormat(code)) {
      return null;
    }
    return LocalReservationService.findReservationByCode(code.toUpperCase());
  }

  static void markCodeAsUsed(String code) {
    _recentCodes.add(code.toUpperCase());
  }

  static void clearRecentCodesCache() {
    _recentCodes.clear();
  }

  static Map<String, dynamic> getStatistics() {
    return {
      'recent_codes_count': _recentCodes.length,
      'max_possible_codes': pow(_chars.length, _codeLength),
      'character_set': _chars,
      'code_length': _codeLength,
    };
  }

  static Future<List<String>> generateCodesBatch(int count) async {
    if (count <= 0 || count > 100) {
      throw ArgumentError('El lote debe ser entre 1 y 100 codigos');
    }

    List<String> codes = [];

    for (int i = 0; i < count; i++) {
      try {
        final code = await generateUniqueCode();
        codes.add(code);
      } catch (e) {
        break;
      }
    }

    return codes;
  }
}
