import 'dart:typed_data';

class Project {
  final int? id;
  final String titulo;
  final String? sinopsis;
  final String? imagenPortada;
  final Uint8List? portadaBlob;
  final int palabras;
  final int capitulosCount;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  const Project({
    this.id,
    required this.titulo,
    this.sinopsis,
    this.imagenPortada,
    this.portadaBlob,
    this.palabras = 0,
    this.capitulosCount = 0,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] as int?,
      titulo: map['titulo'] as String? ?? 'Sin título',
      sinopsis: map['sinopsis'] as String?,
      imagenPortada: map['imagen_portada'] as String?,
      portadaBlob: map['portada_blob'] as Uint8List?,
      palabras: (map['palabras'] as num?)?.toInt() ?? 0,
      capitulosCount: (map['capitulos'] as num?)?.toInt() ?? 0,
      creadoEn: map['creado_en'] != null ? DateTime.tryParse(map['creado_en'].toString()) : null,
      actualizadoEn: map['actualizado_en'] != null ? DateTime.tryParse(map['actualizado_en'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'titulo': titulo,
      'sinopsis': sinopsis,
      'imagen_portada': imagenPortada,
      'portada_blob': portadaBlob,
      if (creadoEn != null) 'creado_en': creadoEn!.toIso8601String(),
      'actualizado_en': (actualizadoEn ?? DateTime.now()).toIso8601String(),
    };
  }

  Project copyWith({
    int? id,
    String? titulo,
    String? sinopsis,
    String? imagenPortada,
    Uint8List? portadaBlob,
    int? palabras,
    int? capitulosCount,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return Project(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      sinopsis: sinopsis ?? this.sinopsis,
      imagenPortada: imagenPortada ?? this.imagenPortada,
      portadaBlob: portadaBlob ?? this.portadaBlob,
      palabras: palabras ?? this.palabras,
      capitulosCount: capitulosCount ?? this.capitulosCount,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }
}
