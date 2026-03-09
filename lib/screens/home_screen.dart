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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  BannerSettings? _bannerSettings;
  bool _bannerLoading = false;

  bool isWebDesktop(BuildContext context) {
    return kIsWeb && MediaQuery.of(context).size.width > 800;
  }

  bool isMobile(BuildContext context) {
    return !kIsWeb || MediaQuery.of(context).size.width <= 800;
  }

  @override
  void initState() {
    super.initState();
    _loadBannerSettings();
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

  void _showSuperAdminAuth(BuildContext context) {
    final pinCtrl = TextEditingController();
    const superAdminPin = '991474';

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
          onSubmitted: (value) {
            if (value == superAdminPin) {
              Navigator.pop(ctx);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SuperAdminScreen()),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PIN incorrecto'), backgroundColor: Colors.red),
              );
              Navigator.pop(ctx);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinCtrl.text == superAdminPin) {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SuperAdminScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN incorrecto'), backgroundColor: Colors.red),
                );
                Navigator.pop(ctx);
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
          // Fondo: imagen de red o gradiente como fallback
          _buildBackground(config),
          // Overlay oscuro elegante
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.6),
                  Colors.black.withValues(alpha: 0.8),
                ],
              ),
            ),
          ),
          // Contenido principal
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isMobileView = constraints.maxWidth < 600;
                bool isSmallMobile = constraints.maxWidth < 400;
                bool isDesktop = constraints.maxWidth >= 800;

                // Espaciados compactos para que quepa todo sin scroll
                double topSpacing = isMobileView ? 10 : (isDesktop ? 15 : 12);
                double logoSpacing = isMobileView ? 20 : (isDesktop ? 25 : 20);
                double taglineSpacing =
                    isMobileView ? 22 : (isDesktop ? 32 : 26);
                double buttonSpacing =
                    isMobileView ? 22 : (isDesktop ? 32 : 26);
                final bool showHolidayBanner = _shouldShowHolidayBanner();
                if (!showHolidayBanner) {
                  taglineSpacing = isMobileView ? 16 : 20;
                  buttonSpacing = isMobileView ? 16 : 20;
                }
                // Empuje suave: si no hay banner, bajamos el bloque de info para ocupar mas fondo
                final double infoOffset = showHolidayBanner
                    ? (isMobileView ? 18 : 24)
                    : (constraints.maxHeight * 0.18).clamp(48.0, 180.0);

                return Stack(
                  children: [
                    SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        isMobileView ? 16.0 : 20.0,
                        8.0,
                        isMobileView ? 16.0 : 20.0,
                        8.0,
                      ),
                      physics: showHolidayBanner
                          ? const BouncingScrollPhysics()
                          : const ClampingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Admin button
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
                                  padding: EdgeInsets.all(12),
                                  margin: EdgeInsets.all(4),
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
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(Icons.admin_panel_settings,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: topSpacing),

                          // Logo del restaurante
                          Column(
                            children: [
                              _buildHeaderLogo(
                                  config, isMobileView, isSmallMobile, isDesktop),
                              SizedBox(height: isMobileView ? 8 : 12),
                              Text(
                                config.subtitle,
                                style: TextStyle(
                                  fontSize: isMobileView
                                      ? (isSmallMobile ? 10 : 11)
                                      : 13,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  letterSpacing: isMobileView ? 2 : 3,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: logoSpacing),

                          // Tagline / Slogan
                          Text(
                            config.slogan,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: isMobileView ? 15 : 17,
                                color: Colors.white.withValues(alpha: 0.9),
                                height: 1.3),
                          ),

                          SizedBox(height: taglineSpacing),

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
                            SizedBox(height: isMobileView ? 18 : 24),
                          ],

                          // Main button - Responsivo
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isMobileView ? double.infinity : 380,
                            ),
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const ReservationFlowScreen())),
                              child: Container(
                                padding: EdgeInsets.all(isMobileView
                                    ? (isSmallMobile ? 16 : 20)
                                    : 24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.white30),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.restaurant,
                                        color: config.accentColor,
                                        size: isMobileView
                                            ? (isSmallMobile ? 26 : 30)
                                            : 34),
                                    SizedBox(height: isMobileView ? 10 : 14),
                                    Text(
                                      'Hacer una reserva',
                                      style: TextStyle(
                                        fontSize: isMobileView
                                            ? (isSmallMobile ? 17 : 19)
                                            : 21,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Mesa para ${config.minGuests}-${config.maxGuests} personas',
                                      style: TextStyle(
                                          fontSize: isMobileView
                                              ? (isSmallMobile ? 11 : 13)
                                              : 15,
                                          color: Colors.white
                                              .withValues(alpha: 0.7)),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Botón "Tengo un código"
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isMobileView ? double.infinity : 380,
                            ),
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ConfirmReservationScreen(),
                                ),
                              ),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobileView ? 16 : 20,
                                  vertical: isMobileView ? 14 : 16,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFF64FFDA).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.verified_user,
                                        color: const Color(0xFF64FFDA),
                                        size: isMobileView ? 18 : 20),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Tengo un código de reserva',
                                      style: TextStyle(
                                        fontSize: isMobileView ? 14 : 15,
                                        color: const Color(0xFF64FFDA),
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: buttonSpacing),

                          SizedBox(height: infoOffset),

                          // Info section - RESPONSIVO Y COMPACTO
                          Container(
                            padding: EdgeInsets.all(isMobileView ? 16 : 18),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildSimpleInfoRow(
                                  Icons.location_on_rounded,
                                  config.address,
                                  onTap: () => _openMaps(),
                                ),
                                SizedBox(height: 10),
                                _buildSimpleInfoRow(
                                  Icons.chat_rounded,
                                  'WhatsApp: ${config.whatsappNumber}',
                                  onTap: () =>
                                      _openWhatsApp(config.whatsappNumber),
                                  color: Colors.green,
                                ),
                                SizedBox(height: 10),
                                _buildSimpleInfoRow(
                                  Icons.people_rounded,
                                  'Capacidad: ${config.totalCapacity} personas',
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: showHolidayBanner ? 10 : 0),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
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

  Widget _buildSimpleInfoRow(IconData icon, String text,
      {VoidCallback? onTap, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color != null
              ? color.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color != null
                ? color.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color ?? Colors.white.withValues(alpha: 0.9),
              size: 18,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.open_in_new_rounded,
                size: 14,
                color: color ?? Colors.white.withValues(alpha: 0.6),
              ),
          ],
        ),
      ),
    );
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
