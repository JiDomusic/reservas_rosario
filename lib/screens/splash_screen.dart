import 'package:flutter/material.dart';
import 'dart:ui';
import 'home_screen.dart';
import 'admin_dashboard_screen.dart';
import '../config/app_config.dart';
import '../services/supabase_service.dart';
import '../utils/web_url_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    await _fadeController.forward();
    await _scaleController.forward();
    await Future.delayed(const Duration(milliseconds: 3500));

    if (!mounted) return;

    // Si hay sesión activa de admin, verificar que pertenezca al tenant actual
    Widget destination = const HomeScreen();
    if (SupabaseService.instance.isLoggedIn) {
      final tenantId = await SupabaseService.instance.getTenantIdForCurrentUser();
      if (tenantId != null && tenantId == SupabaseService.instance.tenantId) {
        destination = const AdminDashboardScreen();
      } else if (tenantId != null && SupabaseService.instance.tenantId == 'demo') {
        // Admin logueado sin tenant en URL → cargar su tenant
        SupabaseService.instance.setTenantId(tenantId);
        updateBrowserUrl(tenantId);
        await AppConfig.reload();
        destination = const AdminDashboardScreen();
      } else {
        // Usuario no pertenece a este tenant, cerrar sesión
        await SupabaseService.instance.signOut();
      }
    }

    // ignore: use_build_context_synchronously
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  /// Si el tenant no completó onboarding, mostrar logo genérico de Reservas-JJ
  bool get _usarGenerico => !AppConfig.instance.onboardingCompleted;

  Widget _buildLogo() {
    final config = AppConfig.instance;
    // Tenant sin onboarding → logo genérico de Reservas-JJ
    if (_usarGenerico) {
      return Image.asset(
        'assets/images/logo_jj_reserva.jpg',
        height: 180,
        width: 180,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackLogo(config);
        },
      );
    }
    if (config.logoColorUrl != null) {
      return Image.network(
        config.logoColorUrl!,
        height: 180,
        width: 180,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackLogo(config);
        },
      );
    } else {
      return Image.asset(
        'assets/images/placeholder_logo.png',
        height: 180,
        width: 180,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackLogo(config);
        },
      );
    }
  }

  Widget _buildFallbackLogo(AppConfig config) {
    final fallbackText =
        config.restaurantName.isNotEmpty ? config.restaurantName : 'Aca va tu logo';
    return Text(
      fallbackText,
      style: TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: config.accentColor,
        letterSpacing: 8,
      ),
    );
  }

  Widget _buildHelperBanner(AppConfig config) {
    if (config.onboardingCompleted) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              final clamped = value.clamp(0.0, 1.0);
              return Opacity(
                opacity: clamped,
                child: Transform.translate(
                  offset: Offset(0, (1 - clamped) * 16),
                  child: Transform.scale(
                    scale: 0.96 + (clamped * 0.04),
                    child: child,
                  ),
                ),
              );
            },
            child: Container(
              width: 440,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0D0A0A).withValues(alpha: 0.95),
                    const Color(0xFF8F1A1A).withValues(alpha: 0.9),
                    const Color(0xFFE36B5C).withValues(alpha: 0.85),
                    const Color(0xFFFFA07A).withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFE1C4).withValues(alpha: 0.65), width: 1.4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 32,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Text(
                    '🍣 Armá tu marca en 3 minutos',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFFE8B2), // título dorado/ámbar
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Carga logo, colores, horarios y contacto. Te guiamos paso a paso.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFCE6D2),
                      fontSize: 17,
                      height: 1.7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Cuando termines, este aviso se va y queda tu splash con tu logo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFFAF3EB),
                      fontSize: 15,
                      height: 1.6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.instance;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: const [
                  Color(0xFF030712),
                  Color(0xFF0B1B2E),
                  Color(0xFF0F2740),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: AnimatedBuilder(
                          animation: _scaleAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _scaleAnimation.value,
                              child: Container(
                                padding: const EdgeInsets.all(50),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      blurRadius: 40,
                                      spreadRadius: 10,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: _buildLogo(),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              _usarGenerico ? 'RESERVAS-JJ' : config.subtitle,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.9),
                                letterSpacing: 6,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: 100,
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white,
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            Text(
                              _usarGenerico ? 'Sistema de reservas para restaurantes' : config.slogan,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                                color: Colors.white.withValues(alpha: 0.7),
                                letterSpacing: 1,
                              ),
                            ),
                            _buildHelperBanner(config),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 60),

                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: ClipOval(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
