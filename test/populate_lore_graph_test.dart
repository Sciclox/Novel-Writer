import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:novel_writer/database/app_database.dart';
import 'package:novel_writer/models/lore_node_model.dart';
import 'package:novel_writer/models/lore_edge_model.dart';
import 'package:novel_writer/models/chapter_coherence_model.dart';
import 'package:novel_writer/repositories/lore_graph_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  const dbPath = r'C:\Users\Lenovo\OneDrive\Documentos\novel_writer.db';

  group('Populate Lore Graph & Chapter Coherence Matrix in Real DB', () {
    test('Populate lore nodes, factions, artifacts, mysteries, edges and chapter coherence', () async {
      final db = await openDatabase(
        dbPath,
        version: 21,
        onUpgrade: (db, oldVersion, newVersion) async {
          await AppDatabase.upgradeDatabaseForTesting(db, oldVersion, newVersion);
        },
      );
      AppDatabase.setDatabaseForTesting(db);

      final repo = LoreGraphRepository();

      // 1. Encontrar el proyecto de la novela web
      final projects = await db.query(
        'proyectos',
        where: 'titulo LIKE ?',
        whereArgs: ['%El Décimo Príncipe%'],
      );
      expect(projects.isNotEmpty, isTrue, reason: 'El proyecto de novela web debe existir en la BD');

      final projectId = projects.first['id'] as int;
      print('>>> Poblando Lore Graph para Proyecto ID: $projectId ("${projects.first['titulo']}")');

      // 2. Sincronizar entidades existentes (personajes y lugares a nodos)
      await repo.syncExistingEntities(projectId);
      var nodes = await repo.getNodes(projectId);
      print('Nodos tras sync base: ${nodes.length}');

      // Identificar nodos clave existentes
      LoreNodeModel? longZeNode = nodes.where((n) => n.tipo == 'personaje' && n.nombre.contains('Long Ze')).firstOrNull;
      LoreNodeModel? zhaoHuNode = nodes.where((n) => n.tipo == 'personaje' && n.nombre.contains('Zhao Hu')).firstOrNull;
      LoreNodeModel? kuroNode = nodes.where((n) => n.tipo == 'personaje' && n.nombre.contains('Kuro')).firstOrNull;
      LoreNodeModel? longZhenNode = nodes.where((n) => n.tipo == 'personaje' && n.nombre.contains('Long Zhen')).firstOrNull;
      LoreNodeModel? pabellonNode = nodes.where((n) => n.tipo == 'lugar' && n.nombre.contains('Pabellón')).firstOrNull;

      // 3. Crear Facciones, Artefactos y Misterios si no existen
      Future<LoreNodeModel> ensureNode({
        required String nombre,
        required String tipo,
        required String subtitulo,
        required String descripcion,
        required String color,
        required double posX,
        required double posY,
        String estado = 'activo',
        Map<String, dynamic> propiedades = const {},
      }) async {
        final existing = nodes.where((n) => n.nombre == nombre && n.tipo == tipo).firstOrNull;
        if (existing != null) return existing;

        final newNode = LoreNodeModel(
          proyectoId: projectId,
          tipo: tipo,
          nombre: nombre,
          subtitulo: subtitulo,
          descripcion: descripcion,
          color: color,
          posX: posX,
          posY: posY,
          estado: estado,
          propiedades: propiedades,
        );
        final id = await repo.addNode(newNode);
        return newNode.copyWith(id: id);
      }

      final dinastiaNode = await ensureNode(
        nombre: 'Dinastía Imperial de las Nueve Nubes',
        tipo: 'faccion',
        subtitulo: 'Corte Imperial / Linaje del Dragón',
        descripcion: 'Imperio central gobernado por el Emperador Tianlong. Nido de intrigas fratricidas y luchas por la sucesión al trono del Dragón.',
        color: '#AB47BC',
        posX: 380,
        posY: 180,
        propiedades: {'poder': 'Nivel Continental', 'gobernante': 'Emperador Tianlong'},
      );

      final sectaLunaNode = await ensureNode(
        nombre: 'Secta de la Luna Sangrienta',
        tipo: 'faccion',
        subtitulo: 'Sindicato de Asesinos en la Sombra',
        descripcion: 'Gremio de cultivadores oscuros especializados en asesinatos políticos silenciosos. Ningún testigo sobrevive a sus cuchillas carmesí.',
        color: '#E91E63',
        posX: 1100,
        posY: 220,
        propiedades: {'lider': 'Señor de la Luna Menguante', 'reputacion': 'Infalible'},
      );

      final alabardaNode = await ensureNode(
        nombre: 'Alabarda del Dragón Oscuro',
        tipo: 'artefacto',
        subtitulo: 'Tesoro Sagrado Prohibido de Rango Divino',
        descripcion: 'Arma sellada en las profundidades del mar de conciencia de Long Ze tras despertar como Asura. Corta el flujo del Qi con un solo tajo.',
        color: '#00E5FF',
        posX: 700,
        posY: 900,
        estado: 'Sellada parcialmente en el dantian',
        propiedades: {'rango': 'Grado Divino', 'elemento': 'Oscuridad / Sangre'},
      );

      final dagaKuroNode = await ensureNode(
        nombre: 'Daga de Qi Negro Corrosivo',
        tipo: 'artefacto',
        subtitulo: 'Arma Asesina de Grado Tierra',
        descripcion: 'Hoja bañada en la ponzoña del Escorpión de Nueve Colas. Destruye los meridianos del objetivo en menos de doce respiraciones.',
        color: '#76FF03',
        posX: 1150,
        posY: 750,
        estado: 'Roto / Retenido como prueba',
        propiedades: {'veneno': 'Escorpión de Nueve Colas', 'creador': 'Secta de la Luna'},
      );

      final pildoraNode = await ensureNode(
        nombre: 'Píldora del Loto Carmesí',
        tipo: 'artefacto',
        subtitulo: 'Elixir de Regeneración de Qi Prohibido',
        descripcion: 'Píldora medicinal que sana órganos internos a costa de quemar la fuerza vital si no se tiene cultivo de hierro.',
        color: '#FFB300',
        posX: 400,
        posY: 880,
        propiedades: {'pureza': '95%', 'efecto': 'Curación rápida'},
      );

      final misterioMengNode = await ensureNode(
        nombre: 'Envenenamiento de la Concubina Meng',
        tipo: 'misterio',
        subtitulo: 'El Secreto de la Muerte Materna',
        descripcion: 'La madre del Décimo Príncipe murió presuntamente de "enfermedad repentina" hace 5 años. Se sospecha una orden directa de la Emperatriz o de Long Zhen.',
        color: '#FF9100',
        posX: 250,
        posY: 520,
        estado: 'Bajo investigación secreta',
        propiedades: {'sospechoso': 'Emperatriz / Primer Príncipe'},
      );

      final misterioComplotNode = await ensureNode(
        nombre: 'El Mandante de la Emboscada Nocturna',
        tipo: 'misterio',
        subtitulo: '¿Quién ordenó la ejecución de Long Ze?',
        descripcion: 'Kuro no actuó por iniciativa propia; portaba un medallón de paso imperial del Tercer o Primer Príncipe.',
        color: '#FF1744',
        posX: 950,
        posY: 480,
        estado: 'Evidencia parcial obtenida',
      );

      // Recargar nodos para tener IDs completos
      nodes = await repo.getNodes(projectId);

      // 4. Crear o verificar Aristas (Relaciones del Lore)
      final existingEdges = await repo.getEdges(projectId);

      Future<void> ensureEdge({
        required int origenId,
        required int destinoId,
        required String tipoRelacion,
        String? etiqueta,
        double intensidad = 1.0,
        bool esBidireccional = false,
        String? detalles,
      }) async {
        final found = existingEdges.where((e) =>
            (e.nodoOrigenId == origenId && e.nodoDestinoId == destinoId) ||
            (esBidireccional && e.nodoOrigenId == destinoId && e.nodoDestinoId == origenId)).firstOrNull;

        if (found == null) {
          await repo.addEdge(LoreEdgeModel(
            proyectoId: projectId,
            nodoOrigenId: origenId,
            nodoDestinoId: destinoId,
            tipoRelacion: tipoRelacion,
            etiqueta: etiqueta,
            intensidad: intensidad,
            esBidireccional: esBidireccional,
            detalles: detalles,
          ));
        }
      }

      if (longZeNode != null && kuroNode != null) {
        await ensureEdge(
          origenId: longZeNode.id!,
          destinoId: kuroNode.id!,
          tipoRelacion: 'enemigo_de',
          etiqueta: 'Tentativa de Homicidio',
          intensidad: 1.0,
          esBidireccional: true,
          detalles: 'Kuro intentó degollar a Long Ze. Long Ze aplastó su cráneo tras despertar.',
        );
      }

      if (longZeNode != null && zhaoHuNode != null) {
        await ensureEdge(
          origenId: longZeNode.id!,
          destinoId: zhaoHuNode.id!,
          tipoRelacion: 'aliado_de',
          etiqueta: 'Lealtad Inquebrantable',
          intensidad: 0.95,
          esBidireccional: true,
          detalles: 'Zhao Hu juró dar su vida por Long Ze al presenciar su renacer.',
        );
      }

      if (longZeNode != null && longZhenNode != null) {
        await ensureEdge(
          origenId: longZeNode.id!,
          destinoId: longZhenNode.id!,
          tipoRelacion: 'enemigo_de',
          etiqueta: 'Rivalidad Fratricida',
          intensidad: 0.9,
          esBidireccional: true,
          detalles: 'Long Zhen considera a Long Ze una mancha en el linaje imperial.',
        );
      }

      if (longZeNode != null) {
        await ensureEdge(
          origenId: longZeNode.id!,
          destinoId: alabardaNode.id!,
          tipoRelacion: 'posee',
          etiqueta: 'Arma Espiritual Asura',
          intensidad: 1.0,
          detalles: 'Sellada en el dantian del Décimo Príncipe.',
        );

        await ensureEdge(
          origenId: longZeNode.id!,
          destinoId: misterioMengNode.id!,
          tipoRelacion: 'investiga',
          etiqueta: 'Venganza Jurada',
          intensidad: 1.0,
          detalles: 'Long Ze buscará a los responsables directos de la muerte de su madre.',
        );
      }

      if (kuroNode != null) {
        await ensureEdge(
          origenId: kuroNode.id!,
          destinoId: sectaLunaNode.id!,
          tipoRelacion: 'miembro_de',
          etiqueta: 'Sicario Rango Oro',
          intensidad: 0.9,
        );

        await ensureEdge(
          origenId: kuroNode.id!,
          destinoId: dagaKuroNode.id!,
          tipoRelacion: 'posee',
          etiqueta: 'Arma Asesina',
          intensidad: 0.8,
        );

        await ensureEdge(
          origenId: kuroNode.id!,
          destinoId: misterioComplotNode.id!,
          tipoRelacion: 'sabe_secreto',
          etiqueta: 'Portador de la Orden',
          intensidad: 0.9,
        );
      }

      if (longZhenNode != null) {
        await ensureEdge(
          origenId: longZhenNode.id!,
          destinoId: dinastiaNode.id!,
          tipoRelacion: 'miembro_de',
          etiqueta: 'Primer Príncipe Heredero',
          intensidad: 0.95,
        );

        await ensureEdge(
          origenId: longZhenNode.id!,
          destinoId: misterioComplotNode.id!,
          tipoRelacion: 'investiga',
          etiqueta: 'Sospechoso de Conspiración',
          intensidad: 0.7,
        );
      }

      await ensureEdge(
        origenId: sectaLunaNode.id!,
        destinoId: dinastiaNode.id!,
        tipoRelacion: 'enemigo_de',
        etiqueta: 'Guerra Fría en las Sombras',
        intensidad: 0.85,
        esBidireccional: true,
      );

      print('Aristas vinculadas exitosamente.');

      // 5. Poblar Matriz de Coherencia de los Capítulos
      final manuscritos = await db.query('manuscritos', where: 'proyecto_id = ?', whereArgs: [projectId]);
      final manId = manuscritos.first['id'] as int;
      final caps = await db.query('capitulos', where: 'manuscrito_id = ?', orderBy: 'orden ASC', whereArgs: [manId]);

      if (caps.isNotEmpty && longZeNode != null) {
        // Capítulo 1
        final cap1 = caps[0];
        final cap1Id = cap1['id'] as int;
        final coh1 = ChapterCoherenceModel(
          capituloId: cap1Id,
          lugarId: pabellonNode?.id,
          personajesIds: [
            longZeNode.id!,
            if (kuroNode != null) kuroNode.id!,
            if (zhaoHuNode != null) zhaoHuNode.id!,
          ],
          artefactosIds: [dagaKuroNode.id!],
          estadoSalud: {
            longZeNode.id!.toString(): 'Ojos carmesí encendidos; Qi desbordante pero cuerpo físico dolorido',
            if (kuroNode != null) kuroNode.id!.toString(): 'Muerto (Cráneo destrozado)',
            if (zhaoHuNode != null) zhaoHuNode.id!.toString(): 'Corte sangrante en hombro izquierdo',
          },
          secretosRevelados: [
            'El Décimo Príncipe Long Ze alberga el alma de un Emperador Asura.',
            'El atacante pertenecía a la temida Secta de la Luna Sangrienta.',
          ],
          notasContinuidad: 'Zhao Hu es el único testigo del despertar. Long Ze le advierte que el silencio es la única garantía de su vida.',
        );
        await repo.saveCoherence(coh1);
        print('Coherencia guardada para Capítulo 1: ${cap1['titulo']}');

        // Capítulo 2
        if (caps.length > 1) {
          final cap2 = caps[1];
          final cap2Id = cap2['id'] as int;
          final coh2 = ChapterCoherenceModel(
            capituloId: cap2Id,
            lugarId: pabellonNode?.id,
            personajesIds: [
              longZeNode.id!,
              if (zhaoHuNode != null) zhaoHuNode.id!,
            ],
            artefactosIds: [dagaKuroNode.id!, pildoraNode.id!],
            estadoSalud: {
              longZeNode.id!.toString(): 'Estabilizando sus meridianos con técnica de respiración Asura',
              if (zhaoHuNode != null) zhaoHuNode.id!.toString(): 'Vendaje apretado con polvo cicatrizante',
            },
            secretosRevelados: [
              'La daga tiene grabado un sello oculto del Tercer Príncipe o del Departamento Imperial de Armas.',
            ],
            notasContinuidad: 'El cuerpo de Kuro fue incinerado sin dejar rastro para evitar que los espías sospechen del cambio en Long Ze.',
          );
          await repo.saveCoherence(coh2);
          print('Coherencia guardada para Capítulo 2: ${cap2['titulo']}');
        }

        // Probar y validar el Prompt generado para el Capítulo 1
        final promptPreview = await repo.generateAiContextPrompt(
          proyectoId: projectId,
          capituloId: cap1Id,
          capituloTitulo: cap1['titulo'] as String? ?? 'Capítulo 1',
        );

        print('\n========================================');
        print('PROMPT GENERADO POR LoreGraphRepository:');
        print('========================================');
        print(promptPreview);
        print('========================================\n');

        expect(promptPreview, contains('FICHA DE COHERENCIA Y ESTADO NARRATIVO'));
        expect(promptPreview, contains('Long Ze'));
        expect(promptPreview, contains('Pabellón'));
        expect(promptPreview, contains('Asura'));
      }
    });
  });
}
