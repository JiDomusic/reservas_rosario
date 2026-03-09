import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';
import '../services/whatsapp_service.dart';
import 'home_screen.dart';

class ReservationConfirmationScreen extends StatelessWidget {
  final String code;
  final String nombre;
  final DateTime fecha;
  final String hora;
  final int personas;

  const ReservationConfirmationScreen({
    super.key,
    required this.code,
    required this.nombre,
    required this.fecha,
    required this.hora,
    required this.personas,
  });

  String _formatDate() {
    final days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${days[fecha.weekday - 1]} ${fecha.day} de ${months[fecha.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.instance;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF64FFDA).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF64FFDA).withValues(alpha: 0.4), width: 2),
                  ),
                  child: const Icon(Icons.check_rounded, color: Color(0xFF64FFDA), size: 48),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Reserva Recibida!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Confirma tu reserva con el código que te enviaremos por WhatsApp',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 32),

                // Confirmation code
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF64FFDA).withValues(alpha: 0.15),
                        const Color(0xFF1DE9B6).withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF64FFDA).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Tu código de confirmación',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Código copiado')),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              code,
                              style: const TextStyle(
                                color: Color(0xFF64FFDA),
                                fontSize: 36,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 6,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.copy, color: Colors.white.withValues(alpha: 0.4), size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Reservation summary
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      _summaryRow(Icons.person, nombre),
                      _summaryRow(Icons.people, '$personas personas'),
                      _summaryRow(Icons.calendar_today, _formatDate()),
                      _summaryRow(Icons.access_time, hora),
                      _summaryRow(Icons.restaurant, config.restaurantName),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // WhatsApp button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      WhatsAppService.sendReservationReminder(
                        phoneNumber: config.whatsappNumber,
                        customerName: nombre,
                        confirmationCode: code,
                        reservationDate: fecha,
                        reservationTime: hora,
                        guests: personas,
                      );
                    },
                    icon: const Icon(Icons.chat, size: 20),
                    label: const Text('Enviar por WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Back to home
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.home, size: 20),
                    label: const Text('Volver al inicio'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 18),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}
