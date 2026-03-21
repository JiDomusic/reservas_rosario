import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_config.dart';
import '../models/area_config.dart';
import '../models/operating_hours.dart';
import '../models/table_definition.dart';
import '../services/local_reservation_service.dart';
import '../services/local_block_service.dart';
import '../services/local_site_status_service.dart';
import '../services/capacity_doc_pdf_service.dart';
import '../services/user_guide_pdf_service.dart';
import '../services/auto_release_service.dart';
import '../services/customer_confirmation_service.dart';
import '../services/reminder_service.dart';
import '../services/waitlist_service.dart';
import '../services/whatsapp_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../utils/web_url_helper.dart';
import 'home_screen.dart';
import 'reports_tab.dart';
import 'table_map_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showChangePassword(BuildContext context) {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1E25),
        title: const Text('Cambiar Contraseña', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nueva contraseña',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                prefixIcon: Icon(Icons.lock, color: Colors.white.withValues(alpha: 0.6)),
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
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPassCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Confirmar contraseña',
                labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withValues(alpha: 0.6)),
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
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPass = newPassCtrl.text;
              final confirmPass = confirmPassCtrl.text;

              if (newPass.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('La contraseña debe tener al menos 6 caracteres'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              if (newPass != confirmPass) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Las contraseñas no coinciden'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              try {
                await SupabaseService.instance.client.auth.updateUser(
                  UserAttributes(password: newPass),
                );
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contraseña cambiada con éxito'),
                      backgroundColor: Color(0xFF64FFDA),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64FFDA)),
            child: const Text('Cambiar', style: TextStyle(color: Color(0xFF0A0E14))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1E25),
        title: const Text('Panel de Administración',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, color: Color(0xFF64FFDA)),
            tooltip: 'Ir al inicio',
            onPressed: () async {
              // Recargar config para reflejar cambios del onboarding
              await AppConfig.reload();
              updateBrowserUrl(SupabaseService.instance.tenantId);
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.lock_outline, color: Colors.white70),
            tooltip: 'Cambiar contraseña',
            onPressed: () => _showChangePassword(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Cerrar sesión'),
                  content: const Text('Vas a salir del panel de administración.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                await SupabaseService.instance.signOut();
                // Volver al tenant demo y limpiar URL
                SupabaseService.instance.setTenantId('demo');
                await AppConfig.reload();
                updateBrowserUrl('demo');
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF64FFDA),
          labelColor: const Color(0xFF64FFDA),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(icon: Icon(Icons.settings), text: 'Config'),
            Tab(icon: Icon(Icons.table_restaurant), text: 'Áreas'),
            Tab(icon: Icon(Icons.schedule), text: 'Horarios'),
            Tab(icon: Icon(Icons.event_note), text: 'Operaciones'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Reportes'),
            Tab(icon: Icon(Icons.map), text: 'Mapa'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Banner de trial
          if (AppConfig.instance.trialEndDate != null)
            _buildTrialBanner(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _ConfigTab(),
                _AreasTab(),
                _HorariosTab(),
                _OperacionesTab(),
                ReportsTab(),
                TableMapScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrialBanner() {
    final config = AppConfig.instance;
    final days = config.trialDaysRemaining;
    final expired = config.isTrialExpired;

    final Color bgColor;
    final Color textColor;
    final IconData icon;
    final String text;

    if (expired) {
      bgColor = Colors.red.withValues(alpha: 0.15);
      textColor = Colors.red;
      icon = Icons.timer_off;
      text = 'Tu período de prueba ha finalizado';
    } else if (days <= 3) {
      bgColor = Colors.orange.withValues(alpha: 0.15);
      textColor = Colors.orange;
      icon = Icons.warning_amber;
      text = 'Quedan $days día${days == 1 ? "" : "s"} de prueba';
    } else {
      bgColor = const Color(0xFF64FFDA).withValues(alpha: 0.1);
      textColor = const Color(0xFF64FFDA);
      icon = Icons.timer_outlined;
      text = '$days días restantes de prueba';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: bgColor,
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TAB 1: CONFIGURACIÓN DEL RESTAURANTE
// ============================================================
class _ConfigTab extends StatefulWidget {
  const _ConfigTab();

  @override
  State<_ConfigTab> createState() => _ConfigTabState();
}

class _ConfigTabState extends State<_ConfigTab> {
  late TextEditingController _nameCtrl;
  late TextEditingController _subtitleCtrl;
  late TextEditingController _sloganCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _provinceCtrl;
  late TextEditingController _countryCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _whatsappCtrl;
  late TextEditingController _countryCodeCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _mapsQueryCtrl;
  late TextEditingController _logoColorCtrl;
  late TextEditingController _logoWhiteCtrl;
  late TextEditingController _backgroundCtrl;
  // PIN removed — auth handled by Supabase

  Color _primaryColor = Colors.blue;
  Color _secondaryColor = Colors.blue;
  Color _tertiaryColor = Colors.blue;
  Color _accentColor = Colors.red;
  int _minGuests = 2;
  int _maxGuests = 15;
  int _lunchAdvance = 2;
  int _regularAdvance = 24;
  int _autoRelease = 15;
  int _confirmationWindow = 2;
  int _reminderHours = 24;
  int _closedDay = 1;
  bool _useTableSystem = false;
  bool _useMultipleAreas = false;
  bool _sharedCapacity = false;
  bool _strictTableOpt = false;

  @override
  void initState() {
    super.initState();
    final c = AppConfig.instance;
    _nameCtrl = TextEditingController(text: c.restaurantName);
    _subtitleCtrl = TextEditingController(text: c.subtitle);
    _sloganCtrl = TextEditingController(text: c.slogan);
    _addressCtrl = TextEditingController(text: c.address);
    _cityCtrl = TextEditingController(text: c.city);
    _provinceCtrl = TextEditingController(text: c.province);
    _countryCtrl = TextEditingController(text: c.country);
    _phoneCtrl = TextEditingController(text: c.contactPhone);
    _whatsappCtrl = TextEditingController(text: c.whatsappNumber);
    _countryCodeCtrl = TextEditingController(text: c.countryCode);
    _emailCtrl = TextEditingController(text: c.contactEmail);
    _mapsQueryCtrl = TextEditingController(text: c.googleMapsQuery);
    _logoColorCtrl = TextEditingController(text: c.logoColorUrl ?? '');
    _logoWhiteCtrl = TextEditingController(text: c.logoWhiteUrl ?? '');
    _backgroundCtrl = TextEditingController(text: c.backgroundUrl ?? '');
    // PIN removed — auth handled by Supabase
    _primaryColor = c.primaryColor;
    _secondaryColor = c.secondaryColor;
    _tertiaryColor = c.tertiaryColor;
    _accentColor = c.accentColor;
    _minGuests = c.minGuests;
    _maxGuests = c.maxGuests;
    _lunchAdvance = c.lunchAdvanceHours;
    _regularAdvance = c.regularAdvanceHours;
    _autoRelease = c.autoReleaseMinutes;
    _confirmationWindow = c.confirmationWindowHours;
    _reminderHours = c.reminderHoursBefore;
    _closedDay = c.closedDay;
    _useTableSystem = c.useTableSystem;
    _useMultipleAreas = c.useMultipleAreas;
    _sharedCapacity = c.sharedCapacity;
    _strictTableOpt = c.strictTableOptimization;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _subtitleCtrl.dispose();
    _sloganCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _provinceCtrl.dispose();
    _countryCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _countryCodeCtrl.dispose();
    _emailCtrl.dispose();
    _mapsQueryCtrl.dispose();
    _logoColorCtrl.dispose();
    _logoWhiteCtrl.dispose();
    _backgroundCtrl.dispose();
    // PIN removed
    super.dispose();
  }

  Future<void> _saveConfig() async {
    final c = AppConfig.instance;
    c.restaurantName = _nameCtrl.text;
    c.subtitle = _subtitleCtrl.text;
    c.slogan = _sloganCtrl.text;
    c.address = _addressCtrl.text;
    c.city = _cityCtrl.text;
    c.province = _provinceCtrl.text;
    c.country = _countryCtrl.text;
    c.contactPhone = _phoneCtrl.text;
    c.whatsappNumber = _whatsappCtrl.text;
    c.countryCode = _countryCodeCtrl.text;
    c.contactEmail = _emailCtrl.text;
    c.googleMapsQuery = _mapsQueryCtrl.text;
    c.logoColorUrl = _logoColorCtrl.text.isEmpty ? null : _logoColorCtrl.text;
    c.logoWhiteUrl = _logoWhiteCtrl.text.isEmpty ? null : _logoWhiteCtrl.text;
    c.backgroundUrl = _backgroundCtrl.text.isEmpty ? null : _backgroundCtrl.text;
    c.primaryColor = _primaryColor;
    c.secondaryColor = _secondaryColor;
    c.tertiaryColor = _tertiaryColor;
    c.accentColor = _accentColor;
    c.minGuests = _minGuests;
    c.maxGuests = _maxGuests;
    c.lunchAdvanceHours = _lunchAdvance;
    c.regularAdvanceHours = _regularAdvance;
    c.autoReleaseMinutes = _autoRelease;
    c.confirmationWindowHours = _confirmationWindow;
    c.reminderHoursBefore = _reminderHours;
    c.closedDay = _closedDay;
    c.useTableSystem = _useTableSystem;
    c.useMultipleAreas = _useMultipleAreas;
    c.sharedCapacity = _sharedCapacity;
    c.strictTableOptimization = _strictTableOpt;
    c.onboardingCompleted = true;

    try {
      final wasFirstOnboarding = !AppConfig.instance.trialExtended;
      await c.saveToLocal();

      // Si es la primera vez que completan onboarding, regalar 5 días extra
      if (wasFirstOnboarding) {
        final extended = await SupabaseService.instance.extendTrialForOnboarding();
        if (extended && mounted) {
          await AppConfig.reload();
          _showTrialGiftDialog();
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada con éxito'),
            backgroundColor: Color(0xFF64FFDA),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar configuración: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showTrialGiftDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1E25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF64FFDA).withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.card_giftcard, color: Color(0xFF64FFDA), size: 48),
            ),
            const SizedBox(height: 20),
            const Text(
              '🎉 ¡Te ganaste 5 días más!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              'Por completar tu onboarding, Programación JJ te regala 5 días extra de prueba.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 8),
            const Text(
              'En total tenés 20 días para probar el sistema.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64FFDA), fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Nos vamos a contactar para que nos cuentes tu experiencia.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64FFDA),
                foregroundColor: const Color(0xFF0A0E14),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('¡Genial, gracias!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickColor(String label, Color current, ValueChanged<Color> onPick) async {
    Color picked = current;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1E25),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        content: ColorPicker(
          color: current,
          onColorChanged: (c) => picked = c,
          pickersEnabled: const {ColorPickerType.wheel: true},
          width: 36,
          height: 36,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              onPick(picked);
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFF64FFDA))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('Información Básica'),
        _textField('Nombre del restaurante', _nameCtrl),
        _textField('Subtítulo', _subtitleCtrl),
        _textField('Slogan', _sloganCtrl),
        _textField('Dirección', _addressCtrl),
        Row(children: [
          Expanded(child: _textField('Ciudad', _cityCtrl)),
          const SizedBox(width: 8),
          Expanded(child: _textField('Provincia', _provinceCtrl)),
        ]),
        _textField('País', _countryCtrl),
        Row(children: [
          SizedBox(width: 80, child: _textField('Cód. País', _countryCodeCtrl)),
          const SizedBox(width: 8),
          Expanded(child: _textField('Teléfono', _phoneCtrl)),
        ]),
        _textField('WhatsApp', _whatsappCtrl),
        _textField('Email', _emailCtrl),
        _textField('Google Maps query', _mapsQueryCtrl),

        const SizedBox(height: 24),
        _sectionTitle('Imágenes'),
        _imageUploadField('Logo color', _logoColorCtrl, 'logo_color.jpg'),
        _imageUploadField('Logo blanco', _logoWhiteCtrl, 'logo_blanco.jpg'),
        _imageUploadField('Foto de fondo', _backgroundCtrl, 'fondo.jpg'),

        const SizedBox(height: 24),
        _sectionTitle('Colores de Marca'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _colorButton('Primario', _primaryColor, (c) => setState(() => _primaryColor = c)),
            _colorButton('Secundario', _secondaryColor, (c) => setState(() => _secondaryColor = c)),
            _colorButton('Terciario', _tertiaryColor, (c) => setState(() => _tertiaryColor = c)),
            _colorButton('Acento', _accentColor, (c) => setState(() => _accentColor = c)),
          ],
        ),

        const SizedBox(height: 24),
        _sectionTitle('Reglas de Reserva'),
        Row(children: [
          Expanded(child: _numberField('Min personas', _minGuests, (v) => setState(() => _minGuests = v))),
          const SizedBox(width: 8),
          Expanded(child: _numberField('Max personas', _maxGuests, (v) => setState(() => _maxGuests = v))),
        ]),
        Row(children: [
          Expanded(child: _numberField('Anticipo almuerzo (hs)', _lunchAdvance, (v) => setState(() => _lunchAdvance = v))),
          const SizedBox(width: 8),
          Expanded(child: _numberField('Anticipo general (hs)', _regularAdvance, (v) => setState(() => _regularAdvance = v))),
        ]),
        _numberField('Auto-release (min)', _autoRelease, (v) => setState(() => _autoRelease = v)),
        _numberField('Ventana confirmación (hs)', _confirmationWindow, (v) => setState(() => _confirmationWindow = v)),
        _numberField('Recordatorio antes (hs)', _reminderHours, (v) => setState(() => _reminderHours = v)),
        _dropdownField('Día cerrado', _closedDay, {
          0: 'Ninguno', 1: 'Lunes', 2: 'Martes', 3: 'Miércoles',
          4: 'Jueves', 5: 'Viernes', 6: 'Sábado', 7: 'Domingo',
        }, (v) => setState(() => _closedDay = v!)),

        const SizedBox(height: 24),
        _sectionTitle('Feature Flags'),
        _switchTile('Sistema de mesas', _useTableSystem, (v) => setState(() => _useTableSystem = v)),
        _switchTile('Múltiples áreas', _useMultipleAreas, (v) => setState(() => _useMultipleAreas = v)),
        _switchTile('Capacidad compartida', _sharedCapacity, (v) => setState(() => _sharedCapacity = v)),

        const SizedBox(height: 24),
        _sectionTitle('Asignación de mesas'),
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1E25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _strictTableOpt ? Colors.amber.withValues(alpha: 0.3) : const Color(0xFF64FFDA).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _strictTableOpt ? Icons.tune : Icons.event_available,
                    color: _strictTableOpt ? Colors.amber : const Color(0xFF64FFDA),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _strictTableOpt ? 'Modo estricto' : 'Modo relajado',
                      style: TextStyle(
                        color: _strictTableOpt ? Colors.amber : const Color(0xFF64FFDA),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Switch(
                    value: _strictTableOpt,
                    activeColor: Colors.amber,
                    inactiveTrackColor: const Color(0xFF64FFDA).withValues(alpha: 0.3),
                    inactiveThumbColor: const Color(0xFF64FFDA),
                    onChanged: (v) => setState(() => _strictTableOpt = v),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _strictTableOpt
                    ? 'Se optimiza el uso de mesas: si queda 1 solo lugar libre en una mesa, puede que ese horario se muestre como "alta demanda" para reservar mejor después. Ideal si el restaurante suele llenarse.'
                    : 'Se aceptan todas las reservas mientras haya lugar disponible, sin importar si sobra 1 silla. Ideal si preferís no perder ninguna reserva.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: _saveConfig,
          icon: const Icon(Icons.save),
          label: const Text('Guardar Configuración'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF64FFDA),
            foregroundColor: const Color(0xFF0A0E14),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(title, style: const TextStyle(
        color: Color(0xFF64FFDA), fontSize: 16, fontWeight: FontWeight.w600,
      )),
    );
  }

  Widget _imageUploadField(String label, TextEditingController ctrl, String fileName) {
    final hasImage = ctrl.text.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              // Preview
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: hasImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(ctrl.text, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white38)),
                      )
                    : const Icon(Icons.image_outlined, color: Colors.white24, size: 32),
              ),
              const SizedBox(width: 12),
              // Buttons
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickAndUploadImage(ctrl, fileName),
                      icon: const Icon(Icons.upload, size: 18),
                      label: Text(hasImage ? 'Cambiar imagen' : 'Subir imagen'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF64FFDA),
                        foregroundColor: const Color(0xFF0A0E14),
                        minimumSize: const Size(double.infinity, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    if (hasImage) ...[
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: () => setState(() => ctrl.text = ''),
                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                        label: const Text('Quitar', style: TextStyle(color: Colors.red, fontSize: 12)),
                        style: TextButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImage(TextEditingController ctrl, String fileName) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
      if (picked == null) return;

      // Mostrar loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subiendo imagen...'), duration: Duration(seconds: 10)),
        );
      }

      final bytes = await picked.readAsBytes();
      final url = await SupabaseService.instance.uploadImage(fileName, Uint8List.fromList(bytes));

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (url != null) {
          setState(() => ctrl.text = url);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imagen subida'), backgroundColor: Color(0xFF4CAF50)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _textField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF64FFDA)),
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _numberField(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: Colors.white54, size: 20),
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
          ),
          Text('$value', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Color(0xFF64FFDA), size: 20),
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }

  Widget _dropdownField(String label, int value, Map<int, String> options, ValueChanged<int?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8)))),
          DropdownButton<int>(
            value: value,
            dropdownColor: const Color(0xFF1A1E25),
            style: const TextStyle(color: Colors.white),
            items: options.entries.map((e) =>
              DropdownMenuItem(value: e.key, child: Text(e.value)),
            ).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF64FFDA),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _colorButton(String label, Color color, ValueChanged<Color> onPick) {
    return GestureDetector(
      onTap: () => _pickColor(label, color, onPick),
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white30),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}

// ============================================================
// TAB 2: ÁREAS Y MESAS
// ============================================================
class _AreasTab extends StatefulWidget {
  const _AreasTab();

  @override
  State<_AreasTab> createState() => _AreasTabState();
}

class _AreasTabState extends State<_AreasTab> {
  List<AreaConfig> _areas = [];
  List<TableDefinition> _tables = [];

  @override
  void initState() {
    super.initState();
    _areas = List.from(AppConfig.instance.areas);
    _tables = List.from(AppConfig.instance.tables);
  }

  Future<void> _save() async {
    AppConfig.instance.areas = _areas;
    AppConfig.instance.tables = _tables;
    try {
      await AppConfig.instance.saveToLocal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Áreas y mesas guardadas con éxito'), backgroundColor: Color(0xFF64FFDA)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar áreas y mesas: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _addArea() {
    final id = 'area_${DateTime.now().millisecondsSinceEpoch}';
    final num = _areas.length + 1;
    setState(() {
      _areas.add(AreaConfig(
        id: id,
        nombre: 'area_$num',
        nombreDisplay: 'Área $num',
        capacidadReal: 20,
        capacidadFrontend: 16, // 80% de 20
        horaInicio: '12:00',
        horaFin: '23:00',
      ));
    });
  }

  void _editArea(int index) {
    final area = _areas[index];
    final displayCtrl = TextEditingController(text: area.nombreDisplay);
    final realCapCtrl = TextEditingController(text: '${area.capacidadReal}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1E25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Editar Área', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dialogTextField('Nombre del área', displayCtrl),
              const SizedBox(height: 4),
              _dialogTextField('Capacidad (personas)', realCapCtrl),
              const SizedBox(height: 8),
              Text(
                'Cuántas personas entran en total en esta zona del restaurante. El sistema reserva un 80% y deja el 20% para imprevistos.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final realCap = int.tryParse(realCapCtrl.text) ?? area.capacidadReal;
              final frontendCap = (realCap * 0.8).round();
              final slug = displayCtrl.text
                  .toLowerCase()
                  .replaceAll(RegExp(r'[áà]'), 'a')
                  .replaceAll(RegExp(r'[éè]'), 'e')
                  .replaceAll(RegExp(r'[íì]'), 'i')
                  .replaceAll(RegExp(r'[óò]'), 'o')
                  .replaceAll(RegExp(r'[úù]'), 'u')
                  .replaceAll(RegExp(r'[ñ]'), 'n')
                  .replaceAll(RegExp(r'[^a-z0-9]'), '_')
                  .replaceAll(RegExp(r'_+'), '_');
              setState(() {
                _areas[index] = AreaConfig(
                  id: area.id,
                  nombre: slug.isNotEmpty ? slug : area.nombre,
                  nombreDisplay: displayCtrl.text,
                  capacidadReal: realCap,
                  capacidadFrontend: frontendCap,
                  horaInicio: area.horaInicio,
                  horaFin: area.horaFin,
                );
              });
              Navigator.pop(ctx);
            },
            child: const Text('Guardar', style: TextStyle(color: Color(0xFF64FFDA))),
          ),
        ],
      ),
    );
  }

  void _addTable(String areaName) {
    final id = 'mesa_${DateTime.now().millisecondsSinceEpoch}';
    final tablesInArea = _tables.where((t) => t.area == areaName).length;
    setState(() {
      _tables.add(TableDefinition(
        id: id,
        nombre: 'Mesa ${tablesInArea + 1}',
        area: areaName,
        minCapacidad: 2,
        maxCapacidad: 4,
        cantidad: 1,
      ));
    });
  }

  void _editTable(int index) {
    final table = _tables[index];
    final nameCtrl = TextEditingController(text: table.nombre);
    final minCtrl = TextEditingController(text: '${table.minCapacidad}');
    final maxCtrl = TextEditingController(text: '${table.maxCapacidad}');
    final qtyCtrl = TextEditingController(text: '${table.cantidad}');
    bool vip = table.esVip;
    bool blockable = table.bloqueable;
    String shape = table.shape;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1E25),
          title: const Text('Editar Mesa', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogTextField('Nombre', nameCtrl),
                _dialogTextField('Min capacidad', minCtrl),
                _dialogTextField('Max capacidad', maxCtrl),
                _dialogTextField('Cantidad', qtyCtrl),
                Row(
                  children: [
                    Text('Forma: ', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                    DropdownButton<String>(
                      value: shape,
                      dropdownColor: const Color(0xFF1A1E25),
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(value: 'rect', child: Text('Rectangular')),
                        DropdownMenuItem(value: 'circle', child: Text('Circular')),
                        DropdownMenuItem(value: 'square', child: Text('Cuadrada')),
                      ],
                      onChanged: (v) => setDialogState(() => shape = v!),
                    ),
                  ],
                ),
                SwitchListTile(
                  title: const Text('VIP', style: TextStyle(color: Colors.white)),
                  value: vip,
                  onChanged: (v) => setDialogState(() => vip = v),
                  activeColor: const Color(0xFF64FFDA),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  title: const Text('Bloqueable', style: TextStyle(color: Colors.white)),
                  value: blockable,
                  onChanged: (v) => setDialogState(() => blockable = v),
                  activeColor: const Color(0xFF64FFDA),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                setState(() {
                  _tables[index] = table.copyWith(
                    nombre: nameCtrl.text,
                    minCapacidad: int.tryParse(minCtrl.text) ?? 2,
                    maxCapacidad: int.tryParse(maxCtrl.text) ?? 4,
                    cantidad: int.tryParse(qtyCtrl.text) ?? 1,
                    esVip: vip,
                    bloqueable: blockable,
                    shape: shape,
                  );
                });
                Navigator.pop(ctx);
              },
              child: const Text('Guardar', style: TextStyle(color: Color(0xFF64FFDA))),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalReal = _areas.fold<int>(0, (sum, a) => sum + a.capacidadReal);
    final totalReservable = _areas.fold<int>(0, (sum, a) => sum + a.capacidadFrontend);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Áreas', style: TextStyle(color: Color(0xFF64FFDA), fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            Text('$totalReal personas | $totalReservable reservables',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFF64FFDA)),
              onPressed: _addArea,
            ),
          ],
        ),
        const SizedBox(height: 8),

        for (int i = 0; i < _areas.length; i++) ...[
          _buildAreaCard(i),
          const SizedBox(height: 8),
        ],

        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: const Text('Guardar Áreas y Mesas'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF64FFDA),
            foregroundColor: const Color(0xFF0A0E14),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildAreaCard(int areaIndex) {
    final area = _areas[areaIndex];
    final areaTables = _tables.asMap().entries.where((e) => e.value.area == area.nombre).toList();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(area.nombreDisplay, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('${area.capacidadReal} personas | ${area.capacidadFrontend} reservables',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white54, size: 18),
                onPressed: () => _editArea(areaIndex),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18),
                onPressed: () {
                  setState(() {
                    _tables.removeWhere((t) => t.area == area.nombre);
                    _areas.removeAt(areaIndex);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final entry in areaTables)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.table_bar, size: 14, color: entry.value.esVip ? Colors.amber : Colors.white38),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${entry.value.nombre}  (${entry.value.minCapacidad}-${entry.value.maxCapacidad}p x${entry.value.cantidad})',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 14, color: Colors.white38),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () => _editTable(entry.key),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 14, color: Colors.redAccent),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.only(left: 8),
                    onPressed: () => setState(() => _tables.removeAt(entry.key)),
                  ),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: () => _addTable(area.nombre),
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Agregar mesa', style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF64FFDA)),
          ),
        ],
      ),
    );
  }

  Widget _dialogTextField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF64FFDA)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}

// ============================================================
// TAB 3: HORARIOS (unchanged)
// ============================================================
class _HorariosTab extends StatefulWidget {
  const _HorariosTab();

  @override
  State<_HorariosTab> createState() => _HorariosTabState();
}

class _HorariosTabState extends State<_HorariosTab> {
  List<OperatingHours> _hours = [];

  static const _dayNames = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

  @override
  void initState() {
    super.initState();
    _hours = List.from(AppConfig.instance.operatingHours);
  }

  Future<void> _save() async {
    AppConfig.instance.operatingHours = _hours;
    try {
      await AppConfig.instance.saveToLocal();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Horarios guardados con éxito'), backgroundColor: Color(0xFF64FFDA)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar horarios: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _addHour() {
    final areas = AppConfig.instance.areas;
    if (areas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero creá un área')),
      );
      return;
    }

    int day = 1;
    String area = areas.first.nombre;
    final startCtrl = TextEditingController(text: '12:00');
    final endCtrl = TextEditingController(text: '15:00');
    int interval = 30;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1E25),
          title: const Text('Nuevo Horario', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<int>(
                  value: day,
                  dropdownColor: const Color(0xFF1A1E25),
                  style: const TextStyle(color: Colors.white),
                  isExpanded: true,
                  items: List.generate(7, (i) => DropdownMenuItem(value: i, child: Text(_dayNames[i]))),
                  onChanged: (v) => setDialogState(() => day = v!),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: area,
                  dropdownColor: const Color(0xFF1A1E25),
                  style: const TextStyle(color: Colors.white),
                  isExpanded: true,
                  items: areas.map((a) => DropdownMenuItem(value: a.nombre, child: Text(a.nombreDisplay))).toList(),
                  onChanged: (v) => setDialogState(() => area = v!),
                ),
                const SizedBox(height: 8),
                _dialogTextField2('Hora inicio (HH:MM)', startCtrl),
                _dialogTextField2('Hora fin (HH:MM)', endCtrl),
                Row(
                  children: [
                    Text('Intervalo: ', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                    DropdownButton<int>(
                      value: interval,
                      dropdownColor: const Color(0xFF1A1E25),
                      style: const TextStyle(color: Colors.white),
                      items: [15, 30, 45, 60].map((v) => DropdownMenuItem(value: v, child: Text('$v min'))).toList(),
                      onChanged: (v) => setDialogState(() => interval = v!),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                final id = 'h_${DateTime.now().millisecondsSinceEpoch}';
                setState(() {
                  _hours.add(OperatingHours(
                    id: id,
                    diaSemana: day,
                    area: area,
                    horaInicio: startCtrl.text,
                    horaFin: endCtrl.text,
                    intervaloMinutos: interval,
                  ));
                });
                Navigator.pop(ctx);
              },
              child: const Text('Agregar', style: TextStyle(color: Color(0xFF64FFDA))),
            ),
          ],
        ),
      ),
    );
  }

  void _editHour(int index) {
    final h = _hours[index];
    int day = h.diaSemana;
    String area = h.area;
    final startCtrl = TextEditingController(text: h.horaInicio);
    final endCtrl = TextEditingController(text: h.horaFin);
    int interval = h.intervaloMinutos;

    final areas = AppConfig.instance.areas;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1E25),
          title: const Text('Editar Horario', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<int>(
                  value: day,
                  dropdownColor: const Color(0xFF1A1E25),
                  style: const TextStyle(color: Colors.white),
                  isExpanded: true,
                  items: List.generate(7, (i) => DropdownMenuItem(value: i, child: Text(_dayNames[i]))),
                  onChanged: (v) => setDialogState(() => day = v!),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: areas.any((a) => a.nombre == area) ? area : areas.first.nombre,
                  dropdownColor: const Color(0xFF1A1E25),
                  style: const TextStyle(color: Colors.white),
                  isExpanded: true,
                  items: areas.map((a) => DropdownMenuItem(value: a.nombre, child: Text(a.nombreDisplay))).toList(),
                  onChanged: (v) => setDialogState(() => area = v!),
                ),
                const SizedBox(height: 8),
                _dialogTextField2('Hora inicio (HH:MM)', startCtrl),
                _dialogTextField2('Hora fin (HH:MM)', endCtrl),
                Row(
                  children: [
                    Text('Intervalo: ', style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                    DropdownButton<int>(
                      value: interval,
                      dropdownColor: const Color(0xFF1A1E25),
                      style: const TextStyle(color: Colors.white),
                      items: [15, 30, 45, 60].map((v) => DropdownMenuItem(value: v, child: Text('$v min'))).toList(),
                      onChanged: (v) => setDialogState(() => interval = v!),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                setState(() {
                  _hours[index] = OperatingHours(
                    id: h.id,
                    diaSemana: day,
                    area: area,
                    horaInicio: startCtrl.text,
                    horaFin: endCtrl.text,
                    intervaloMinutos: interval,
                  );
                });
                Navigator.pop(ctx);
              },
              child: const Text('Guardar', style: TextStyle(color: Color(0xFF64FFDA))),
            ),
          ],
        ),
      ),
    );
  }

  void _copyDay(int fromDay) {
    final toCopy = _hours.where((h) => h.diaSemana == fromDay).toList();
    if (toCopy.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) {
        final selected = <int>{};
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xFF1A1E25),
            title: Text('Copiar desde ${_dayNames[fromDay]}', style: const TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(7, (i) {
                if (i == fromDay) return const SizedBox.shrink();
                return CheckboxListTile(
                  title: Text(_dayNames[i], style: const TextStyle(color: Colors.white)),
                  value: selected.contains(i),
                  onChanged: (v) => setDialogState(() {
                    if (v == true) selected.add(i); else selected.remove(i);
                  }),
                  activeColor: const Color(0xFF64FFDA),
                );
              }),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              TextButton(
                onPressed: () {
                  setState(() {
                    for (final targetDay in selected) {
                      _hours.removeWhere((h) => h.diaSemana == targetDay);
                      for (final source in toCopy) {
                        _hours.add(OperatingHours(
                          id: 'h_${DateTime.now().millisecondsSinceEpoch}_${targetDay}_${source.area}',
                          diaSemana: targetDay,
                          area: source.area,
                          horaInicio: source.horaInicio,
                          horaFin: source.horaFin,
                          intervaloMinutos: source.intervaloMinutos,
                        ));
                      }
                    }
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Copiar', style: TextStyle(color: Color(0xFF64FFDA))),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final byDay = <int, List<MapEntry<int, OperatingHours>>>{};
    for (int i = 0; i < _hours.length; i++) {
      byDay.putIfAbsent(_hours[i].diaSemana, () => []);
      byDay[_hours[i].diaSemana]!.add(MapEntry(i, _hours[i]));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Horarios de Operación', style: TextStyle(color: Color(0xFF64FFDA), fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Color(0xFF64FFDA)),
              onPressed: _addHour,
            ),
          ],
        ),
        const SizedBox(height: 8),

        for (int day = 0; day < 7; day++) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_dayNames[day], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16, color: Colors.white54),
                      tooltip: 'Copiar a otros días',
                      onPressed: byDay[day]?.isNotEmpty == true ? () => _copyDay(day) : null,
                    ),
                  ],
                ),
                if (byDay[day] == null || byDay[day]!.isEmpty)
                  Text('Sin horarios', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12))
                else
                  for (final entry in byDay[day]!)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            '${entry.value.area}: ${entry.value.horaInicio} - ${entry.value.horaFin} (${entry.value.intervaloMinutos}min)',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 14, color: Colors.white38),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            onPressed: () => _editHour(entry.key),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 14, color: Colors.redAccent),
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.only(left: 8),
                            onPressed: () => setState(() => _hours.removeAt(entry.key)),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save),
          label: const Text('Guardar Horarios'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF64FFDA),
            foregroundColor: const Color(0xFF0A0E14),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _dialogTextField2(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF64FFDA)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}

// ============================================================
// TAB 4: OPERACIONES (enhanced with all features)
// ============================================================
class _OperacionesTab extends StatefulWidget {
  const _OperacionesTab();

  @override
  State<_OperacionesTab> createState() => _OperacionesTabState();
}

class _OperacionesTabState extends State<_OperacionesTab> {
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _reservations = [];
  List<Map<String, dynamic>> _reminders = [];
  List<Map<String, dynamic>> _waitlist = [];
  bool _loading = false;
  int _autoReleased = 0;
  int _expiredConfirmations = 0;

  // Banner
  bool _bannerEnabled = false;
  final _bannerTextCtrl = TextEditingController();
  DateTime? _bannerDate;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _loadBanner();
  }

  @override
  void dispose() {
    _bannerTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      // Process auto-release and expired confirmations
      _autoReleased = await AutoReleaseService.processAutoRelease();
      _expiredConfirmations = await CustomerConfirmationService.processExpiredConfirmations();

      _reservations = await LocalReservationService.getReservationsForDate(_selectedDate);
      LocalReservationService.clearReservationsCache();
      _reminders = await ReminderService.getPendingReminders();
      _waitlist = await WaitlistService.getWaitlistForDate(_selectedDate);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadBanner() async {
    final settings = await LocalSiteStatusService.fetchBannerSettings();
    if (mounted) {
      setState(() {
        _bannerEnabled = settings.enabled;
        _bannerTextCtrl.text = settings.message;
        _bannerDate = settings.reopenDate;
      });
    }
  }

  Future<void> _saveBanner() async {
    try {
      await LocalSiteStatusService.saveBannerSettings(
        enabled: _bannerEnabled,
        reopenDate: _bannerDate,
        message: _bannerTextCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner guardado con éxito'), backgroundColor: Color(0xFF64FFDA)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar banner: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'confirmada': return 'Confirmada';
      case 'pendiente_confirmacion': return 'Pend. Confirm.';
      case 'en_mesa': return 'En mesa';
      case 'completada': return 'Completada';
      case 'no_show': return 'No show';
      case 'cancelada': return 'Cancelada';
      default: return status ?? '?';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'confirmada': return Colors.blue;
      case 'pendiente_confirmacion': return Colors.purple;
      case 'en_mesa': return Colors.green;
      case 'completada': return Colors.teal;
      case 'no_show': return Colors.orange;
      case 'cancelada': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Auto-release / expired info
        if (_autoReleased > 0 || _expiredConfirmations > 0)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    [
                      if (_autoReleased > 0) '$_autoReleased reserva(s) marcada(s) no-show (auto-release)',
                      if (_expiredConfirmations > 0) '$_expiredConfirmations confirmación(es) expirada(s)',
                    ].join('\n'),
                    style: const TextStyle(color: Colors.amber, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        // Date picker
        _sectionTitle('Reservas del día'),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: () {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                _loadAll();
              },
            ),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) {
                    _selectedDate = picked;
                    _loadAll();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: () {
                _selectedDate = _selectedDate.add(const Duration(days: 1));
                _loadAll();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_loading)
          const Center(child: CircularProgressIndicator(color: Color(0xFF64FFDA)))
        else if (_reservations.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            child: Text('No hay reservas para este día',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5))),
          )
        else
          for (final r in _reservations) _buildReservationCard(r),

        // Reminders section
        if (_reminders.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionTitle('Recordatorios Pendientes'),
          for (final r in _reminders) _buildReminderCard(r),
        ],

        // Waitlist section
        if (_waitlist.isNotEmpty) ...[
          const SizedBox(height: 24),
          _sectionTitle('Lista de Espera'),
          for (final w in _waitlist) _buildWaitlistCard(w),
        ],

        const SizedBox(height: 32),

        // Blocks section
        _sectionTitle('Bloqueos'),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await LocalBlockService.blockDay(_selectedDate, reason: 'Bloqueado por admin');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Día ${_selectedDate.day}/${_selectedDate.month} bloqueado')),
                    );
                  }
                },
                icon: const Icon(Icons.block, size: 16),
                label: const Text('Bloquear día'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await LocalBlockService.unblockDay(_selectedDate);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Día ${_selectedDate.day}/${_selectedDate.month} desbloqueado')),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Desbloquear día'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Banner section
        _sectionTitle('Banner de cierre'),
        SwitchListTile(
          title: const Text('Banner activo', style: TextStyle(color: Colors.white)),
          value: _bannerEnabled,
          onChanged: (v) => setState(() => _bannerEnabled = v),
          activeColor: const Color(0xFF64FFDA),
          contentPadding: EdgeInsets.zero,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: _bannerTextCtrl,
            style: const TextStyle(color: Colors.white),
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Mensaje del banner',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF64FFDA)),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
        Row(
          children: [
            Text(
              _bannerDate != null
                  ? 'Reapertura: ${_bannerDate!.day}/${_bannerDate!.month}/${_bannerDate!.year}'
                  : 'Sin fecha de reapertura',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
            const Spacer(),
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _bannerDate = picked);
              },
              child: const Text('Elegir fecha', style: TextStyle(color: Color(0xFF64FFDA))),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _saveBanner,
          icon: const Icon(Icons.save),
          label: const Text('Guardar Banner'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF64FFDA),
            foregroundColor: const Color(0xFF0A0E14),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),

        const SizedBox(height: 32),

        // Manual del sistema
        _sectionTitle('Documentación'),
        ElevatedButton.icon(
          onPressed: () => CapacityDocPdfService.generateAndOpen(),
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Manual Técnico (PDF)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => UserGuidePdfService.generateAndOpen(),
          icon: const Icon(Icons.menu_book),
          label: const Text('Guía de Uso Completa (PDF)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF64FFDA).withValues(alpha: 0.15),
            foregroundColor: const Color(0xFF64FFDA),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF64FFDA)),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> r) {
    final status = r['estado'] as String?;
    final lateMinutes = AutoReleaseService.getLateMinutes(r);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _statusColor(status).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${r['hora']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_statusLabel(status), style: TextStyle(color: _statusColor(status), fontSize: 11)),
              ),
              if (lateMinutes != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Tarde - $lateMinutes min', style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w600)),
                ),
              ],
              const Spacer(),
              Text('${r['personas']}p', style: const TextStyle(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 4),
          Text('${r['nombre']} - ${r['telefono']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          if (r['codigo_confirmacion'] != null)
            Text('Código: ${r['codigo_confirmacion']}', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
          if (r['comentarios'] != null && (r['comentarios'] as String).isNotEmpty)
            Text('${r['comentarios']}', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11, fontStyle: FontStyle.italic)),

          // Actions for pendiente_confirmacion
          if (status == 'pendiente_confirmacion') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _actionButton('Confirmar', Icons.check_circle, Colors.blue, () async {
                  await CustomerConfirmationService.adminConfirm(r['id']);
                  _loadAll();
                }),
                const SizedBox(width: 8),
                _actionButton('Cancelar', Icons.cancel, Colors.red, () async {
                  await LocalReservationService.cancelReservation(r['id']);
                  _loadAll();
                }),
              ],
            ),
          ],

          // Actions for confirmada
          if (status == 'confirmada') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _actionButton('Llegó', Icons.check, Colors.green, () async {
                  await LocalReservationService.markCustomerArrived(r['id']);
                  _loadAll();
                }),
                const SizedBox(width: 8),
                _actionButton('No show', Icons.person_off, Colors.orange, () async {
                  await LocalReservationService.markAsNoShow(r['id']);
                  _loadAll();
                }),
                const SizedBox(width: 8),
                _actionButton('Cancelar', Icons.cancel, Colors.red, () async {
                  await LocalReservationService.cancelReservation(r['id']);
                  // Check waitlist matches
                  final matches = await WaitlistService.findWaitlistMatches(
                    fecha: _selectedDate,
                    hora: r['hora'],
                  );
                  if (matches.isNotEmpty && mounted) {
                    _showWaitlistMatches(matches, r['hora']);
                  }
                  _loadAll();
                }),
              ],
            ),
          ],

          if (status == 'en_mesa') ...[
            const SizedBox(height: 8),
            _actionButton('Completar', Icons.done_all, Colors.teal, () async {
              await LocalReservationService.completeReservation(r['id']);
              _loadAll();
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${r['nombre']} - ${r['fecha']} ${r['hora']}',
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                Text('${r['personas']}p - Tel: ${r['telefono']}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 22),
            tooltip: 'Enviar recordatorio por WhatsApp',
            onPressed: () async {
              try {
                final fecha = DateTime.parse(r['fecha']);
                final message = WhatsAppService.buildReminderMessage(
                  customerName: r['nombre'],
                  confirmationCode: r['codigo_confirmacion'] ?? '',
                  reservationDate: fecha,
                  reservationTime: r['hora'],
                  guests: r['personas'],
                );
                await WhatsAppService.sendMessage(
                  phoneNumber: r['telefono'],
                  message: message,
                );
                await ReminderService.markReminderSent(r['id']);
                _loadAll();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWaitlistCard(Map<String, dynamic> w) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.hourglass_top, color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${w['nombre']} - ${w['hora']}',
                    style: const TextStyle(color: Colors.white, fontSize: 13)),
                Text('${w['personas']}p - Tel: ${w['telefono']}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
              ],
            ),
          ),
          if (w['notificado'] == true)
            const Icon(Icons.check, color: Colors.green, size: 16)
          else
            IconButton(
              icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
              tooltip: 'Notificar disponibilidad',
              onPressed: () async {
                try {
                  final fecha = DateTime.parse(w['fecha']);
                  final message = WhatsAppService.buildWaitlistNotificationMessage(
                    customerName: w['nombre'],
                    date: fecha,
                    time: w['hora'],
                    guests: w['personas'],
                  );
                  await WhatsAppService.sendMessage(
                    phoneNumber: w['telefono'],
                    message: message,
                  );
                  await WaitlistService.markNotified(w['id']);
                  _loadAll();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
            onPressed: () async {
              await WaitlistService.removeFromWaitlist(w['id']);
              _loadAll();
            },
          ),
        ],
      ),
    );
  }

  void _showWaitlistMatches(List<Map<String, dynamic>> matches, String hora) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1E25),
        title: const Text('Lista de espera', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hay ${matches.length} persona(s) esperando para las $hora:',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
            const SizedBox(height: 12),
            for (final m in matches.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${m['nombre']} - ${m['personas']}p',
                          style: const TextStyle(color: Colors.white, fontSize: 13)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 18),
                      onPressed: () async {
                        try {
                          final fecha = DateTime.parse(m['fecha']);
                          final message = WhatsAppService.buildWaitlistNotificationMessage(
                            customerName: m['nombre'],
                            date: fecha,
                            time: m['hora'],
                            guests: m['personas'],
                          );
                          await WhatsAppService.sendMessage(
                            phoneNumber: m['telefono'],
                            message: message,
                          );
                          await WaitlistService.markNotified(m['id']);
                        } catch (_) {}
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: Color(0xFF64FFDA))),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(
        color: Color(0xFF64FFDA), fontSize: 16, fontWeight: FontWeight.w600,
      )),
    );
  }
}
