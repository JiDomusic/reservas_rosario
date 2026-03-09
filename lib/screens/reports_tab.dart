import 'package:flutter/material.dart';
import '../services/report_service.dart';
import '../widgets/simple_bar_chart.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});

  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  Map<String, dynamic>? _report;

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _generateReport() async {
    final report = await ReportService.generateReport(_startDate, _endDate);
    if (mounted) {
      setState(() {
        _report = report;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF64FFDA),
              onPrimary: Color(0xFF0A0E14),
              surface: Color(0xFF1A1E25),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _startDate = picked.start;
      _endDate = picked.end;
      _generateReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date range selector
        GestureDetector(
          onTap: _pickDateRange,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range, color: Color(0xFF64FFDA), size: 20),
                const SizedBox(width: 12),
                Text(
                  '${_startDate.day}/${_startDate.month}/${_startDate.year} - ${_endDate.day}/${_endDate.month}/${_endDate.year}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const Spacer(),
                Icon(Icons.edit, color: Colors.white.withValues(alpha: 0.4), size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (report == null || report['total_reservas'] == 0) ...[
          Container(
            padding: const EdgeInsets.all(32),
            child: Text(
              'No hay datos para el período seleccionado',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
            ),
          ),
        ] else ...[
          // Metric cards row 1
          Row(children: [
            Expanded(child: _metricCard('Total Reservas', '${report['total_reservas']}', Icons.book_online, const Color(0xFF64FFDA))),
            const SizedBox(width: 8),
            Expanded(child: _metricCard('Prom. Personas', (report['promedio_personas'] as double).toStringAsFixed(1), Icons.people, Colors.blue)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _metricCard('No-Show', '${(report['tasa_no_show'] as double).toStringAsFixed(1)}%', Icons.person_off, Colors.orange)),
            const SizedBox(width: 8),
            Expanded(child: _metricCard('Cancelación', '${(report['tasa_cancelacion'] as double).toStringAsFixed(1)}%', Icons.cancel, Colors.red)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _metricCard(
              'Día top',
              report['dia_mas_ocupado'] ?? '-',
              Icons.calendar_today,
              Colors.purple,
            )),
            const SizedBox(width: 8),
            Expanded(child: _metricCard(
              'Hora top',
              report['horario_mas_ocupado'] ?? '-',
              Icons.access_time,
              Colors.teal,
            )),
          ]),
          const SizedBox(height: 24),

          // Charts
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SimpleBarChart(
              title: 'Reservas por día',
              data: _castToIntMap(report['reservas_por_dia']),
              barColor: const Color(0xFF64FFDA),
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SimpleBarChart(
              title: 'Reservas por horario',
              data: _castToIntMap(report['reservas_por_hora']),
              barColor: Colors.blue,
              height: 220,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SimpleBarChart(
              title: 'Por estado',
              data: _castToIntMap(report['reservas_por_estado']),
              barColor: Colors.amber,
            ),
          ),
          const SizedBox(height: 16),

          if ((report['ocupacion_por_area'] as Map).isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SimpleBarChart(
                title: 'Por área',
                data: _castToIntMap(report['ocupacion_por_area']),
                barColor: Colors.purple,
              ),
            ),
          const SizedBox(height: 32),
        ],
      ],
    );
  }

  Map<String, int> _castToIntMap(dynamic map) {
    if (map is Map<String, int>) return map;
    if (map is Map) return map.map((k, v) => MapEntry(k.toString(), v is int ? v : 0));
    return {};
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
        ],
      ),
    );
  }
}
