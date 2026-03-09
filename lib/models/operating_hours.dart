class OperatingHours {
  final String id;
  final int diaSemana;      // 0=Domingo, 1=Lunes, ... 6=Sábado
  final String area;         // "planta_baja", "planta_alta"
  final String horaInicio;   // "09:00"
  final String horaFin;      // "19:30"
  final int intervaloMinutos; // 30
  final bool activo;

  const OperatingHours({
    required this.id,
    required this.diaSemana,
    required this.area,
    required this.horaInicio,
    required this.horaFin,
    this.intervaloMinutos = 30,
    this.activo = true,
  });

  factory OperatingHours.fromMap(Map<String, dynamic> map) {
    return OperatingHours(
      id: map['id'] ?? '',
      diaSemana: map['dia_semana'] ?? 0,
      area: map['area'] ?? '',
      horaInicio: map['hora_inicio']?.toString().substring(0, 5) ?? '09:00',
      horaFin: map['hora_fin']?.toString().substring(0, 5) ?? '21:00',
      intervaloMinutos: map['intervalo_minutos'] ?? 30,
      activo: map['activo'] ?? true,
    );
  }

  int get horaInicioInt => int.parse(horaInicio.split(':')[0]);
  int get minutoInicioInt => int.parse(horaInicio.split(':')[1]);
  int get horaFinInt => int.parse(horaFin.split(':')[0]);
  int get minutoFinInt => int.parse(horaFin.split(':')[1]);

  static const List<String> diasNombres = [
    'Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'
  ];

  String get diaNombre => diasNombres[diaSemana];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dia_semana': diaSemana,
      'area': area,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'intervalo_minutos': intervaloMinutos,
      'activo': activo,
    };
  }
}
