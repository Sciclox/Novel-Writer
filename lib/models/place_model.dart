import 'dart:convert';

class Place {
  final int? id;
  final int proyectoId;
  final String nombre;
  final String? descripcion;
  final String? clima;
  final String? poblacion;
  final String importancia;
  final String? imagenPath;
  final Map<String, String> atributos;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  const Place({
    this.id,
    required this.proyectoId,
    required this.nombre,
    this.descripcion,
    this.clima,
    this.poblacion,
    this.importancia = 'Secundario',
    this.imagenPath,
    this.atributos = const {},
    this.creadoEn,
    this.actualizadoEn,
  });

  factory Place.fromMap(Map<String, dynamic> map) {
    Map<String, String> parsedAtributos = {};
    if (map['atributos'] != null) {
      try {
        final decoded = map['atributos'] is String
            ? jsonDecode(map['atributos'] as String)
            : map['atributos'];
        if (decoded is Map) {
          parsedAtributos = decoded.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
        }
      } catch (_) {}
    }

    return Place(
      id: map['id'] as int?,
      proyectoId: (map['proyecto_id'] as num?)?.toInt() ?? 0,
      nombre: map['nombre'] as String? ?? 'Lugar sin nombre',
      descripcion: map['descripcion'] as String?,
      clima: map['clima'] as String?,
      poblacion: map['poblacion'] as String?,
      importancia: map['importancia'] as String? ?? 'Secundario',
      imagenPath: map['imagen_path'] as String?,
      atributos: parsedAtributos,
      creadoEn: map['creado_en'] != null ? DateTime.tryParse(map['creado_en'].toString()) : null,
      actualizadoEn: map['actualizado_en'] != null ? DateTime.tryParse(map['actualizado_en'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'proyecto_id': proyectoId,
      'nombre': nombre,
      'descripcion': descripcion,
      'clima': clima,
      'poblacion': poblacion,
      'importancia': importancia,
      'imagen_path': imagenPath,
      'atributos': jsonEncode(atributos),
      if (creadoEn != null) 'creado_en': creadoEn!.toIso8601String(),
      'actualizado_en': (actualizadoEn ?? DateTime.now()).toIso8601String(),
    };
  }

  Place copyWith({
    int? id,
    int? proyectoId,
    String? nombre,
    String? descripcion,
    String? clima,
    String? poblacion,
    String? importancia,
    String? imagenPath,
    Map<String, String>? atributos,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return Place(
      id: id ?? this.id,
      proyectoId: proyectoId ?? this.proyectoId,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      clima: clima ?? this.clima,
      poblacion: poblacion ?? this.poblacion,
      importancia: importancia ?? this.importancia,
      imagenPath: imagenPath ?? this.imagenPath,
      atributos: atributos ?? this.atributos,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }
}
