import 'package:flutter/material.dart';

class TimeSlotWithCross extends StatelessWidget {
  final String timeSlot;
  final bool isAvailable;
  final bool showCross;
  final VoidCallback? onTap;
  final bool isSelected;

  const TimeSlotWithCross({
    Key? key,
    required this.timeSlot,
    required this.isAvailable,
    this.showCross = false,
    this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final disabled = showCross || !isAvailable;

    return GestureDetector(
      onTap: !disabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _getBorderColor(),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: _getBorderColor().withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 1)]
              : null,
        ),
        child: Text(
          timeSlot,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: _getTextColor(),
            decoration: showCross ? TextDecoration.lineThrough : null,
            decorationColor: Colors.red.withValues(alpha: 0.7),
            decorationThickness: 2,
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    if (showCross || !isAvailable) {
      return Colors.grey.shade200.withValues(alpha: 0.5);
    }
    if (isSelected) {
      return Colors.blue.shade50;
    }
    return Colors.white;
  }

  Color _getBorderColor() {
    if (showCross || !isAvailable) {
      return Colors.grey.shade300;
    }
    if (isSelected) {
      return Colors.blue;
    }
    return Colors.grey.shade300;
  }

  Color _getTextColor() {
    if (showCross || !isAvailable) {
      return Colors.grey.shade400;
    }
    if (isSelected) {
      return Colors.blue;
    }
    return Colors.black87;
  }
}

class TimeSlotGrid extends StatelessWidget {
  final List<Map<String, dynamic>> timeSlots;
  final String? selectedTimeSlot;
  final Function(String) onTimeSlotSelected;
  final int guests;

  const TimeSlotGrid({
    Key? key,
    required this.timeSlots,
    this.selectedTimeSlot,
    required this.onTimeSlotSelected,
    required this.guests,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 600 ? 5 : (width > 400 ? 4 : 3);

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: timeSlots.map((slot) {
        final hora = slot['hora'] as String;
        final isAvailable = slot['available'] as bool;
        final showCross = slot['showCross'] as bool? ?? false;
        final blockTwoGuests = slot['blockTwoGuests'] as bool? ?? false;

        final shouldShowCross = showCross || (blockTwoGuests && guests == 2);

        return TimeSlotWithCross(
          timeSlot: hora,
          isAvailable: isAvailable && !shouldShowCross,
          showCross: shouldShowCross,
          isSelected: selectedTimeSlot == hora,
          onTap: () {
            if (isAvailable && !shouldShowCross) {
              onTimeSlotSelected(hora);
            }
          },
        );
      }).toList(),
    );
  }
}

class CapacityInfoWidget extends StatelessWidget {
  final String area;
  final int maxCapacity;
  final int currentOccupancy;
  final int remaining;

  const CapacityInfoWidget({
    Key? key,
    required this.area,
    required this.maxCapacity,
    required this.currentOccupancy,
    required this.remaining,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = (currentOccupancy / maxCapacity * 100).round();
    final areaName = area == 'planta_alta' ? 'Planta Alta' : 'Planta Baja';

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _getCapacityColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getCapacityColor(),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                areaName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$currentOccupancy/$maxCapacity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _getCapacityColor(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: currentOccupancy / maxCapacity,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(_getCapacityColor()),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            remaining > 0
                ? 'Quedan $remaining lugares disponibles ($percentage% ocupado)'
                : 'COMPLETO - No hay lugares disponibles',
            style: TextStyle(
              fontSize: 14,
              color: _getCapacityColor(),
              fontWeight: remaining > 0 ? FontWeight.normal : FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCapacityColor() {
    if (remaining <= 0) return Colors.red;
    if (remaining < maxCapacity * 0.2) return Colors.orange;
    return Colors.green;
  }
}
