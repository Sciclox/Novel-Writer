class CharacterRelation {
  final int? id;
  final int personajeAId;
  final int personajeBId;
  final String tipo;
  final int intensidad;
  final String? notas;
  final String? nombreOtro;
  final String? imagenOtro;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  const CharacterRelation({
    this.id,
    required this.personajeAId,
    required this.personajeBId,
    required this.tipo,
    this.intensidad = 50,
    this.notas,
    this.nombreOtro,
    this.imagenOtro,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory CharacterRelation.fromMap(Map<String, dynamic> map) {
    return CharacterRelation(
      id: map['id'] as int?,
      personajeAId: (map['personaje_a_id'] as num?)?.toInt() ?? 0,
      personajeBId: (map['personaje_b_id'] as num?)?.toInt() ?? 0,
      tipo: map['tipo'] as String? ?? 'Aliado',
      intensidad: (map['intensidad'] as num?)?.toInt() ?? 50,
      notas: map['notas'] as String?,
      nombreOtro: map['nombre_otro'] as String?,
      imagenOtro: map['imagen_otro'] as String?,
      creadoEn: map['creado_en'] != null ? DateTime.tryParse(map['creado_en'].toString()) : null,
      actualizadoEn: map['actualizado_en'] != null ? DateTime.tryParse(map['actualizado_en'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'personaje_a_id': personajeAId,
      'personaje_b_id': personajeBId,
      'tipo': tipo,
      'intensidad': intensidad,
      'notas': notas,
      if (creadoEn != null) 'creado_en': creadoEn!.toIso8601String(),
      'actualizado_en': (actualizadoEn ?? DateTime.now()).toIso8601String(),
    };
  }

  CharacterRelation copyWith({
    int? id,
    int? personajeAId,
    int? personajeBId,
    String? tipo,
    int? intensidad,
    String? notas,
    String? nombreOtro,
    String? imagenOtro,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return CharacterRelation(
      id: id ?? this.id,
      personajeAId: personajeAId ?? this.personajeAId,
      personajeBId: personajeBId ?? this.personajeBId,
      tipo: tipo ?? this.tipo,
      intensidad: intensidad ?? this.intensidad,
      notas: notas ?? this.notas,
      nombreOtro: nombreOtro ?? this.nombreOtro,
      imagenOtro: imagenOtro ?? this.imagenOtro,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }
}
