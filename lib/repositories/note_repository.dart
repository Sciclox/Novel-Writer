import '../database/app_database.dart';
import '../models/note_model.dart';

class NoteRepository {
  Future<List<Note>> getByManuscript(int manuscritoId) async {
    final rows = await AppDatabase.getNotasByManuscrito(manuscritoId);
    return rows.map((r) => Note.fromMap(r)).toList();
  }

  Future<int> create(Note note) async {
    return await AppDatabase.insertNota(note.toMap());
  }

  Future<int> updatePosition(int id, double x, double y) async {
    return await AppDatabase.updateNotaPosicion(id, x, y);
  }

  Future<int> updateContent(int id, String content) async {
    return await AppDatabase.updateNotaContenido(id, content);
  }

  Future<int> delete(int id) async {
    return await AppDatabase.deleteNota(id);
  }

  Future<List<NoteCategory>> getCategories() async {
    final rows = await AppDatabase.getCategorias();
    return rows.map((r) => NoteCategory.fromMap(r)).toList();
  }

  Future<int> createCategory(NoteCategory category) async {
    return await AppDatabase.insertCategoria(category.toMap());
  }

  Future<int> updateCategory(NoteCategory category) async {
    return await AppDatabase.updateCategoria(category.id, category.toMap());
  }

  Future<int> deleteCategory(int id) async {
    return await AppDatabase.deleteCategoria(id);
  }
}
