import '../database/app_database.dart';
import '../models/character_model.dart';
import '../models/character_relation_model.dart';

class CharacterRepository {
  Future<List<Character>> getByProject(int proyectoId) async {
    final rows = await AppDatabase.getPersonajesByProyecto(proyectoId);
    return rows.map((r) => Character.fromMap(r)).toList();
  }

  Future<int> create(Character character) async {
    return await AppDatabase.insertPersonaje(character.toMap());
  }

  Future<int> update(Character character) async {
    if (character.id == null) return -1;
    return await AppDatabase.updatePersonaje(character.id!, character.toMap());
  }

  Future<int> delete(int id) async {
    return await AppDatabase.deletePersonaje(id);
  }

  Future<List<CharacterRelation>> getRelations(int characterId) async {
    final rows = await AppDatabase.getRelacionesByPersonaje(characterId);
    return rows.map((r) => CharacterRelation.fromMap(r)).toList();
  }

  Future<int> createRelation(CharacterRelation relation) async {
    return await AppDatabase.insertRelacion(relation.toMap());
  }

  Future<int> updateRelation(CharacterRelation relation) async {
    if (relation.id == null) return -1;
    return await AppDatabase.updateRelacion(relation.id!, relation.toMap());
  }

  Future<int> deleteRelation(int id) async {
    return await AppDatabase.deleteRelacion(id);
  }
}
