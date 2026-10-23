import 'dart:typed_data';
import '../database/app_database.dart';
import '../models/project_model.dart';

class ProjectRepository {
  Future<List<Project>> getAll() async {
    final rows = await AppDatabase.getProyectos();
    final projects = rows.map((r) => Project.fromMap(r)).toList();
    final result = <Project>[];
    for (final p in projects) {
      if (p.id != null) {
        final stats = await AppDatabase.getProyectoStats(p.id!);
        result.add(p.copyWith(
          palabras: stats['palabras'] ?? 0,
          capitulosCount: stats['capitulos'] ?? 0,
        ));
      } else {
        result.add(p);
      }
    }
    return result;
  }

  Future<int> create(Project project) async {
    return await AppDatabase.insertProyecto(project.toMap());
  }

  Future<int> update(Project project) async {
    return await AppDatabase.updateProyecto(project.toMap());
  }

  Future<int> updateTitleAndSynopsis(int id, String title, String synopsis) async {
    return await AppDatabase.updateProyectoCompleto(id, title, synopsis);
  }

  Future<void> updateCover(int id, Uint8List? imageBytes) async {
    await AppDatabase.updateProyectoPortada(id, imageBytes);
  }

  Future<int> duplicate(int id) async {
    return await AppDatabase.duplicateProyecto(id);
  }

  Future<int> delete(int id) async {
    return await AppDatabase.deleteProyecto(id);
  }

  Future<Map<String, dynamic>> getStats(int id) async {
    return await AppDatabase.getProyectoStats(id);
  }
}
