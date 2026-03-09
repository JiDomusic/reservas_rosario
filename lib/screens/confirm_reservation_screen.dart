import 'package:flutter/material.dart';
import '../services/customer_confirmation_service.dart';
import 'home_screen.dart';

class ConfirmReservationScreen extends StatefulWidget {
  final String? initialCode;

  const ConfirmReservationScreen({super.key, this.initialCode});

  @override
  State<ConfirmReservationScreen> createState() => _ConfirmReservationScreenState();
}

class _ConfirmReservationScreenState extends State<ConfirmReservationScreen> {
  late TextEditingController _codeCtrl;
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _confirmedData;

  @override
  void initState() {
    super.initState();
    _codeCtrl = TextEditingController(text: widget.initialCode ?? '');
    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _confirm();
    }
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Ingresá tu código de confirmación');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await CustomerConfirmationService.confirmByCode(code);

    if (mounted) {
      setState(() {
        _loading = false;
        if (result['success'] == true) {
          _confirmedData = result['data'] as Map<String, dynamic>?;
        } else {
          _error = result['error'] as String?;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Confirmar Reserva',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w300),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: _confirmedData != null ? _buildSuccess() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.verified_user, color: Color(0xFF64FFDA), size: 56),
        const SizedBox(height: 24),
        Text(
          'Ingresá tu código de confirmación',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 18),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Lo recibiste por WhatsApp al hacer tu reserva',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _codeCtrl,
          textCapitalization: TextCapitalization.characters,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF64FFDA),
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 6,
          ),
          decoration: InputDecoration(
            hintText: 'ABC123',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 28,
              letterSpacing: 6,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF64FFDA)),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF64FFDA),
              foregroundColor: const Color(0xFF0A0E14),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _loading
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0A0E14)),
                  )
                : const Text('Confirmar', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    final r = _confirmedData!;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF64FFDA).withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF64FFDA).withValues(alpha: 0.4), width: 2),
          ),
          child: const Icon(Icons.check_rounded, color: Color(0xFF64FFDA), size: 48),
        ),
        const SizedBox(height: 24),
        const Text(
          'Reserva Confirmada!',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _infoRow(Icons.person, '${r['nombre']}'),
              _infoRow(Icons.calendar_today, '${r['fecha']}'),
              _infoRow(Icons.access_time, '${r['hora']}'),
              _infoRow(Icons.people, '${r['personas']} personas'),
              _infoRow(Icons.confirmation_number, '${r['codigo_confirmacion']}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Recordá llegar 10 minutos antes',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
        ),
        const SizedBox(height: 32),
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
    );
  }

  Widget _infoRow(IconData icon, String text) {
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
