import 'package:flutter/material.dart';
import '../models/table_definition.dart';

class TableMapEditor extends StatefulWidget {
  final List<TableDefinition> tables;
  final String selectedArea;
  final ValueChanged<List<TableDefinition>> onTablesChanged;

  const TableMapEditor({
    super.key,
    required this.tables,
    required this.selectedArea,
    required this.onTablesChanged,
  });

  @override
  State<TableMapEditor> createState() => _TableMapEditorState();
}

class _TableMapEditorState extends State<TableMapEditor> {
  String? _selectedTableId;

  List<TableDefinition> get _areaTables =>
      widget.tables.where((t) => t.area == widget.selectedArea && t.activo).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(0xFF1A1E25),
          child: Row(
            children: [
              const Icon(Icons.drag_indicator, color: Colors.white54, size: 16),
              const SizedBox(width: 8),
              Text('Arrastrá las mesas a su posición',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
              const Spacer(),
              if (_selectedTableId != null)
                Text(
                  'Seleccionada: ${_areaTables.where((t) => t.id == _selectedTableId).firstOrNull?.nombre ?? ""}',
                  style: const TextStyle(color: Color(0xFF64FFDA), fontSize: 12),
                ),
            ],
          ),
        ),
        // Canvas
        Expanded(
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(200),
            minScale: 0.5,
            maxScale: 3.0,
            child: Container(
              width: 1000,
              height: 800,
              decoration: BoxDecoration(
                color: const Color(0xFF0D1117),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Stack(
                children: [
                  // Grid lines
                  CustomPaint(
                    size: const Size(1000, 800),
                    painter: _GridPainter(),
                  ),
                  // Tables
                  for (final table in _areaTables)
                    Positioned(
                      left: table.posX,
                      top: table.posY,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTableId = table.id),
                        onPanUpdate: (details) {
                          _moveTable(table.id, details.delta.dx, details.delta.dy);
                        },
                        child: _buildTableWidget(table),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _moveTable(String tableId, double dx, double dy) {
    final updated = widget.tables.map((t) {
      if (t.id == tableId) {
        return t.copyWith(
          posX: (t.posX + dx).clamp(0, 920),
          posY: (t.posY + dy).clamp(0, 720),
        );
      }
      return t;
    }).toList();
    widget.onTablesChanged(updated);
  }

  Widget _buildTableWidget(TableDefinition table) {
    final isSelected = _selectedTableId == table.id;
    final isCircle = table.shape == 'circle';

    return Container(
      width: table.width,
      height: table.height,
      decoration: BoxDecoration(
        color: table.esVip
            ? Colors.amber.withValues(alpha: 0.3)
            : const Color(0xFF64FFDA).withValues(alpha: 0.15),
        borderRadius: isCircle ? null : BorderRadius.circular(8),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        border: Border.all(
          color: isSelected ? Colors.white : (table.esVip ? Colors.amber : const Color(0xFF64FFDA)),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [BoxShadow(color: Colors.white.withValues(alpha: 0.2), blurRadius: 8)]
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              table.nombre,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${table.minCapacidad}-${table.maxCapacidad}p',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 8),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
