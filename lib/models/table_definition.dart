class TableDefinition {
  final String id;
  final String nombre;
  final String area;         // "planta_alta"
  final int minCapacidad;
  final int maxCapacidad;
  final int cantidad;
  final bool esVip;
  final bool bloqueable;
  final bool activo;
  final double posX;
  final double posY;
  final double width;
  final double height;
  final String shape; // 'rect', 'circle', 'square'

  const TableDefinition({
    required this.id,
    required this.nombre,
    required this.area,
    required this.minCapacidad,
    required this.maxCapacidad,
    this.cantidad = 1,
    this.esVip = false,
    this.bloqueable = false,
    this.activo = true,
    this.posX = 0,
    this.posY = 0,
    this.width = 80,
    this.height = 80,
    this.shape = 'rect',
  });

  TableDefinition copyWith({
    String? id,
    String? nombre,
    String? area,
    int? minCapacidad,
    int? maxCapacidad,
    int? cantidad,
    bool? esVip,
    bool? bloqueable,
    bool? activo,
    double? posX,
    double? posY,
    double? width,
    double? height,
    String? shape,
  }) {
    return TableDefinition(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      area: area ?? this.area,
      minCapacidad: minCapacidad ?? this.minCapacidad,
      maxCapacidad: maxCapacidad ?? this.maxCapacidad,
      cantidad: cantidad ?? this.cantidad,
      esVip: esVip ?? this.esVip,
      bloqueable: bloqueable ?? this.bloqueable,
      activo: activo ?? this.activo,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      width: width ?? this.width,
      height: height ?? this.height,
      shape: shape ?? this.shape,
    );
  }

  factory TableDefinition.fromMap(Map<String, dynamic> map) {
    return TableDefinition(
      id: map['id'] ?? '',
      nombre: map['nombre'] ?? '',
      area: map['area'] ?? '',
      minCapacidad: map['min_capacidad'] ?? 2,
      maxCapacidad: map['max_capacidad'] ?? 4,
      cantidad: map['cantidad'] ?? 1,
      esVip: map['es_vip'] ?? false,
      bloqueable: map['bloqueable'] ?? false,
      activo: map['activo'] ?? true,
      posX: (map['pos_x'] ?? 0).toDouble(),
      posY: (map['pos_y'] ?? 0).toDouble(),
      width: (map['width'] ?? 80).toDouble(),
      height: (map['height'] ?? 80).toDouble(),
      shape: map['shape'] ?? 'rect',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'area': area,
      'min_capacidad': minCapacidad,
      'max_capacidad': maxCapacidad,
      'cantidad': cantidad,
      'es_vip': esVip,
      'bloqueable': bloqueable,
      'activo': activo,
      'pos_x': posX,
      'pos_y': posY,
      'width': width,
      'height': height,
      'shape': shape,
    };
  }
}
