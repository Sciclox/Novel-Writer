class IdeaCard {
  final int? id;
  final int proyectoId;
  final String titulo;
  final String? contenido;
  final String tipo;
  final String color;
  final double posX;
  final double posY;
  final double ancho;
  final double alto;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;

  const IdeaCard({
    this.id,
    required this.proyectoId,
    required this.titulo,
    this.contenido,
    this.tipo = 'idea',
    this.color = '#FFCDD2',
    this.posX = 0,
    this.posY = 0,
    this.ancho = 250,
    this.alto = 200,
    this.creadoEn,
    this.actualizadoEn,
  });

  factory IdeaCard.fromMap(Map<String, dynamic> map) {
    return IdeaCard(
      id: map['id'] as int?,
      proyectoId: (map['proyecto_id'] as num?)?.toInt() ?? 0,
      titulo: map['titulo'] as String? ?? 'Idea sin título',
      contenido: map['contenido'] as String?,
      tipo: map['tipo'] as String? ?? 'idea',
      color: map['color'] as String? ?? '#FFCDD2',
      posX: (map['pos_x'] as num?)?.toDouble() ?? 0,
      posY: (map['pos_y'] as num?)?.toDouble() ?? 0,
      ancho: (map['ancho'] as num?)?.toDouble() ?? 250,
      alto: (map['alto'] as num?)?.toDouble() ?? 200,
      creadoEn: map['creado_en'] != null ? DateTime.tryParse(map['creado_en'].toString()) : null,
      actualizadoEn: map['actualizado_en'] != null ? DateTime.tryParse(map['actualizado_en'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'proyecto_id': proyectoId,
      'titulo': titulo,
      'contenido': contenido,
      'tipo': tipo,
      'color': color,
      'pos_x': posX,
      'pos_y': posY,
      'ancho': ancho,
      'alto': alto,
      if (creadoEn != null) 'creado_en': creadoEn!.toIso8601String(),
      'actualizado_en': (actualizadoEn ?? DateTime.now()).toIso8601String(),
    };
  }

  IdeaCard copyWith({
    int? id,
    int? proyectoId,
    String? titulo,
    String? contenido,
    String? tipo,
    String? color,
    double? posX,
    double? posY,
    double? ancho,
    double? alto,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
  }) {
    return IdeaCard(
      id: id ?? this.id,
      proyectoId: proyectoId ?? this.proyectoId,
      titulo: titulo ?? this.titulo,
      contenido: contenido ?? this.contenido,
      tipo: tipo ?? this.tipo,
      color: color ?? this.color,
      posX: posX ?? this.posX,
      posY: posY ?? this.posY,
      ancho: ancho ?? this.ancho,
      alto: alto ?? this.alto,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
    );
  }
}

class IdeaConnection {
  final int? id;
  final int tarjetaOrigenId;
  final int tarjetaDestinoId;
  final DateTime? creadoEn;

  const IdeaConnection({
    this.id,
    required this.tarjetaOrigenId,
    required this.tarjetaDestinoId,
    this.creadoEn,
  });

  factory IdeaConnection.fromMap(Map<String, dynamic> map) {
    return IdeaConnection(
      id: map['id'] as int?,
      tarjetaOrigenId: (map['tarjeta_origen_id'] as num?)?.toInt() ?? 0,
      tarjetaDestinoId: (map['tarjeta_destino_id'] as num?)?.toInt() ?? 0,
      creadoEn: map['creado_en'] != null ? DateTime.tryParse(map['creado_en'].toString()) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'tarjeta_origen_id': tarjetaOrigenId,
      'tarjeta_destino_id': tarjetaDestinoId,
      if (creadoEn != null) 'creado_en': creadoEn!.toIso8601String(),
    };
  }
}
