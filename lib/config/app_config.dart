import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/area_config.dart';
import '../models/table_definition.dart';
import '../models/operating_hours.dart';
import '../services/supabase_service.dart';

/// Singleton que contiene toda la configuración del restaurante.
/// Se carga de LocalStorageService al iniciar la app.
class AppConfig {
  static AppConfig? _instance;
  static AppConfig get instance => _instance!;
  static bool get isInitialized => _instance != null;

  // Info básica
  String restaurantName;
  String subtitle;
  String slogan;
  String address;
  String city;
  String province;
  String country;
  String googleMapsQuery;
  String contactEmail;
  String contactPhone;
  String whatsappNumber;
  String countryCode;
  String website;

  // Branding
  String? logoColorUrl;
  String? logoWhiteUrl;
  String? backgroundUrl;
  Color primaryColor;
  Color secondaryColor;
  Color tertiaryColor;
  Color accentColor;

  // Reglas operativas
  int closedDay;        // 0=ninguno, 1=Lun, 7=Dom
  int minGuests;
  int maxGuests;
  int lunchAdvanceHours;
  int regularAdvanceHours;
  int autoReleaseMinutes;
  int maxAdvanceDays;
  int confirmationWindowHours;
  int reminderHoursBefore;

  // Datos estructurados
  List<AreaConfig> areas;
  List<TableDefinition> tables;
  List<OperatingHours> operatingHours;

  // Admin
  List<String> adminEmails;
  List<String> superAdminEmails;

  // Feature flags
  bool useTableSystem;
  bool useMultipleAreas;
  bool sharedCapacity;
  bool strictTableOptimization;
  bool onboardingCompleted;

  // Suscripción
  String? subscriptionStartDate;
  int subscriptionDueDay;

  AppConfig._({
    required this.restaurantName,
    required this.subtitle,
    required this.slogan,
    required this.address,
    required this.city,
    required this.province,
    required this.country,
    required this.googleMapsQuery,
    required this.contactEmail,
    required this.contactPhone,
    required this.whatsappNumber,
    required this.countryCode,
    required this.website,
    required this.logoColorUrl,
    required this.logoWhiteUrl,
    required this.backgroundUrl,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
    required this.accentColor,
    required this.closedDay,
    required this.minGuests,
    required this.maxGuests,
    required this.lunchAdvanceHours,
    required this.regularAdvanceHours,
    required this.autoReleaseMinutes,
    required this.maxAdvanceDays,
    required this.confirmationWindowHours,
    required this.reminderHoursBefore,
    required this.areas,
    required this.tables,
    required this.operatingHours,
    required this.adminEmails,
    required this.superAdminEmails,
    required this.useTableSystem,
    required this.useMultipleAreas,
    required this.sharedCapacity,
    required this.strictTableOptimization,
    required this.onboardingCompleted,
    this.subscriptionStartDate,
    required this.subscriptionDueDay,
  });

  /// Carga toda la configuración desde Supabase
  static Future<void> initialize() async {
    await initializeFromSupabase();
  }

  /// Carga desde Supabase
  static Future<void> initializeFromSupabase() async {
    final storage = SupabaseService.instance;
    final config = await storage.getConfig();

    final areasData = await storage.getAreas();
    final areas = areasData.map((a) => AreaConfig.fromMap(a)).toList();

    final tablesData = await storage.getTables();
    final tables = tablesData.map((t) => TableDefinition.fromMap(t)).toList();

    final hoursData = await storage.getOperatingHours();
    final hours = hoursData.map((h) => OperatingHours.fromMap(h)).toList();

    _instance = AppConfig._(
      restaurantName: config['nombre_restaurante'] ?? '',
      subtitle: config['subtitulo'] ?? '',
      slogan: config['slogan'] ?? '',
      address: config['direccion'] ?? '',
      city: config['ciudad'] ?? '',
      province: config['provincia'] ?? '',
      country: config['pais'] ?? '',
      googleMapsQuery: config['google_maps_query'] ?? '',
      contactEmail: config['email_contacto'] ?? '',
      contactPhone: config['telefono_contacto'] ?? '',
      whatsappNumber: config['whatsapp_numero'] ?? '',
      countryCode: config['codigo_pais_telefono'] ?? '54',
      website: config['sitio_web'] ?? '',
      // Compat: aceptar logo_url / logo_blanco_url si vienen de otros proyectos
      logoColorUrl: _nullIfEmpty(config['logo_color_url'] ?? config['logo_url']),
      logoWhiteUrl: _nullIfEmpty(config['logo_blanco_url'] ?? config['logo_white_url']),
      backgroundUrl: _nullIfEmpty(config['fondo_url']),
      primaryColor: _parseColor(config['color_primario'], 0xFF194485),
      secondaryColor: _parseColor(config['color_secundario'], 0xFF154080),
      tertiaryColor: _parseColor(config['color_terciario'], 0xFF1B427C),
      accentColor: _parseColor(config['color_acento'], 0xFFFF0000),
      closedDay: int.tryParse(config['dia_cerrado'] ?? '1') ?? 1,
      minGuests: int.tryParse(config['min_personas'] ?? '2') ?? 2,
      maxGuests: int.tryParse(config['max_personas'] ?? '15') ?? 15,
      lunchAdvanceHours: int.tryParse(config['anticipo_almuerzo_horas'] ?? '2') ?? 2,
      regularAdvanceHours: int.tryParse(config['anticipo_regular_horas'] ?? '24') ?? 24,
      autoReleaseMinutes: int.tryParse(config['minutos_liberacion_auto'] ?? '15') ?? 15,
      maxAdvanceDays: int.tryParse(config['dias_adelanto_maximo'] ?? '60') ?? 60,
      confirmationWindowHours: int.tryParse(config['ventana_confirmacion_horas'] ?? '2') ?? 2,
      reminderHoursBefore: int.tryParse(config['recordatorio_horas_antes'] ?? '24') ?? 24,
      areas: areas,
      tables: tables,
      operatingHours: hours,
      adminEmails: _parseJsonList(config['admin_emails']),
      superAdminEmails: _parseJsonList(config['super_admin_emails']),
      useTableSystem: config['usa_sistema_mesas'] == 'true',
      useMultipleAreas: config['usa_areas_multiples'] == 'true',
      sharedCapacity: config['capacidad_compartida'] == 'true',
      strictTableOptimization: config['optimizacion_estricta_mesas'] == 'true',
      onboardingCompleted: await storage.getOnboardingCompleted(),
      subscriptionStartDate: _nullIfEmpty(config['subscription_start_date']),
      subscriptionDueDay: int.tryParse(config['subscription_due_day'] ?? '18') ?? 18,
    );
  }

  /// Guarda la configuración actual en Supabase
  Future<void> saveToLocal() async {
    final storage = SupabaseService.instance;

    await storage.saveConfig({
      'nombre_restaurante': restaurantName,
      'subtitulo': subtitle,
      'slogan': slogan,
      'direccion': address,
      'ciudad': city,
      'provincia': province,
      'pais': country,
      'google_maps_query': googleMapsQuery,
      'email_contacto': contactEmail,
      'telefono_contacto': contactPhone,
      'whatsapp_numero': whatsappNumber,
      'codigo_pais_telefono': countryCode,
      'sitio_web': website,
      // Guardar en ambos nombres para compatibilidad (logo_color_url y logo_url)
      'logo_color_url': logoColorUrl ?? '',
      'logo_url': logoColorUrl ?? '',
      'logo_blanco_url': logoWhiteUrl ?? '',
      'logo_white_url': logoWhiteUrl ?? '',
      'fondo_url': backgroundUrl ?? '',
      'color_primario': _colorToHex(primaryColor),
      'color_secundario': _colorToHex(secondaryColor),
      'color_terciario': _colorToHex(tertiaryColor),
      'color_acento': _colorToHex(accentColor),
      'dia_cerrado': closedDay.toString(),
      'min_personas': minGuests.toString(),
      'max_personas': maxGuests.toString(),
      'anticipo_almuerzo_horas': lunchAdvanceHours.toString(),
      'anticipo_regular_horas': regularAdvanceHours.toString(),
      'minutos_liberacion_auto': autoReleaseMinutes.toString(),
      'dias_adelanto_maximo': maxAdvanceDays.toString(),
      'ventana_confirmacion_horas': confirmationWindowHours.toString(),
      'recordatorio_horas_antes': reminderHoursBefore.toString(),
      'admin_emails': jsonEncode(adminEmails),
      'super_admin_emails': jsonEncode(superAdminEmails),
      'usa_sistema_mesas': useTableSystem.toString(),
      'usa_areas_multiples': useMultipleAreas.toString(),
      'capacidad_compartida': sharedCapacity.toString(),
      'optimizacion_estricta_mesas': strictTableOptimization.toString(),
      'subscription_start_date': subscriptionStartDate ?? '',
      'subscription_due_day': subscriptionDueDay.toString(),
    });

    await storage.saveAreas(areas.map((a) => a.toMap()).toList());
    await storage.saveTables(tables.map((t) => t.toMap()).toList());
    await storage.saveOperatingHours(operatingHours.map((h) => h.toMap()).toList());
    await storage.setOnboardingCompleted(onboardingCompleted);
  }

  /// Recarga la configuración
  static Future<void> reload() async {
    await initializeFromSupabase();
  }

  /// Capacidad total sumando todas las áreas
  int get totalCapacity => areas.fold(0, (sum, a) => sum + a.capacidadFrontend);

  /// Busca un área por nombre interno
  AreaConfig? getArea(String nombre) {
    try {
      return areas.firstWhere((a) => a.nombre == nombre);
    } catch (_) {
      return null;
    }
  }

  /// Horarios para un día específico de la semana
  List<OperatingHours> getHoursForDay(int weekday) {
    // Convertir weekday de Dart (1=Lun, 7=Dom) a nuestro formato (0=Dom, 1=Lun, 6=Sáb)
    final day = weekday == 7 ? 0 : weekday;
    return operatingHours.where((h) => h.diaSemana == day).toList();
  }

  /// Verifica si un día de la semana está cerrado
  bool isDayClosed(int weekday) {
    if (closedDay == 0) return false;
    return weekday == closedDay;
  }

  /// Mesas de un área específica
  List<TableDefinition> getTablesForArea(String area) {
    return tables.where((t) => t.area == area).toList();
  }

  /// Nombre completo de ubicación
  String get fullLocation {
    final parts = [address, city, province, country].where((s) => s.isNotEmpty);
    return parts.join(', ');
  }

  // Helpers privados
  static String _colorToHex(Color c) {
    final r = (c.r * 255).round().toRadixString(16).padLeft(2, '0');
    final g = (c.g * 255).round().toRadixString(16).padLeft(2, '0');
    final b = (c.b * 255).round().toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }

  static String? _nullIfEmpty(String? s) => (s == null || s.isEmpty) ? null : s;

  static Color _parseColor(String? hex, int defaultColor) {
    if (hex == null || hex.isEmpty) return Color(defaultColor);
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Color(defaultColor);
    }
  }

  static List<String> _parseJsonList(String? json) {
    if (json == null || json.isEmpty || json == '[]') return [];
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }
}
