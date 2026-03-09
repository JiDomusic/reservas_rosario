import 'package:flutter/material.dart';
import '../models/table_definition.dart';
import '../services/table_map_service.dart';

class TableMapView extends StatelessWidget {
  final List<TableDefinition> tables;
  final String selectedArea;
  final Map<String, TableAssignment> assignments;
  final ValueChanged<TableDefinition>? onTableTap;

  const TableMapView({
    super.key,
    required this.tables,
    required this.selectedArea,
    required this.assignments,
    this.onTableTap,
  });

  @override
  Widget build(BuildContext context) {
    final areaTables = tables.where((t) => t.area == selectedArea && t.activo).toList();

    return Column(
      children: [
        // Legend
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(0xFF1A1E25),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(TableMapService.statusColor(TableStatus.free), 'Libre'),
              const SizedBox(width: 12),
              _legendDot(TableMapService.statusColor(TableStatus.reserved), 'Reservada'),
              const SizedBox(width: 12),
              _legendDot(TableMapService.statusColor(TableStatus.occupied), 'Ocupada'),
              const SizedBox(width: 12),
              _legendDot(TableMapService.statusColor(TableStatus.vip), 'VIP'),
              const SizedBox(width: 12),
              _legendDot(TableMapService.statusColor(TableStatus.blocked), 'Bloqueada'),
            ],
          ),
        ),
        // Map
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
                  // Grid
                  CustomPaint(
                    size: const Size(1000, 800),
                    painter: _GridPainter(),
                  ),
                  // Tables
                  for (final table in areaTables)
                    Positioned(
                      left: table.posX,
                      top: table.posY,
                      child: GestureDetector(
                        onTap: () => onTableTap?.call(table),
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

  Widget _buildTableWidget(TableDefinition table) {
    final assignment = assignments[table.id] ?? const TableAssignment(status: TableStatus.free);
    final color = TableMapService.statusColor(assignment.status);
    final isCircle = table.shape == 'circle';
    final res = assignment.reservation;
    final personas = res?['personas'] as int?;
    final nombre = res?['nombre'] as String?;

    return Container(
      width: table.width,
      height: table.height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: isCircle ? null : BorderRadius.circular(8),
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        border: Border.all(
          color: color,
          width: assignment.isCombined ? 3 : 2,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                table.nombre,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              if (res != null) ...[
                // Nombre del cliente
                if (nombre != null && nombre.isNotEmpty)
                  Text(
                    nombre.length > 10 ? '${nombre.substring(0, 10)}.' : nombre,
                    style: TextStyle(color: color, fontSize: 7, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                // Personas
                Text(
                  '${personas ?? '?'}p',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 7),
                ),
                // Indicador de mesas combinadas
                if (assignment.isCombined)
                  Text(
                    '+ ${assignment.combinedWith!.first}',
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 6, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
              ] else ...[
                Text(
                  TableMapService.statusLabel(assignment.status),
                  style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10)),
      ],
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
