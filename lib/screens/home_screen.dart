import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'admin_login_screen.dart';
import 'super_admin_screen.dart';
import 'reservation_flow_screen.dart';
import 'confirm_reservation_screen.dart';
import '../config/app_config.dart';
import '../services/local_site_status_service.dart';
import '../services/supabase_service.dart';
import '../widgets/welcome_overlay.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  BannerSettings? _bannerSettings;
  bool _bannerLoading = false;
  late bool _showWelcomeOverlay;

  late AnimationController _floatController;
  late AnimationController _pulseController;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;

  bool isWebDesktop(BuildContext context) {
    return kIsWeb && MediaQuery.of(context).size.width > 800;
  }

  bool isMobile(BuildContext context) {
    return !kIsWeb || MediaQuery.of(context).size.width <= 800;
  }

  @override
  void initState() {
    super.initState();
    // Mostrar overlay de marketing solo en tenant demo (landing pública)
    final tenantId = SupabaseService.instance.tenantId;
    _showWelcomeOverlay = (tenantId == 'demo' || tenantId.isEmpty);
    _loadBannerSettings();

    _floatController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadBannerSettings() async {
    try {
      setState(() => _bannerLoading = true);
      final settings = await LocalSiteStatusService.fetchBannerSettings();
      if (!mounted) return;
      setState(() {
        _bannerSettings = settings;
        _bannerLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _bannerLoading = false);
    }
  }

  String _formatBannerDate(DateTime date) {
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${date.day.toString().padLeft(2, '0')} de ${months[date.month - 1]}';
  }

  String _bannerTitle() {
    if (_bannerSettings != null && _bannerSettings!.message.isNotEmpty) {
      return _bannerSettings!.message;
    }
    return '';
  }

  String _bannerSubtitle() {
    final date = _bannerSettings?.reopenDate;
    if (date != null) {
      return 'Volveremos el ${_formatBannerDate(date)}.';
    }
    return '';
  }

  Future<bool> _verifyPin(String pin) async {
    try {
      final result = await SupabaseService.instance.client.rpc(
        'verify_super_admin_pin',
        params: {'p_pin': pin},
      );
      return result == true;
    } catch (_) {
      return false;
    }
  }

  void _showSuperAdminAuth(BuildContext context) {
    final pinCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1E25),
        title: const Text('Super Admin', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: pinCtrl,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(color: Colors.white, letterSpacing: 8, fontSize: 24),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            labelText: 'PIN de acceso',
            labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            counterText: '',
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF64FFDA)),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
          ),
          onSubmitted: (value) async {
            if (await _verifyPin(value)) {
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SuperAdminScreen()),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN incorrecto'), backgroundColor: Colors.red),
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (await _verifyPin(pinCtrl.text)) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SuperAdminScreen()),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN incorrecto'), backgroundColor: Colors.red),
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64FFDA)),
            child: const Text('Entrar', style: TextStyle(color: Color(0xFF0A0E14))),
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
          // Fondo: imagen o gradiente
          _buildBackground(config),
          // Overlay oscuro con gradiente artístico
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.8,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.5),
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Orbes decorativos flotantes (estilo Dalí - formas orgánicas)
          ..._buildFloatingOrbs(config),
          // Contenido principal
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isMobileView = constraints.maxWidth < 600;
                bool isSmallMobile = constraints.maxWidth < 400;
                bool isDesktop = constraints.maxWidth >= 800;
                final bool showHolidayBanner = _shouldShowHolidayBanner();

                return Stack(
                  children: [
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobileView ? 20.0 : 32.0,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: isMobileView ? 12 : 20),

                              // Admin button - discreto, elegante
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  GestureDetector(
                                    onLongPress: () => _showSuperAdminAuth(context),
                                    onTap: () => Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation,
                                                secondaryAnimation) =>
                                            const AdminLoginScreen(),
                                        transitionsBuilder: (context, animation,
                                            secondaryAnimation, child) {
                                          return FadeTransition(
                                            opacity: animation,
                                            child: SlideTransition(
                                              position: Tween<Offset>(
                                                begin: const Offset(1.0, 0.0),
                                                end: Offset.zero,
                                              ).animate(CurvedAnimation(
                                                parent: animation,
                                                curve: Curves.easeInOut,
                                              )),
                                              child: child,
                                            ),
                                          );
                                        },
                                        transitionDuration:
                                            const Duration(milliseconds: 600),
                                      ),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: config.accentColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 2.5),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.admin_panel_settings,
                                          color: Colors.white, size: 16),
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: isMobileView ? 16 : 24),

                              // Logo con efecto flotante
                              AnimatedBuilder(
                                animation: _floatAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, _floatAnimation.value),
                                    child: child,
                                  );
                                },
                                child: Column(
                                  children: [
                                    _buildHeaderLogo(
                                        config, isMobileView, isSmallMobile, isDesktop),
                                    SizedBox(height: isMobileView ? 10 : 14),
                                    // Línea decorativa orgánica bajo el logo
                                    AnimatedBuilder(
                                      animation: _pulseAnimation,
                                      builder: (context, child) {
                                        return Container(
                                          width: (isMobileView ? 60.0 : 80.0) *
                                              _pulseAnimation.value,
                                          height: 2,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                config.accentColor.withValues(alpha: 0),
                                                config.accentColor,
                                                config.accentColor.withValues(alpha: 0),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(1),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      config.subtitle,
                                      style: TextStyle(
                                        fontSize: isMobileView
                                            ? (isSmallMobile ? 10 : 11)
                                            : 13,
                                        fontWeight: FontWeight.w300,
                                        color: Colors.white.withValues(alpha: 0.7),
                                        letterSpacing: isMobileView ? 3 : 5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: isMobileView ? 24 : 36),

                              // Slogan con estilo editorial
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobileView ? 8 : 24,
                                ),
                                child: Text(
                                  config.slogan,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isMobileView ? 16 : 19,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    height: 1.5,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),

                              SizedBox(height: isMobileView ? 28 : 40),

                              if (showHolidayBanner) ...[
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 450),
                                  switchInCurve: Curves.easeOutBack,
                                  switchOutCurve: Curves.easeIn,
                                  child: _buildHolidayBanner(
                                    config,
                                    isMobileView,
                                    isSmallMobile,
                                    key: const ValueKey('holidayBannerInline'),
                                  ),
                                ),
                                SizedBox(height: isMobileView ? 24 : 32),
                              ],

                              // CTA Principal - Botón dramático estilo Dalí
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isMobileView ? double.infinity : 420,
                                ),
                                child: _buildMainCTA(config, isMobileView, isSmallMobile),
                              ),

                              const SizedBox(height: 16),

                              // Botón "Tengo un código" - minimalista
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isMobileView ? double.infinity : 420,
                                ),
                                child: _buildCodeButton(config, isMobileView),
                              ),

                              SizedBox(height: isMobileView ? 32 : 48),

                              // Info section - tarjetas individuales con personalidad
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isMobileView ? double.infinity : 420,
                                ),
                                child: _buildInfoSection(config, isMobileView),
                              ),

                              SizedBox(height: isMobileView ? 16 : 20),

                              // Botón "Suscribite gratis" — marketing
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isMobileView ? double.infinity : 420,
                                ),
                                child: _buildSubscribeButton(config, isMobileView),
                              ),

                              SizedBox(height: isMobileView ? 20 : 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Welcome overlay (tipo Netflix) — deja libre el botón admin arriba
          if (_showWelcomeOverlay)
            Positioned(
              top: 70,
              left: 0,
              right: 0,
              bottom: 0,
              child: WelcomeOverlay(
                onSubscribe: () {
                  _openProgramacionJJWhatsApp();
                },
              ),
            ),
        ],
      ),
    );
  }

  // Botón de suscripción / contacto Programación JJ
  Widget _buildSubscribeButton(AppConfig config, bool isMobileView) {
    return GestureDetector(
      onTap: () => setState(() => _showWelcomeOverlay = true),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobileView ? 16 : 24,
          vertical: isMobileView ? 14 : 16,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              config.accentColor.withValues(alpha: 0.08),
              const Color(0xFF64FFDA).withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: config.accentColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rocket_launch_rounded,
              color: config.accentColor.withValues(alpha: 0.7),
              size: isMobileView ? 18 : 20,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Tenes un restaurante? Proba gratis 15 dias',
                style: TextStyle(
                  fontSize: isMobileView ? 13 : 14,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openProgramacionJJWhatsApp() async {
    const phone = '543413363551';
    const msg = 'Hola! Quiero probar el sistema de reservas Reservas-JJ gratis por 15 dias';
    final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(msg)}';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir WhatsApp')),
        );
      }
    }
  }

  void _openReservaJJLink() async {
    const url = 'https://reserva-jj.web.app/';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    }
  }

  // Orbes flotantes decorativos - formas orgánicas surrealistas
  List<Widget> _buildFloatingOrbs(AppConfig config) {
    return [
      AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, _) {
          return Positioned(
            top: -40 + _floatAnimation.value * 1.5,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    config.accentColor.withValues(alpha: 0.12),
                    config.accentColor.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, _) {
          return Positioned(
            bottom: 80 - _floatAnimation.value * 2,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    config.primaryColor.withValues(alpha: 0.15),
                    config.primaryColor.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, _) {
          return Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            right: -80,
            child: Opacity(
              opacity: _pulseAnimation.value * 0.5,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      config.accentColor.withValues(alpha: 0.08),
                      config.accentColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ];
  }

  // CTA principal - plato surrealista, invita a la acción
  Widget _buildMainCTA(AppConfig config, bool isMobileView, bool isSmallMobile) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ReservationFlowScreen()),
      ),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: config.accentColor.withValues(
                    alpha: 0.15 + (_pulseAnimation.value * 0.1),
                  ),
                  blurRadius: 30 + (_pulseAnimation.value * 10),
                  spreadRadius: -5,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: isMobileView ? (isSmallMobile ? 24 : 28) : 36,
                horizontal: isMobileView ? 20 : 28,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    config.accentColor.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: config.accentColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  // Icono en un círculo decorativo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: config.accentColor.withValues(alpha: 0.15),
                      border: Border.all(
                        color: config.accentColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Icon(
                      Icons.restaurant_menu_rounded,
                      color: config.accentColor,
                      size: isMobileView ? (isSmallMobile ? 28 : 32) : 38,
                    ),
                  ),
                  SizedBox(height: isMobileView ? 16 : 20),
                  Text(
                    'Hacer una reserva',
                    style: TextStyle(
                      fontSize: isMobileView ? (isSmallMobile ? 19 : 22) : 24,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: config.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${config.minGuests}-${config.maxGuests} personas',
                      style: TextStyle(
                        fontSize: isMobileView ? (isSmallMobile ? 12 : 13) : 14,
                        color: config.accentColor.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Botón código de reserva - línea limpia, elegante
  Widget _buildCodeButton(AppConfig config, bool isMobileView) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ConfirmReservationScreen()),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobileView ? 16 : 24,
          vertical: isMobileView ? 14 : 16,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: config.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.confirmation_number_outlined,
                color: config.accentColor.withValues(alpha: 0.8),
                size: isMobileView ? 16 : 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Tengo un código de reserva',
              style: TextStyle(
                fontSize: isMobileView ? 14 : 15,
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Info section - tarjetas con personalidad artística
  Widget _buildInfoSection(AppConfig config, bool isMobileView) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.all(isMobileView ? 16 : 20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              _buildInfoTile(
                icon: Icons.location_on_rounded,
                text: config.address,
                onTap: _openMaps,
                accentColor: config.accentColor,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Divider(
                  color: Colors.white.withValues(alpha: 0.06),
                  height: 1,
                ),
              ),
              _buildInfoTile(
                icon: Icons.chat_bubble_rounded,
                text: 'WhatsApp: ${config.whatsappNumber}',
                onTap: () => _openWhatsApp(config.whatsappNumber),
                accentColor: const Color(0xFF25D366),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Divider(
                  color: Colors.white.withValues(alpha: 0.06),
                  height: 1,
                ),
              ),
              _buildInfoTile(
                icon: Icons.groups_rounded,
                text: 'Capacidad: ${config.totalCapacity} personas',
                accentColor: Colors.white.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String text,
    VoidCallback? onTap,
    required Color accentColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accentColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w400,
                  height: 1.3,
                ),
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_outward_rounded,
                size: 14,
                color: accentColor.withValues(alpha: 0.5),
              ),
          ],
        ),
      ),
    );
  }

  /// Construye el fondo: imagen de red si hay URL, o gradiente como fallback
  Widget _buildBackground(AppConfig config) {
    if (config.backgroundUrl != null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(config.backgroundUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        height: double.infinity,
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
      );
    }
  }

  /// Construye el logo del header: imagen de red si hay URL, o texto como fallback
  Widget _buildHeaderLogo(
      AppConfig config, bool isMobileView, bool isSmallMobile, bool isDesktop) {
    final double logoHeight =
        isMobileView ? (isSmallMobile ? 70 : 80) : (isDesktop ? 110 : 90);

    if (config.logoWhiteUrl != null) {
      return Image.network(
        config.logoWhiteUrl!,
        height: logoHeight,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackLogoText(
              config, isMobileView, isSmallMobile, isDesktop);
        },
      );
    } else {
      return _buildFallbackLogoText(
          config, isMobileView, isSmallMobile, isDesktop);
    }
  }

  Widget _buildFallbackLogoText(
      AppConfig config, bool isMobileView, bool isSmallMobile, bool isDesktop) {
    return Text(
      config.restaurantName,
      style: TextStyle(
        fontSize:
            isMobileView ? (isSmallMobile ? 32 : 40) : (isDesktop ? 48 : 42),
        fontWeight: FontWeight.w100,
        color: Colors.white,
        letterSpacing: isMobileView ? 6 : 10,
      ),
    );
  }

  Widget _buildHolidayBanner(AppConfig config, bool isMobileView,
      bool isSmallMobile, {Key? key}) {
    final double imageSize = isMobileView ? (isSmallMobile ? 58 : 66) : 78;
    final double titleSize = isMobileView ? (isSmallMobile ? 16 : 18) : 20;
    final double subtitleSize = isMobileView ? 14 : 15;
    final double maxWidth = isMobileView ? 340 : 440;
    final double minHeight = isMobileView ? 150 : 180;
    final Color bannerBase = const Color(0xFF1E3A5F);

    return TweenAnimationBuilder<double>(
      key: key,
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        final clamped = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: clamped,
          child: Transform.scale(
            scale: 0.9 + (0.1 * clamped),
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            constraints: BoxConstraints(
              minWidth: isMobileView ? 260 : 300,
              maxWidth: maxWidth,
              minHeight: minHeight,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isMobileView ? 18 : 22,
              vertical: isMobileView ? 18 : 20,
            ),
            decoration: BoxDecoration(
              color: bannerBase.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(22),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.28)),
              boxShadow: [
                BoxShadow(
                  color: bannerBase.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: imageSize,
                  height: imageSize,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: config.logoColorUrl != null
                      ? Image.network(
                          config.logoColorUrl!,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.restaurant,
                                size: imageSize * 0.5,
                                color: config.primaryColor);
                          },
                        )
                      : Image.asset(
                          'assets/images/placeholder_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.restaurant,
                                size: imageSize * 0.5,
                                color: config.primaryColor);
                          },
                        ),
                ),
                SizedBox(height: isMobileView ? 14 : 16),
                Text(
                  _bannerTitle(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 8),
                // Solo mostramos el mensaje principal configurado en admin (sin repetir)
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _shouldShowHolidayBanner() {
    if (_bannerLoading && _bannerSettings == null) {
      return false;
    }
    if (_bannerSettings != null) {
      return _bannerSettings!.enabled;
    }
    return false;
  }

  void _openWhatsApp(String phone) async {
    final config = AppConfig.instance;
    // Limpiar el numero de telefono (quitar espacios, guiones, etc.)
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    final url = 'https://wa.me/${config.countryCode}$cleanPhone';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir WhatsApp')),
        );
      }
    }
  }

  void _openMaps() async {
    final config = AppConfig.instance;
    final query = Uri.encodeComponent(config.googleMapsQuery);
    final url = 'https://maps.google.com/?q=$query';
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir Google Maps')),
        );
      }
    }
  }
}
