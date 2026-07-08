import 'dart:convert';

class NovelStyle {
  final int? id;
  final int? proyectoId;
  final String nombre;
  final int orden;
  final int? heredaDeId;
  final String? atajo;
  final bool esGlobal;
  Map<String, dynamic> config;

  NovelStyle({
    this.id,
    this.proyectoId,
    required this.nombre,
    this.orden = 0,
    this.heredaDeId,
    this.atajo,
    this.esGlobal = false,
    Map<String, dynamic>? config,
  }) : config = config ?? {};

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    if (proyectoId != null) 'proyecto_id': proyectoId,
    'nombre': nombre,
    'orden': orden,
    'hereda_de_id': heredaDeId,
    'atajo': atajo,
    'es_global': esGlobal ? 1 : 0,
    'config': jsonEncode(config),
  };

  factory NovelStyle.fromMap(Map<String, dynamic> map) => NovelStyle(
    id: map['id'] as int?,
    proyectoId: map['proyecto_id'] as int?,
    nombre: map['nombre'] as String,
    orden: map['orden'] as int? ?? 0,
    heredaDeId: map['hereda_de_id'] as int?,
    atajo: map['atajo'] as String?,
    esGlobal: (map['es_global'] as int?) == 1,
    config: map['config'] is String
        ? jsonDecode(map['config'] as String) as Map<String, dynamic>
        : (map['config'] as Map<String, dynamic>?) ?? {},
  );

  NovelStyle copyWith({
    int? id,
    int? proyectoId,
    String? nombre,
    int? orden,
    int? heredaDeId,
    String? atajo,
    bool? esGlobal,
    Map<String, dynamic>? config,
  }) => NovelStyle(
    id: id ?? this.id,
    proyectoId: proyectoId ?? this.proyectoId,
    nombre: nombre ?? this.nombre,
    orden: orden ?? this.orden,
    heredaDeId: heredaDeId ?? this.heredaDeId,
    atajo: atajo ?? this.atajo,
    esGlobal: esGlobal ?? this.esGlobal,
    config: config ?? Map<String, dynamic>.from(this.config),
  );
}

Map<String, dynamic> mergeStyleConfig(NovelStyle style, List<NovelStyle> allStyles) {
  if (style.heredaDeId == null) return Map<String, dynamic>.from(style.config);
  final parent = allStyles.where((s) => s.id == style.heredaDeId).firstOrNull;
  if (parent == null) return Map<String, dynamic>.from(style.config);
  final merged = mergeStyleConfig(parent, allStyles);
  merged.addAll(style.config);
  return merged;
}

const List<Map<String, dynamic>> defaultStyleConfigs = [
  {
    'nombre': 'Texto normal',
    'atajo': 'Ctrl+1',
    'orden': 0,
    'config': {
      'fontSize': 12.0,
      'fontFamily': 'Merriweather',
      'fontWeight': 'normal',
      'fontStyle': 'normal',
      'alignment': 'justify',
      'lineHeight': 1.8,
      'color': null,
      'backgroundColor': null,
    },
  },
  {
    'nombre': 'Capítulo',
    'atajo': 'Ctrl+2',
    'orden': 1,
    'config': {
      'fontSize': 28.0,
      'fontFamily': 'Merriweather',
      'fontWeight': 'bold',
      'fontStyle': 'normal',
      'alignment': 'center',
      'lineHeight': 1.4,
      'color': null,
      'backgroundColor': null,
    },
  },
  {
    'nombre': 'Diálogo',
    'atajo': 'Ctrl+3',
    'orden': 2,
    'hereda_de_id': 1,
    'config': {
      'fontStyle': 'normal',
      'indentLeft': 20.0,
      'indentRight': 20.0,
      'wrapperOpen': '— ',
      'wrapperClose': '',
    },
  },
  {
    'nombre': 'Pensamiento',
    'atajo': 'Ctrl+4',
    'orden': 3,
    'hereda_de_id': 1,
    'config': {
      'fontStyle': 'italic',
      'color': '#A5ADBA',
      'wrapperOpen': '*',
      'wrapperClose': '*',
    },
  },
  {
    'nombre': 'Cita',
    'atajo': 'Ctrl+5',
    'orden': 4,
    'hereda_de_id': 1,
    'config': {
      'fontStyle': 'italic',
      'fontSize': 11.0,
      'indentLeft': 30.0,
      'indentRight': 30.0,
      'color': '#6C7A89',
      'wrapperOpen': '«',
      'wrapperClose': '»',
    },
  },
  {
    'nombre': 'Nota del autor',
    'atajo': null,
    'orden': 5,
    'hereda_de_id': 1,
    'config': {
      'fontSize': 10.0,
      'color': '#6C7A89',
      'fontStyle': 'italic',
      'wrapperOpen': '[Nota: ',
      'wrapperClose': ']',
    },
  },
];
