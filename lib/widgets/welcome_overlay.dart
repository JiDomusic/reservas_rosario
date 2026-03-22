import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/app_config.dart';

// Paleta “sushi”: rojos, ámbar, verde inglés y acentos plateados sobre fondo oscuro
const _primary = Color(0xFFB31217);   // rojo profundo
const _secondary = Color(0xFFD68C00); // ámbar oscuro
const _accent = Color(0xFF0B3B2E);    // verde inglés
const _silver = Color(0xFFC0C0C0);    // acento plateado
const _textDark = Color(0xFFE6E6E6);  // texto claro para fondo oscuro
const _panel = Color(0xFF0F1418);     // carta oscuro

class WelcomeOverlay extends StatefulWidget {
  final VoidCallback onSubscribe;
  /// Si es true, muestra un aviso de que el restaurante se está configurando
  final bool mostrarAvisoPendiente;

  const WelcomeOverlay({
    super.key,
    required this.onSubscribe,
    this.mostrarAvisoPendiente = false,
  });

  @override
  State<WelcomeOverlay> createState() => _WelcomeOverlayState();
}

class _WelcomeOverlayState extends State<WelcomeOverlay>
    with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _iconBounceController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _shimmerAnimation;

  int _currentStep = 0; // 0 = welcome, 1 = features, 2 = CTA

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );

    _iconBounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _iconBounceController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.linear),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _iconBounceController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
    } else {
      widget.onSubscribe();
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.instance;
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    // Colores del overlay: fondo blanco, textos oscuros, acentos amarillo y rojo
    const bgColor = _panel;
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: child,
        );
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050505),
              Color(0xFF0B1015),
            ],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: child,
              );
            },
            child: Container(
              margin: EdgeInsets.all(isMobile ? 20 : 40),
              constraints: const BoxConstraints(maxWidth: 480, maxHeight: 620),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _silver,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 40,
                    spreadRadius: -6,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    // Decoración de fondo — iconos flotantes
                    ..._buildFloatingFoodIcons(config),
                    // Contenido
                    Padding(
                      padding: EdgeInsets.all(isMobile ? 24 : 32),
                      child: Column(
                        children: [
                          if (widget.mostrarAvisoPendiente) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: _secondary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _secondary.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.construction_rounded, color: _secondary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Este restaurante se esta configurando.\nProximamente estara disponible.',
                                      style: TextStyle(
                                        fontSize: isMobile ? 12 : 13,
                                        color: _textDark.withValues(alpha: 0.85),
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              switchInCurve: Curves.easeOutBack,
                              switchOutCurve: Curves.easeIn,
                              child: _buildStep(config, isMobile),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildStepIndicator(config),
                          const SizedBox(height: 16),
                          _buildMainButton(config, isMobile),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(AppConfig config, bool isMobile) {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep(config, isMobile);
      case 1:
        return _buildFeaturesStep(config, isMobile);
      case 2:
        return _buildCtaStep(config, isMobile);
      default:
        return const SizedBox.shrink();
    }
  }

  // Paso 0: Bienvenida
  Widget _buildWelcomeStep(AppConfig config, bool isMobile) {
    return Column(
      key: const ValueKey('step_welcome'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Logo animado
        AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _bounceAnimation.value),
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_secondary, _primary],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: _silver, width: 3),
              boxShadow: [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo_jj_reserva.jpg',
                width: isMobile ? 120 : 140,
                height: isMobile ? 120 : 140,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.restaurant_menu_rounded,
                  color: _primary,
                  size: isMobile ? 44 : 52,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: isMobile ? 20 : 28),
        AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment(_shimmerAnimation.value - 1, 0),
                  end: Alignment(_shimmerAnimation.value, 0),
                  colors: const [_primary, _accent, _primary],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(rect);
              },
              child: child!,
            );
          },
          child: Text(
            'JJ Reserva',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.w700,
              color: Colors.white, // ShaderMask necesita blanco
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Sistema de reservas para restaurantes',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w700,
            color: _primary,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Desarrollado por Programacion JJ en Rosario',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: _secondary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            'Sistema JJ Reserva',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'El sistema de reservas mas completo\npara tu restaurante',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: _textDark.withValues(alpha: 0.7),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // Paso 1: Features
  Widget _buildFeaturesStep(AppConfig config, bool isMobile) {
    return Column(
      key: const ValueKey('step_features'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Tu local, tu estilo',
          style: TextStyle(
            fontSize: isMobile ? 22 : 26,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        Text(
          'Es super facil de configurar',
          style: TextStyle(
            fontSize: isMobile ? 14 : 16,
            color: _textDark.withValues(alpha: 0.5),
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: isMobile ? 24 : 32),
        _buildFeatureItem(
          icon: Icons.palette_rounded,
          title: 'Colores y marca',
          subtitle: 'Cambia colores, logo y fondo con un toque',
          accentColor: _primary,
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 12 : 16),
        _buildFeatureItem(
          icon: Icons.table_restaurant_rounded,
          title: 'Mesas y areas',
          subtitle: 'Configura tus mesas, turnos y capacidad',
          accentColor: _secondary,
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 12 : 16),
        _buildFeatureItem(
          icon: Icons.chat_rounded,
          title: 'WhatsApp integrado',
          subtitle: 'Notificaciones automaticas a tus clientes',
          accentColor: const Color(0xFF25D366),
          isMobile: isMobile,
        ),
        SizedBox(height: isMobile ? 12 : 16),
        _buildFeatureItem(
          icon: Icons.bar_chart_rounded,
          title: 'Reportes en vivo',
          subtitle: 'Estadisticas, graficos y control total',
          accentColor: _primary,
          isMobile: isMobile,
        ),
      ],
    );
  }

  // Paso 2: CTA final
  Widget _buildCtaStep(AppConfig config, bool isMobile) {
    return Column(
      key: const ValueKey('step_cta'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Iconos de cubiertos animados
        AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: Offset(-_bounceAnimation.value, _bounceAnimation.value),
                  child: Transform.rotate(
                    angle: -0.3,
                    child: Icon(Icons.restaurant_rounded,
                        color: _secondary.withValues(alpha: 0.7),
                        size: 32),
                  ),
                ),
                const SizedBox(width: 8),
                Transform.translate(
                  offset: Offset(0, -_bounceAnimation.value.abs()),
                  child: const Icon(Icons.local_dining_rounded,
                      color: _primary, size: 48),
                ),
                const SizedBox(width: 8),
                Transform.translate(
                  offset: Offset(_bounceAnimation.value, _bounceAnimation.value),
                  child: Transform.rotate(
                    angle: 0.3,
                    child: Icon(Icons.restaurant_rounded,
                        color: _secondary.withValues(alpha: 0.7),
                        size: 32),
                  ),
                ),
              ],
            );
          },
        ),
        SizedBox(height: isMobile ? 28 : 36),
        Text(
          'Estas a un clic de\ntener mas clientes',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.w800,
            color: _textDark,
            height: 1.2,
          ),
        ),
        SizedBox(height: isMobile ? 16 : 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_secondary, _accent],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _silver, width: 1.2),
          ),
          child: Column(
            children: [
              const Icon(Icons.card_giftcard_rounded,
                  color: _silver, size: 28),
              const SizedBox(height: 8),
              Text(
                'Gratis por 15 dias',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 20,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Sin tarjeta, sin compromiso',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: _textDark.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isMobile ? 12 : 16),
        Text(
          'Industria Nacional',
          style: TextStyle(
            fontSize: isMobile ? 11 : 12,
            color: _textDark.withValues(alpha: 0.5),
            letterSpacing: 2,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: isMobile ? 8 : 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_rounded,
                color: Color(0xFF25D366), size: 16),
            const SizedBox(width: 6),
            Text(
              'Apreta aca y te pasamos el link!',
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                color: const Color(0xFF25D366),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accentColor,
    required bool isMobile,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accentColor, size: isMobile ? 20 : 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  color: _textDark.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator(AppConfig config) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final isActive = i == _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? _primary
                : _textDark.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildMainButton(AppConfig config, bool isMobile) {
    final isLastStep = _currentStep == 2;

    return GestureDetector(
      onTap: _nextStep,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 18),
        decoration: BoxDecoration(
          gradient: isLastStep
              ? const LinearGradient(colors: [_primary, _secondary])
              : null,
          color: isLastStep ? null : _accent.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          border: isLastStep
              ? null
              : Border.all(color: _primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLastStep)
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Icon(Icons.rocket_launch_rounded,
                    color: Colors.white, size: 20),
              ),
            Text(
              isLastStep ? 'Empezar ahora' : 'Siguiente',
              style: TextStyle(
                fontSize: isMobile ? 16 : 17,
                fontWeight: isLastStep ? FontWeight.w700 : FontWeight.w600,
                color: isLastStep ? Colors.white : _textDark,
                letterSpacing: 0.5,
              ),
            ),
            if (!isLastStep)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.arrow_forward_rounded,
                    color: Color(0xFF1A1A1A), size: 18),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFloatingFoodIcons(AppConfig config) {
    final icons = [
      Icons.restaurant_rounded,
      Icons.local_cafe_rounded,
      Icons.dinner_dining_rounded,
      Icons.wine_bar_rounded,
      Icons.table_bar_rounded,
      Icons.cake_rounded,
    ];

    return List.generate(icons.length, (i) {
      final random = math.Random(i * 42);
      final left = random.nextDouble() * 400;
      final top = random.nextDouble() * 550;
      final size = 18.0 + random.nextDouble() * 14;
      final opacity = 0.03 + random.nextDouble() * 0.05;
      final rotationOffset = (i.isEven ? 1.0 : -1.0);

      return AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, _) {
          return Positioned(
            left: left,
            top: top + (_bounceAnimation.value * rotationOffset * 1.5),
            child: Transform.rotate(
              angle: (i * 0.5) + (_bounceAnimation.value * 0.02 * rotationOffset),
              child: Icon(
                icons[i],
                color: (i.isEven ? _primary : _secondary).withValues(alpha: opacity),
                size: size,
              ),
            ),
          );
        },
      );
    });
  }
}
