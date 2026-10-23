import '../database/app_database.dart';
import '../models/chapter_model.dart';

class ChapterRepository {
  Future<Map<String, dynamic>?> getManuscript(int proyectoId) async {
    return await AppDatabase.getManuscritoByProyecto(proyectoId);
  }

  Future<int> createManuscript(int proyectoId) async {
    return await AppDatabase.insertManuscrito({
      'proyecto_id': proyectoId,
      'contenido': '',
    });
  }

  Future<List<Chapter>> getChaptersByManuscript(int manuscritoId, {bool includeTrash = false}) async {
    final rows = await AppDatabase.getCapitulosByManuscrito(manuscritoId, includeTrash: includeTrash);
    return rows.map((r) => Chapter.fromMap(r)).toList();
  }

  Future<List<Chapter>> getTrash(int manuscritoId) async {
    final rows = await AppDatabase.getCapitulosPapelera(manuscritoId);
    return rows.map((r) => Chapter.fromMap(r)).toList();
  }

  Future<int> createChapter(Chapter chapter) async {
    return await AppDatabase.insertCapitulo(chapter.toMap());
  }

  Future<int> updateChapter(Chapter chapter) async {
    if (chapter.id == null) return -1;
    return await AppDatabase.updateCapitulo(chapter.id!, chapter.toMap());
  }

  Future<int> updateChapterRaw(int id, Map<String, dynamic> data) async {
    return await AppDatabase.updateCapitulo(id, data);
  }

  Future<int> moveToTrash(int id) async {
    return await AppDatabase.softDeleteCapitulo(id);
  }

  Future<int> restoreFromTrash(int id) async {
    return await AppDatabase.restoreCapitulo(id);
  }

  Future<int> deleteChapterPermanently(int id) async {
    return await AppDatabase.deleteCapitulo(id);
  }

  Future<int> emptyTrash(int manuscritoId) async {
    return await AppDatabase.emptyTrash(manuscritoId);
  }

  Future<int> createSnapshot(int capituloId, String contenido, {int palabras = 0, String? motivo}) async {
    return await AppDatabase.insertCapituloVersion(
      capituloId,
      contenido,
      palabras: palabras,
      motivo: motivo,
    );
  }

  Future<List<Map<String, dynamic>>> getVersions(int capituloId) async {
    return await AppDatabase.getCapituloVersiones(capituloId);
  }

  Future<int> deleteVersion(int versionId) async {
    return await AppDatabase.deleteCapituloVersion(versionId);
  }
}
