import 'supabase_service.dart';

class WaitlistService {
  /// Agregar a la lista de espera.
  static Future<Map<String, dynamic>> addToWaitlist({
    required DateTime fecha,
    required String hora,
    required int personas,
    required String nombre,
    required String telefono,
    String? email,
    String? comentarios,
  }) async {
    final storage = SupabaseService.instance;
    final waitlist = await storage.getWaitlist();
    final id = 'wl_${DateTime.now().millisecondsSinceEpoch}';
    final fechaStr = fecha.toIso8601String().split('T')[0];

    final entry = {
      'id': id,
      'fecha': fechaStr,
      'hora': hora,
      'personas': personas,
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'comentarios': comentarios,
      'estado': 'esperando',
      'notificado': false,
      'created_at': DateTime.now().toIso8601String(),
    };

    waitlist.add(entry);
    await storage.saveWaitlist(waitlist);

    return {'success': true, 'data': entry};
  }

  /// Obtener waitlist para una fecha.
  static Future<List<Map<String, dynamic>>> getWaitlistForDate(DateTime fecha) async {
    final fechaStr = fecha.toIso8601String().split('T')[0];
    final waitlist = await SupabaseService.instance.getWaitlist();
    return waitlist
        .where((w) => w['fecha'] == fechaStr && w['estado'] == 'esperando')
        .toList()
      ..sort((a, b) => (a['created_at'] as String).compareTo(b['created_at'] as String));
  }

  /// Obtener el siguiente en la lista para un slot específico.
  static Future<Map<String, dynamic>?> getNextInLine({
    required DateTime fecha,
    required String hora,
    int? maxPersonas,
  }) async {
    final fechaStr = fecha.toIso8601String().split('T')[0];
    final waitlist = await SupabaseService.instance.getWaitlist();

    final matches = waitlist.where((w) =>
      w['fecha'] == fechaStr &&
      w['hora'] == hora &&
      w['estado'] == 'esperando'
    ).toList()
      ..sort((a, b) => (a['created_at'] as String).compareTo(b['created_at'] as String));

    if (matches.isEmpty) return null;

    if (maxPersonas != null) {
      try {
        return matches.firstWhere((w) => (w['personas'] as int) <= maxPersonas);
      } catch (_) {
        return null;
      }
    }

    return matches.first;
  }

  /// Buscar matches en waitlist para un slot que se liberó.
  static Future<List<Map<String, dynamic>>> findWaitlistMatches({
    required DateTime fecha,
    required String hora,
    int? availableCapacity,
  }) async {
    final fechaStr = fecha.toIso8601String().split('T')[0];
    final waitlist = await SupabaseService.instance.getWaitlist();

    var matches = waitlist.where((w) =>
      w['fecha'] == fechaStr &&
      w['hora'] == hora &&
      w['estado'] == 'esperando'
    ).toList()
      ..sort((a, b) => (a['created_at'] as String).compareTo(b['created_at'] as String));

    if (availableCapacity != null) {
      matches = matches.where((w) => (w['personas'] as int) <= availableCapacity).toList();
    }

    return matches;
  }

  /// Marcar como notificado.
  static Future<bool> markNotified(String waitlistId) async {
    final storage = SupabaseService.instance;
    final waitlist = await storage.getWaitlist();
    final index = waitlist.indexWhere((w) => w['id'] == waitlistId);
    if (index == -1) return false;

    waitlist[index]['notificado'] = true;
    waitlist[index]['notificado_at'] = DateTime.now().toIso8601String();
    await storage.saveWaitlist(waitlist);
    return true;
  }

  /// Remover de la waitlist.
  static Future<bool> removeFromWaitlist(String waitlistId) async {
    final storage = SupabaseService.instance;
    final waitlist = await storage.getWaitlist();
    final index = waitlist.indexWhere((w) => w['id'] == waitlistId);
    if (index == -1) return false;

    waitlist[index]['estado'] = 'removido';
    await storage.saveWaitlist(waitlist);
    return true;
  }

  /// Obtener toda la waitlist activa.
  static Future<List<Map<String, dynamic>>> getAllActive() async {
    final waitlist = await SupabaseService.instance.getWaitlist();
    return waitlist
        .where((w) => w['estado'] == 'esperando')
        .toList()
      ..sort((a, b) => (a['created_at'] as String).compareTo(b['created_at'] as String));
  }
}
