import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/supabase_service.dart';

class SuperAdminScreen extends StatefulWidget {
  const SuperAdminScreen({super.key});

  @override
  State<SuperAdminScreen> createState() => _SuperAdminScreenState();
}

class _SuperAdminScreenState extends State<SuperAdminScreen> {
  static const _baseClientUrl = 'https://reserva-jj.web.app';
  List<Map<String, dynamic>> _tenants = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    setState(() => _loading = true);
    try {
      final tenants = await SupabaseService.instance.getAllTenants();
      if (mounted) setState(() { _tenants = tenants; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _createRestaurant() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController(text: _generateTempPassword());

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1E25),
        title: const Text('Nuevo Restaurante', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecor('Nombre del restaurante', Icons.restaurant),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecor('Email del administrador', Icons.email),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                decoration: _inputDecor('Contraseña temporal', Icons.lock),
              ),
              const SizedBox(height: 8),
              Text(
                'El administrador puede cambiar la contraseña después',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64FFDA)),
            child: const Text('Crear', style: TextStyle(color: Color(0xFF0A0E14))),
          ),
        ],
      ),
    );

    if (result != true) return;

    final name = nameCtrl.text.trim();
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text;

    if (name.isEmpty || email.isEmpty || password.length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Completá todos los campos (contraseña min 6 caracteres)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Generar tenant_id desde el nombre
    final tenantId = _nameToTenantId(name);

    if (mounted) {
      _showProgress('Creando restaurante...');
    }

    try {
      // 1. Crear usuario auth (sin afectar sesión actual)
      final userId = await SupabaseService.instance.createAuthUser(email, password);

      // 2. Crear tenant en la base de datos
      await SupabaseService.instance.createRestaurant(
        tenantId: tenantId,
        restaurantName: name,
        adminUserId: userId,
        adminEmail: email,
      );

      if (mounted) Navigator.pop(context); // cerrar progress

      // Guardar credenciales localmente para referencia del super admin
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sa_cred_email_$tenantId', email);
      await prefs.setString('sa_cred_pass_$tenantId', password);

      // Mostrar resultado con el link
      if (mounted) {
        _showSuccess(
          tenantId: tenantId,
          restaurantName: name,
          email: email,
          password: password,
        );
      }

      _loadTenants();
    } catch (e) {
      if (mounted) Navigator.pop(context); // cerrar progress
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showProgress(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1E25),
        content: Row(
          children: [
            const CircularProgressIndicator(color: Color(0xFF64FFDA)),
            const SizedBox(width: 20),
            Text(message, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  void _showSuccess({
    required String tenantId,
    required String restaurantName,
    required String email,
    required String password,
  }) {
    final link = '$_baseClientUrl/$tenantId';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1E25),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF64FFDA), size: 28),
            SizedBox(width: 8),
            Text('Restaurante Creado', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _infoRow('Restaurante', restaurantName),
              _infoRow('Tenant ID', tenantId),
              _infoRow('Email admin', email),
              _infoRow('Contraseña', password),
              const Divider(color: Colors.white24),
              const SizedBox(height: 8),
              const Text('Link para el cliente:',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(link,
                          style: const TextStyle(
                              color: Color(0xFF64FFDA),
                              fontFamily: 'monospace',
                              fontSize: 12)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.white54, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: link));
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Link copiado')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enviále estos datos al cliente por WhatsApp.\n'
                'El cliente entra al link, se loguea con email y contraseña, '
                'y configura todo desde el onboarding.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final text = 'Hola! Tu sistema de reservas está listo.\n\n'
                  'Link: $link\n'
                  'Email: $email\n'
                  'Contraseña: $password\n\n'
                  'Ingresá al link, logueate y configurá tu restaurante.';
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Mensaje copiado al portapapeles')),
              );
            },
            child: const Text('Copiar mensaje para WhatsApp'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64FFDA)),
            child: const Text('Cerrar', style: TextStyle(color: Color(0xFF0A0E14))),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRestaurant(String tenantId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1E25),
        title: const Text('Eliminar restaurante', style: TextStyle(color: Colors.white)),
        content: Text(
          'Vas a eliminar "$name" y TODOS sus datos (reservas, mesas, horarios).\n\nEsto no se puede deshacer.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await SupabaseService.instance.deleteRestaurant(tenantId);
      _loadTenants();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$name" eliminado')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1E25),
        title: const Text('Super Admin', style: TextStyle(color: Colors.white, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _loadTenants,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createRestaurant,
        backgroundColor: const Color(0xFF64FFDA),
        icon: const Icon(Icons.add_business, color: Color(0xFF0A0E14)),
        label: const Text('Nuevo Restaurante', style: TextStyle(color: Color(0xFF0A0E14), fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF64FFDA)))
          : _tenants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store_mall_directory, size: 80, color: Colors.white.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      Text(
                        'No hay restaurantes',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tocá el botón + para crear el primero',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tenants.length,
                  itemBuilder: (ctx, i) => _buildTenantCard(_tenants[i]),
                ),
    );
  }

  Widget _buildTenantCard(Map<String, dynamic> tenant) {
    final id = tenant['id'] as String;
    final name = tenant['nombre_restaurante'] as String? ?? id;
    final email = tenant['email_contacto'] as String? ?? '';
    final onboarded = tenant['onboarding_completed'] as bool? ?? false;
    final trialEndStr = tenant['trial_end_date'] as String?;
    final trialExtended = tenant['trial_extended'] as bool? ?? false;
    final trialEnd = trialEndStr != null ? DateTime.tryParse(trialEndStr) : null;
    final trialDays = trialEnd != null ? trialEnd.difference(DateTime.now()).inDays : 15;
    final trialExpired = trialDays < 0;
    final link = '$_baseClientUrl/$id';

    return Card(
      color: const Color(0xFF1A1E25),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.restaurant, color: Color(0xFF64FFDA), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(id, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontFamily: 'monospace')),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(email, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: onboarded
                            ? const Color(0xFF4CAF50).withValues(alpha: 0.2)
                            : Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        onboarded ? 'Activo' : 'Pendiente',
                        style: TextStyle(
                          color: onboarded ? const Color(0xFF4CAF50) : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: trialExpired
                            ? Colors.red.withValues(alpha: 0.2)
                            : trialDays <= 3
                                ? Colors.orange.withValues(alpha: 0.2)
                                : const Color(0xFF64FFDA).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            trialExpired ? Icons.timer_off : Icons.timer_outlined,
                            size: 12,
                            color: trialExpired
                                ? Colors.red
                                : trialDays <= 3 ? Colors.orange : const Color(0xFF64FFDA),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            trialExpired
                                ? 'Expirado${trialExtended ? " (ext)" : ""}'
                                : '$trialDays días${trialExtended ? " (ext)" : ""}',
                            style: TextStyle(
                              color: trialExpired
                                  ? Colors.red
                                  : trialDays <= 3 ? Colors.orange : const Color(0xFF64FFDA),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(link,
                        style: const TextStyle(color: Color(0xFF64FFDA), fontSize: 11, fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white54, size: 18),
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copiado')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (email.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.email_outlined, color: Colors.white.withValues(alpha: 0.4), size: 16),
                    const SizedBox(width: 6),
                    Text(email, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showCredentials(id, name),
                  icon: Icon(Icons.key, color: Colors.white.withValues(alpha: 0.6), size: 18),
                  label: Text('Credenciales', style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
                ),
                TextButton.icon(
                  onPressed: () => _deleteRestaurant(id, name),
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                  label: const Text('Eliminar', style: TextStyle(color: Colors.red, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCredentials(String tenantId, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('sa_cred_email_$tenantId') ?? 'No guardado';
    final savedPass = prefs.getString('sa_cred_pass_$tenantId') ?? 'No guardado';
    final link = '$_baseClientUrl/$tenantId';

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1E25),
        title: Text('Credenciales: $name', style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _infoRow('Email', savedEmail),
            _infoRow('Contraseña', savedPass),
            _infoRow('Link', link),
            const SizedBox(height: 12),
            Text(
              'La contraseña es la temporal. Si el admin la cambió, esta ya no es válida.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final text = 'Restaurante: $name\n'
                  'Link: $link\n'
                  'Email: $savedEmail\n'
                  'Contraseña: $savedPass';
              Clipboard.setData(ClipboardData(text: text));
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('Credenciales copiadas')),
              );
            },
            child: const Text('Copiar todo'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64FFDA)),
            child: const Text('Cerrar', style: TextStyle(color: Color(0xFF0A0E14))),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecor(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
      prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.6)),
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
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:', style: const TextStyle(color: Colors.white54, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  String _nameToTenantId(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[áàä]'), 'a')
        .replaceAll(RegExp(r'[éèë]'), 'e')
        .replaceAll(RegExp(r'[íìï]'), 'i')
        .replaceAll(RegExp(r'[óòö]'), 'o')
        .replaceAll(RegExp(r'[úùü]'), 'u')
        .replaceAll(RegExp(r'ñ'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  String _generateTempPassword() {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final buf = StringBuffer();
    for (int i = 0; i < 8; i++) {
      buf.write(chars[(random + i * 17) % chars.length]);
    }
    return buf.toString();
  }
}
