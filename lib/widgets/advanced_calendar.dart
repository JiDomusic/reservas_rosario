import 'package:flutter/material.dart';
import 'dart:ui';
import '../config/app_config.dart';

class AdvancedCalendar extends StatefulWidget {
  final Function(DateTime?) onDateSelected;
  final DateTime? selectedDate;

  const AdvancedCalendar({
    super.key,
    required this.onDateSelected,
    this.selectedDate,
  });

  @override
  State<AdvancedCalendar> createState() => _AdvancedCalendarState();
}

class _AdvancedCalendarState extends State<AdvancedCalendar> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isDayClosed(DateTime date) {
    return AppConfig.instance.isDayClosed(date.weekday);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isMobile = screenWidth < 400;

    return Container(
      width: isMobile ? screenWidth * 0.95 : (isSmallScreen ? screenWidth - 32 : 640),
      height: isMobile ? screenHeight * 0.75 : (isSmallScreen ? screenHeight * 0.65 : screenHeight * 0.7),
      constraints: BoxConstraints(
        maxWidth: isMobile ? screenWidth * 0.95 : (isSmallScreen ? screenWidth - 32 : 640),
        minHeight: isMobile ? 450 : (isSmallScreen ? 400 : 450),
        maxHeight: isMobile ? screenHeight * 0.85 : screenHeight * 0.8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A0E14).withValues(alpha: 0.95),
            const Color(0xFF1A1E25).withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF64FFDA).withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            children: [
              _buildModernCalendarHeader(),
              _buildMinimalistWeekDayHeaders(),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    final currentMonth = DateTime.now().add(Duration(days: 30 * index));
                    return _buildUltraModernMonthView(currentMonth);
                  },
                ),
              ),
              _buildFuturisticNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernCalendarHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMobile = screenWidth < 400;
    final now = DateTime.now();
    final currentMonth = now.add(Duration(days: 30 * _currentPage));
    final monthNames = [
      '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : (isSmallScreen ? 24 : 32),
        isMobile ? 16 : (isSmallScreen ? 24 : 32),
        isMobile ? 16 : (isSmallScreen ? 24 : 32),
        isMobile ? 12 : (isSmallScreen ? 16 : 20)
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
                    Text(
                      monthNames[currentMonth.month],
                      style: TextStyle(
                        fontSize: isMobile ? 22 : (isSmallScreen ? 28 : 36),
                        fontWeight: FontWeight.w200,
                        color: Colors.white,
                        letterSpacing: isMobile ? -0.8 : -1.2,
                        height: 0.9,
                      ),
                    ),
                    Text(
                      '${currentMonth.year}',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : (isSmallScreen ? 16 : 20),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64FFDA),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF64FFDA).withValues(alpha: 0.2),
                      const Color(0xFF1DE9B6).withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF64FFDA).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF64FFDA),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_currentPage + 1}/2',
                      style: const TextStyle(
                        color: Color(0xFF64FFDA),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.red.shade300,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selecciona tu fecha perfecta',
                style: TextStyle(
                  fontSize: isSmallScreen ? 13 : 15,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Toca el dia de nuevo para deseleccionar',
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 11,
                  color: Colors.white.withValues(alpha: 0.4),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalistWeekDayHeaders() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    const weekDays = ['D', 'L', 'M', 'M', 'J', 'V', 'S'];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 20 : 32,
        vertical: isSmallScreen ? 12 : 16
      ),
      child: Row(
        children: weekDays.asMap().entries.map((entry) {
          final index = entry.key;
          final day = entry.value;
          final isWeekend = index == 0 || index == 6;

          return Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 8 : 12),
              child: Text(
                day,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 10 : 11,
                  fontWeight: FontWeight.w600,
                  color: isWeekend
                    ? const Color(0xFF64FFDA).withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.5),
                  letterSpacing: isSmallScreen ? 0.5 : 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUltraModernMonthView(DateTime month) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;

    final horizontalPadding = isSmallScreen ? 12.0 : 20.0;
    final cellSpacing = isSmallScreen ? 2.0 : 4.0;
    final availableWidth = screenWidth - (horizontalPadding * 2) - (cellSpacing * 6);
    final cellWidth = availableWidth / 7;
    final cellHeight = isSmallScreen ? cellWidth * 0.8 : cellWidth * 0.9;

    final totalDaysInCalendar = ((firstWeekday + lastDayOfMonth.day - 1) ~/ 7 + 1) * 7;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: SingleChildScrollView(
        child: Column(
          children: [
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: cellWidth / cellHeight,
                crossAxisSpacing: cellSpacing,
                mainAxisSpacing: cellSpacing,
              ),
              itemCount: totalDaysInCalendar,
              itemBuilder: (context, index) {
                final dayIndex = index - firstWeekday;

                if (dayIndex < 0 || dayIndex >= lastDayOfMonth.day) {
                  return Container();
                }

                final day = dayIndex + 1;
                final date = DateTime(month.year, month.month, day);
                final isToday = date.day == now.day &&
                               date.month == now.month &&
                               date.year == now.year;
                final isPast = date.isBefore(now.subtract(const Duration(days: 1)));
                final isClosed = _isDayClosed(date);
                final isSelected = widget.selectedDate?.day == date.day &&
                                  widget.selectedDate?.month == date.month &&
                                  widget.selectedDate?.year == date.year;
                final isWeekend = date.weekday == DateTime.saturday ||
                                 date.weekday == DateTime.sunday;

                return GestureDetector(
                  onTap: (isPast || isClosed) ? null : () {
                    if (isSelected) {
                      widget.onDateSelected(null);
                    } else {
                      widget.onDateSelected(date);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      gradient: (isPast || isClosed)
                        ? null
                        : isSelected
                          ? LinearGradient(
                              colors: [
                                const Color(0xFF64FFDA).withValues(alpha: 0.3),
                                const Color(0xFF1DE9B6).withValues(alpha: 0.2),
                              ],
                            )
                          : isToday
                            ? LinearGradient(
                                colors: [
                                  const Color(0xFF64FFDA).withValues(alpha: 0.4),
                                  const Color(0xFF1DE9B6).withValues(alpha: 0.3),
                                ],
                              )
                            : null,
                      color: (isPast || isClosed)
                        ? Colors.transparent
                        : !isSelected && !isToday
                          ? Colors.white.withValues(alpha: 0.05)
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: (isPast || isClosed)
                          ? Colors.transparent
                          : isSelected
                            ? const Color(0xFF64FFDA)
                            : isToday
                              ? const Color(0xFF64FFDA).withValues(alpha: 0.6)
                              : isWeekend
                                ? const Color(0xFF64FFDA).withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.1),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: const Color(0xFF64FFDA).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ] : null,
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            day.toString(),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              fontWeight: isSelected || isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                              color: (isPast || isClosed)
                                ? Colors.white.withValues(alpha: 0.3)
                                : isSelected
                                  ? const Color(0xFF0A0E14)
                                  : isToday
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.95),
                              decoration: isClosed ? TextDecoration.lineThrough : null,
                              decorationColor: isClosed ? Colors.red.withValues(alpha: 0.5) : null,
                            ),
                          ),
                        ),
                        if (isToday && !isSelected)
                          Positioned(
                            bottom: isSmallScreen ? 4 : 6,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Container(
                                height: isSmallScreen ? 2 : 3,
                                width: isSmallScreen ? 16 : 20,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF64FFDA),
                                      Color(0xFF1DE9B6),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        if (isWeekend && !isToday && !isSelected && !isPast && !isClosed)
                          Positioned(
                            top: isSmallScreen ? 4 : 6,
                            right: isSmallScreen ? 4 : 6,
                            child: Container(
                              width: isSmallScreen ? 4 : 6,
                              height: isSmallScreen ? 4 : 6,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF64FFDA),
                                    Color(0xFF1DE9B6),
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuturisticNavigationButtons() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isMobile = screenWidth < 400;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : (isSmallScreen ? 24 : 32),
        isMobile ? 8 : (isSmallScreen ? 12 : 16),
        isMobile ? 16 : (isSmallScreen ? 24 : 32),
        isMobile ? 16 : (isSmallScreen ? 24 : 32)
      ),
      child: Column(
        children: [
          if (widget.selectedDate != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF64FFDA).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF64FFDA).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF64FFDA),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Has elegido: ${_formatSelectedDate(widget.selectedDate!)}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            color: const Color(0xFF64FFDA),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          widget.onDateSelected(null);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade300,
                          side: BorderSide(color: Colors.red.shade300, width: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.close_rounded, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Cancelar',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF64FFDA),
                          foregroundColor: const Color(0xFF0A0E14),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Confirmar',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.check_rounded, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: _currentPage > 0 ? 1.0 : 0.3,
                child: GestureDetector(
                  onTap: _currentPage > 0 ? () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  } : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 20,
                      vertical: isSmallScreen ? 12 : 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: _currentPage > 0
                        ? LinearGradient(
                            colors: [
                              const Color(0xFF64FFDA).withValues(alpha: 0.2),
                              const Color(0xFF1DE9B6).withValues(alpha: 0.15),
                            ],
                          )
                        : null,
                      color: _currentPage > 0 ? null : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _currentPage > 0
                          ? const Color(0xFF64FFDA).withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back_ios_rounded,
                          color: _currentPage > 0
                            ? const Color(0xFF64FFDA)
                            : Colors.white.withValues(alpha: 0.4),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Mes Anterior',
                          style: TextStyle(
                            color: _currentPage > 0
                              ? const Color(0xFF64FFDA)
                              : Colors.white.withValues(alpha: 0.4),
                            fontSize: isSmallScreen ? 12 : 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF64FFDA).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF64FFDA).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${_currentPage + 1}/2',
                  style: const TextStyle(
                    color: Color(0xFF64FFDA),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Opacity(
                opacity: _currentPage < 1 ? 1.0 : 0.3,
                child: GestureDetector(
                  onTap: _currentPage < 1 ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  } : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 20,
                      vertical: isSmallScreen ? 12 : 14,
                    ),
                    decoration: BoxDecoration(
                      gradient: _currentPage < 1
                        ? LinearGradient(
                            colors: [
                              const Color(0xFF64FFDA).withValues(alpha: 0.2),
                              const Color(0xFF1DE9B6).withValues(alpha: 0.15),
                            ],
                          )
                        : null,
                      color: _currentPage < 1 ? null : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _currentPage < 1
                          ? const Color(0xFF64FFDA).withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Mes Siguiente',
                          style: TextStyle(
                            color: _currentPage < 1
                              ? const Color(0xFF64FFDA)
                              : Colors.white.withValues(alpha: 0.4),
                            fontSize: isSmallScreen ? 12 : 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: _currentPage < 1
                            ? const Color(0xFF64FFDA)
                            : Colors.white.withValues(alpha: 0.4),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSelectedDate(DateTime date) {
    final days = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];

    final dayName = days[date.weekday - 1];
    final monthName = months[date.month - 1];

    return '$dayName ${date.day} de $monthName, ${date.year}';
  }
}
