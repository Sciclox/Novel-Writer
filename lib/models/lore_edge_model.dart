class LoreEdgeModel {
  final int? id;
  final int proyectoId;
  final int nodoOrigenId;
  final int nodoDestinoId;
  final String tipoRelacion; // 'posee', 'enemigo_de', 'aliado_de', 'miembro_de', 'investiga', 'oculto_en', 'sabe_secreto', 'creo'
  final String? etiqueta;
  final double intensidad; // 0.0 a 1.0
  final bool esBidireccional;
  final String? detalles;
  final String? creadoEn;

  const LoreEdgeModel({
    this.id,
    required this.proyectoId,
    required this.nodoOrigenId,
    required this.nodoDestinoId,
    required this.tipoRelacion,
    this.etiqueta,
    this.intensidad = 1.0,
    this.esBidireccional = false,
    this.detalles,
    this.creadoEn,
  });

  factory LoreEdgeModel.fromMap(Map<String, dynamic> map) {
    return LoreEdgeModel(
      id: map['id'] as int?,
      proyectoId: map['proyecto_id'] as int,
      nodoOrigenId: map['nodo_origen_id'] as int,
      nodoDestinoId: map['nodo_destino_id'] as int,
      tipoRelacion: map['tipo_relacion'] as String? ?? 'relacion',
      etiqueta: map['etiqueta'] as String?,
      intensidad: (map['intensidad'] as num?)?.toDouble() ?? 1.0,
      esBidireccional: (map['es_bidireccional'] == 1 || map['es_bidireccional'] == true),
      detalles: map['detalles'] as String?,
      creadoEn: map['creado_en'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'proyecto_id': proyectoId,
      'nodo_origen_id': nodoOrigenId,
      'nodo_destino_id': nodoDestinoId,
      'tipo_relacion': tipoRelacion,
      'etiqueta': etiqueta,
      'intensidad': intensidad,
      'es_bidireccional': esBidireccional ? 1 : 0,
      'detalles': detalles,
      if (creadoEn != null) 'creado_en': creadoEn,
    };
  }

  LoreEdgeModel copyWith({
    int? id,
    int? proyectoId,
    int? nodoOrigenId,
    int? nodoDestinoId,
    String? tipoRelacion,
    String? etiqueta,
    double? intensidad,
    bool? esBidireccional,
    String? detalles,
    String? creadoEn,
  }) {
    return LoreEdgeModel(
      id: id ?? this.id,
      proyectoId: proyectoId ?? this.proyectoId,
      nodoOrigenId: nodoOrigenId ?? this.nodoOrigenId,
      nodoDestinoId: nodoDestinoId ?? this.nodoDestinoId,
      tipoRelacion: tipoRelacion ?? this.tipoRelacion,
      etiqueta: etiqueta ?? this.etiqueta,
      intensidad: intensidad ?? this.intensidad,
      esBidireccional: esBidireccional ?? this.esBidireccional,
      detalles: detalles ?? this.detalles,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }
}
