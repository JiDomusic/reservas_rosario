import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/table_definition.dart';
import '../services/table_map_service.dart';
import '../widgets/table_map_editor.dart';
import '../widgets/table_map_view.dart';

class TableMapScreen extends StatefulWidget {
  const TableMapScreen({super.key});

  @override
  State<TableMapScreen> createState() => _TableMapScreenState();
}

class _TableMapScreenState extends State<TableMapScreen> {
  bool _isEditorMode = false;
  late List<TableDefinition> _tables;
  String _selectedArea = '';
  DateTime _selectedDate = DateTime.now();
  String _selectedTime = '12:00';
  Map<String, TableAssignment> _assignments = {};
  bool _loadingStatuses = false;

  @override
  void initState() {
    super.initState();
    _tables = [];
    final areas = AppConfig.instance.areas;
    if (areas.isNotEmpty) {
      _selectedArea = areas.first.nombre;
    }
    _loadTables();
  }

  Future<void> _loadTables() async {
    final tables = await TableMapService.expandTablesForMap(AppConfig.instance.tables);
    if (mounted) {
      setState(() => _tables = tables);
    }
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    setState(() => _loadingStatuses = true);
    final assignments = await TableMapService.getSmartAssignments(_selectedDate, _selectedTime);
    if (mounted) {
      setState(() {
        _assignments = assignments;
        _loadingStatuses = false;
      });
    }
  }

  Future<void> _savePositions() async {
    await TableMapService.saveTablePositions(_tables);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Posiciones guardadas'), backgroundColor: Color(0xFF64FFDA)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final areas = AppConfig.instance.areas;

    return Column(
      children: [
        // Controls bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(0xFF1A1E25),
          child: Column(
            children: [
              Row(
                children: [
                  // Mode toggle
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Live', style: TextStyle(fontSize: 12))),
                      ButtonSegment(value: true, label: Text('Editor', style: TextStyle(fontSize: 12))),
                    ],
                    selected: {_isEditorMode},
                    onSelectionChanged: (v) => setState(() => _isEditorMode = v.first),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const Color(0xFF64FFDA).withValues(alpha: 0.2);
                        }
                        return Colors.transparent;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) return const Color(0xFF64FFDA);
                        return Colors.white54;
                      }),
                    ),
                  ),
                  const Spacer(),
                  if (_isEditorMode)
                    TextButton.icon(
                      onPressed: _savePositions,
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('Guardar', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF64FFDA)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Area tabs
              if (areas.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: areas.map((area) {
                      final isSelected = area.nombre == _selectedArea;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(area.nombreDisplay, style: const TextStyle(fontSize: 11)),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedArea = area.nombre),
                          selectedColor: const Color(0xFF64FFDA).withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF64FFDA) : Colors.white54,
                          ),
                          backgroundColor: Colors.transparent,
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF64FFDA) : Colors.white24,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              if (!_isEditorMode) ...[
                const SizedBox(height: 8),
                // Time selector for live view
                Row(
                  children: [
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 7)),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) {
                          _selectedDate = picked;
                          _loadStatuses();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_selectedDate.day}/${_selectedDate.month}',
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        final parts = _selectedTime.split(':');
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: int.parse(parts[0]),
                            minute: int.parse(parts[1]),
                          ),
                        );
                        if (picked != null) {
                          _selectedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                          _loadStatuses();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _selectedTime,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Color(0xFF64FFDA), size: 20),
                      onPressed: _loadStatuses,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        // Map content
        Expanded(
          child: _isEditorMode
              ? TableMapEditor(
                  tables: _tables,
                  selectedArea: _selectedArea,
                  onTablesChanged: (updated) => setState(() => _tables = updated),
                )
              : _loadingStatuses
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF64FFDA)))
                  : TableMapView(
                      tables: _tables,
                      selectedArea: _selectedArea,
                      assignments: _assignments,
                      onTableTap: (table) => _showTableDetail(table),
                    ),
        ),
      ],
    );
  }

  void _showTableDetail(TableDefinition table) {
    final assignment = _assignments[table.id] ?? const TableAssignment(status: TableStatus.free);
    final color = TableMapService.statusColor(assignment.status);
    final res = assignment.reservation;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1E25),
        title: Text(table.nombre, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(TableMapService.statusLabel(assignment.status),
                    style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            _detailRow('Capacidad mesa', '${table.minCapacidad}-${table.maxCapacidad} personas'),
            _detailRow('Área', table.area),
            if (table.esVip) _detailRow('Tipo', 'VIP'),
            if (res != null) ...[
              const Divider(color: Colors.white24, height: 20),
              _detailRow('Cliente', res['nombre'] ?? ''),
              _detailRow('Personas', '${res['personas'] ?? '?'}'),
              _detailRow('Hora', res['hora'] ?? ''),
              _detailRow('Estado', res['estado'] ?? ''),
              if (assignment.isCombined)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.link, color: Colors.orangeAccent, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Juntada con: ${assignment.combinedWith!.join(", ")}',
                          style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              if (assignment.wastedSeats > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        assignment.wastedSeats <= 2 ? Icons.check_circle : Icons.warning_amber,
                        color: assignment.wastedSeats <= 2 ? Colors.green : Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        assignment.wastedSeats == 1
                            ? '1 silla libre'
                            : '${assignment.wastedSeats} sillas libres',
                        style: TextStyle(
                          color: assignment.wastedSeats <= 2 ? Colors.green : Colors.amber,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}
