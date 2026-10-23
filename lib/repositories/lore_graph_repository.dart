import '../database/app_database.dart';
import '../models/lore_node_model.dart';
import '../models/lore_edge_model.dart';
import '../models/chapter_coherence_model.dart';

class LoreGraphRepository {
  Future<List<LoreNodeModel>> getNodes(int proyectoId) async {
    final rows = await AppDatabase.getGrafoNodos(proyectoId);
    return rows.map((r) => LoreNodeModel.fromMap(r)).toList();
  }

  Future<int> addNode(LoreNodeModel node) async {
    return await AppDatabase.insertGrafoNodo(node.toMap());
  }

  Future<int> updateNode(LoreNodeModel node) async {
    if (node.id == null) return -1;
    return await AppDatabase.updateGrafoNodo(node.id!, node.toMap());
  }

  Future<int> deleteNode(int id) async {
    return await AppDatabase.deleteGrafoNodo(id);
  }

  Future<List<LoreEdgeModel>> getEdges(int proyectoId) async {
    final rows = await AppDatabase.getGrafoAristas(proyectoId);
    return rows.map((r) => LoreEdgeModel.fromMap(r)).toList();
  }

  Future<int> addEdge(LoreEdgeModel edge) async {
    return await AppDatabase.insertGrafoArista(edge.toMap());
  }

  Future<int> updateEdge(LoreEdgeModel edge) async {
    if (edge.id == null) return -1;
    return await AppDatabase.updateGrafoArista(edge.id!, edge.toMap());
  }

  Future<int> deleteEdge(int id) async {
    return await AppDatabase.deleteGrafoArista(id);
  }

  Future<ChapterCoherenceModel?> getCoherence(int capituloId) async {
    final row = await AppDatabase.getCapituloCoherencia(capituloId);
    if (row == null) return null;
    return ChapterCoherenceModel.fromMap(row);
  }

  Future<int> saveCoherence(ChapterCoherenceModel model) async {
    return await AppDatabase.upsertCapituloCoherencia(model.capituloId, model.toMap());
  }

  Future<void> syncExistingEntities(int proyectoId) async {
    await AppDatabase.syncGrafoFromProjectEntities(proyectoId);
  }

  /// Construye una ficha de contexto estructurado para el capítulo lista para enviar a la IA o consultar por el autor
  Future<String> generateAiContextPrompt({
    required int proyectoId,
    required int capituloId,
    required String capituloTitulo,
  }) async {
    final coherence = await getCoherence(capituloId);
    final nodes = await getNodes(proyectoId);
    final edges = await getEdges(proyectoId);

    final sb = StringBuffer();
    sb.writeln('### FICHA DE COHERENCIA Y ESTADO NARRATIVO');
    sb.writeln('**Capítulo:** $capituloTitulo');

    // 1. Escenario
    if (coherence?.lugarId != null) {
      final lugarNode = nodes.where((n) => n.id == coherence!.lugarId || (n.tipo == 'lugar' && n.referenciaId == coherence.lugarId)).firstOrNull;
      if (lugarNode != null) {
        sb.writeln('\n#### 📍 Escenario / Ubicación');
        sb.writeln('- **${lugarNode.nombre}:** ${lugarNode.descripcion ?? 'Sin descripción'}');
      }
    }

    // 2. Personajes Presentes y Estados
    if (coherence != null && coherence.personajesIds.isNotEmpty) {
      sb.writeln('\n#### 👥 Personajes Presentes en Escena');
      for (final pId in coherence.personajesIds) {
        final node = nodes.where((n) => n.id == pId || (n.tipo == 'personaje' && n.referenciaId == pId)).firstOrNull;
        if (node != null) {
          final estadoStr = coherence.estadoSalud[pId.toString()] ?? coherence.estadoSalud[node.id.toString()] ?? node.estado;
          sb.writeln('- **${node.nombre}** (${node.subtitulo ?? 'Personaje'})');
          sb.writeln('  * Condición / Salud: $estadoStr');
          if (node.propiedades['objetivo'] != null && node.propiedades['objetivo'].toString().isNotEmpty) {
            sb.writeln('  * Objetivo actual: ${node.propiedades['objetivo']}');
          }

          // Relaciones con otros presentes
          final rels = edges.where((e) => (e.nodoOrigenId == node.id || e.nodoDestinoId == node.id)).toList();
          for (final r in rels) {
            final otherNodeId = r.nodoOrigenId == node.id ? r.nodoDestinoId : r.nodoOrigenId;
            final otherNode = nodes.where((n) => n.id == otherNodeId).firstOrNull;
            if (otherNode != null && (coherence.personajesIds.contains(otherNode.id) || (otherNode.referenciaId != null && coherence.personajesIds.contains(otherNode.referenciaId)))) {
              final tag = r.etiqueta ?? r.tipoRelacion;
              sb.writeln('  * Vínculo con ${otherNode.nombre}: $tag (${(r.intensidad * 100).round()}% intensidad)');
            }
          }
        }
      }
    }

    // 3. Artefactos / Armas en Juego
    if (coherence != null && coherence.artefactosIds.isNotEmpty) {
      sb.writeln('\n#### ⚔️ Artefactos y Armas en Escena');
      for (final aId in coherence.artefactosIds) {
        final node = nodes.where((n) => n.id == aId).firstOrNull;
        if (node != null) {
          sb.writeln('- **${node.nombre}:** ${node.descripcion ?? node.subtitulo ?? 'En mano'}');
        }
      }
    }

    // 4. Secretos y Reglas de Continuidad
    if (coherence != null) {
      if (coherence.secretosRevelados.isNotEmpty) {
        sb.writeln('\n#### 🗝️ Secretos Conocidos en este Punto');
        for (final s in coherence.secretosRevelados) {
          sb.writeln('- $s');
        }
      }
      if (coherence.notasContinuidad != null && coherence.notasContinuidad!.trim().isNotEmpty) {
        sb.writeln('\n#### ⚠️ Reglas y Advertencias de Continuidad');
        sb.writeln(coherence.notasContinuidad!.trim());
      }
    }

    sb.writeln('\n---');
    sb.writeln('*Instrucción para redacción: Respeta estrictamente los estados, heridas y limitaciones expuestos arriba. Cero contradicciones con hechos previos.*');

    return sb.toString();
  }
}
