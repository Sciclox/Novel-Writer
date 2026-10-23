import 'dart:convert';

class ChapterCoherenceModel {
  final int? id;
  final int capituloId;
  final int? lugarId;
  final List<int> personajesIds;
  final List<int> artefactosIds;
  final Map<String, String> estadoSalud; // PersonajeId -> Estado/Herida
  final List<String> secretosRevelados;
  final String? notasContinuidad;

  const ChapterCoherenceModel({
    this.id,
    required this.capituloId,
    this.lugarId,
    this.personajesIds = const [],
    this.artefactosIds = const [],
    this.estadoSalud = const {},
    this.secretosRevelados = const [],
    this.notasContinuidad,
  });

  factory ChapterCoherenceModel.fromMap(Map<String, dynamic> map) {
    List<int> parseIds(dynamic val) {
      if (val == null) return [];
      try {
        if (val is String && val.isNotEmpty) {
          final decoded = jsonDecode(val);
          if (decoded is List) return decoded.map((e) => (e as num).toInt()).toList();
        } else if (val is List) {
          return val.map((e) => (e as num).toInt()).toList();
        }
      } catch (_) {}
      return [];
    }

    Map<String, String> parseMap(dynamic val) {
      if (val == null) return {};
      try {
        if (val is String && val.isNotEmpty) {
          final decoded = jsonDecode(val);
          if (decoded is Map) return Map<String, String>.from(decoded.map((k, v) => MapEntry(k.toString(), v.toString())));
        } else if (val is Map) {
          return Map<String, String>.from(val.map((k, v) => MapEntry(k.toString(), v.toString())));
        }
      } catch (_) {}
      return {};
    }

    List<String> parseStringList(dynamic val) {
      if (val == null) return [];
      try {
        if (val is String && val.isNotEmpty) {
          final decoded = jsonDecode(val);
          if (decoded is List) return decoded.map((e) => e.toString()).toList();
        } else if (val is List) {
          return val.map((e) => e.toString()).toList();
        }
      } catch (_) {}
      return [];
    }

    return ChapterCoherenceModel(
      id: map['id'] as int?,
      capituloId: map['capitulo_id'] as int,
      lugarId: map['lugar_id'] as int?,
      personajesIds: parseIds(map['personajes_ids']),
      artefactosIds: parseIds(map['artefactos_ids']),
      estadoSalud: parseMap(map['estado_salud']),
      secretosRevelados: parseStringList(map['secretos_revelados']),
      notasContinuidad: map['notas_continuidad'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'capitulo_id': capituloId,
      'lugar_id': lugarId,
      'personajes_ids': jsonEncode(personajesIds),
      'artefactos_ids': jsonEncode(artefactosIds),
      'estado_salud': jsonEncode(estadoSalud),
      'secretos_revelados': jsonEncode(secretosRevelados),
      'notas_continuidad': notasContinuidad,
    };
  }

  ChapterCoherenceModel copyWith({
    int? id,
    int? capituloId,
    int? lugarId,
    List<int>? personajesIds,
    List<int>? artefactosIds,
    Map<String, String>? estadoSalud,
    List<String>? secretosRevelados,
    String? notasContinuidad,
  }) {
    return ChapterCoherenceModel(
      id: id ?? this.id,
      capituloId: capituloId ?? this.capituloId,
      lugarId: lugarId ?? this.lugarId,
      personajesIds: personajesIds ?? this.personajesIds,
      artefactosIds: artefactosIds ?? this.artefactosIds,
      estadoSalud: estadoSalud ?? this.estadoSalud,
      secretosRevelados: secretosRevelados ?? this.secretosRevelados,
      notasContinuidad: notasContinuidad ?? this.notasContinuidad,
    );
  }
}
