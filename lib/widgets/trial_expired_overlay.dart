import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';

/// Overlay que se muestra cuando el período de prueba expiró.
/// Se muestra en el Home público del restaurante.
class TrialExpiredOverlay extends StatelessWidget {
  final VoidCallback onExtended;

  const TrialExpiredOverlay({super.key, required this.onExtended});

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.instance;
    final totalDias = config.trialExtended ? 20 : 15;

    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            constraints: const BoxConstraints(maxWidth: 480),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1A1E25),
                  Color(0xFF0D1117),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.orange.withValues(alpha: 0.15),
                  ),
                  child: const Icon(Icons.timer_off_outlined, color: Colors.orange, size: 48),
                ),
                const SizedBox(height: 20),

                // Título
                const Text(
                  'Tu período de prueba finalizó',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Los $totalDias días de prueba gratuita de "${config.restaurantName}" han terminado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Mensaje de contacto
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64FFDA).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF64FFDA).withValues(alpha: 0.2)),
                  ),
                  child: const Text(
                    'Desde Programación JJ te vamos a contactar para conocer tu experiencia y ayudarte a activar tu suscripción.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF64FFDA),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Botón WhatsApp
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openWhatsApp(),
                    icon: const Icon(Icons.chat, size: 20),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'Contactar por WhatsApp',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Industria Nacional — Programación JJ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    final msg = Uri.encodeComponent(
      'Hola! Soy admin de "${AppConfig.instance.restaurantName}" en Reservas-JJ. '
      'Mi período de prueba terminó y quiero consultar sobre la suscripción.',
    );
    final url = Uri.parse('https://wa.me/543413363551?text=$msg');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
