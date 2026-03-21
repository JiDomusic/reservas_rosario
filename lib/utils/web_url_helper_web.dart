// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Actualiza la URL del browser sin recargar la página.
/// Sanitiza el tenantId para prevenir inyección de rutas.
void updateBrowserUrl(String tenantId) {
  // Solo permitir caracteres seguros: alfanuméricos, guión, guión bajo
  final sanitized = tenantId.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '');
  if (sanitized.isEmpty) return;
  html.window.history.replaceState(null, '', '/$sanitized');
}
