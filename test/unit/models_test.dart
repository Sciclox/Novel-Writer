import 'package:flutter_test/flutter_test.dart';
import 'package:novel_writer/models/project_model.dart';
import 'package:novel_writer/models/chapter_model.dart';
import 'package:novel_writer/models/character_model.dart';
import 'package:novel_writer/models/place_model.dart';
import 'package:novel_writer/models/timeline_event_model.dart';
import 'package:novel_writer/models/note_model.dart';
import 'package:novel_writer/models/idea_card_model.dart';

void main() {
  group('Model Serialization Tests', () {
    test('Project model fromMap and toMap', () {
      final project = Project(
        id: 1,
        titulo: 'Crónicas de la Niebla',
        sinopsis: 'Una aventura épica.',
        palabras: 12500,
        capitulosCount: 8,
      );

      final map = project.toMap();
      expect(map['id'], 1);
      expect(map['titulo'], 'Crónicas de la Niebla');
      expect(map['sinopsis'], 'Una aventura épica.');

      final parsed = Project.fromMap(map);
      expect(parsed.id, 1);
      expect(parsed.titulo, 'Crónicas de la Niebla');
      expect(parsed.sinopsis, 'Una aventura épica.');
    });

    test('Chapter model fromMap and toMap', () {
      final chapter = Chapter(
        id: 10,
        manuscritoId: 2,
        titulo: 'El Despertar',
        contenido: '[{"insert":"Hola mundo"}]',
        orden: 1,
        tipo: 'capitulo',
        palabras: 2,
        metaSesion: 500,
        metaDiaria: 1000,
      );

      final map = chapter.toMap();
      expect(map['manuscrito_id'], 2);
      expect(map['titulo'], 'El Despertar');
      expect(map['palabras'], 2);

      final parsed = Chapter.fromMap(map);
      expect(parsed.id, 10);
      expect(parsed.titulo, 'El Despertar');
      expect(parsed.metaSesion, 500);
      expect(parsed.metaDiaria, 1000);
    });

    test('Character model with complex attributes', () {
      final character = Character(
        id: 5,
        proyectoId: 1,
        nombre: 'Kaelen',
        rol: 'Protagonista',
        alias: 'El Errante',
        fraseIconica: 'La noche siempre cede ante el alba.',
        atributos: {
          'DESEO': 'Encontrar la verdad',
          'MIEDO': 'El olvido',
        },
      );

      final map = character.toMap();
      expect(map['nombre'], 'Kaelen');
      expect(map['atributos'], contains('Encontrar la verdad'));

      final parsed = Character.fromMap(map);
      expect(parsed.nombre, 'Kaelen');
      expect(parsed.atributos['DESEO'], 'Encontrar la verdad');
      expect(parsed.atributos['MIEDO'], 'El olvido');
    });

    test('Place model fromMap and toMap', () {
      final place = Place(
        id: 3,
        proyectoId: 1,
        nombre: 'Valle de Eldor',
        clima: 'Templado y brumoso',
        importancia: 'Principal',
        atributos: {'HISTORIA': 'Antigua ciudadela élfica'},
      );

      final map = place.toMap();
      expect(map['nombre'], 'Valle de Eldor');
      expect(map['importancia'], 'Principal');

      final parsed = Place.fromMap(map);
      expect(parsed.nombre, 'Valle de Eldor');
      expect(parsed.atributos['HISTORIA'], 'Antigua ciudadela élfica');
    });

    test('TimelineEvent model fromMap and toMap', () {
      final event = TimelineEvent(
        id: 4,
        proyectoId: 1,
        titulo: 'Batalla del Río Helado',
        fechaRelativa: 'Día 15',
        importancia: 3,
        colorHex: '#FF5252',
        orden: 2,
      );

      final map = event.toMap();
      expect(map['titulo'], 'Batalla del Río Helado');
      expect(map['importancia'], 3);

      final parsed = TimelineEvent.fromMap(map);
      expect(parsed.titulo, 'Batalla del Río Helado');
      expect(parsed.importancia, 3);
      expect(parsed.colorHex, '#FF5252');
    });

    test('Note & Category models fromMap and toMap', () {
      final note = Note(
        id: 7,
        manuscritoId: 1,
        contenido: 'Revisar ritmo del diálogo en escena 2.',
        categoria: 'dialogo',
        posX: 120.0,
        posY: 240.0,
      );

      final map = note.toMap();
      expect(map['categoria'], 'dialogo');

      final parsed = Note.fromMap(map);
      expect(parsed.contenido, 'Revisar ritmo del diálogo en escena 2.');
      expect(parsed.posX, 120.0);
      expect(parsed.posY, 240.0);
    });

    test('IdeaCard model fromMap and toMap', () {
      final card = IdeaCard(
        id: 9,
        proyectoId: 1,
        titulo: 'Giro de trama',
        contenido: 'El mentor era en realidad el villano.',
        tipo: 'trama',
        color: '#BBDEFB',
      );

      final map = card.toMap();
      expect(map['titulo'], 'Giro de trama');

      final parsed = IdeaCard.fromMap(map);
      expect(parsed.titulo, 'Giro de trama');
      expect(parsed.tipo, 'trama');
      expect(parsed.color, '#BBDEFB');
    });
  });
}
