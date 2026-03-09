import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static LocalStorageService? _instance;
  static LocalStorageService get instance => _instance!;
  static bool get isInitialized => _instance != null;

  late SharedPreferences _prefs;

  LocalStorageService._();

  static Future<void> initialize() async {
    _instance = LocalStorageService._();
    _instance!._prefs = await SharedPreferences.getInstance();
  }

  // Keys
  static const String _configKey = 'restaurant_config';
  static const String _areasKey = 'areas';
  static const String _tablesKey = 'tables';
  static const String _hoursKey = 'operating_hours';
  static const String _reservationsKey = 'reservations';
  static const String _blocksKey = 'blocks';
  static const String _adminPinKey = 'admin_pin';
  static const String _onboardingKey = 'onboarding_completed';
  static const String _tableBlocksKey = 'table_blocks';
  static const String _waitlistKey = 'waitlist';
  static const String _mapPositionsKey = 'map_positions';

  // Generic JSON read/write
  Map<String, String> getConfig() {
    final raw = _prefs.getString(_configKey);
    if (raw == null) return {};
    return Map<String, String>.from(jsonDecode(raw));
  }

  Future<void> saveConfig(Map<String, String> config) async {
    await _prefs.setString(_configKey, jsonEncode(config));
  }

  Future<void> setConfigValue(String key, String value) async {
    final config = getConfig();
    config[key] = value;
    await saveConfig(config);
  }

  String? getConfigValue(String key) {
    return getConfig()[key];
  }

  List<Map<String, dynamic>> getAreas() {
    final raw = _prefs.getString(_areasKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(
      (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  Future<void> saveAreas(List<Map<String, dynamic>> areas) async {
    await _prefs.setString(_areasKey, jsonEncode(areas));
  }

  List<Map<String, dynamic>> getTables() {
    final raw = _prefs.getString(_tablesKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(
      (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  Future<void> saveTables(List<Map<String, dynamic>> tables) async {
    await _prefs.setString(_tablesKey, jsonEncode(tables));
  }

  List<Map<String, dynamic>> getOperatingHours() {
    final raw = _prefs.getString(_hoursKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(
      (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  Future<void> saveOperatingHours(List<Map<String, dynamic>> hours) async {
    await _prefs.setString(_hoursKey, jsonEncode(hours));
  }

  // Reservations
  List<Map<String, dynamic>> getReservations() {
    final raw = _prefs.getString(_reservationsKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(
      (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  Future<void> saveReservations(List<Map<String, dynamic>> reservations) async {
    await _prefs.setString(_reservationsKey, jsonEncode(reservations));
  }

  // Blocks
  List<Map<String, dynamic>> getBlocks() {
    final raw = _prefs.getString(_blocksKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(
      (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  Future<void> saveBlocks(List<Map<String, dynamic>> blocks) async {
    await _prefs.setString(_blocksKey, jsonEncode(blocks));
  }

  // Table blocks (VIP)
  Map<String, bool> getTableBlocks() {
    final raw = _prefs.getString(_tableBlocksKey);
    if (raw == null) return {};
    return Map<String, bool>.from(jsonDecode(raw));
  }

  Future<void> saveTableBlocks(Map<String, bool> blocks) async {
    await _prefs.setString(_tableBlocksKey, jsonEncode(blocks));
  }

  // Waitlist
  List<Map<String, dynamic>> getWaitlist() {
    final raw = _prefs.getString(_waitlistKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(
      (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e)),
    );
  }

  Future<void> saveWaitlist(List<Map<String, dynamic>> waitlist) async {
    await _prefs.setString(_waitlistKey, jsonEncode(waitlist));
  }

  // Map positions (expanded table positions for the visual map)
  Map<String, Map<String, double>> getMapPositions() {
    final raw = _prefs.getString(_mapPositionsKey);
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((key, value) => MapEntry(
      key,
      Map<String, double>.from((value as Map).map((k, v) => MapEntry(k, (v as num).toDouble()))),
    ));
  }

  Future<void> saveMapPositions(Map<String, Map<String, double>> positions) async {
    await _prefs.setString(_mapPositionsKey, jsonEncode(positions));
  }

  // Admin PIN
  String getAdminPin() {
    return _prefs.getString(_adminPinKey) ?? '1234';
  }

  Future<void> setAdminPin(String pin) async {
    await _prefs.setString(_adminPinKey, pin);
  }

  // Onboarding
  bool get onboardingCompleted {
    return _prefs.getBool(_onboardingKey) ?? false;
  }

  Future<void> setOnboardingCompleted(bool value) async {
    await _prefs.setBool(_onboardingKey, value);
  }

  // Export all data as JSON
  Map<String, dynamic> exportAll() {
    return {
      'config': getConfig(),
      'areas': getAreas(),
      'tables': getTables(),
      'operating_hours': getOperatingHours(),
      'reservations': getReservations(),
      'blocks': getBlocks(),
      'table_blocks': getTableBlocks(),
      'waitlist': getWaitlist(),
      'onboarding_completed': onboardingCompleted,
    };
  }

  // Import from JSON
  Future<void> importAll(Map<String, dynamic> data) async {
    if (data['config'] != null) {
      await saveConfig(Map<String, String>.from(data['config']));
    }
    if (data['areas'] != null) {
      await saveAreas(List<Map<String, dynamic>>.from(
        (data['areas'] as List).map((e) => Map<String, dynamic>.from(e)),
      ));
    }
    if (data['tables'] != null) {
      await saveTables(List<Map<String, dynamic>>.from(
        (data['tables'] as List).map((e) => Map<String, dynamic>.from(e)),
      ));
    }
    if (data['operating_hours'] != null) {
      await saveOperatingHours(List<Map<String, dynamic>>.from(
        (data['operating_hours'] as List).map((e) => Map<String, dynamic>.from(e)),
      ));
    }
    if (data['reservations'] != null) {
      await saveReservations(List<Map<String, dynamic>>.from(
        (data['reservations'] as List).map((e) => Map<String, dynamic>.from(e)),
      ));
    }
    if (data['blocks'] != null) {
      await saveBlocks(List<Map<String, dynamic>>.from(
        (data['blocks'] as List).map((e) => Map<String, dynamic>.from(e)),
      ));
    }
    if (data['waitlist'] != null) {
      await saveWaitlist(List<Map<String, dynamic>>.from(
        (data['waitlist'] as List).map((e) => Map<String, dynamic>.from(e)),
      ));
    }
    if (data['onboarding_completed'] != null) {
      await setOnboardingCompleted(data['onboarding_completed'] as bool);
    }
  }

  // Seed default demo data
  Future<void> seedDefaultData() async {
    // Only seed if no config exists
    if (getConfig().isNotEmpty) return;

    await saveConfig({
      'nombre_restaurante': 'Mi Restaurante',
      'subtitulo': 'COCINA & BAR',
      'slogan': 'Una experiencia gastronómica única',
      'direccion': 'Av. Principal 123',
      'ciudad': 'Buenos Aires',
      'provincia': 'Buenos Aires',
      'pais': 'Argentina',
      'google_maps_query': 'Mi Restaurante Buenos Aires',
      'email_contacto': 'info@mirestaurante.com',
      'telefono_contacto': '1122334455',
      'whatsapp_numero': '1122334455',
      'codigo_pais_telefono': '54',
      'sitio_web': '',
      'logo_color_url': '',
      'logo_blanco_url': '',
      'fondo_url': '',
      'color_primario': '#194485',
      'color_secundario': '#154080',
      'color_terciario': '#1B427C',
      'color_acento': '#FF0000',
      'dia_cerrado': '1',
      'min_personas': '2',
      'max_personas': '15',
      'anticipo_almuerzo_horas': '2',
      'anticipo_regular_horas': '24',
      'minutos_liberacion_auto': '15',
      'dias_adelanto_maximo': '60',
      'usa_sistema_mesas': 'false',
      'usa_areas_multiples': 'false',
      'capacidad_compartida': 'false',
      'banner_activo': 'false',
      'banner_texto': 'Nos tomamos un descanso. Volvemos pronto.',
      'banner_fecha': '',
    });

    await saveAreas([
      {
        'id': 'area_1',
        'nombre': 'principal',
        'nombre_display': 'Salón Principal',
        'capacidad_real': 40,
        'capacidad_frontend': 35,
        'hora_inicio': '09:00',
        'hora_fin': '23:00',
        'activo': true,
      },
    ]);

    await saveTables([
      {
        'id': 'mesa_1',
        'nombre': 'Mesa 2p',
        'area': 'principal',
        'min_capacidad': 2,
        'max_capacidad': 2,
        'cantidad': 5,
        'es_vip': false,
        'bloqueable': false,
        'activo': true,
      },
      {
        'id': 'mesa_2',
        'nombre': 'Mesa 4p',
        'area': 'principal',
        'min_capacidad': 2,
        'max_capacidad': 4,
        'cantidad': 4,
        'es_vip': false,
        'bloqueable': false,
        'activo': true,
      },
      {
        'id': 'mesa_3',
        'nombre': 'Mesa 6p',
        'area': 'principal',
        'min_capacidad': 4,
        'max_capacidad': 6,
        'cantidad': 2,
        'es_vip': false,
        'bloqueable': false,
        'activo': true,
      },
    ]);

    // Operating hours: Martes a Domingo (closed Monday = dia_cerrado 1)
    final hours = <Map<String, dynamic>>[];
    int hourId = 1;
    for (int day = 0; day <= 6; day++) {
      if (day == 1) continue; // Lunes cerrado
      hours.add({
        'id': 'h_${hourId++}',
        'dia_semana': day,
        'area': 'principal',
        'hora_inicio': '12:00',
        'hora_fin': '15:00',
        'intervalo_minutos': 30,
        'activo': true,
      });
      hours.add({
        'id': 'h_${hourId++}',
        'dia_semana': day,
        'area': 'principal',
        'hora_inicio': '20:00',
        'hora_fin': '23:00',
        'intervalo_minutos': 30,
        'activo': true,
      });
    }
    await saveOperatingHours(hours);

    await setOnboardingCompleted(false);
  }
}
