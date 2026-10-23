class TimelineEvent {
  final int? id;
  final int proyectoId;
  final String titulo;
  final String? descripcion;
  final String? fechaRelativa;
  final int importancia;
  final String colorHex;
  final int orden;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  const TimelineEvent({
    this.id,
    required this.proyectoId,
    required this.titulo,
    this.descripcion,
    this.fechaRelativa,
    this.importancia = 1,
    this.colorHex = '#00F0FF',
    this.orden = 0,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory TimelineEvent.fromMap(Map<String, dynamic> map) {
    return TimelineEvent(
      id: map['id'] as int?,
      proyectoId: (map['proyecto_id'] as num?)?.toInt() ?? 0,
      titulo: map['titulo'] as String? ?? '',
      descripcion: map['descripcion'] as String?,
      fechaRelativa: map['fecha_relativa'] as String?,
      importancia: (map['importancia'] as num?)?.toInt() ?? 1,
      colorHex: map['color_hex'] as String? ?? '#00F0FF',
      orden: (map['orden'] as num?)?.toInt() ?? 0,
      creadoEn: map['creado_en'] != null ? DateTime.tryParse(map['creado_en'].toString()) : null,
      actualizadoEn: map['actualizado_en'] != null ? DateTime.tryParse(map['actualizado_en'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'proyecto_id': proyectoId,
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha_relativa': fechaRelativa,
      'importancia': importancia,
      'color_hex': colorHex,
      'orden': orden,
      if (creadoEn != null) 'creado_en': creadoEn!.toIso8601String(),
      'actualizado_en': (actualizadoEn ?? DateTime.now()).toIso8601String(),
    };
  }

  TimelineEvent copyWith({
    int? id,
    int? proyectoId,
    String? titulo,
    String? descripcion,
    String? fechaRelativa,
    int? importancia,
    String? colorHex,
    int? orden,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return TimelineEvent(
      id: id ?? this.id,
      proyectoId: proyectoId ?? this.proyectoId,
      titulo: titulo ?? this.titulo,
      descripcion: descripcion ?? this.descripcion,
      fechaRelativa: fechaRelativa ?? this.fechaRelativa,
      importancia: importancia ?? this.importancia,
      colorHex: colorHex ?? this.colorHex,
      orden: orden ?? this.orden,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }
}
