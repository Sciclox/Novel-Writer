import '../database/app_database.dart';
import '../models/place_model.dart';

class PlaceRepository {
  Future<List<Place>> getByProject(int proyectoId) async {
    final rows = await AppDatabase.getLugaresByProyecto(proyectoId);
    return rows.map((r) => Place.fromMap(r)).toList();
  }

  Future<int> create(Place place) async {
    return await AppDatabase.insertLugar(place.toMap());
  }

  Future<int> update(Place place) async {
    if (place.id == null) return -1;
    return await AppDatabase.updateLugar(place.id!, place.toMap());
  }

  Future<int> delete(int id) async {
    return await AppDatabase.deleteLugar(id);
  }
}
