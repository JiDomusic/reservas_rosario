import 'package:flutter/material.dart';

/// Banner animado que muestra disponibilidad baja con urgencia elegante.
/// Aparece cuando queda poca capacidad en un horario.
class UrgencyBanner extends StatefulWidget {
  final int availableSpots;
  final int totalCapacity;
  final String timeSlot;

  const UrgencyBanner({
    super.key,
    required this.availableSpots,
    required this.totalCapacity,
    required this.timeSlot,
  });

  /// Devuelve true si debería mostrarse (< 30% capacidad y > 0 disponible)
  static bool shouldShow(int available, int total) {
    if (total <= 0 || available <= 0) return false;
    return available / total < 0.3;
  }

  @override
  State<UrgencyBanner> createState() => _UrgencyBannerState();
}

class _UrgencyBannerState extends State<UrgencyBanner>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.04,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _pulseController.repeat(reverse: true);
        _shimmerController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = widget.availableSpots <= _getThreshold();
    final urgencyColor = isLast
        ? const Color(0xFFFF6B6B)  // rojo suave para "último"
        : const Color(0xFFFFB74D); // ámbar para "pocos"

    return SlideTransition(
      position: _slideAnimation,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: [
                    urgencyColor.withValues(alpha: 0.15),
                    urgencyColor.withValues(alpha: 0.08),
                    urgencyColor.withValues(alpha: 0.15),
                  ],
                ),
                border: Border.all(
                  color: urgencyColor.withValues(alpha: 0.4),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: urgencyColor.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    // Shimmer effect
                    Positioned.fill(
                      child: ShaderMask(
                        shaderCallback: (rect) {
                          return LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.transparent,
                              urgencyColor.withValues(alpha: 0.1),
                              Colors.transparent,
                            ],
                            stops: [
                              _shimmerAnimation.value - 0.3,
                              _shimmerAnimation.value,
                              _shimmerAnimation.value + 0.3,
                            ].map((s) => s.clamp(0.0, 1.0)).toList(),
                          ).createShader(rect);
                        },
                        blendMode: BlendMode.srcATop,
                        child: Container(
                          color: urgencyColor.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Icono animado
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: urgencyColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: urgencyColor.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              isLast ? Icons.whatshot_rounded : Icons.local_fire_department_rounded,
                              color: urgencyColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Texto
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _getTitle(isLast),
                                  style: TextStyle(
                                    color: urgencyColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _getSubtitle(isLast),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Badge con número
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: urgencyColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: urgencyColor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              '${widget.availableSpots}',
                              style: TextStyle(
                                color: urgencyColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  int _getThreshold() {
    // "último" si quedan 4 o menos personas de capacidad
    return 4;
  }

  String _getTitle(bool isLast) {
    if (isLast) {
      if (widget.availableSpots <= 2) {
        return 'Últimos lugares disponibles';
      }
      return 'Últimos ${widget.availableSpots} lugares';
    }
    return 'Pocos lugares disponibles';
  }

  String _getSubtitle(bool isLast) {
    if (isLast) {
      return 'Reservá ahora para las ${widget.timeSlot}';
    }
    return 'Quedan ${widget.availableSpots} lugares para las ${widget.timeSlot}';
  }
}
