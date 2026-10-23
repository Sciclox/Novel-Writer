import 'dart:convert';

class Character {
  final int? id;
  final int proyectoId;
  final String nombre;
  final String? rol;
  final String? alias;
  final String? fraseIconica;
  final String? estadoEmocional;
  final String? estadoActual;
  final String? edad;
  final String? descripcion;
  final String? imagenPath;
  final Map<String, String> atributos;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  const Character({
    this.id,
    required this.proyectoId,
    required this.nombre,
    this.rol,
    this.alias,
    this.fraseIconica,
    this.estadoEmocional,
    this.estadoActual,
    this.edad,
    this.descripcion,
    this.imagenPath,
    this.atributos = const {},
    this.creadoEn,
    this.actualizadoEn,
  });

  factory Character.fromMap(Map<String, dynamic> map) {
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

    return Character(
      id: map['id'] as int?,
      proyectoId: (map['proyecto_id'] as num?)?.toInt() ?? 0,
      nombre: map['nombre'] as String? ?? 'Sin nombre',
      rol: map['rol'] as String?,
      alias: map['alias'] as String?,
      fraseIconica: map['frase_iconica'] as String?,
      estadoEmocional: map['estado_emocional'] as String?,
      estadoActual: map['estado_actual'] as String?,
      edad: map['edad'] as String?,
      descripcion: map['descripcion'] as String?,
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
      'rol': rol,
      'alias': alias,
      'frase_iconica': fraseIconica,
      'estado_emocional': estadoEmocional,
      'estado_actual': estadoActual,
      'edad': edad,
      'descripcion': descripcion,
      'imagen_path': imagenPath,
      'atributos': jsonEncode(atributos),
      if (creadoEn != null) 'creado_en': creadoEn!.toIso8601String(),
      'actualizado_en': (actualizadoEn ?? DateTime.now()).toIso8601String(),
    };
  }

  Character copyWith({
    int? id,
    int? proyectoId,
    String? nombre,
    String? rol,
    String? alias,
    String? fraseIconica,
    String? estadoEmocional,
    String? estadoActual,
    String? edad,
    String? descripcion,
    String? imagenPath,
    Map<String, String>? atributos,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return Character(
      id: id ?? this.id,
      proyectoId: proyectoId ?? this.proyectoId,
      nombre: nombre ?? this.nombre,
      rol: rol ?? this.rol,
      alias: alias ?? this.alias,
      fraseIconica: fraseIconica ?? this.fraseIconica,
      estadoEmocional: estadoEmocional ?? this.estadoEmocional,
      estadoActual: estadoActual ?? this.estadoActual,
      edad: edad ?? this.edad,
      descripcion: descripcion ?? this.descripcion,
      imagenPath: imagenPath ?? this.imagenPath,
      atributos: atributos ?? this.atributos,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }
}
