class Chapter {
  final int? id;
  final int manuscritoId;
  final String titulo;
  final String contenido;
  final int orden;
  final String tipo; // 'capitulo', 'prologo', 'epilogo', 'escena', etc.
  final int palabras;
  final int metaSesion;
  final int metaDiaria;
  final String sinopsis;
  final int? povPersonajeId;
  final String estado; // 'borrador', 'en_revision', 'reescritura', 'completado'
  final int metaPalabras;
  final DateTime? eliminadoEn;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  const Chapter({
    this.id,
    required this.manuscritoId,
    required this.titulo,
    this.contenido = '',
    this.orden = 0,
    this.tipo = 'capitulo',
    this.palabras = 0,
    this.metaSesion = 0,
    this.metaDiaria = 0,
    this.sinopsis = '',
    this.povPersonajeId,
    this.estado = 'borrador',
    this.metaPalabras = 0,
    this.eliminadoEn,
    this.creadoEn,
    this.actualizadoEn,
  });

  bool get isDeleted => eliminadoEn != null;

  factory Chapter.fromMap(Map<String, dynamic> map) {
    return Chapter(
      id: map['id'] as int?,
      manuscritoId: (map['manuscrito_id'] as num?)?.toInt() ?? 0,
      titulo: map['titulo'] as String? ?? 'Sin título',
      contenido: map['contenido'] as String? ?? '',
      orden: (map['orden'] as num?)?.toInt() ?? 0,
      tipo: map['tipo'] as String? ?? 'capitulo',
      palabras: (map['palabras'] as num?)?.toInt() ?? 0,
      metaSesion: (map['meta_sesion'] as num?)?.toInt() ?? 0,
      metaDiaria: (map['meta_diaria'] as num?)?.toInt() ?? 0,
      sinopsis: map['sinopsis'] as String? ?? '',
      povPersonajeId: (map['pov_personaje_id'] as num?)?.toInt(),
      estado: map['estado'] as String? ?? 'borrador',
      metaPalabras: (map['meta_palabras'] as num?)?.toInt() ?? 0,
      eliminadoEn: map['eliminado_en'] != null ? DateTime.tryParse(map['eliminado_en'].toString()) : null,
      creadoEn: map['creado_en'] != null ? DateTime.tryParse(map['creado_en'].toString()) : null,
      actualizadoEn: map['actualizado_en'] != null ? DateTime.tryParse(map['actualizado_en'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'manuscrito_id': manuscritoId,
      'titulo': titulo,
      'contenido': contenido,
      'orden': orden,
      'tipo': tipo,
      'palabras': palabras,
      'meta_sesion': metaSesion,
      'meta_diaria': metaDiaria,
      'sinopsis': sinopsis,
      'pov_personaje_id': povPersonajeId,
      'estado': estado,
      'meta_palabras': metaPalabras,
      'eliminado_en': eliminadoEn?.toIso8601String(),
      if (creadoEn != null) 'creado_en': creadoEn!.toIso8601String(),
      'actualizado_en': (actualizadoEn ?? DateTime.now()).toIso8601String(),
    };
  }

  Chapter copyWith({
    int? id,
    int? manuscritoId,
    String? titulo,
    String? contenido,
    int? orden,
    String? tipo,
    int? palabras,
    int? metaSesion,
    int? metaDiaria,
    String? sinopsis,
    int? povPersonajeId,
    String? estado,
    int? metaPalabras,
    DateTime? eliminadoEn,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return Chapter(
      id: id ?? this.id,
      manuscritoId: manuscritoId ?? this.manuscritoId,
      titulo: titulo ?? this.titulo,
      contenido: contenido ?? this.contenido,
      orden: orden ?? this.orden,
      tipo: tipo ?? this.tipo,
      palabras: palabras ?? this.palabras,
      metaSesion: metaSesion ?? this.metaSesion,
      metaDiaria: metaDiaria ?? this.metaDiaria,
      sinopsis: sinopsis ?? this.sinopsis,
      povPersonajeId: povPersonajeId ?? this.povPersonajeId,
      estado: estado ?? this.estado,
      metaPalabras: metaPalabras ?? this.metaPalabras,
      eliminadoEn: eliminadoEn ?? this.eliminadoEn,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }
}
