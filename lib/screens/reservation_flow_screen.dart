import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/restaurant_service.dart';
import '../services/local_reservation_service.dart';
import '../services/local_block_service.dart';
import '../services/confirmation_code_service.dart';
import '../widgets/advanced_calendar.dart';
import '../widgets/time_slot_with_cross.dart';
import '../widgets/urgency_banner.dart';
import 'reservation_confirmation_screen.dart';
import 'waitlist_confirmation_screen.dart';
import '../services/waitlist_service.dart';

class ReservationFlowScreen extends StatefulWidget {
  const ReservationFlowScreen({super.key});

  @override
  State<ReservationFlowScreen> createState() => _ReservationFlowScreenState();
}

class _ReservationFlowScreenState extends State<ReservationFlowScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Step 1: Personas
  int? _selectedGuests;

  // Step 2: Fecha
  DateTime? _selectedDate;

  // Step 3: Horario
  String? _selectedTime;
  List<Map<String, dynamic>> _timeSlots = [];
  bool _loadingSlots = false;

  // Capacidad disponible para el slot seleccionado
  int _availableCapacity = 0;
  int _totalCapacity = 0;

  // Step 4: Datos del cliente
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  void _next() {
    if (_currentPage < 3) _goToPage(_currentPage + 1);
  }

  void _back() {
    if (_currentPage > 0) {
      _goToPage(_currentPage - 1);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _loadTimeSlots() async {
    if (_selectedDate == null || _selectedGuests == null) return;
    setState(() => _loadingSlots = true);

    final allSlots = RestaurantService.getAllTimeSlotsForDate(_selectedDate!, _selectedGuests!);
    final blockStatus = await LocalBlockService.getStatus(_selectedDate!);

    final List<Map<String, dynamic>> slots = [];
    for (final hora in allSlots) {
      final isBlocked = blockStatus.isDayBlocked || blockStatus.blockedHours.contains(hora);
      final isOutside = RestaurantService.isOutsideAdvanceTime(_selectedDate!, hora, _selectedGuests!);

      // Cargar capacidad disponible para cada slot
      final capacityInfo = await LocalReservationService.getAvailableCapacity(
        fecha: _selectedDate!,
        hora: hora,
      );

      final available = (capacityInfo['available'] ?? 0) as int;
      final totalCap = (capacityInfo['total_capacity'] ?? 0) as int;
      final noCapacity = available < _selectedGuests!;

      slots.add({
        'hora': hora,
        'available': !isBlocked && !isOutside && !noCapacity,
        'showCross': isBlocked || isOutside || noCapacity,
        'availableCapacity': available,
        'totalCapacity': totalCap,
      });
    }

    if (mounted) {
      setState(() {
        _timeSlots = slots;
        _loadingSlots = false;
        _selectedTime = null;
        _availableCapacity = 0;
        _totalCapacity = 0;
      });
    }
  }

  Future<void> _submit() async {
    if (_selectedGuests == null || _selectedDate == null || _selectedTime == null) return;
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y teléfono son obligatorios')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      // Validate
      final validation = await RestaurantService.validateReservation(
        date: _selectedDate!,
        time: _selectedTime!,
        guests: _selectedGuests!,
      );

      if (validation['valid'] != true) {
        if (mounted) {
          final errorMsg = validation['error'] ?? 'Error de validación';
          setState(() => _submitting = false);
          // Si el error es por capacidad o demanda, ofrecer waitlist
          if (errorMsg.contains('No hay mas lugar') ||
              errorMsg.contains('capacidad') ||
              errorMsg.contains('alta demanda')) {
            _showWaitlistDialog(errorMsg);
          } else {
            _showErrorDialog(errorMsg);
          }
        }
        return;
      }

      // Generate code
      final code = await ConfirmationCodeService.generateUniqueCode();

      // Create reservation
      final result = await LocalReservationService.createReservation(
        fecha: _selectedDate!,
        hora: _selectedTime!,
        personas: _selectedGuests!,
        nombre: _nameCtrl.text.trim(),
        telefono: _phoneCtrl.text.trim(),
        codigoConfirmacion: code,
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        comentarios: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
      );

      if (mounted) {
        if (result['success'] == true) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => ReservationConfirmationScreen(
                code: code,
                nombre: _nameCtrl.text.trim(),
                fecha: _selectedDate!,
                hora: _selectedTime!,
                personas: _selectedGuests!,
              ),
            ),
          );
        } else {
          _showErrorDialog(result['error'] ?? 'Error al crear reserva');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error al procesar la reserva. Intentá de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1E25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Color(0xFFFFB74D), size: 24),
            SizedBox(width: 10),
            Text('Aviso', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Entendido', style: TextStyle(color: Color(0xFF64FFDA))),
          ),
        ],
      ),
    );
  }

  void _showWaitlistDialog(String errorMsg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1E25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono grande animado
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                    const Color(0xFFFF6B6B).withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.5), width: 2),
              ),
              child: const Icon(Icons.whatshot_rounded, color: Color(0xFFFF6B6B), size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Horario muy solicitado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFFF6B6B), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      errorMsg,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB74D).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: Color(0xFFFFB74D), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Unite a la lista de espera y te avisamos cuando se libere un lugar.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Botón principal - lista de espera
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
                    _showErrorDialog('Completá nombre y teléfono primero');
                    return;
                  }
                  await WaitlistService.addToWaitlist(
                    fecha: _selectedDate!,
                    hora: _selectedTime!,
                    personas: _selectedGuests!,
                    nombre: _nameCtrl.text.trim(),
                    telefono: _phoneCtrl.text.trim(),
                    email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
                    comentarios: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
                  );
                  if (mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => WaitlistConfirmationScreen(
                          nombre: _nameCtrl.text.trim(),
                          fecha: _selectedDate!,
                          hora: _selectedTime!,
                          personas: _selectedGuests!,
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.notifications_active, size: 18),
                label: const Text('Unirme a la lista de espera', style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFB74D),
                  foregroundColor: const Color(0xFF0A0E14),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Botón secundario - cerrar
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Elegir otro horario',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = AppConfig.instance;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _back,
        ),
        title: Text(
          _pageTitle(),
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w300),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress indicator
          _buildProgressBar(),

          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) => setState(() => _currentPage = page),
              children: [
                _buildGuestsPage(config),
                _buildDatePage(),
                _buildTimePage(),
                _buildDataPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _pageTitle() {
    switch (_currentPage) {
      case 0: return 'Cantidad de personas';
      case 1: return 'Elegí la fecha';
      case 2: return 'Elegí el horario';
      case 3: return 'Tus datos';
      default: return '';
    }
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = i <= _currentPage;
          return Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF64FFDA) : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ===== PAGE 1: GUESTS =====
  Widget _buildGuestsPage(AppConfig config) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people, color: Color(0xFF64FFDA), size: 48),
            const SizedBox(height: 16),
            Text(
              'Mesa para cuántas personas?',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 18),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: List.generate(
                config.maxGuests - config.minGuests + 1,
                (i) {
                  final guests = config.minGuests + i;
                  final isSelected = _selectedGuests == guests;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedGuests = guests);
                      Future.delayed(const Duration(milliseconds: 300), _next);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF64FFDA).withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF64FFDA)
                              : Colors.white.withValues(alpha: 0.15),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$guests',
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF64FFDA) : Colors.white,
                            fontSize: 22,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w300,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Para más de ${config.maxGuests} personas, contactanos por WhatsApp',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ===== PAGE 2: DATE =====
  Widget _buildDatePage() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: AdvancedCalendar(
          selectedDate: _selectedDate,
          onDateSelected: (date) {
            setState(() => _selectedDate = date);
            if (date != null) {
              _loadTimeSlots();
              Future.delayed(const Duration(milliseconds: 400), _next);
            }
          },
        ),
      ),
    );
  }

  // ===== PAGE 3: TIME =====
  Widget _buildTimePage() {
    if (_loadingSlots) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF64FFDA)));
    }

    if (_timeSlots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, color: Colors.white38, size: 48),
            const SizedBox(height: 16),
            Text('No hay horarios disponibles',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _back,
              child: const Text('Elegir otra fecha', style: TextStyle(color: Color(0xFF64FFDA))),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} - $_selectedGuests personas',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              ),
            ),
          TimeSlotGrid(
            timeSlots: _timeSlots,
            selectedTimeSlot: _selectedTime,
            guests: _selectedGuests ?? 2,
            onTimeSlotSelected: (hora) {
              // Buscar capacidad del slot seleccionado
              final slot = _timeSlots.firstWhere(
                (s) => s['hora'] == hora,
                orElse: () => {'availableCapacity': 0, 'totalCapacity': 0},
              );
              setState(() {
                _selectedTime = hora;
                _availableCapacity = slot['availableCapacity'] as int? ?? 0;
                _totalCapacity = slot['totalCapacity'] as int? ?? 0;
              });
              Future.delayed(const Duration(milliseconds: 300), _next);
            },
          ),
        ],
      ),
    );
  }

  // ===== PAGE 4: CLIENT DATA =====
  Widget _buildDataPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF64FFDA).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF64FFDA).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.restaurant, color: Color(0xFF64FFDA), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$_selectedGuests personas  |  ${_selectedDate?.day}/${_selectedDate?.month}  |  $_selectedTime',
                    style: const TextStyle(color: Color(0xFF64FFDA), fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Banner de urgencia si queda poca capacidad
          if (_selectedTime != null &&
              _totalCapacity > 0 &&
              UrgencyBanner.shouldShow(_availableCapacity, _totalCapacity))
            UrgencyBanner(
              availableSpots: _availableCapacity,
              totalCapacity: _totalCapacity,
              timeSlot: _selectedTime!,
            ),

          const SizedBox(height: 16),

          _inputField('Nombre *', _nameCtrl, Icons.person),
          _inputField('Teléfono *', _phoneCtrl, Icons.phone, keyboardType: TextInputType.phone),
          _inputField('Email (opcional)', _emailCtrl, Icons.email, keyboardType: TextInputType.emailAddress),
          _inputField('Comentarios (opcional)', _commentCtrl, Icons.comment, maxLines: 3),

          const SizedBox(height: 32),

          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64FFDA),
              foregroundColor: const Color(0xFF0A0E14),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              disabledBackgroundColor: const Color(0xFF64FFDA).withValues(alpha: 0.3),
            ),
            child: _submitting
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0A0E14)),
                  )
                : const Text(
                    'Confirmar Reserva',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 20),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF64FFDA)),
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
