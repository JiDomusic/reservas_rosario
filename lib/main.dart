import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'config/app_config.dart';
import 'services/supabase_service.dart';
import 'screens/splash_screen.dart';
import 'utils/web_url_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.initialize();

  // Determinar tenant_id: primero de la URL, luego del usuario logueado, luego 'demo'
  String tenantId = _getTenantFromUrl() ?? 'demo';

  // Si hay sesión activa, verificar que coincida con el tenant de la URL
  if (SupabaseService.instance.isLoggedIn) {
    final userTenant = await SupabaseService.instance.getTenantIdForCurrentUser();
    if (tenantId == 'demo' && userTenant != null) {
      // Sin tenant en URL → usar el del usuario logueado
      tenantId = userTenant;
    } else if (tenantId != 'demo' && userTenant != tenantId) {
      // Sesión de otro tenant (o super admin probando) → limpiar para entrar como anon
      await SupabaseService.instance.signOut();
    }
  }

  SupabaseService.instance.setTenantId(tenantId);

  // Asegurar que la URL del browser refleje el tenant activo
  if (kIsWeb && tenantId != 'demo') {
    updateBrowserUrl(tenantId);
  }

  // Load app config from Supabase
  await AppConfig.initialize();

  runApp(const ReservaApp());
}

/// Lee el tenant de la URL en Flutter Web.
/// URL formatos soportados:
/// - Path limpio: https://dominio.web.app/nombre-restaurante
/// - Fragmento:   https://dominio.web.app/#/nombre-restaurante
/// - Query param: https://dominio.web.app/?tenant=nombre-restaurante
String? _getTenantFromUrl() {
  if (!kIsWeb) return null;
  try {
    final uri = Uri.base;

    // Intentar path limpio: /jj_rosario
    final pathTenant = uri.pathSegments.cast<String?>().firstWhere(
          (seg) => seg != null && seg.isNotEmpty && seg != 'index.html',
          orElse: () => null,
        );
    if (pathTenant != null) return pathTenant;

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

Widget _getInitialScreen(AppConfig config) {
  // Always show splash → home. Admin accesses dashboard via login button.
  return const SplashScreen();
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
      home: _getInitialScreen(config),
    );
  }
}
