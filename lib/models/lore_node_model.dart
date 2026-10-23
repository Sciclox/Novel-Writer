import 'dart:convert';

class LoreNodeModel {
  final int? id;
  final int proyectoId;
  final String tipo; // 'personaje', 'faccion', 'artefacto', 'lugar', 'misterio', 'trama'
  final int? referenciaId;
  final String nombre;
  final String? subtitulo;
  final String? descripcion;
  final String? color;
  final double posX;
  final double posY;
  final String estado; // 'activo', 'herido', 'destruido', 'resuelto'
  final Map<String, dynamic> propiedades;
  final String? creadoEn;

  const LoreNodeModel({
    this.id,
    required this.proyectoId,
    required this.tipo,
    this.referenciaId,
    required this.nombre,
    this.subtitulo,
    this.descripcion,
    this.color,
    this.posX = 0.0,
    this.posY = 0.0,
    this.estado = 'activo',
    this.propiedades = const {},
    this.creadoEn,
  });

  factory LoreNodeModel.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> props = {};
    if (map['propiedades'] != null) {
      try {
        if (map['propiedades'] is String && (map['propiedades'] as String).isNotEmpty) {
          props = jsonDecode(map['propiedades'] as String);
        } else if (map['propiedades'] is Map) {
          props = Map<String, dynamic>.from(map['propiedades']);
        }
      } catch (_) {}
    }

    return LoreNodeModel(
      id: map['id'] as int?,
      proyectoId: map['proyecto_id'] as int,
      tipo: map['tipo'] as String? ?? 'personaje',
      referenciaId: map['referencia_id'] as int?,
      nombre: map['nombre'] as String? ?? '',
      subtitulo: map['subtitulo'] as String?,
      descripcion: map['descripcion'] as String?,
      color: map['color'] as String?,
      posX: (map['pos_x'] as num?)?.toDouble() ?? 0.0,
      posY: (map['pos_y'] as num?)?.toDouble() ?? 0.0,
      estado: map['estado'] as String? ?? 'activo',
      propiedades: props,
      creadoEn: map['creado_en'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'proyecto_id': proyectoId,
      'tipo': tipo,
      'referencia_id': referenciaId,
      'nombre': nombre,
      'subtitulo': subtitulo,
      'descripcion': descripcion,
      'color': color,
      'pos_x': posX,
      'pos_y': posY,
      'estado': estado,
      'propiedades': jsonEncode(propiedades),
      if (creadoEn != null) 'creado_en': creadoEn,
    };
  }

  LoreNodeModel copyWith({
    int? id,
    int? proyectoId,
    String? tipo,
    int? referenciaId,
    String? nombre,
    String? subtitulo,
    String? descripcion,
    String? color,
    double? posX,
    double? posY,
    String? estado,
    Map<String, dynamic>? propiedades,
    String? creadoEn,
  }) {
    return LoreNodeModel(
      id: id ?? this.id,
      proyectoId: proyectoId ?? this.proyectoId,
      tipo: tipo ?? this.tipo,
      referenciaId: referenciaId ?? this.referenciaId,
      nombre: nombre ?? this.nombre,
      subtitulo: subtitulo ?? this.subtitulo,
      descripcion: descripcion ?? this.descripcion,
      color: color ?? this.color,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      estado: estado ?? this.estado,
      propiedades: propiedades ?? this.propiedades,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }
}
