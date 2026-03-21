import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio centralizado para leer/escribir datos en Supabase.
/// Reemplaza a LocalStorageService.
/// Todos los métodos filtran por tenant_id automáticamente.
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance!;
  static bool get isInitialized => _instance != null;

  final SupabaseClient _client;
  String _tenantId = '';

  SupabaseService._(this._client);

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://gqgxxbiulijhvevmygto.supabase.co',
      // Usar la anon key (JWT público), no la publishable ni la service_role
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
          '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdxZ3h4Yml1bGlqaHZldm15Z3RvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE5Njg3NDIsImV4cCI6MjA4NzU0NDc0Mn0'
          '.FEGy0n17MtVlSSFJ-BBDmDeHFIQNmiaguMv8UGAGPUM',
    );
    _instance = SupabaseService._(Supabase.instance.client);
  }

  SupabaseClient get client => _client;
  String get tenantId => _tenantId;
  void setTenantId(String id) => _tenantId = id;

  /// Obtiene el tenant_id del usuario logueado
  Future<String?> getTenantIdForCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    final result = await _client
        .from('tenants')
        .select('id')
        .eq('admin_user_id', user.id)
        .maybeSingle();
    return result?['id'] as String?;
  }

  // ═══════════════════════════════════════════════════
  // CONFIG (tenants)
  // ═══════════════════════════════════════════════════

  Future<Map<String, String>> getConfig() async {
    final row = await _client
        .from('tenants')
        .select()
        .eq('id', _tenantId)
        .maybeSingle();
    if (row == null) return {};

    final config = <String, String>{};
    row.forEach((key, value) {
      if (value != null &&
          key != 'created_at' &&
          key != 'updated_at' &&
          key != 'admin_user_id') {
        config[key] = value.toString();
      }
    });
    return config;
  }

  Future<void> saveConfig(Map<String, String> config) async {
    final row = <String, dynamic>{};
    for (final entry in config.entries) {
      final key = entry.key;
      final val = entry.value;

      if (val == 'true' || val == 'false') {
        row[key] = val == 'true';
      } else if (_intFields.contains(key)) {
        row[key] = int.tryParse(val) ?? 0;
      } else {
        row[key] = val.isEmpty ? null : val;
      }
    }

    await _client.from('tenants').update(row).eq('id', _tenantId);
  }

  /// Lee un valor individual del config (de la tabla tenants)
  Future<String?> getConfigValue(String key) async {
    final config = await getConfig();
    return config[key];
  }

  /// Guarda un valor individual en el config
  Future<void> setConfigValue(String key, String value) async {
    await saveConfig({key: value});
  }

  static const _intFields = {
    'dia_cerrado', 'min_personas', 'max_personas',
    'anticipo_almuerzo_horas', 'anticipo_regular_horas',
    'minutos_liberacion_auto', 'dias_adelanto_maximo',
    'ventana_confirmacion_horas', 'recordatorio_horas_antes',
    'subscription_due_day',
  };

  // ═══════════════════════════════════════════════════
  // AREAS
  // ═══════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getAreas() async {
    final result = await _client
        .from('areas')
        .select()
        .eq('tenant_id', _tenantId);
    return _stripTenantId(result);
  }

  Future<void> saveAreas(List<Map<String, dynamic>> areas) async {
    await _client.from('areas').delete().eq('tenant_id', _tenantId);
    if (areas.isNotEmpty) {
      final rows = areas.map((a) => {...a, 'tenant_id': _tenantId}).toList();
      await _client.from('areas').insert(rows);
    }
  }

  // ═══════════════════════════════════════════════════
  // MESAS
  // ═══════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getTables() async {
    final result = await _client
        .from('tables_def')
        .select()
        .eq('tenant_id', _tenantId);
    return _stripTenantId(result);
  }

  Future<void> saveTables(List<Map<String, dynamic>> tables) async {
    await _client.from('tables_def').delete().eq('tenant_id', _tenantId);
    if (tables.isNotEmpty) {
      final rows = tables.map((t) => {...t, 'tenant_id': _tenantId}).toList();
      await _client.from('tables_def').insert(rows);
    }
  }

  // ═══════════════════════════════════════════════════
  // HORARIOS
  // ═══════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getOperatingHours() async {
    final result = await _client
        .from('operating_hours')
        .select()
        .eq('tenant_id', _tenantId);
    return _stripTenantId(result);
  }

  Future<void> saveOperatingHours(List<Map<String, dynamic>> hours) async {
    await _client.from('operating_hours').delete().eq('tenant_id', _tenantId);
    if (hours.isNotEmpty) {
      final rows = hours.map((h) => {...h, 'tenant_id': _tenantId}).toList();
      await _client.from('operating_hours').insert(rows);
    }
  }

  // ═══════════════════════════════════════════════════
  // RESERVAS
  // ═══════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getReservations() async {
    final result = await _client
        .from('reservations')
        .select()
        .eq('tenant_id', _tenantId);
    return _stripTenantId(result);
  }

  Future<void> saveReservations(List<Map<String, dynamic>> reservations) async {
    await _client.from('reservations').delete().eq('tenant_id', _tenantId);
    if (reservations.isNotEmpty) {
      final rows = reservations.map((r) => {...r, 'tenant_id': _tenantId}).toList();
      await _client.from('reservations').insert(rows);
    }
  }

  Future<void> insertReservation(Map<String, dynamic> reserva) async {
    await _client
        .from('reservations')
        .insert({...reserva, 'tenant_id': _tenantId});
  }

  Future<void> updateReservation(String id, Map<String, dynamic> updates) async {
    await _client
        .from('reservations')
        .update(updates)
        .eq('tenant_id', _tenantId)
        .eq('id', id);
  }

  Future<List<Map<String, dynamic>>> getReservationsForDate(String fecha) async {
    final result = await _client
        .from('reservations')
        .select()
        .eq('tenant_id', _tenantId)
        .eq('fecha', fecha);
    return _stripTenantId(result);
  }

  Future<Map<String, dynamic>?> getReservationByCode(String code) async {
    final result = await _client
        .from('reservations')
        .select()
        .eq('tenant_id', _tenantId)
        .eq('codigo_confirmacion', code)
        .maybeSingle();
    if (result == null) return null;
    return _stripTenantIdSingle(result);
  }

  // ═══════════════════════════════════════════════════
  // WAITLIST
  // ═══════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getWaitlist() async {
    final result = await _client
        .from('waitlist')
        .select()
        .eq('tenant_id', _tenantId);
    return _stripTenantId(result);
  }

  Future<void> saveWaitlist(List<Map<String, dynamic>> waitlist) async {
    await _client.from('waitlist').delete().eq('tenant_id', _tenantId);
    if (waitlist.isNotEmpty) {
      final rows = waitlist.map((w) => {...w, 'tenant_id': _tenantId}).toList();
      await _client.from('waitlist').insert(rows);
    }
  }

  Future<void> insertWaitlistEntry(Map<String, dynamic> entry) async {
    await _client
        .from('waitlist')
        .insert({...entry, 'tenant_id': _tenantId});
  }

  Future<void> updateWaitlistEntry(String id, Map<String, dynamic> updates) async {
    await _client
        .from('waitlist')
        .update(updates)
        .eq('tenant_id', _tenantId)
        .eq('id', id);
  }

  // ═══════════════════════════════════════════════════
  // BLOQUEOS
  // ═══════════════════════════════════════════════════

  Future<List<Map<String, dynamic>>> getBlocks() async {
    final result = await _client
        .from('blocks')
        .select()
        .eq('tenant_id', _tenantId);
    return _stripTenantId(result);
  }

  Future<void> saveBlocks(List<Map<String, dynamic>> blocks) async {
    await _client.from('blocks').delete().eq('tenant_id', _tenantId);
    if (blocks.isNotEmpty) {
      final rows = blocks.map((b) {
        final row = Map<String, dynamic>.from(b);
        row['tenant_id'] = _tenantId;
        row.remove('id');
        return row;
      }).toList();
      await _client.from('blocks').insert(rows);
    }
  }

  // ═══════════════════════════════════════════════════
  // TABLE BLOCKS
  // ═══════════════════════════════════════════════════

  Future<Map<String, bool>> getTableBlocks() async {
    final result = await _client
        .from('table_blocks')
        .select()
        .eq('tenant_id', _tenantId);
    final map = <String, bool>{};
    for (final row in result) {
      map[row['table_id'] as String] = row['bloqueada'] as bool? ?? false;
    }
    return map;
  }

  Future<void> saveTableBlocks(Map<String, bool> blocks) async {
    await _client.from('table_blocks').delete().eq('tenant_id', _tenantId);
    if (blocks.isNotEmpty) {
      final rows = blocks.entries.map((e) => {
        'tenant_id': _tenantId,
        'table_id': e.key,
        'bloqueada': e.value,
      }).toList();
      await _client.from('table_blocks').insert(rows);
    }
  }

  // ═══════════════════════════════════════════════════
  // MAP POSITIONS
  // ═══════════════════════════════════════════════════

  Future<Map<String, Map<String, double>>> getMapPositions() async {
    final result = await _client
        .from('map_positions')
        .select()
        .eq('tenant_id', _tenantId);
    final positions = <String, Map<String, double>>{};
    for (final row in result) {
      positions[row['map_id'] as String] = {
        'posX': (row['pos_x'] as num).toDouble(),
        'posY': (row['pos_y'] as num).toDouble(),
      };
    }
    return positions;
  }

  Future<void> saveMapPositions(Map<String, Map<String, double>> positions) async {
    await _client.from('map_positions').delete().eq('tenant_id', _tenantId);
    if (positions.isNotEmpty) {
      final rows = positions.entries.map((e) => {
        'tenant_id': _tenantId,
        'map_id': e.key,
        'pos_x': e.value['posX'] ?? 0,
        'pos_y': e.value['posY'] ?? 0,
      }).toList();
      await _client.from('map_positions').insert(rows);
    }
  }

  // ═══════════════════════════════════════════════════
  // STORAGE (imágenes)
  // ═══════════════════════════════════════════════════

  Future<String?> uploadImage(String fileName, Uint8List bytes) async {
    final path = '$_tenantId/$fileName';
    await _client.storage.from('restaurant-images').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: true),
    );
    // Agregar cache buster para que el browser no muestre la imagen vieja
    final baseUrl = _client.storage.from('restaurant-images').getPublicUrl(path);
    return '$baseUrl?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  // ═══════════════════════════════════════════════════
  // AUTH
  // ═══════════════════════════════════════════════════

  bool get isLoggedIn => _client.auth.currentUser != null;
  User? get currentUser => _client.auth.currentUser;

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // ═══════════════════════════════════════════════════
  // ONBOARDING
  // ═══════════════════════════════════════════════════

  Future<bool> getOnboardingCompleted() async {
    final row = await _client
        .from('tenants')
        .select('onboarding_completed')
        .eq('id', _tenantId)
        .maybeSingle();
    return row?['onboarding_completed'] as bool? ?? false;
  }

  Future<void> setOnboardingCompleted(bool value) async {
    await _client
        .from('tenants')
        .update({'onboarding_completed': value})
        .eq('id', _tenantId);
  }

  // ═══════════════════════════════════════════════════
  // TRIAL
  // ═══════════════════════════════════════════════════

  /// Extiende el trial 5 días más por completar onboarding (total 20 días).
  /// Solo se puede usar una vez.
  Future<bool> extendTrialForOnboarding() async {
    // Leer trial_end_date actual y sumarle 5 días
    final row = await _client
        .from('tenants')
        .select('trial_end_date, trial_extended')
        .eq('id', _tenantId)
        .maybeSingle();
    if (row == null) return false;
    if (row['trial_extended'] == true) return false; // ya se extendió

    final currentEnd = DateTime.tryParse(row['trial_end_date'] ?? '') ?? DateTime.now();
    final newEnd = currentEnd.add(const Duration(days: 5)).toIso8601String();

    await _client.from('tenants').update({
      'trial_end_date': newEnd,
      'trial_extended': true,
    }).eq('id', _tenantId);
    return true;
  }

  // ═══════════════════════════════════════════════════
  // EXPORT
  // ═══════════════════════════════════════════════════

  Future<Map<String, dynamic>> exportAll() async {
    return {
      'config': await getConfig(),
      'areas': await getAreas(),
      'tables': await getTables(),
      'operating_hours': await getOperatingHours(),
      'reservations': await getReservations(),
      'blocks': await getBlocks(),
      'table_blocks': await getTableBlocks(),
      'waitlist': await getWaitlist(),
      'onboarding_completed': await getOnboardingCompleted(),
    };
  }

  // ═══════════════════════════════════════════════════
  // SUPER ADMIN (crear restaurantes)
  // ═══════════════════════════════════════════════════

  /// Crea un usuario auth via Edge Function de Supabase.
  /// El SRK queda en el servidor, nunca se expone al cliente.
  Future<String> createAuthUser(String email, String password) async {
    final response = await _client.functions.invoke(
      'create-auth-user',
      body: {
        'email': email,
        'password': password,
        'pin': '991474',
      },
    );

    if (response.status != 200) {
      final error = response.data?['error'] ?? 'Error al crear usuario';
      throw Exception(error);
    }

    final userId = response.data?['id'] as String?;
    if (userId == null) {
      throw Exception('No se pudo obtener el ID del usuario creado');
    }
    return userId;
  }

  /// Crea un nuevo tenant (restaurante) con su usuario admin.
  /// Si falla el INSERT, elimina el usuario auth para no dejar huérfanos.
  Future<void> createRestaurant({
    required String tenantId,
    required String restaurantName,
    required String adminUserId,
    String? adminEmail,
  }) async {
    try {
      await _client.from('tenants').insert({
        'id': tenantId,
        'nombre_restaurante': restaurantName,
        'admin_user_id': adminUserId,
        if (adminEmail != null) 'email_contacto': adminEmail,
      });
    } catch (e) {
      // Limpiar usuario auth huérfano
      try {
        await _client.rpc('delete_auth_user', params: {'p_user_id': adminUserId});
      } catch (_) {}
      rethrow;
    }
  }

  /// Lista todos los tenants (solo para super admin).
  Future<List<Map<String, dynamic>>> getAllTenants() async {
    final result = await _client
        .from('tenants')
        .select('id, nombre_restaurante, admin_user_id, onboarding_completed, email_contacto, trial_end_date, trial_extended, created_at')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(result);
  }

  /// Elimina un tenant y todos sus datos (cascade).
  Future<void> deleteRestaurant(String tenantId) async {
    await _client.from('tenants').delete().eq('id', tenantId);
  }

  // ═══════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════

  List<Map<String, dynamic>> _stripTenantId(List<Map<String, dynamic>> rows) {
    return rows.map((r) {
      final m = Map<String, dynamic>.from(r);
      m.remove('tenant_id');
      return m;
    }).toList();
  }

  Map<String, dynamic> _stripTenantIdSingle(Map<String, dynamic> row) {
    final m = Map<String, dynamic>.from(row);
    m.remove('tenant_id');
    return m;
  }
}
