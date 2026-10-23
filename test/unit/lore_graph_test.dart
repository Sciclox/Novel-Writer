import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:novel_writer/models/lore_node_model.dart';
import 'package:novel_writer/models/lore_edge_model.dart';
import 'package:novel_writer/models/chapter_coherence_model.dart';

void main() {
  group('LoreNodeModel Tests', () {
    test('LoreNodeModel serialization and deserialization', () {
      final node = LoreNodeModel(
        id: 1,
        proyectoId: 18,
        tipo: 'personaje',
        referenciaId: 101,
        nombre: 'Long Ze',
        subtitulo: 'Décimo Príncipe / Reencarnación de Asura',
        descripcion: 'Antiguo cobarde transformado en soberano impasible.',
        color: '#00F0FF',
        posX: 500.0,
        posY: 400.0,
        estado: 'Herida leve en palma izquierda',
        propiedades: {
          'cultivo': 'Reino Alma Naciente Incompleto',
          'objetivo': 'Vengar a su madre Meng',
        },
      );

      final map = node.toMap();
      expect(map['id'], 1);
      expect(map['proyecto_id'], 18);
      expect(map['tipo'], 'personaje');
      expect(map['nombre'], 'Long Ze');
      expect(map['pos_x'], 500.0);
      expect(map['pos_y'], 400.0);
      expect(jsonDecode(map['propiedades']), containsPair('cultivo', 'Reino Alma Naciente Incompleto'));

      final parsed = LoreNodeModel.fromMap(map);
      expect(parsed.id, 1);
      expect(parsed.proyectoId, 18);
      expect(parsed.nombre, 'Long Ze');
      expect(parsed.subtitulo, 'Décimo Príncipe / Reencarnación de Asura');
      expect(parsed.propiedades['cultivo'], 'Reino Alma Naciente Incompleto');
      expect(parsed.estado, 'Herida leve en palma izquierda');
    });
  });

  group('LoreEdgeModel Tests', () {
    test('LoreEdgeModel serialization and deserialization', () {
      final edge = LoreEdgeModel(
        id: 10,
        proyectoId: 18,
        nodoOrigenId: 1,
        nodoDestinoId: 2,
        tipoRelacion: 'enemigo_de',
        etiqueta: 'Tentativa de Regicidio',
        detalles: 'Kuro intentó degollar a Long Ze durante la emboscada.',
        intensidad: 0.95,
        esBidireccional: true,
      );

      final map = edge.toMap();
      expect(map['id'], 10);
      expect(map['nodo_origen_id'], 1);
      expect(map['nodo_destino_id'], 2);
      expect(map['tipo_relacion'], 'enemigo_de');
      expect(map['intensidad'], 0.95);
      expect(map['es_bidireccional'], 1);

      final parsed = LoreEdgeModel.fromMap(map);
      expect(parsed.id, 10);
      expect(parsed.nodoOrigenId, 1);
      expect(parsed.nodoDestinoId, 2);
      expect(parsed.etiqueta, 'Tentativa de Regicidio');
      expect(parsed.esBidireccional, isTrue);
      expect(parsed.intensidad, 0.95);
    });
  });

  group('ChapterCoherenceModel Tests', () {
    test('ChapterCoherenceModel serialization and complex maps', () {
      final coherence = ChapterCoherenceModel(
        id: 5,
        capituloId: 42,
        lugarId: 7,
        personajesIds: [1, 2, 3],
        artefactosIds: [100, 101],
        estadoSalud: {
          '1': 'Herida superficial en hombro derecho',
          '2': 'Degollado / Muerto',
          '3': 'Fatiga extrema tras combate',
        },
        secretosRevelados: [
          'El Tercer Príncipe contrató a la Secta Sombría.',
          'La daga del asesino tenía veneno Quiebra-Meridianos.',
        ],
        notasContinuidad: 'Long Ze aún no puede volar ni usar la técnica de la luna frente a testigos.',
      );

      final map = coherence.toMap();
      expect(map['capitulo_id'], 42);
      expect(map['lugar_id'], 7);
      expect(jsonDecode(map['personajes_ids']), [1, 2, 3]);
      expect(jsonDecode(map['artefactos_ids']), [100, 101]);

      final parsed = ChapterCoherenceModel.fromMap(map);
      expect(parsed.capituloId, 42);
      expect(parsed.lugarId, 7);
      expect(parsed.personajesIds, [1, 2, 3]);
      expect(parsed.artefactosIds, [100, 101]);
      expect(parsed.estadoSalud['1'], 'Herida superficial en hombro derecho');
      expect(parsed.estadoSalud['2'], 'Degollado / Muerto');
      expect(parsed.secretosRevelados.length, 2);
      expect(parsed.secretosRevelados.first, contains('Tercer Príncipe'));
      expect(parsed.notasContinuidad, contains('Long Ze aún no puede volar'));
    });
  });
}
