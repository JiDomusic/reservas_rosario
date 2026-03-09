import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'services/supabase_service.dart';
import 'screens/splash_screen.dart';
import 'screens/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.initialize();

  // Determinar tenant_id
  final tenantId = _getTenantFromUrl() ?? 'demo';
  SupabaseService.instance.setTenantId(tenantId);

  // Load app config from Supabase
  await AppConfig.initialize();

  runApp(const ReservaApp());
}

/// Lee el tenant de la URL en Flutter Web.
/// URL formato: https://dominio.web.app/#/nombre-restaurante
/// O con query param: https://dominio.web.app/?tenant=nombre-restaurante
String? _getTenantFromUrl() {
  if (!kIsWeb) return null;
  try {
    final uri = Uri.base;

    // Intentar query param: ?tenant=jj_rosario
    final tenantParam = uri.queryParameters['tenant'];
    if (tenantParam != null && tenantParam.isNotEmpty) return tenantParam;

    // Intentar fragment: #/jj_rosario
    final fragment = uri.fragment;
    if (fragment.isNotEmpty) {
      final path = fragment.startsWith('/') ? fragment.substring(1) : fragment;
      if (path.isNotEmpty && !path.contains('/')) return path;
    }

    return null;
  } catch (_) {
    return null;
  }
}

class ReservaApp extends StatelessWidget {
  const ReservaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.instance;

    return MaterialApp(
      title: config.restaurantName.isNotEmpty ? config.restaurantName : 'Reserva Template',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: config.primaryColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: config.onboardingCompleted
          ? const SplashScreen()
          : const AdminDashboardScreen(),
    );
  }
}
