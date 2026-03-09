class AreaConfig {
  final String id;
  final String nombre;       // identificador interno: "planta_baja"
  final String nombreDisplay; // para mostrar: "Planta Baja"
  final int capacidadReal;
  final int capacidadFrontend;
  final String? horaInicio;   // "09:00"
  final String? horaFin;      // "19:30"
  final bool activo;

  const AreaConfig({
    required this.id,
    required this.nombre,
    required this.nombreDisplay,
    required this.capacidadReal,
    required this.capacidadFrontend,
    this.horaInicio,
    this.horaFin,
    this.activo = true,
  });

  factory AreaConfig.fromMap(Map<String, dynamic> map) {
    return AreaConfig(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      nombreDisplay: map['nombre_display'] ?? map['nombre'] ?? '',
      capacidadReal: map['capacidad_real'] ?? 0,
      capacidadFrontend: map['capacidad_frontend'] ?? map['capacidad_real'] ?? 0,
      horaInicio: map['hora_inicio']?.toString().substring(0, 5),
      horaFin: map['hora_fin']?.toString().substring(0, 5),
      activo: map['activo'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'nombre_display': nombreDisplay,
      'capacidad_real': capacidadReal,
      'capacidad_frontend': capacidadFrontend,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'activo': activo,
    };
  }
}
