import 'package:flutter/material.dart';
import '../config/app_config.dart';

class PageBackground extends StatelessWidget {
  final Widget child;

  const PageBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.instance;

    // Fondo de pagina: foto de fondo > color elegido > gradiente
    final fondoUrl = config.backgroundUrl ?? '';
    final colorFondo = config.colorFondoPagina;

    if (fondoUrl.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(fondoUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withAlpha(140),
              BlendMode.srcOver,
            ),
          ),
        ),
        child: child,
      );
    }

    if (colorFondo.isNotEmpty) {
      final bgColor = _parseColor(colorFondo);
      return Container(
        color: bgColor,
        child: child,
      );
    }

    // Gradiente por defecto usando colores del restaurante
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            config.primaryColor,
            config.secondaryColor,
            config.tertiaryColor,
          ],
        ),
      ),
      child: child,
    );
  }

  static Color _parseColor(String hex) {
    if (hex.isEmpty) return Colors.white;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return Colors.white;
    }
  }
}
