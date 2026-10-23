class Note {
  final int? id;
  final int manuscritoId;
  final String contenido;
  final int? posicionCursor;
  final String color;
  final String categoria;
  final double posX;
  final double posY;
  final double ancho;
  final double alto;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  const Note({
    this.id,
    required this.manuscritoId,
    required this.contenido,
    this.posicionCursor,
    this.color = '#FFF9C4',
    this.categoria = 'general',
    this.posX = 0,
    this.posY = 0,
    this.ancho = 200,
    this.alto = 150,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      manuscritoId: (map['manuscrito_id'] as num?)?.toInt() ?? 0,
      contenido: map['contenido'] as String? ?? '',
      posicionCursor: (map['posicion_cursor'] as num?)?.toInt(),
      color: map['color'] as String? ?? '#FFF9C4',
      categoria: map['categoria'] as String? ?? 'general',
      posX: (map['pos_x'] as num?)?.toDouble() ?? 0,
      posY: (map['pos_y'] as num?)?.toDouble() ?? 0,
      ancho: (map['ancho'] as num?)?.toDouble() ?? 200,
      alto: (map['alto'] as num?)?.toDouble() ?? 150,
      creadoEn: map['creado_en'] != null ? DateTime.tryParse(map['creado_en'].toString()) : null,
      actualizadoEn: map['actualizado_en'] != null ? DateTime.tryParse(map['actualizado_en'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'manuscrito_id': manuscritoId,
      'contenido': contenido,
      'posicion_cursor': posicionCursor,
      'color': color,
      'categoria': categoria,
      'pos_x': posX,
      'pos_y': posY,
      'ancho': ancho,
      'alto': alto,
      if (creadoEn != null) 'creado_en': creadoEn!.toIso8601String(),
      'actualizado_en': (actualizadoEn ?? DateTime.now()).toIso8601String(),
    };
  }

  Note copyWith({
    int? id,
    int? manuscritoId,
    String? contenido,
    int? posicionCursor,
    String? color,
    String? categoria,
    double? posX,
    double? posY,
    double? ancho,
    double? alto,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return Note(
      id: id ?? this.id,
      manuscritoId: manuscritoId ?? this.manuscritoId,
      contenido: contenido ?? this.contenido,
      posicionCursor: posicionCursor ?? this.posicionCursor,
      color: color ?? this.color,
      categoria: categoria ?? this.categoria,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      ancho: ancho ?? this.ancho,
      alto: alto ?? this.alto,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }
}

class NoteCategory {
  final int id;
  final int? proyectoId;
  final String nombre;
  final String icon;
  final String color;
  final int orden;

  const NoteCategory({
    required this.id,
    this.proyectoId,
    required this.nombre,
    required this.icon,
    required this.color,
    this.orden = 0,
  });

  factory NoteCategory.fromMap(Map<String, dynamic> map) {
    return NoteCategory(
      id: (map['id'] as num?)?.toInt() ?? 0,
      proyectoId: (map['proyecto_id'] as num?)?.toInt(),
      nombre: map['nombre'] as String? ?? 'Sin nombre',
      icon: map['icon'] as String? ?? 'auto_awesome',
      color: map['color'] as String? ?? '#FFF9C4',
      orden: (map['orden'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'proyecto_id': proyectoId,
      'nombre': nombre,
      'icon': icon,
      'color': color,
      'orden': orden,
    };
  }
}
